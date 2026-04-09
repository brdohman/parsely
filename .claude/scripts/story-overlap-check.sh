#!/bin/bash
set -euo pipefail

# Check if stories in the same wave have overlapping target files.
# Used by /build-epic to determine safe parallel dispatch.
#
# Usage: story-overlap-check.sh <story-id-1> <story-id-2> [story-id-3 ...]
#
# Output:
#   DISJOINT              — all stories touch different files, safe to parallelize
#   OVERLAP:<id1>:<id2>   — these two stories share files, must serialize
#   UNKNOWN               — couldn't determine files, fall back to serial
#
# Reads task JSON files from ~/.claude/tasks/${CLAUDE_CODE_TASK_LIST_ID}/

if [ $# -lt 2 ]; then
    echo "Usage: story-overlap-check.sh <story-id-1> <story-id-2> [...]" >&2
    echo "  Requires at least 2 story IDs to compare." >&2
    exit 1
fi

TASK_DIR="${HOME}/.claude/tasks/${CLAUDE_CODE_TASK_LIST_ID:-default}"

if [ ! -d "$TASK_DIR" ]; then
    echo "UNKNOWN"
    exit 0
fi

# Check jq is available
if ! command -v jq &>/dev/null; then
    echo "UNKNOWN"
    exit 0
fi

# Extract file paths from a task's description, checklist, and target_files.
# Returns one path per line (deduplicated).
extract_files_for_story() {
    local story_id="$1"
    local all_files=""

    # Find child tasks of this story
    for task_file in "$TASK_DIR"/*.json; do
        [ -f "$task_file" ] || continue

        # Check if this task's parent matches the story ID
        local parent
        parent=$(jq -r '.metadata.parent // empty' "$task_file" 2>/dev/null) || continue
        [ "$parent" = "$story_id" ] || continue

        # Extract from metadata.ai_context.target_files (most reliable)
        local target_files
        target_files=$(jq -r '.metadata.ai_context.target_files[]? // empty' "$task_file" 2>/dev/null) || true
        if [ -n "$target_files" ]; then
            all_files="${all_files}${target_files}"$'\n'
        fi

        # Extract .swift file paths from description
        local desc_files
        desc_files=$(jq -r '.description // empty' "$task_file" 2>/dev/null | grep -oE '[A-Za-z0-9_/]+\.swift' || true)
        if [ -n "$desc_files" ]; then
            all_files="${all_files}${desc_files}"$'\n'
        fi

        # Extract .swift file paths from checklist items
        local checklist_files
        checklist_files=$(jq -r '.metadata.checklist[]? // empty' "$task_file" 2>/dev/null | grep -oE '[A-Za-z0-9_/]+\.swift' || true)
        if [ -n "$checklist_files" ]; then
            all_files="${all_files}${checklist_files}"$'\n'
        fi

        # Extract .swift file paths from ai_execution_hints
        local hint_files
        hint_files=$(jq -r '.metadata.ai_execution_hints | tostring // empty' "$task_file" 2>/dev/null | grep -oE '[A-Za-z0-9_/]+\.swift' || true)
        if [ -n "$hint_files" ]; then
            all_files="${all_files}${hint_files}"$'\n'
        fi
    done

    # Deduplicate and normalize (basename only for comparison, since paths may be relative)
    echo "$all_files" | grep -v '^$' | xargs -I{} basename {} 2>/dev/null | sort -u
}

# Build file sets for each story
declare -A story_files
story_ids=("$@")

for sid in "${story_ids[@]}"; do
    files=$(extract_files_for_story "$sid")
    if [ -z "$files" ]; then
        # Can't determine files for this story — unsafe to parallelize
        echo "UNKNOWN"
        exit 0
    fi
    story_files["$sid"]="$files"
done

# Compare all pairs for overlap
for ((i=0; i<${#story_ids[@]}; i++)); do
    for ((j=i+1; j<${#story_ids[@]}; j++)); do
        sid1="${story_ids[$i]}"
        sid2="${story_ids[$j]}"

        # Find common files between the two stories
        overlap=$(comm -12 \
            <(echo "${story_files[$sid1]}" | sort) \
            <(echo "${story_files[$sid2]}" | sort) \
        )

        if [ -n "$overlap" ]; then
            echo "OVERLAP:${sid1}:${sid2}"
            exit 0
        fi
    done
done

echo "DISJOINT"
