---
disable-model-invocation: true
trigger: fix issue|fix bug|resolve issue
---

# Fix Issue Skill

Take a GitHub issue and drive it to a merged PR. Follow this workflow:

## Input
The user will provide an issue number (e.g., "fix issue #42" or "fix bug 42").

## Workflow

### 1. Understand the issue
```bash
gh issue view <number>
```
Read the full issue description, labels, and any comments.

### 2. Create a feature branch
```bash
git checkout -b fix/<number>-<short-description>
```

### 3. Search the codebase
Use Grep and Glob to find relevant code:
- Search for keywords from the issue
- Find related test files
- Understand the current behavior

### 4. Implement the fix
- Make minimal, focused changes
- Follow the project's code style (check CLAUDE.md, pyproject.toml)
- Add type hints to any new functions
- Handle edge cases mentioned in the issue

### 5. Write/update tests
- Add tests that reproduce the bug (they should fail without the fix)
- Verify the fix resolves the issue
- Run the full test suite: `poetry run pytest`

### 6. Verify quality
- Run linter: `poetry run ruff check .`
- Run formatter: `poetry run ruff format --check .`
- Run type checker: `poetry run mypy .` (if configured)

### 7. Commit and push
- Stage changes: `git add <specific files>`
- Commit: `git commit -m "fix(<scope>): <description>\n\nCloses #<number>"`
- Push: `git push -u origin fix/<number>-<short-description>`

### 8. Create PR
```bash
gh pr create \
  --title "fix(<scope>): <description>" \
  --body "Closes #<number>\n\n## Changes\n<bullet points>\n\n## Test plan\n<what was tested>"
```

## Important
- Always run tests before committing
- Reference the issue number in the commit and PR
- Keep changes minimal -- fix the issue, don't refactor the world
