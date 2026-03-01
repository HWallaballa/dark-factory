#!/usr/bin/env bash
# =============================================================================
# Dark Factory Orchestrator — Profit-First Edition
#
# Philosophy: Every Claude API dollar spent must return more in revenue.
#   - Small specs  → local Ollama (free)
#   - Medium specs → Claude Haiku (~$0.25/task)
#   - Large specs  → Claude Sonnet (~$2-5/task, only for revenue-critical work)
#
# Daily budget guard: stops spending if daily API cost hits $DAILY_BUDGET_USD.
# =============================================================================

set -euo pipefail

# --- Config ------------------------------------------------------------------
DARK_FACTORY_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)"
SPECS_DIR="$DARK_FACTORY_DIR/specs"
IN_PROGRESS_DIR="$SPECS_DIR/in-progress"
COMPLETED_DIR="$SPECS_DIR/completed"
LOGS_DIR="$DARK_FACTORY_DIR/logs"
COST_LOG="$LOGS_DIR/daily-cost-$(date +%Y-%m-%d).json"
LOG_FILE="$LOGS_DIR/orchestrator-$(date +%Y-%m-%d).log"
POLL_INTERVAL="${POLL_INTERVAL:-30}"

# Daily budget in USD — orchestrator pauses Claude API if exceeded
DAILY_BUDGET_USD="${DAILY_BUDGET_USD:-15}"

# Ollama local model for small tasks (free)
LOCAL_MODEL="${LOCAL_MODEL:-deepseek-coder-v2:16b}"
OLLAMA_URL="${OLLAMA_URL:-http://127.0.0.1:11434}"

# --- Cost tracking -----------------------------------------------------------
# Rough token cost estimates (USD per 1K tokens, Sonnet pricing)
COST_PER_1K_INPUT=0.003
COST_PER_1K_OUTPUT=0.015

get_todays_spend() {
  if [[ -f "$COST_LOG" ]]; then
    python3 -c "import json,sys; d=json.load(open('$COST_LOG')); print(sum(r.get('cost_usd',0) for r in d))" 2>/dev/null || echo "0"
  else
    echo "0"
  fi
}

log_cost() {
  local spec_name="$1" engine="$2" cost_usd="$3" tokens_in="$4" tokens_out="$5"
  python3 - <<PYEOF
import json, os, time
log_file = "$COST_LOG"
records = json.load(open(log_file)) if os.path.exists(log_file) else []
records.append({
  "ts": time.strftime("%Y-%m-%dT%H:%M:%S"),
  "spec": "$spec_name",
  "engine": "$engine",
  "cost_usd": float("$cost_usd"),
  "tokens_in": int("${tokens_in:-0}"),
  "tokens_out": int("${tokens_out:-0}")
})
json.dump(records, open(log_file, "w"), indent=2)
PYEOF
}

# --- Helpers -----------------------------------------------------------------
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"; }

notify() {
  local title="$1" body="$2"
  log "NOTIFY: $title — $body"
  if [[ -n "${DISCORD_WEBHOOK_URL:-}" ]]; then
    curl -s -X POST "$DISCORD_WEBHOOK_URL" \
      -H "Content-Type: application/json" \
      -d "{\"content\":\"**${title}**\n${body}\"}" >/dev/null
  fi
}

# --- Route spec to the right engine ------------------------------------------
# Code implementation always uses Claude Code CLI (only thing that writes files).
# Local Ollama is reserved for meta-tasks (commit messages, summaries) — future use.
# Returns: "sonnet" for all code specs
route_spec() {
  local spec_file="$1"
  local task_type
  task_type=$(grep -m1 '^- \*\*task_type:\*\*' "$spec_file" 2>/dev/null | grep -oP '(meta|code)' || echo "code")

  case "$task_type" in
    meta)  echo "local" ;;   # commit messages, summaries, non-file tasks
    *)     echo "sonnet" ;;  # all code implementation → Claude Code CLI
  esac
}

# --- Run with local Ollama (free) -------------------------------------------
run_local() {
  local spec_name="$1" prompt="$2" run_log="$3"

  log "  Engine: LOCAL ($LOCAL_MODEL) — \$0.00"

  local response
  response=$(curl -s "$OLLAMA_URL/api/generate" \
    -d "{\"model\":\"$LOCAL_MODEL\",\"prompt\":$(echo "$prompt" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'),\"stream\":false}" \
    | python3 -c "import json,sys; print(json.load(sys.stdin).get('response',''))" 2>/dev/null)

  echo "$response" >> "$run_log"
  log_cost "$spec_name" "local" "0" "0" "0"
  echo "$response"
}

