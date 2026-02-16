---
disable-model-invocation: true
trigger: fix issue|fix bug|resolve issue
---

# Fix Issue Skill

Take a GitHub issue and drive it to a committed fix on main. Follow this workflow:

## Input
The user will provide an issue number (e.g., "fix issue #42" or "fix bug 42").

## Workflow

### 1. Understand the issue
```bash
gh issue view <number>
```
Read the full issue description, labels, and any comments.

### 2. Search the codebase
Use Grep and Glob to find relevant code:
- Search for keywords from the issue
- Find related test files
- Understand the current behavior

### 3. Implement the fix
- Make minimal, focused changes
- Follow the project's code style (check CLAUDE.md, pyproject.toml)
- Add type hints to any new functions
- Handle edge cases mentioned in the issue

### 4. Write/update tests
- Add tests that reproduce the bug (they should fail without the fix)
- Verify the fix resolves the issue
- Run the full test suite: `pytest`

### 5. Verify quality
- Run linter: `ruff check .`
- Run formatter: `ruff format --check .`
- Run type checker: `pyright .` (if configured)

### 6. Commit and push
- Stage changes: `git add <specific files>`
- Commit: `git commit -m "fix(<scope>): <description>\n\nCloses #<number>"`
- Push: `git push`

## Important
- Always run tests before committing
- Reference the issue number in the commit message
- Keep changes minimal -- fix the issue, don't refactor the world
