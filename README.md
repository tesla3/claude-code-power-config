# Claude Code Power Config

Production-grade Claude Code configuration as a portable plugin + global setup. Clone on any machine, run `install.sh`, and get a fully configured Claude Code environment.

## What's Included

### Plugin (commands, agents, skills, hooks)

| Component | Name | Description |
|-----------|------|-------------|
| Command | `/commit-push-pr` | Stage, commit, push, and create a PR in one step |
| Command | `/catchup` | Summarize what changed on the current branch |
| Command | `/review` | Self-review all changes before committing |
| Agent | `security-reviewer` | Read-only security audit (runs on Sonnet) |
| Agent | `code-reviewer` | Read-only code quality review (runs on Sonnet) |
| Skill | `fix-issue` | GitHub issue -> implementation -> PR workflow |

### Hooks (automatic)

| Hook | Trigger | Action |
|------|---------|--------|
| Auto-format | Write/Edit .py files | Runs `ruff format` + `ruff check --fix` |
| Auto-test | Write/Edit test files | Runs `pytest` on changed file |
| Block destructive | Bash commands | Blocks `rm -rf`, `sudo`, force push, pipe-to-bash |
| Branch protection | Write/Edit on main | Blocks edits when on main/master branch |

### Global Config

- **CLAUDE.md**: Python-focused defaults (stack, style, conventions)
- **settings.json**: Permission allowlists + denylists, env vars, statusline
- **statusline.sh**: Color-coded context window monitor

## Install

```bash
git clone <your-repo-url> ~/w/claude-code-power-config
cd ~/w/claude-code-power-config
./install.sh
```

The install script will:
1. Symlink the plugin to `~/.claude/plugins/power-config/`
2. Symlink `CLAUDE.md` to `~/.claude/CLAUDE.md`
3. Symlink `statusline.sh` to `~/.claude/statusline.sh`
4. Merge permission allow/deny lists into `~/.claude/settings.json`
5. Set env vars (autocompact, telemetry)
6. Offer to disable `bypassPermissions` (if enabled)

## Uninstall

```bash
cd ~/w/claude-code-power-config
./uninstall.sh
```

Removes symlinks. Does not revert settings.json (prints manual cleanup instructions).

## Customization

- Edit `global/CLAUDE.md` for your stack (changes apply everywhere via symlink)
- Edit `plugin/hooks/hooks.json` to add/remove hooks
- Add new commands in `plugin/commands/`
- Add new agents in `plugin/agents/`

## Permissions

### Allowed (auto-approved)
`poetry`, `pytest`, `ruff`, `mypy`, `python -m`, `git` (status, diff, log, add, commit, push, checkout, branch), `gh` (pr, issue)

### Denied (blocked)
`rm -rf`, `sudo`, `curl|bash`, `wget|bash`, `git push --force`, `git reset --hard`, reading `~/.ssh`, `~/.aws`, `~/.gnupg`, `.env` files

## Requirements

- [Claude Code](https://claude.ai/claude-code) CLI installed
- `jq` (for install script settings merge)
- `ruff` (for auto-format hook)
- `gh` CLI (for PR/issue commands)
