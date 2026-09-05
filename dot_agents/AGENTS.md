# Global agent instructions

A repo's documented conventions, in its CLAUDE.md, AGENTS.md, or CONTRIBUTING.md, win over these files. Patterns you notice in existing code are not conventions and do not.

## Before coding
- For non-trivial changes, first state in a few sentences: what the change touches, the simplest design that fits the existing architecture, and what could break. Think like an architect reviewing the change.
- When fixing a bug, always reproduce it first.
- Before adding a function, search for one that already does most of the job. Prefer extending it and updating callers over adding a near-duplicate. If the edit changes behavior for existing callers, mention it in the summary.

## Standards
- New behavior gets a test. Bug fixes get a regression test.
- For UI changes, match the design exactly: spacing, alignment, type. If the project already has a way to render or screenshot, check the result before calling it done. Do not set up screenshot tooling just for this.
- If something nearby looks wrong, even if it is unrelated to your change, including lint errors and failing or flaky tests, fix it if it is small and safe. Otherwise mention it in the summary rather than expanding the change.

## Summary
When you finish, end with a short summary:
- What changed, and any design pattern you used.
- What you verified and how. If you did not run the tests or lint, say so.
- What you noticed but did not change, and any behavior change for existing callers.
- Assumptions you made where the task was ambiguous.

## Never
- Modify CHANGELOG.md or files marked auto-generated.
- Use the em dash; use a plain dash.
- Disable a lint rule, skip a test, or delete a failing test to make a check pass. Fix the cause, or mention it in the summary.

@~/OPINIONS.md
@~/VOICE.md
