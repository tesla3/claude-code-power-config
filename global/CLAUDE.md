# Global Claude Code Configuration

## Stack
- Python 3.13, Poetry for dependency management
- pytest for testing, ruff for linting/formatting, mypy for type checking
- Git + GitHub (gh CLI) for version control

## Build & Run Commands
- Install deps: `poetry install`
- Run app: `poetry run python -m <module>`
- Test all: `poetry run pytest`
- Test single: `poetry run pytest path/to/test_file.py -x`
- Test verbose: `poetry run pytest -xvs`
- Lint: `poetry run ruff check .`
- Format: `poetry run ruff format .`
- Type check: `poetry run mypy .`
- Lint + fix: `poetry run ruff check --fix .`

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
- YOU MUST run `poetry run pytest` before committing to verify tests pass
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
- IMPORTANT: Always check if a virtualenv exists before running commands
- When using Poetry, prefix commands with `poetry run` or activate the venv
- Check pyproject.toml for project-specific ruff/mypy config before assuming defaults
- If tests fail after changes, fix them before moving on -- never leave broken tests
