#!/bin/bash
set -euo pipefail

# Design skill suggestion hook for Claude Code
# PostToolUse hook (Bash matcher) — suggests design system files when build errors match patterns
# Exit 0 always (informational only, never blocks)

# Read hook input from stdin
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
OUTPUT=$(echo "$INPUT" | jq -r '.tool_output.stdout // empty')
STDERR=$(echo "$INPUT" | jq -r '.tool_output.stderr // empty')
COMBINED="${OUTPUT}${STDERR}"

# Only trigger on build commands
if ! echo "$COMMAND" | grep -qE '(xcodebuild|swift build|swift run)'; then
    exit 0
fi

# Only trigger on failure (non-zero exit or error patterns)
EXIT_CODE=$(echo "$INPUT" | jq -r '.tool_output.exit_code // 0')
if [ "$EXIT_CODE" = "0" ] && ! echo "$COMBINED" | grep -qiE '(error:|BUILD FAILED)'; then
    exit 0
fi

SUGGESTIONS=""

# Liquid Glass API errors
if echo "$COMBINED" | grep -qiE "(cannot find 'glassEffect'|cannot find 'GlassEffectContainer'|cannot find 'GlassButtonStyle'|cannot find 'glassProminent'|cannot find 'glassEffectUnion'|cannot find 'GlassEffectTransition')"; then
    SUGGESTIONS="${SUGGESTIONS}\n- Load .claude/skills/macos-ui-review/liquid-glass-design.md for .glassEffect() API usage and migration from manual materials"
fi

# Deprecated NavigationView
if echo "$COMBINED" | grep -qiE "(NavigationView.*deprecated|'NavigationView' is deprecated)"; then
    SUGGESTIONS="${SUGGESTIONS}\n- Load .claude/skills/design-system/references/hig-decisions.md for NavigationSplitView/NavigationStack decision tree"
fi

# Accessibility-related errors
if echo "$COMBINED" | grep -qiE "(accessibilityLabel|accessibilityHint|accessibilityValue|accessibility.*identifier).*error"; then
    SUGGESTIONS="${SUGGESTIONS}\n- Check accessibility guidance in .claude/skills/design-system/components.md"
fi

# Deprecated property wrappers
if echo "$COMBINED" | grep -qiE "(@StateObject.*deprecated|@ObservedObject.*deprecated|@EnvironmentObject.*deprecated)"; then
    SUGGESTIONS="${SUGGESTIONS}\n- Use @Observable + @State instead. See CLAUDE.md tech stack (macOS 26+ target enables @Observable macro)"
fi

# Material/blur deprecations
if echo "$COMBINED" | grep -qiE "(blur.*deprecated|VisualEffectView.*deprecated|NSVisualEffectView.*cannot)"; then
    SUGGESTIONS="${SUGGESTIONS}\n- Load .claude/skills/macos-ui-review/liquid-glass-design.md for macOS 26 material system migration"
fi

# TabView style issues on macOS
if echo "$COMBINED" | grep -qiE "(tabViewStyle.*page|PageTabViewStyle.*macOS)"; then
    SUGGESTIONS="${SUGGESTIONS}\n- Load .claude/skills/design-system/references/hig-decisions.md — PageTabViewStyle is iOS-only. Use .sidebarAdaptable or .tabBarOnly on macOS"
fi

if [ -n "$SUGGESTIONS" ]; then
    echo "" >&2
    echo "DESIGN SYSTEM SUGGESTION: Build errors match known design patterns. Consider loading:" >&2
    echo -e "$SUGGESTIONS" >&2
    echo "" >&2
fi

exit 0
