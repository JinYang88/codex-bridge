#!/usr/bin/env bash
# Parse codex-review output and extract finding counts by severity.
#
# Usage: parse-findings.sh < review-output.md
#   or:  parse-findings.sh /path/to/review-output.md
#
# Output: one line per severity with count, e.g.:
#   CRITICAL=1
#   WARNING=3
#   SUGGESTION=2
#   VERDICT=NEEDS_REVISION

set -euo pipefail

# Read input from file argument or stdin
if [ $# -ge 1 ] && [ -f "$1" ]; then
  input=$(cat "$1")
else
  input=$(cat)
fi

# Count findings by severity (format: ### [CRITICAL] or ### CRITICAL)
critical=$(printf '%s\n' "$input" | grep -c '### \[CRITICAL\]' || true)
warning=$(printf '%s\n' "$input" | grep -c '### \[WARNING\]' || true)
suggestion=$(printf '%s\n' "$input" | grep -c '### \[SUGGESTION\]' || true)

# Extract verdict
verdict=$(printf '%s\n' "$input" | grep -A1 '## Verdict' | tail -1 | tr -d '[:space:]')
if [ -z "$verdict" ]; then
  verdict="UNKNOWN"
fi

echo "CRITICAL=$critical"
echo "WARNING=$warning"
echo "SUGGESTION=$suggestion"
echo "VERDICT=$verdict"
