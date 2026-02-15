# Worklog

## 2026-02-15 -- Sprite env bootstrap + mypy -> pyright migration

### Done
- Installed tooling on Sprite VM: micromamba 2.5.0, pyright 1.1.408, pytest 9.0.2
- Removed mypy, replaced with pyright across all config files
- Fixed chezmoi dotfile source repo remote from HTTPS to SSH (matches `gh` auth)
- Added `bin/` to `.gitignore` (chezmoi installer artifact)

### Files changed
- `global/CLAUDE.md` -- stack, type check command, gotchas: mypy -> pyright
- `install.sh` -- settings patch + summary output: mypy -> pyright
- `README.md` -- permissions section: mypy -> pyright
- `plugin/skills/fix-issue/SKILL.md` -- verify quality step: mypy -> pyright
- `~/.claude/settings.json` -- allow list: mypy -> pyright
- `.gitignore` -- added `bin/`

### Lessons learned
- `~/.claude/CLAUDE.md` is a symlink into this repo via chezmoi; edits here propagate everywhere
- Sprite checkpoints are the "commit" primitive in this environment, not git
- This repo pushes directly to main (personal config, not a code project)
- chezmoi source is at `~/.local/share/chezmoi`; use `chezmoi update -v` to pull + apply