# --- Run with Claude Code CLI ------------------------------------------------
run_claude() {
  local spec_name="$1" prompt="$2" run_log="$3" target_repo="$4"

  log "  Engine: Claude Sonnet (API)"

  # Check daily budget before spending
  local todays_spend
  todays_spend=$(get_todays_spend)
  if python3 -c "exit(0 if float('$todays_spend') < $DAILY_BUDGET_USD else 1)" 2>/dev/null; then
    log "  Today's spend: \$${todays_spend} / \$${DAILY_BUDGET_USD} budget"
  else
    log "⚠️  DAILY BUDGET REACHED (\$${todays_spend} >= \$${DAILY_BUDGET_USD}). Requeuing."
    notify "⚠️ Budget Paused" "Daily budget of \$$DAILY_BUDGET_USD reached. Restarting at midnight."
    return 1
  fi

  # Validate target repo exists
  if [[ ! -d "$target_repo" ]]; then
    log "❌ Target repo not found: $target_repo"
    return 1
  fi

  log "  Target repo: $target_repo"

  # Build a full implementation prompt for Claude Code
  local full_prompt
  full_prompt="You are an autonomous software engineer. Implement the following spec completely.

IMPORTANT RULES:
- Create a git branch named: spec/${spec_name}-$(date +%Y%m%d)
- Write all code changes to the files specified in the spec
- Run any available tests (npm test, etc.) and fix failures
- Open a GitHub PR with: title = 'feat: ${spec_name}', body = summary of what was built
- Do NOT ask for clarification — make reasonable decisions and document them in the PR

SPEC:
${prompt}"

  local exit_code=0

  # Claude Code requires a real TTY — use script(1) to provide one
  (
    cd "$target_repo"
    script -q -e /dev/null -c \
      "ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY:-} claude --dangerously-skip-permissions -p $(printf '%q' "$full_prompt")" \
      >> "$run_log" 2>&1
  ) || exit_code=$?

  # Estimate cost (word count proxy)
  local words_in words_out est_cost
  words_in=$(echo "$full_prompt" | wc -w)
  words_out=$(wc -w < "$run_log" 2>/dev/null || echo 1000)
  est_cost=$(python3 -c "print(round(($words_in/750)*$COST_PER_1K_INPUT + ($words_out/750)*$COST_PER_1K_OUTPUT, 4))")
  log_cost "$spec_name" "claude-sonnet" "$est_cost" "$words_in" "$words_out"
  log "  Estimated cost: \$${est_cost}"

  return $exit_code
}

# --- Dispatch a spec ---------------------------------------------------------
dispatch_spec() {
  local spec_file="$1"
  local spec_name
  spec_name="$(basename "$spec_file" .md)"
  local run_log="$LOGS_DIR/run-$spec_name-$(date +%Y%m%d-%H%M%S).log"

  log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  log "Spec: $spec_name"

  # Move to in-progress
  mv "$spec_file" "$IN_PROGRESS_DIR/"
  local working_spec="$IN_PROGRESS_DIR/$spec_name.md"

  # Extract target repo from spec (fallback to website repo)
  local target_repo
  target_repo=$(grep -m1 '^\- \*\*repo:\*\*' "$working_spec" 2>/dev/null | sed 's/.*\*\*repo:\*\* *//' | xargs || true)
  target_repo="${target_repo:-/home/gilberto/Desktop/Pinehaven Ventures/pinehaven-ventures-website}"

  local engine
  engine=$(route_spec "$working_spec")
  log "  Route: $engine | Repo: $(basename "$target_repo")"

  local prompt
  prompt="$(cat "$working_spec")"

  notify "🏭 Dark Factory" "Starting: $spec_name → $(basename "$target_repo")"

  local exit_code=0

  case "$engine" in
    local)
      run_local "$spec_name" "$prompt" "$run_log" || exit_code=$?
      ;;
    *)
      run_claude "$spec_name" "$prompt" "$run_log" "$target_repo" || exit_code=$?
      ;;
  esac

  if [[ $exit_code -eq 0 ]]; then
    mv "$working_spec" "$COMPLETED_DIR/"
    log "✅ Complete: $spec_name"
    notify "✅ Done" "$spec_name complete. Review the PR on GitHub."
  else
    mv "$working_spec" "$SPECS_DIR/"
    log "❌ Failed: $spec_name (exit $exit_code). Requeued. See: $run_log"
    notify "❌ Failed" "$spec_name failed. Check $run_log"
  fi
}

# --- Daily cost report -------------------------------------------------------
print_cost_summary() {
  if [[ -f "$COST_LOG" ]]; then
    local total
    total=$(get_todays_spend)
    log "💰 Today's API spend: \$${total} / \$${DAILY_BUDGET_USD} budget"
  fi
}

# --- Main loop ---------------------------------------------------------------
main() {
  mkdir -p "$IN_PROGRESS_DIR" "$COMPLETED_DIR" "$LOGS_DIR"

  log "════════════════════════════════════════════════"
  log "🏭 Dark Factory Orchestrator — Profit-First"
  log "════════════════════════════════════════════════"
  log "Watching: $SPECS_DIR"
  log "Poll: ${POLL_INTERVAL}s | Daily budget: \$${DAILY_BUDGET_USD}"
  log "Local model: $LOCAL_MODEL"

  if [[ -z "${ANTHROPIC_API_KEY:-}" ]]; then
    log "⚠️  ANTHROPIC_API_KEY not set — medium/large specs will fail"
  else
    log "✅ Anthropic API key loaded"
  fi

  local tick=0
  while true; do
    # Every 60 ticks (~30 min), print cost summary
    if (( tick % 60 == 0 )); then
      print_cost_summary
    fi
    tick=$((tick + 1))

    # Process any .md files sitting in specs/ (not subdirectories)
    while IFS= read -r -d '' spec_file; do
      dispatch_spec "$spec_file"
    done < <(find "$SPECS_DIR" -maxdepth 1 -name "*.md" -not -name "README.md" -print0 2>/dev/null)

    sleep "$POLL_INTERVAL"
  done
}

main "$@"
