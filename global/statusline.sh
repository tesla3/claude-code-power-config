#!/usr/bin/env bash
# Claude Code statusline: shows model, tokens, cost, and context usage %
# Reads JSON from stdin, outputs a color-coded status line

set -euo pipefail

INPUT=$(cat)

# Extract fields from JSON
MODEL=$(echo "$INPUT" | jq -r '.model // "unknown"')
TOKENS_USED=$(echo "$INPUT" | jq -r '.context_tokens // 0')
CONTEXT_LIMIT=$(echo "$INPUT" | jq -r '.context_limit // 200000')
COST=$(echo "$INPUT" | jq -r '.session_cost // "0.00"')

# Calculate context usage percentage
if [ "$CONTEXT_LIMIT" -gt 0 ] 2>/dev/null; then
  PCT=$((TOKENS_USED * 100 / CONTEXT_LIMIT))
else
  PCT=0
fi

# ANSI color codes
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
RESET='\033[0m'

# Color based on context usage
if [ "$PCT" -ge 60 ]; then
  COLOR="$RED"
elif [ "$PCT" -ge 40 ]; then
  COLOR="$YELLOW"
else
  COLOR="$GREEN"
fi

# Format token count (e.g., 45000 -> 45k)
if [ "$TOKENS_USED" -ge 1000 ] 2>/dev/null; then
  TOKENS_FMT="$((TOKENS_USED / 1000))k"
else
  TOKENS_FMT="$TOKENS_USED"
fi

# Output the status line
printf "${COLOR}ctx:${PCT}%%${RESET} | ${TOKENS_FMT} tokens | \$${COST} | ${MODEL}"
