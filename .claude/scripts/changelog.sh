#!/bin/bash
set -e

# Generate changelog from conventional commits
# Usage: .claude/scripts/changelog.sh [output-file]
# Default output: CHANGELOG.md

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
OUTPUT="${1:-$PROJECT_ROOT/CHANGELOG.md}"

if ! command -v git-cliff &> /dev/null; then
    echo "ERROR: git-cliff not found. Install with: brew install git-cliff"
    exit 1
fi

echo "=== Generating Changelog ==="
git-cliff --config "$PROJECT_ROOT/.cliff.toml" --output "$OUTPUT"
echo "Changelog written to: $OUTPUT"
