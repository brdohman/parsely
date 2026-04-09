#!/bin/bash
set -e

# Scan Swift package dependencies for known vulnerabilities
# Usage: .claude/scripts/dep-audit.sh
# Requires: trivy (brew install aquasecurity/trivy/trivy)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Find Package.resolved
RESOLVED=$(find "$PROJECT_ROOT/app" -name "Package.resolved" -type f 2>/dev/null | head -1)

if [ -z "$RESOLVED" ]; then
    echo "No Package.resolved found. Nothing to audit."
    exit 0
fi

echo "=== Running Dependency Audit ==="
echo "File: $RESOLVED"
echo ""

if ! command -v trivy &> /dev/null; then
    echo "ERROR: trivy not found. Install with: brew install aquasecurity/trivy/trivy"
    exit 1
fi

trivy fs "$RESOLVED" --severity HIGH,CRITICAL 2>&1

AUDIT_EXIT=$?

if [ $AUDIT_EXIT -eq 0 ]; then
    echo ""
    echo "=== Dependency Audit PASSED ==="
else
    echo ""
    echo "=== Dependency Audit FAILED (exit code: $AUDIT_EXIT) ==="
    exit $AUDIT_EXIT
fi
