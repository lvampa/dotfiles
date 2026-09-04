# Global agent instructions

## Before coding
- For non-trivial changes, first state in a few sentences: what the change touches, the simplest design that fits the existing architecture, and what could break. Think like an architect reviewing the change, then implement it.
- When fixing a bug, always reproduce it first.
- Before adding a function, search for one that already does most of the job. Prefer extending it and updating callers over adding a near-duplicate. Ask first if the edit changes behavior for existing callers.

## Standards
- Prefer quality, simplicity, robustness, scalability, and long-term maintainability over development cost.
- Hold lint, tests, and flakiness to the same standard as feature code.
- Be picky about the UI and obsessed with pixel perfection.
- If something looks wrong nearby, fix it if it is small and safe. Otherwise mention it in the summary rather than expanding the change.

## Never
- Modify CHANGELOG.md or files marked auto-generated.
- Use the em dash; use a plain dash.

@~/OPINIONS.md
@~/VOICE.md
