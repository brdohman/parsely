#!/usr/bin/env bash
# test-scope.sh — Map changed Swift files to relevant test class names.
#
# Usage: .claude/scripts/test-scope.sh [file1.swift] [file2.swift] ...
#
# Outputs newline-separated test class names. If no mappings found, outputs "ALL".
# Always exits 0.
#
# Conventions:
#   FooViewModel.swift   → FooViewModelTests
#   FooService.swift     → FooServiceTests
#   Foo.swift (model)    → FooTests
#   *DatabaseService*    → also adds conformance tests
#   *View.swift          → skipped (visual QA via RenderPreview)
#   *Tests.swift         → skipped (already a test file)

set -euo pipefail

test_classes=""

add_class() {
    local cls="$1"
    # Deduplicate: only add if not already present
    if ! echo "$test_classes" | grep -qx "$cls" 2>/dev/null; then
        if [ -z "$test_classes" ]; then
            test_classes="$cls"
        else
            test_classes="$test_classes
$cls"
        fi
    fi
}

for file in "$@"; do
    basename="${file##*/}"
    basename="${basename%.swift}"

    # Skip test files
    case "$basename" in
        *Tests) continue ;;
    esac

    # Skip View files (visual QA handles these), but not ViewModels
    case "$basename" in
        *ViewModel) ;;  # Don't skip ViewModels
        *View) continue ;;  # Skip Views
    esac

    # Map to test class name
    add_class "${basename}Tests"

    # DatabaseService changes also include conformance tests
    case "$basename" in
        *DatabaseService*) add_class "DatabaseServiceConformanceTests" ;;
    esac
done

if [ -z "$test_classes" ]; then
    echo "ALL"
else
    echo "$test_classes" | sort
fi

exit 0
