#!/bin/bash
# start-dashboard.sh — Start the React dashboard dev server for FlowMeet
# Called by Xcode as a Run Script Build Phase.

set -euo pipefail

# ── Resolve npm path ──────────────────────────────────────────────────
# Xcode's shell has a minimal PATH; add common Node.js install locations.
export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.nvm/versions/node/$(ls "$HOME/.nvm/versions/node/" 2>/dev/null | sort -V | tail -1)/bin:$PATH"

NPM=$(command -v npm 2>/dev/null || true)

if [ -z "$NPM" ]; then
    echo "warning: npm not found — skipping dashboard dev server start" >&2
    exit 0
fi

# ── Paths ─────────────────────────────────────────────────────────────
DASHBOARD_DIR="${SRCROOT:-$(cd "$(dirname "$0")/.." && pwd)}/dashboard"
LOG_FILE="$DASHBOARD_DIR/.dev-server.log"
PID_FILE="$DASHBOARD_DIR/.dev-server.pid"

if [ ! -d "$DASHBOARD_DIR" ]; then
    echo "warning: dashboard directory not found at $DASHBOARD_DIR" >&2
    exit 0
fi

# ── Check if port 3000 is already in use ──────────────────────────────
if lsof -i :3000 -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo "note: Port 3000 already in use — dashboard dev server appears to be running."
    exit 0
fi

# ── Start the dev server in the background ────────────────────────────
cd "$DASHBOARD_DIR"

# Install deps if node_modules is missing
if [ ! -d "node_modules" ]; then
    echo "Installing dashboard dependencies…"
    "$NPM" install >> "$LOG_FILE" 2>&1
fi

echo "Starting dashboard dev server…"
nohup "$NPM" run dev >> "$LOG_FILE" 2>&1 &
DEV_PID=$!

echo "$DEV_PID" > "$PID_FILE"
echo "Dashboard dev server started (PID $DEV_PID). Logs: $LOG_FILE"
