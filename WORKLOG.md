# Worklog

## 2026-02-15 -- Switch to deny-list permissions (allow all Bash)

### Problem
Individual `Bash(git status*)`, `Bash(pytest *)`, etc. allow rules only match commands
that start with that exact tool. Compound commands like `for dir in ...; do git pull; done`
don't match any allow rule and trigger permission prompts, despite being non-destructive.

### Solution
Replaced 15 individual `Bash(...)` allow rules with a single `"Bash"` entry that
auto-approves all Bash commands. Safety is maintained by two independent defense layers:

1. **Permission deny rules** -- `rm -rf *`, `sudo *`, `git push --force*`,
   `git reset --hard*`, `curl *|bash*`, `wget *|bash*`, plus secret file reads
2. **PreToolUse hook** (already in plugin) -- regex inspection blocks destructive
   commands before execution (exit code 2)

Deny rules always beat allow rules in Claude Code's permission system, so destructive
commands are blocked regardless of the broad allow.

### Files changed
- `install.sh` -- settings patch: 15 individual Bash allow rules -> `"Bash"`, added `WebSearch`/`WebFetch`; updated summary output
- `README.md` -- permissions section rewritten to document deny-list approach and defense layers
- `~/.claude/settings.json` -- same allow/deny change applied to live config
- `~/w/.claude/settings.local.json` -- emptied (redundant with global config)

### Notes
- chezmoi manages `~/.claude/settings.json` -- run `chezmoi re-add ~/.claude/settings.json` after changes
- The `PreToolUse` hook in `plugin/hooks/hooks.json` was already installed and unchanged
- No changes to hooks, agents, commands, skills, or CLAUDE.md

---

## 2026-02-15 -- Sprite env bootstrap + mypy -> pyright migration

### Done
- Installed tooling on Sprite VM: micromamba 2.5.0, chezmoi 2.69.4, pyright 1.1.408, pytest 9.0.2
- Removed mypy, replaced with pyright across all config files
- Fixed chezmoi dotfile source repo remote from HTTPS to SSH (matches `gh` auth)
- Added `bin/` to `.gitignore` (chezmoi installer drops a binary there)
- Synced chezmoi source after direct edit to `~/.claude/settings.json` (`chezmoi re-add`)
- Added chezmoi cross-device sync section and `pyright` to README requirements
- Updated fix-issue skill to use pyright

### Files changed
- `global/CLAUDE.md` -- stack, type check command, gotchas: mypy -> pyright
- `install.sh` -- settings patch + summary output: mypy -> pyright
- `README.md` -- permissions, requirements, added chezmoi sync docs
- `plugin/skills/fix-issue/SKILL.md` -- verify quality step: mypy -> pyright
- `~/.claude/settings.json` -- allow list: mypy -> pyright
- `.gitignore` -- added `bin/`

### Architecture notes
- `~/.claude/CLAUDE.md` is a chezmoi-managed symlink -> `~/w/claude-code-power-config/global/CLAUDE.md`
- `~/.claude/settings.json` is a chezmoi-managed file (not symlink); drift requires `chezmoi re-add`
- chezmoi source at `~/.local/share/chezmoi` tracks the dotfile repo
- This repo pushes directly to main (personal config, not a code project)
- On Sprite VMs, checkpoints (`sprite-env checkpoints create`) are the persistence primitive alongside git
