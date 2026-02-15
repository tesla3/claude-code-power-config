# Worklog

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
