#!/bin/bash
# check-mcp-deps.sh — Check MCP server and plugin availability for workflow stages
#
# Usage: .claude/scripts/check-mcp-deps.sh [stage]
#
# Stages:
#   build      — checks needed for /build, /build-story
#   design     — checks needed for /design, /build-epic Phase A
#   qa         — checks needed for /qa, visual QA
#   security   — checks needed for /security-audit
#   review     — checks needed for /code-review
#   build-epic — full epic build (ALL tools, MCP servers, and plugins required)
#   all        — check everything (default)
#
# Checks two integration types:
#   MCP servers: Xcode, Peekaboo, Aikido, Trivy (protocol-based tool integration)
#   Plugins:     CodeRabbit (installed via `claude plugin install coderabbit`)
#
# Exit 0: all required dependencies available
# Exit 1: one or more required dependencies missing (prints warnings)

STAGE="${1:-all}"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
WARNINGS=()
MISSING=0

# --- Helper: check if MCP server is configured (any scope) ---
# Uses `claude mcp list` as the single source of truth.
check_mcp_configured() {
    local name="$1"
    if command -v claude &>/dev/null && claude mcp list 2>/dev/null | grep -qi "$name"; then
        echo "  $name: OK"
        return 0
    fi
    return 1
}

# --- Xcode MCP ---
check_xcode_mcp() {
    if ! pgrep -q "Xcode"; then
        echo "  xcode: NOT AVAILABLE (Xcode not running)"
        WARNINGS+=("Xcode MCP: Xcode is not running. Agents will use shell script fallback (xcodebuild).")
        return 1
    fi
    if ! xcrun --find mcpbridge >/dev/null 2>&1; then
        echo "  xcode: NOT AVAILABLE (mcpbridge not found, requires Xcode 26.3+)"
        WARNINGS+=("Xcode MCP: mcpbridge not found. Requires Xcode 26.3+. Agents will use shell fallback.")
        return 1
    fi
    if check_mcp_configured "xcode"; then
        return 0
    fi
    echo "  xcode: NOT CONFIGURED"
    WARNINGS+=("Xcode MCP: Not configured. Run setup-dependencies.sh or add manually.")
    return 1
}

# --- Peekaboo MCP ---
check_peekaboo_mcp() {
    if check_mcp_configured "peekaboo"; then
        return 0
    fi
    echo "  peekaboo: NOT CONFIGURED"
    WARNINGS+=("Peekaboo MCP: Not configured. Visual QA, screenshots, and UI automation unavailable.")
    return 1
}

# --- Aikido MCP ---
check_aikido_mcp() {
    if check_mcp_configured "aikido"; then
        return 0
    fi
    echo "  aikido: NOT CONFIGURED"
    WARNINGS+=("Aikido MCP: Not configured. SAST + secrets scanning unavailable. See tools/dependency-setup.md.")
    return 1
}

# --- Trivy MCP ---
check_trivy_mcp() {
    if ! command -v trivy &>/dev/null; then
        echo "  trivy: NOT INSTALLED (CLI missing)"
        WARNINGS+=("Trivy: CLI not installed. Run 'brew install trivy'. Dependency CVE scanning unavailable.")
        return 1
    fi
    # Check if MCP plugin is installed
    if ! trivy plugin list 2>/dev/null | grep -q "mcp"; then
        echo "  trivy: CLI OK, MCP PLUGIN MISSING"
        WARNINGS+=("Trivy MCP: Plugin not installed. Run 'trivy plugin install mcp'.")
        return 1
    fi
    if check_mcp_configured "trivy"; then
        return 0
    fi
    echo "  trivy: CLI + PLUGIN OK, MCP NOT CONFIGURED"
    WARNINGS+=("Trivy MCP: CLI and plugin installed but MCP not configured. Run setup-dependencies.sh.")
    return 1
}

# --- CodeRabbit Plugin ---
check_coderabbit_plugin() {
    if command -v coderabbit &>/dev/null; then
        echo "  coderabbit: OK (CLI installed)"
        return 0
    fi
    echo "  coderabbit: NOT INSTALLED"
    WARNINGS+=("CodeRabbit: CLI not installed. Run 'curl -fsSL https://cli.coderabbit.ai/install.sh | sh' then 'claude plugin install coderabbit'.")
    return 1
}

