#!/usr/bin/env bash
# install.sh - Install Claude Code Power Config
# Symlinks plugin + global config, merges settings.json, disables bypassPermissions
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
RESET='\033[0m'

info()  { printf "${GREEN}[+]${RESET} %s\n" "$1"; }
warn()  { printf "${YELLOW}[!]${RESET} %s\n" "$1"; }
error() { printf "${RED}[x]${RESET} %s\n" "$1"; }

echo ""
printf "${BOLD}Claude Code Power Config - Install${RESET}\n"
echo "==========================================="
echo ""

# --- 1. Ensure ~/.claude exists ---
mkdir -p "$CLAUDE_DIR/plugins"

# --- 2. Symlink plugin ---
PLUGIN_TARGET="$CLAUDE_DIR/plugins/power-config"
if [ -L "$PLUGIN_TARGET" ]; then
  warn "Plugin symlink already exists, updating..."
  rm "$PLUGIN_TARGET"
elif [ -d "$PLUGIN_TARGET" ]; then
  error "Plugin directory already exists (not a symlink): $PLUGIN_TARGET"
  error "Please remove it manually and re-run install."
  exit 1
fi
ln -s "$SCRIPT_DIR/plugin" "$PLUGIN_TARGET"
info "Plugin symlinked: $PLUGIN_TARGET -> $SCRIPT_DIR/plugin"

# --- 3. Symlink global CLAUDE.md ---
CLAUDE_MD_TARGET="$CLAUDE_DIR/CLAUDE.md"
if [ -L "$CLAUDE_MD_TARGET" ]; then
  warn "CLAUDE.md symlink already exists, updating..."
  rm "$CLAUDE_MD_TARGET"
elif [ -f "$CLAUDE_MD_TARGET" ]; then
  BACKUP="$CLAUDE_MD_TARGET.backup.$(date +%s)"
  warn "Existing CLAUDE.md found, backing up to $BACKUP"
  mv "$CLAUDE_MD_TARGET" "$BACKUP"
fi
ln -s "$SCRIPT_DIR/global/CLAUDE.md" "$CLAUDE_MD_TARGET"
info "CLAUDE.md symlinked: $CLAUDE_MD_TARGET -> $SCRIPT_DIR/global/CLAUDE.md"

# --- 4. Symlink statusline.sh ---
STATUSLINE_TARGET="$CLAUDE_DIR/statusline.sh"
if [ -L "$STATUSLINE_TARGET" ]; then
  rm "$STATUSLINE_TARGET"
elif [ -f "$STATUSLINE_TARGET" ]; then
  mv "$STATUSLINE_TARGET" "$STATUSLINE_TARGET.backup.$(date +%s)"
fi
ln -s "$SCRIPT_DIR/global/statusline.sh" "$STATUSLINE_TARGET"
info "Statusline symlinked: $STATUSLINE_TARGET -> $SCRIPT_DIR/global/statusline.sh"

# --- 5. Merge settings.json ---
info "Configuring settings.json..."

# Initialize settings if missing
if [ ! -f "$SETTINGS_FILE" ]; then
  echo '{}' > "$SETTINGS_FILE"
fi

# Create the settings patch
SETTINGS_PATCH=$(cat <<'PATCH_EOF'
{
  "permissions": {
    "allow": [
      "Bash",
      "WebSearch",
      "WebFetch"
    ],
    "deny": [
      "Bash(rm -rf *)",
      "Bash(sudo *)",
      "Bash(curl *|bash*)",
      "Bash(wget *|bash*)",
      "Bash(git push --force*)",
      "Bash(git reset --hard*)",
      "Read(~/.ssh/**)",
      "Read(~/.aws/**)",
      "Read(~/.gnupg/**)",
      "Read(./.env)",
      "Read(./.env.*)"
    ]
  },
  "env": {
    "CLAUDE_AUTOCOMPACT_PCT_OVERRIDE": "80",
    "DISABLE_TELEMETRY": "1",
    "DISABLE_ERROR_REPORTING": "1"
  },
  "statusline": {
    "command": "~/.claude/statusline.sh"
  }
}
PATCH_EOF
)

# Merge using jq: deep merge that preserves existing settings
# For arrays (allow/deny), we concatenate and deduplicate
MERGED=$(jq -s '
  def deep_merge(a; b):
    a as $a | b as $b |
    if ($a | type) == "object" and ($b | type) == "object" then
      ($a | keys) + ($b | keys) | unique | map(
        . as $k |
        if ($a | has($k)) and ($b | has($k)) then
          if ($a[$k] | type) == "array" and ($b[$k] | type) == "array" then
            { ($k): (($a[$k] + $b[$k]) | unique) }
          elif ($a[$k] | type) == "object" and ($b[$k] | type) == "object" then
            { ($k): deep_merge($a[$k]; $b[$k]) }
          else
            { ($k): $b[$k] }
          end
        elif ($b | has($k)) then
          { ($k): $b[$k] }
        else
          { ($k): $a[$k] }
        end
      ) | add
    else
      $b
    end;
  deep_merge(.[0]; .[1])
' "$SETTINGS_FILE" <(echo "$SETTINGS_PATCH"))

echo "$MERGED" | jq '.' > "$SETTINGS_FILE.tmp"
mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
info "Settings merged: permissions, env vars, statusline"

# --- 6. Disable bypassPermissions ---
CURRENT_BYPASS=$(jq -r '.bypassPermissions // false' "$SETTINGS_FILE")
if [ "$CURRENT_BYPASS" = "true" ]; then
  echo ""
  warn "bypassPermissions is currently ENABLED in your settings."
  warn "This is the #1 security mistake with Claude Code."
  echo ""
  printf "  Disable bypassPermissions? (recommended) [Y/n] "
  read -r RESPONSE
  RESPONSE=${RESPONSE:-Y}
  if [[ "$RESPONSE" =~ ^[Yy] ]]; then
    jq '.bypassPermissions = false' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp"
    mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
    info "bypassPermissions disabled"
  else
    warn "bypassPermissions left enabled (not recommended)"
  fi
fi

# --- 7. Summary ---
echo ""
printf "${BOLD}Installation complete!${RESET}\n"
echo "==========================================="
echo ""
echo "What was configured:"
echo "  - Plugin installed at ~/.claude/plugins/power-config/"
echo "  - Global CLAUDE.md at ~/.claude/CLAUDE.md"
echo "  - Statusline at ~/.claude/statusline.sh"
echo "  - Permissions: allow all Bash + deny destructive (defense-in-depth with hooks)"
echo "  - Deny list: rm -rf, sudo, force push, hard reset, pipe-to-bash, secrets"
echo "  - Env vars: autocompact at 80%, telemetry disabled"
echo ""
echo "Available commands:  /commit-push-pr  /catchup  /review"
echo "Available agents:    security-reviewer  code-reviewer"
echo "Available skills:    fix-issue"
echo ""
echo "Hooks (active in plugin projects):"
echo "  - Auto-format: ruff on .py file saves"
echo "  - Auto-test: pytest on test file saves"
echo "  - Block destructive: blocks rm -rf, sudo, force push"
echo "  - Branch protection: blocks edits on main/master"
echo ""
info "Run 'claude' to start using your new config!"
