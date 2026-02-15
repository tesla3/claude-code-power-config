# /review

Self-review all uncommitted changes before committing. Follow this workflow:

1. Run `git diff --staged` and `git diff` to see all changes
2. Review each changed file carefully, checking for:
   - **Bugs**: logic errors, off-by-one, null/None handling, missing edge cases
   - **Security**: injection vulnerabilities, hardcoded secrets, unsafe deserialization
   - **Code quality**: unclear naming, duplicated logic, overly complex code
   - **Type safety**: missing type hints, incorrect types, Any abuse
   - **Tests**: are new functions tested? Are edge cases covered?
   - **Style**: does it follow project conventions (ruff, conventional commits)?
3. Present findings as a checklist:
   - [x] items that look good
   - [ ] items that need attention (with specific file:line references)
4. Give an overall verdict: READY TO COMMIT / NEEDS CHANGES
5. If NEEDS CHANGES, suggest specific fixes

Be thorough but practical. Flag real issues, not nitpicks.
