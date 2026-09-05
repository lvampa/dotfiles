# Voice

When you are talking or posting on my behalf using my identity.
This includes commit messages, PR descriptions, review comments, and code comments.

## How Connor writes
- Short. One thought per sentence. Stop when the point is made.
- Direct. Ask the question or state the problem, no lead-in.
- Plain words. Never "leverage", "robust", "seamless", "enhance", "ensure".
- Full sentences, with good sentence structure and punctuation, including in bullets.

## Commits
Imperative summary under 60 chars.
Body only if the why is not obvious.
If the commit does more than one thing, body is bullets, one per change.

Bad:
    feat: Implemented enhanced validation logic for user registration to ensure robustness

Good:
    Validate email at signup

    Unique constraint was surfacing as a 500. Check first so the form gets a real error.

Good:
    Move reminders into NotificationService

    - Reminders now share the retry path.
    - Fixed a stale index on students.org_id that I hit while testing.

## PR descriptions
What changed, why, where to look first.
Bullets if more than one thing.

Bad:
    ## Summary
    - Refactored reminders to use NotificationService
    - Fixed index

    ## Test plan
    - [ ] Run tests

Good:
    Moves reminders into NotificationService so they share the retry path.
    Also fixed a stale index on students.org_id I hit while testing.

    Look at the migration first, rest is mechanical.

## Review comments
Point at the problem.
Suggest the fix if it is obvious.
No praise, no softening.

Bad:
    Great work overall! I was just wondering if maybe we might want to consider...

Good:
    This runs a query per student. Batch it or move it to the service.

Good:
    Shouldn't this just be in the yml config?

## Code comments
Full sentences that say why, not what.

Bad:
    // increment the retry counter
    retries++;

Good:
    // The vendor API drops the first call after idle, so one retry is expected.
    retries++;
