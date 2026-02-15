# /catchup

Summarize what changed on the current branch since it diverged from main. Follow this workflow:

1. Run `git log main..HEAD --oneline` to see all commits on this branch
2. Run `git diff main...HEAD --stat` to see which files changed
3. Run `git diff main...HEAD` to see the actual changes
4. Provide a clear summary:
   - **Branch**: current branch name
   - **Commits**: count and list of commit messages
   - **Files changed**: grouped by type (new, modified, deleted)
   - **Summary**: 3-5 bullet points explaining what was done and why
   - **Status**: any uncommitted changes, test status

If already on main, say so and suggest checking out a feature branch.
