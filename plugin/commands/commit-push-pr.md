# /commit-push-pr

Commit all staged changes, push, and create a PR. Follow this workflow exactly:

1. Run `git status` to see what's changed
2. Run `git diff --staged` and `git diff` to understand all changes
3. Stage all relevant changes with `git add` (specific files, not `-A`)
4. Write a conventional commit message (`type(scope): description`) based on the actual changes
5. Commit the changes
6. Push the current branch to origin with `-u` flag
7. Create a PR using `gh pr create`:
   - Title: same as commit message (without the type prefix if it's cleaner)
   - Body: bullet-point summary of changes + test plan
   - Target: main branch

If there are no changes to commit, say so and stop.
If the current branch is main/master, say so and stop -- create a feature branch first.
If tests haven't been run, run `poetry run pytest` (or `pytest`) before committing.