# --- CLI Tools ---
check_cli_tools() {
    local cli_missing=0
    for tool in swiftlint gitleaks jq; do
        if command -v "$tool" &>/dev/null; then
            echo "  $tool: OK"
        else
            echo "  $tool: NOT INSTALLED"
            WARNINGS+=("$tool: Not installed. Run 'brew install $tool'.")
            cli_missing=$((cli_missing + 1))
        fi
    done
    return $cli_missing
}

# --- Run checks based on stage ---
echo "MCP Dependency Check (stage: $STAGE)"
echo "======================================"

case "$STAGE" in
    build)
        echo "Required: Xcode MCP (or shell fallback)"
        echo "Optional: Peekaboo (visual sanity check)"
        echo ""
        echo "MCP Servers:"
        check_xcode_mcp || true
        check_peekaboo_mcp || true
        ;;
    design)
        echo "Required: Xcode MCP (build verification)"
        echo "Optional: Peekaboo (screenshot captures)"
        echo ""
        echo "MCP Servers:"
        check_xcode_mcp || true
        check_peekaboo_mcp || true
        ;;
    review)
        echo "Required: Xcode MCP (build check)"
        echo "Recommended: Aikido MCP (SAST + secrets on changed files)"
        echo "Recommended: CodeRabbit plugin (AI review)"
        echo ""
        echo "MCP Servers:"
        check_xcode_mcp || true
        check_aikido_mcp || true
        echo ""
        echo "Plugins:"
        check_coderabbit_plugin || true
        ;;
    qa)
        echo "Required: Xcode MCP (test runner)"
        echo "Required: Peekaboo (visual QA for UI stories)"
        echo ""
        echo "MCP Servers:"
        check_xcode_mcp || MISSING=$((MISSING + 1))
        check_peekaboo_mcp || MISSING=$((MISSING + 1))
        ;;
    security)
        echo "Required: Aikido (SAST + secrets + SCA)"
        echo "Required: Trivy (dependency CVEs + SBOM)"
        echo ""
        echo "MCP Servers:"
        check_aikido_mcp || MISSING=$((MISSING + 1))
        check_trivy_mcp || MISSING=$((MISSING + 1))
        ;;
    build-epic)
        echo "All dependencies required for /build-epic."
        echo ""
        echo "CLI Tools:"
        for tool in gitleaks swiftlint jq; do
            if command -v "$tool" &>/dev/null; then
                echo "  $tool: OK"
            else
                echo "  $tool: NOT INSTALLED"
                WARNINGS+=("$tool: Not installed. Run 'brew install $tool'.")
                MISSING=$((MISSING + 1))
            fi
        done
        echo ""
        echo "MCP Servers:"
        check_xcode_mcp || MISSING=$((MISSING + 1))
        check_peekaboo_mcp || MISSING=$((MISSING + 1))
        check_aikido_mcp || MISSING=$((MISSING + 1))
        check_trivy_mcp || MISSING=$((MISSING + 1))
        echo ""
        echo "Plugins:"
        check_coderabbit_plugin || MISSING=$((MISSING + 1))
        ;;
    all)
        echo "MCP Servers:"
        check_xcode_mcp || true
        check_peekaboo_mcp || true
        check_aikido_mcp || true
        check_trivy_mcp || true
        echo ""
        echo "Plugins:"
        check_coderabbit_plugin || true
        echo ""
        echo "CLI Tools:"
        check_cli_tools || true
        ;;
    *)
        echo "Unknown stage: $STAGE"
        echo "Valid stages: build, design, review, qa, security, all"
        exit 2
        ;;
esac

# --- Print warnings ---
if [ ${#WARNINGS[@]} -gt 0 ]; then
    echo ""
    echo "WARNINGS:"
    for w in "${WARNINGS[@]}"; do
        echo "  ⚠️  $w"
    done
fi

# --- Summary ---
echo ""
if [ ${#WARNINGS[@]} -eq 0 ]; then
    echo "STATUS: All dependencies available ✅"
    exit 0
elif [ "$MISSING" -gt 0 ]; then
    echo "STATUS: $MISSING required dependency(s) missing ❌"
    echo "Fix these before proceeding, or some workflow stages will fail."
    exit 1
else
    echo "STATUS: Some dependencies unavailable (non-blocking) ⚠️"
    echo "Agents will use fallbacks where available. Some features degraded."
    exit 0
fi
