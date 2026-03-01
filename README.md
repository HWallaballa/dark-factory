# 🏭 Dark Factory — Autonomous AI Pipeline

**Pinehaven Ventures** | Internal | v1.0

The Dark Factory is a 24/7 autonomous software development pipeline. Hunter writes specs; AI builds, tests, and opens PRs. Hunter evaluates outcomes and approves production deployments.

---

## Architecture

```
specs/*.md  →  orchestrator.sh  →  claude --print  →  PR on GitHub  →  Hunter reviews
```

| Layer | Who | What |
|---|---|---|
| 1 — Specification | Hunter | Write Markdown spec, drop in `/specs/` |
| 2 — Orchestration | orchestrator.sh | Detects spec, dispatches Claude Code |
| 3 — Implementation | Claude Code CLI | Creates branch, writes code, opens PR |
| 4 — Validation | GitHub Actions | Runs tests, blocks on failure |
| 5 — Evaluation | Hunter | Reviews PR, approves production deploy |

---

## Directory Structure

```
dark-factory/
├── specs/
│   ├── templates/        ← Copy SPEC_TEMPLATE.md to start a new spec
│   ├── in-progress/      ← Orchestrator moves specs here while running
│   └── completed/        ← Specs move here after Claude finishes
├── scripts/
│   └── orchestrator.sh   ← The daemon (run this or install as systemd service)
├── logs/                 ← Per-run logs + daily orchestrator log
└── dark-factory.service  ← systemd unit file
```

---

## Quick Start

### 1. Set your Anthropic API key

```bash
mkdir -p ~/.config/dark-factory
echo "ANTHROPIC_API_KEY=sk-ant-..." > ~/.config/dark-factory/secrets.env
chmod 600 ~/.config/dark-factory/secrets.env
```

### 2. Run the orchestrator manually (test mode)

```bash
cd "/home/gilberto/Desktop/Pinehaven Ventures/dark-factory"
ANTHROPIC_API_KEY=sk-ant-... ./scripts/orchestrator.sh
```

### 3. Drop a spec and watch it run

```bash
cp specs/templates/SPEC_TEMPLATE.md specs/my-first-feature.md
# Edit the spec, then save — orchestrator picks it up within 30 seconds
```

### 4. Install as a 24/7 systemd service

```bash
# First, set your key in ~/.config/dark-factory/secrets.env
sudo cp dark-factory.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable dark-factory
sudo systemctl start dark-factory
sudo systemctl status dark-factory
```

### 5. Check logs

```bash
tail -f logs/orchestrator-$(date +%Y-%m-%d).log
```

---

## Writing a Good Spec

The quality of the output equals the quality of the spec. Use the template:

```bash
cp specs/templates/SPEC_TEMPLATE.md specs/your-feature-name.md
```

**Required sections:**
- `repo:` — which product repo to work in
- What to Build — one clear paragraph
- Acceptance Criteria — checkboxes Claude will verify
- Technical Details — file paths, API contracts
- Out of Scope — prevent scope creep

---

## Cost Management

| Task | Engine | Est. Cost |
|---|---|---|
| Complex feature | Claude Sonnet (API) | $1–$10 |
| Simple change | Claude Sonnet (API) | $0.10–$1 |
| Commit message | Local Ollama (llama3.1:8b) | $0 |
| Code lint/format | ESLint/Prettier | $0 |

Set a spending limit at [console.anthropic.com](https://console.anthropic.com) → Billing → Limits.

---

## Kill Switch

```bash
# Stop immediately
sudo systemctl stop dark-factory

# Or if running manually: Ctrl+C
```

All state is in Git. Nothing is lost if the service stops.
