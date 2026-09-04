# Opinions

Judgment about what good code looks like. Match the "good" examples.
Process rules (analyze first, reproduce bugs, reuse existing code) live in AGENTS.md.

## 1. Readability and reader flow over cleverness

The reader should be able to follow a function top to bottom without jumping
around. High-level steps first, details below. Intermediate variables with
good names beat a dense one-liner.

Bad:
    const r = d.filter(x => x.s === 'a').map(x => ({ ...x, t: calc(x) }));

Good:
    const activeStudents = students.filter(isActive);
    const withTotals = activeStudents.map(addTotal);

Bad - the important step is buried in the middle:
    function process(order) {
      const tax = order.items.reduce((s, i) => s + i.price * 0.07, 0);
      if (!order.customer.verified) throw new Error('unverified');
      const total = order.items.reduce((s, i) => s + i.price, 0) + tax;
      return { ...order, total };
    }

Good - guard first, then the steps in the order a reader expects:
    function process(order) {
      assertVerified(order.customer);
      const subtotal = sumPrices(order.items);
      const tax = salesTax(subtotal);
      return { ...order, total: subtotal + tax };
    }

## 2. Names carry the meaning; comments only when they add what a name can't

If a comment explains what the code does, rename or extract instead.
Comments are for the why: workarounds, external constraints, invariants,
links to issues.

Bad:
    // check if the user is allowed
    if (u.r === 'admin' || u.o === doc.o) { ... }

Good:
    if (canEditDocument(user, doc)) { ... }

Bad - restates the code:
    // loop over students and send each one an email
    for (const student of students) { sendEmail(student); }

Acceptable - explains a why that no name can hold:
    // Stripe sends the webhook twice on retries; the event id is our idempotency key.
    if (await events.seen(event.id)) return;

## 3. Reach for a known design pattern when the problem fits one

Use patterns to remove a growing conditional, decouple a caller from
implementations, or make a change point obvious. Do not add a pattern
where a plain function would do. Name the pattern in the summary so the
reader knows what to expect.

Bad - a growing if/else on type:
    if (type === 'email') { ... }
    else if (type === 'sms') { ... }
    else if (type === 'push') { ... }

Good - strategy:
    const senders: Record<ChannelType, Sender> = {
      email: emailSender,
      sms: smsSender,
      push: pushSender,
    };
    await senders[channel].send(message);

Bad - pattern with no problem to solve:
    class GreetingFactory {
      static create(): Greeting { return new Greeting(); }
    }

Good:
    const greeting = new Greeting();
