#!/bin/bash
# detect-xcode-mcp.sh — Check if Xcode MCP bridge is available
#
# Usage: .claude/scripts/detect-xcode-mcp.sh
# Exit 0 + JSON: MCP available
# Exit 1 + JSON: MCP not available (fall back to shell scripts)

# Check 1: Is Xcode running?
if ! pgrep -q "Xcode"; then
    echo '{"available": false, "reason": "Xcode not running"}'
    exit 1
fi

# Check 2: Is xcrun mcpbridge installed? (Xcode 26.3+)
if ! xcrun --find mcpbridge >/dev/null 2>&1; then
    echo '{"available": false, "reason": "mcpbridge not found (requires Xcode 26.3+)"}'
    exit 1
fi

# Check 3: Does .mcp.json exist with xcode server config?
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
if [ ! -f "$PROJECT_DIR/.mcp.json" ]; then
    echo '{"available": false, "reason": ".mcp.json not found in project root"}'
    exit 1
fi

echo '{"available": true}'
exit 0
