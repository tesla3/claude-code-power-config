# Global Claude Code Configuration

## Preferences
- I use vim, tmux, and the terminal for everything. No GUI suggestions.
- I work across Mac and Linux -- note when a command is OS-specific.

## Stack
- Python 3.14, micromamba for per-project/per-task environments
- pytest for testing, ruff for linting/formatting, pyright for type checking

## Code Style
- IMPORTANT: All code MUST pass `ruff check` and `ruff format` before committing

## Git Conventions
- IMPORTANT: Use conventional commits: `type(scope): description`
  - Types: feat, fix, refactor, test, docs, chore, ci, perf
  - Scope is optional but encouraged
  - Description is lowercase, no period, imperative mood
- Commit and push directly to main -- no feature branches or PRs

## Architecture Patterns
- Flat module structure preferred unless project exceeds ~10 files
- Separate concerns: CLI entry point, core logic, data models, utils
- Tests mirror source structure: `src/foo.py` -> `tests/test_foo.py`

## Testing
- YOU MUST run `pytest` before committing to verify tests pass
- Name tests descriptively: `test_<function>_<scenario>_<expected>`

## Running Code in Claude Code Sessions
- IMPORTANT: Claude Code's shell does NOT source .zshrc, so `micromamba activate` will fail
- Use `micromamba run -n <env-name> <command>` to run commands in a micromamba env
  - Example: `micromamba run -n myproject pytest -xvs`
  - Example: `micromamba run -n myproject python -m mymodule`
  - Example: `micromamba run -n myproject pip install -r requirements.txt`
- To find which env to use: `micromamba env list` and ask the user if unclear
- For installing into an env: `micromamba run -n <env-name> pip install <package>`

## Key Gotchas
- Each project/task has its own micromamba env -- do not install into base
- Check pyproject.toml for project-specific ruff/pyright config before assuming defaults
