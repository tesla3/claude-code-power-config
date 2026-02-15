# Global Claude Code Configuration

## Preferences
- I use vim, tmux, and the terminal for everything. No GUI suggestions.
- Prefer CLI tools and shell commands over graphical alternatives.
- When suggesting file edits, give me the exact content, not vague descriptions.
- I work across Mac and Linux -- note when a command is OS-specific.

## Stack
- Python 3.14, micromamba for per-project/per-task environments
- pytest for testing, ruff for linting/formatting, mypy for type checking
- Git + GitHub (gh CLI) for version control

## Build & Run Commands
- Create env: `micromamba create -n <name> python=3.14 -y`
- Activate env: `micromamba activate <name>`
- Install deps: `pip install -r requirements.txt`
- Run app: `python -m <module>`
- Test all: `pytest`
- Test single: `pytest path/to/test_file.py -x`
- Test verbose: `pytest -xvs`
- Lint: `ruff check .`
- Format: `ruff format .`
- Type check: `mypy .`
- Lint + fix: `ruff check --fix .`

## Code Style
- IMPORTANT: All code MUST pass `ruff check` and `ruff format` before committing
- Use type hints on all function signatures (params and return types)
- Prefer early returns over nested if/else
- Use dataclasses or Pydantic models over raw dicts for structured data
- Use pathlib.Path over os.path
- Use f-strings over .format() or % formatting
- Max line length: 88 (ruff default)
- Imports: use ruff's isort-compatible ordering (stdlib, third-party, local)
- Prefer comprehensions over map/filter for simple transforms
- Use `from __future__ import annotations` for modern type syntax

## Git Conventions
- IMPORTANT: Use conventional commits: `type(scope): description`
  - Types: feat, fix, refactor, test, docs, chore, ci, perf
  - Scope is optional but encouraged
  - Description is lowercase, no period, imperative mood
- Create feature branches: `feat/description` or `fix/description`
- YOU MUST never commit directly to main -- always use a feature branch
- Keep commits atomic -- one logical change per commit
- Write meaningful commit messages that explain WHY, not just WHAT

## Architecture Patterns
- Flat module structure preferred unless project exceeds ~10 files
- Separate concerns: CLI entry point, core logic, data models, utils
- Tests mirror source structure: `src/foo.py` -> `tests/test_foo.py`
- Use dependency injection over global state
- Prefer composition over inheritance

## Testing
- YOU MUST run `pytest` before committing to verify tests pass
- Write tests for all new functionality
- Use pytest fixtures for shared test setup
- Use parametrize for testing multiple inputs
- Aim for testing behavior, not implementation details
- Name tests descriptively: `test_<function>_<scenario>_<expected>`

## Error Handling
- Use specific exception types, never bare `except:`
- Let unexpected exceptions propagate -- don't swallow errors
- Use logging over print for diagnostic output
- Validate at boundaries (CLI args, API inputs), trust internal data

## Key Gotchas
- IMPORTANT: Always check if a micromamba env is active before running commands
- Each project/task has its own micromamba env -- do not install into base
- Check pyproject.toml for project-specific ruff/mypy config before assuming defaults
- If tests fail after changes, fix them before moving on -- never leave broken tests
