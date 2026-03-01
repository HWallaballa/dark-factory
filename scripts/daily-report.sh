#!/usr/bin/env bash
# =============================================================================
# Dark Factory — Daily Profit Report
# Run anytime: ./scripts/daily-report.sh
# =============================================================================

DARK_FACTORY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOGS_DIR="$DARK_FACTORY_DIR/logs"
COST_LOG="$LOGS_DIR/daily-cost-$(date +%Y-%m-%d).json"
SPECS_COMPLETED="$DARK_FACTORY_DIR/specs/completed"

echo ""
echo "════════════════════════════════════════════════"
echo "🏭 Dark Factory — Daily Report ($(date +%Y-%m-%d))"
echo "════════════════════════════════════════════════"
echo ""

# --- API Costs ---------------------------------------------------------------
if [[ -f "$COST_LOG" ]]; then
  echo "💸 API Costs Today:"
  python3 - <<PYEOF
import json
records = json.load(open("$COST_LOG"))
total = sum(r.get("cost_usd", 0) for r in records)
by_engine = {}
for r in records:
    e = r.get("engine", "unknown")
    by_engine[e] = by_engine.get(e, 0) + r.get("cost_usd", 0)
for engine, cost in sorted(by_engine.items()):
    print(f"   {engine:<25} \${cost:.4f}")
print(f"   {'TOTAL':<25} \${total:.4f}")
print(f"   Tasks run: {len(records)}")
PYEOF
else
  echo "   No API costs logged today (or factory hasn't run yet)."
fi

echo ""

# --- Specs Status ------------------------------------------------------------
completed=$(find "$SPECS_COMPLETED" -name "*.md" 2>/dev/null | wc -l)
pending=$(find "$DARK_FACTORY_DIR/specs" -maxdepth 1 -name "*.md" 2>/dev/null | wc -l)
in_progress=$(find "$DARK_FACTORY_DIR/specs/in-progress" -name "*.md" 2>/dev/null | wc -l)

echo "📋 Specs:"
echo "   Completed (all time): $completed"
echo "   Pending: $pending"
echo "   In progress: $in_progress"
echo ""

# --- Revenue Reminder --------------------------------------------------------
echo "💰 Revenue Targets (from 90-day plan):"
echo "   Power Queue Tracker: +\$2.1K MRR/week needed"
echo "   Power Digital:        2 licenses/week needed"
echo "   AutoReels:           +\$1.7K MRR/week needed"
echo "   Crypto Log:          140 premium upgrades/week needed"
echo ""
echo "   Update actual numbers in: scripts/daily-report.sh"
echo ""

# --- Factory Status ----------------------------------------------------------
if systemctl is-active dark-factory >/dev/null 2>&1; then
  echo "⚙️  Factory: RUNNING (systemd)"
else
  echo "⚙️  Factory: NOT RUNNING as a service"
  echo "   Start with: sudo systemctl start dark-factory"
  echo "   Or run manually: ./scripts/orchestrator.sh"
fi

echo ""
echo "════════════════════════════════════════════════"
echo ""
