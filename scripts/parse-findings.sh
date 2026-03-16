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
if [ $# -ge 1 ]; then
  if [ ! -f "$1" ]; then
    echo "ERROR: file not found: $1" >&2
    exit 1
  fi
  input=$(cat "$1")
else
  input=$(cat)
fi

# Count findings by severity
# Match both formats: "### [CRITICAL] title" and "### CRITICAL title"
critical=$(printf '%s\n' "$input" | grep -cE '### \[?CRITICAL\]?' || true)
warning=$(printf '%s\n' "$input" | grep -cE '### \[?WARNING\]?' || true)
suggestion=$(printf '%s\n' "$input" | grep -cE '### \[?SUGGESTION\]?' || true)

# Extract verdict: take the first non-empty line after "## Verdict"
# and require it to be exactly one of the known values
verdict=$(printf '%s\n' "$input" | awk '
  /^## Verdict/ { found=1; next }
  found && /^[[:space:]]*$/ { next }
  found {
    # Trim whitespace and check for exact match
    gsub(/^[[:space:]]+|[[:space:]]+$/, "")
    if ($0 ~ /^(APPROVE|NEEDS_REVISION|CRITICAL_ISSUES|NO_CHANGES)$/) {
      print $0
    }
    exit
  }
')
if [ -z "$verdict" ]; then
  verdict="UNKNOWN"
fi

echo "CRITICAL=$critical"
echo "WARNING=$warning"
echo "SUGGESTION=$suggestion"
echo "VERDICT=$verdict"
