#!/usr/bin/env bash
# =============================================================================
# Dark Factory Orchestrator
# Watches /specs for new or updated Markdown specs and dispatches Claude Code.
#
# Usage: ./scripts/orchestrator.sh
# As a service: managed by systemd (see dark-factory.service)
# =============================================================================

set -euo pipefail

# --- Config ------------------------------------------------------------------
DARK_FACTORY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SPECS_DIR="$DARK_FACTORY_DIR/specs"
IN_PROGRESS_DIR="$SPECS_DIR/in-progress"
COMPLETED_DIR="$SPECS_DIR/completed"
LOGS_DIR="$DARK_FACTORY_DIR/logs"
LOG_FILE="$LOGS_DIR/orchestrator-$(date +%Y-%m-%d).log"
POLL_INTERVAL=30  # seconds between checks

# --- Helpers -----------------------------------------------------------------
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"; }

notify() {
  local title="$1" body="$2"
  log "NOTIFY: $title — $body"
  # Extend: add Discord/email webhook here
  if [[ -n "${DISCORD_WEBHOOK_URL:-}" ]]; then
    curl -s -X POST "$DISCORD_WEBHOOK_URL" \
      -H "Content-Type: application/json" \
      -d "{\"content\":\"**$title**\\n$body\"}" >/dev/null
  fi
}

# --- Dispatch a spec to Claude Code ------------------------------------------
dispatch_spec() {
  local spec_file="$1"
  local spec_name
  spec_name="$(basename "$spec_file" .md)"
  local branch="spec/$spec_name-$(date +%Y%m%d-%H%M%S)"
  local run_log="$LOGS_DIR/run-$spec_name-$(date +%Y%m%d-%H%M%S).log"

  log "Dispatching spec: $spec_name → branch: $branch"
  notify "🏭 Dark Factory" "Starting work on: $spec_name"

  # Move spec to in-progress
  mv "$spec_file" "$IN_PROGRESS_DIR/"

  # Determine target repo from spec frontmatter (default: pinehaven-ventures-website)
  local target_repo
  target_repo=$(grep -m1 '^repo:' "$IN_PROGRESS_DIR/$spec_name.md" 2>/dev/null | awk '{print $2}' || true)
  target_repo="${target_repo:-/home/gilberto/Desktop/Pinehaven Ventures/pinehaven-ventures-website}"

  # Build the Claude Code prompt
  local prompt
  prompt="$(cat "$IN_PROGRESS_DIR/$spec_name.md")"

  local exit_code=0

  # Run Claude Code CLI non-interactively
  if ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY:-}" claude \
    --print \
    --no-color \
    --dangerously-skip-permissions \
    -p "$prompt" \
    >> "$run_log" 2>&1; then
    log "✅ Spec complete: $spec_name"
    mv "$IN_PROGRESS_DIR/$spec_name.md" "$COMPLETED_DIR/"
    notify "✅ Spec Complete" "$spec_name finished. Check $branch for the PR."
  else
    exit_code=$?
    log "❌ Spec failed: $spec_name (exit $exit_code). See $run_log"
    notify "❌ Spec Failed" "$spec_name failed with exit code $exit_code. Review $run_log"
    # Move back to specs for retry
    mv "$IN_PROGRESS_DIR/$spec_name.md" "$SPECS_DIR/"
  fi
}

# --- Main loop ---------------------------------------------------------------
main() {
  mkdir -p "$IN_PROGRESS_DIR" "$COMPLETED_DIR" "$LOGS_DIR"

  log "=== Dark Factory Orchestrator Started ==="
  log "Watching: $SPECS_DIR"
  log "Poll interval: ${POLL_INTERVAL}s"

  if [[ -z "${ANTHROPIC_API_KEY:-}" ]]; then
    log "WARNING: ANTHROPIC_API_KEY is not set. Claude Code will not work."
    log "Set it in ~/.bashrc or pass it via environment."
  fi

  while true; do
    # Find .md files directly in specs/ (not in subdirectories)
    while IFS= read -r -d '' spec_file; do
      log "Found new spec: $spec_file"
      dispatch_spec "$spec_file"
    done < <(find "$SPECS_DIR" -maxdepth 1 -name "*.md" -not -name "README.md" -print0 2>/dev/null)

    sleep "$POLL_INTERVAL"
  done
}

main "$@"
