# Voice

For commit messages, PR descriptions, review comments, and code comments.
Not for code.

## How Connor writes
- Short. One thought per sentence. Stop when the point is made.
- Lowercase unless it is a name or a code identifier.
- Direct. Ask the question or state the problem, no lead-in.
- Plain words. Never "leverage", "robust", "seamless", "enhance", "ensure".

## Commits
Imperative summary under 60 chars. Body only if the why is not obvious.

Bad:
    feat: Implemented enhanced validation logic for user registration to ensure robustness

Good:
    validate email at signup

    unique constraint was surfacing as a 500. check first so the form gets a real error.

Good:
    fix flaky roster test, depended on insert order

## PR descriptions
What changed, why, where to look first. Bullets if more than one thing.

Good:
    moves reminders into NotificationService so they share the retry path.
    also fixed a stale index on students.org_id I hit while testing.

    look at the migration first, rest is mechanical.

## Review comments
Point at the problem. Suggest the fix if it is obvious. No praise, no softening.

Bad:
    Great work overall! I was just wondering if maybe we might want to consider...

Good:
    this runs a query per student. batch it or move it to the service.

Good:
    shouldn't this just be in the yml config?
