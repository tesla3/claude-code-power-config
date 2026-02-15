#!/usr/bin/env bash
# uninstall.sh - Remove Claude Code Power Config symlinks
set -euo pipefail

CLAUDE_DIR="$HOME/.claude"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
RESET='\033[0m'

info()  { printf "${GREEN}[+]${RESET} %s\n" "$1"; }
warn()  { printf "${YELLOW}[!]${RESET} %s\n" "$1"; }

echo ""
printf "${BOLD}Claude Code Power Config - Uninstall${RESET}\n"
echo "==========================================="
echo ""

# Remove plugin symlink
PLUGIN_TARGET="$CLAUDE_DIR/plugins/power-config"
if [ -L "$PLUGIN_TARGET" ]; then
  rm "$PLUGIN_TARGET"
  info "Removed plugin symlink: $PLUGIN_TARGET"
elif [ -d "$PLUGIN_TARGET" ]; then
  warn "Plugin directory is not a symlink, skipping: $PLUGIN_TARGET"
else
  warn "Plugin symlink not found, skipping"
fi

# Remove CLAUDE.md symlink
CLAUDE_MD_TARGET="$CLAUDE_DIR/CLAUDE.md"
if [ -L "$CLAUDE_MD_TARGET" ]; then
  rm "$CLAUDE_MD_TARGET"
  info "Removed CLAUDE.md symlink: $CLAUDE_MD_TARGET"
  # Restore backup if it exists
  BACKUP=$(ls -t "$CLAUDE_DIR"/CLAUDE.md.backup.* 2>/dev/null | head -1)
  if [ -n "$BACKUP" ]; then
    mv "$BACKUP" "$CLAUDE_MD_TARGET"
    info "Restored backup: $BACKUP"
  fi
else
  warn "CLAUDE.md symlink not found, skipping"
fi

# Remove statusline symlink
STATUSLINE_TARGET="$CLAUDE_DIR/statusline.sh"
if [ -L "$STATUSLINE_TARGET" ]; then
  rm "$STATUSLINE_TARGET"
  info "Removed statusline symlink: $STATUSLINE_TARGET"
else
  warn "Statusline symlink not found, skipping"
fi

echo ""
printf "${BOLD}Symlinks removed.${RESET}\n"
echo ""
echo "NOTE: settings.json was NOT modified. To clean up manually:"
echo ""
echo "  1. Remove permission entries added by install:"
echo "     vi ~/.claude/settings.json"
echo ""
echo "  2. Remove env var overrides (optional):"
echo "     - CLAUDE_AUTOCOMPACT_PCT_OVERRIDE"
echo "     - DISABLE_TELEMETRY"
echo "     - DISABLE_ERROR_REPORTING"
echo ""
echo "  3. Remove statusline config (optional):"
echo "     jq 'del(.statusline)' ~/.claude/settings.json > tmp && mv tmp ~/.claude/settings.json"
echo ""
info "Uninstall complete."
