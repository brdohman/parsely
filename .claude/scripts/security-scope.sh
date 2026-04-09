#!/usr/bin/env bash
# security-scope.sh — Classify changed files for security review relevance.
#
# Usage:
#   .claude/scripts/security-scope.sh [file1] [file2] ...
#   git diff --name-only | .claude/scripts/security-scope.sh
#
# Outputs "CLEAR" or "SECURITY_REVIEW_REQUIRED" with flagged files.
# Always exits 0 (classifier, not a gate).
#
# Bash 3.2 compatible (macOS default).

set -euo pipefail

# --- Collect file list from args or stdin ---

files=""

if [ $# -gt 0 ]; then
    for f in "$@"; do
        if [ -z "$files" ]; then
            files="$f"
        else
            files="$files
$f"
        fi
    done
elif [ ! -t 0 ]; then
    # Read from stdin (piped input)
    while IFS= read -r line; do
        if [ -n "$line" ]; then
            if [ -z "$files" ]; then
                files="$line"
            else
                files="$files
$line"
            fi
        fi
    done
else
    echo "Usage: security-scope.sh [file1] [file2] ..."
    echo "       git diff --name-only | security-scope.sh"
    echo ""
    echo "Classifies changed files for security review relevance."
    echo "Outputs CLEAR or SECURITY_REVIEW_REQUIRED with flagged files."
    exit 0
fi

if [ -z "$files" ]; then
    echo "CLEAR"
    exit 0
fi

# --- Classify files (use tmpfile since pipe creates subshell) ---

tmpfile="${TMPDIR:-/tmp}/security-scope.$$.tmp"
trap 'rm -f "$tmpfile"' EXIT
: > "$tmpfile"

echo "$files" | while IFS= read -r filepath; do
    [ -z "$filepath" ] && continue
    basename="${filepath##*/}"
    basename_no_ext="${basename%.*}"

    # --- Filename patterns ---

    case "$basename" in
        *.entitlements)
            echo "  $filepath (filename: entitlements)" >> "$tmpfile"
            continue
            ;;
        Info.plist)
            echo "  $filepath (filename: Info.plist)" >> "$tmpfile"
            continue
            ;;
        *.xcprivacy)
            echo "  $filepath (filename: xcprivacy)" >> "$tmpfile"
            continue
            ;;
        Package.swift)
            echo "  $filepath (filename: Package.swift)" >> "$tmpfile"
            continue
            ;;
        Package.resolved)
            echo "  $filepath (filename: Package.resolved)" >> "$tmpfile"
            continue
            ;;
    esac

    # Only process Swift files from here
    case "$basename" in
        *.swift) ;;
        *) continue ;;
    esac

    # Check Swift filename for security-related names
    matched_name=""
    case "$basename_no_ext" in
        *Keychain*)    matched_name="Keychain" ;;
        *Security*)    matched_name="Security" ;;
        *Auth*)        matched_name="Auth" ;;
        *Crypto*)      matched_name="Crypto" ;;
        *Token*)       matched_name="Token" ;;
        *Secret*)      matched_name="Secret" ;;
        *Credential*)  matched_name="Credential" ;;
        *Network*)     matched_name="Network" ;;
        *API*)         matched_name="API" ;;
    esac

    if [ -n "$matched_name" ]; then
        echo "  $filepath (filename: $matched_name)" >> "$tmpfile"
    fi

    # --- Content patterns (Swift files only, must exist on disk) ---

    if [ -f "$filepath" ]; then
        content_match=""
        content_match=$(grep -nE '(password|token|secret|apiKey|API_KEY|UserDefaults|SecItem|kSecClass|URLSession|certificate)' "$filepath" 2>/dev/null | head -1 || true)
        if [ -n "$content_match" ]; then
            matched_keyword=""
            for kw in password token secret apiKey API_KEY UserDefaults SecItem kSecClass URLSession certificate; do
                if echo "$content_match" | grep -qF "$kw" 2>/dev/null; then
                    matched_keyword="$kw"
                    break
                fi
            done
            if [ -n "$matched_keyword" ]; then
                # Only add content match if this file wasn't already flagged by filename
                if ! grep -qF "$filepath" "$tmpfile" 2>/dev/null; then
                    echo "  $filepath (content: $matched_keyword)" >> "$tmpfile"
                fi
            fi
        fi
    fi

done

if [ -s "$tmpfile" ]; then
    echo "SECURITY_REVIEW_REQUIRED"
    echo "Flagged files:"
    cat "$tmpfile"
else
    echo "CLEAR"
fi

exit 0
