# 0005. Nexus diagnostic frames only at own failure surfaces

## Status
Accepted

## Context and Problem Statement

ADR [0004-diagnostic-call-stack-frames-virtualized-per-coroutine](./0004-diagnostic-call-stack-frames-virtualized-per-coroutine.md)
activated Nexus's manual diagnostic call stack across Echo and Multiplex, but
deliberately left Nexus itself unswept until its much larger public surface
had an explicit instrumentation rule. Applying Echo and Multiplex's "every
public entry point" rule uniformly to Nexus would add a push/pop pair to pure
arithmetic, accessors, and forwarding wrappers that cannot themselves produce
an assertion, panic, or typed error. Those frames would consume hot-path time
and the fixed 64-frame budget without adding a failure site the trace could
diagnose.

The opposite extreme -- leaving Nexus uninstrumented -- would keep failures
inside its foundational systems attributed only to the consuming library one
frame above. A Nexus function that fails its own contract or creates its own
error needs to name itself before that failure occurs.

## Decision Drivers

- A function that fails its own contract must appear in the panic trace.
- Instrumentation cost and the fixed frame budget must be spent where the
  frame can add diagnostic information.
- Error construction must happen while the producing function's frame is
  still active; only the completed `NexusError` may cross the subsequent pop.
- The context mechanism must not instrument the allocator and byte-operation
  primitives it uses to lazily create its own per-thread storage, or first use
  would recurse before that storage exists.
- Activating frames must not make the memory observer report its own live
  per-thread context as a leak.

## Considered Options

- Instrument every public Nexus function, matching Echo and Multiplex.
- Instrument only Nexus functions with their own diagnostic failure surface,
  plus complex internal helpers that directly fail (chosen).
- Leave Nexus itself uninstrumented.

## Decision Outcome

Instrument a Nexus function when its body directly checks an assertion or
precondition, raises a panic, constructs a typed `NexusError`, or is a
platform-unsupported implementation that unconditionally raises. A function
that only forwards another function's result, or cannot fail through the
diagnostic mechanisms, does not receive a frame. Complex internal helpers
follow the same rule.

Push is the first executable statement, before the function's own contract
checks. On an ordinary error path, construct the `NexusError` while the frame
is active, then pop and return the saved pointer. Every non-terminating return
path balances its push with a pop.

The allocator, reallocator, deallocator, byte-set/byte-copy primitives, and
the program-context accessors themselves remain uninstrumented because the
per-thread context is built from those primitives. The lazily allocated
context is marked persistent in the memory tracker and is still deallocated
by the TLS destructor when the thread exits.

### Pros and Cons of the Options

**Every public Nexus function.** Maximizes caller-chain detail and is easy to
state mechanically. Rejected because pure functions and forwarding wrappers
cannot identify a new failure locus, while every pair still costs execution
time and stack capacity. Recursive APIs also consume one of the 64 fixed
frames per level.

**Own failure surfaces only (chosen).** Attributes failures to the Nexus
operation that actually owns the check or error construction and avoids most
uninformative overhead. The downside is intentionally uneven coverage: a
forwarding wrapper is absent, and reviewers must judge whether a changed
function has acquired its own failure surface.

**No Nexus instrumentation.** Has no added runtime cost and cannot recurse
through the context's dependencies. Rejected because a panic raised directly
inside Nexus would still omit the responsible public operation.

## Consequences

Nexus header-resident string, filesystem-path, and environment operations,
plus out-of-line filesystem, memory-mapping, program-error, real-number,
signal, guarded-stack, string-builder, threading, and time operations with
their own failure surfaces now contribute diagnostic frames. Pure
`n_uint128` operations and the platform raiser remain untouched;
allocator/context primitives retain their explicit recursion exemption.

The rule is not a promise of zero overhead. Some selected operations are hot,
and recursive directory operations can consume multiple frames. The current
cost is accepted for diagnostics but remains unprofiled; a measured regression
can justify revisiting either the selected surface or the fixed snapshot
representation without weakening frame correctness.

## Framework Hook

This spends observation cost in proportion to the information gained: Nexus
records a frame where its own model can fail, while avoiding observer
self-interference in the allocator/context dependency cycle. That preserves
Second-Order Observation without turning a foundational library's entire
surface into uniform instrumentation ceremony.

## Related Decisions

Extends
[0004-diagnostic-call-stack-frames-virtualized-per-coroutine](./0004-diagnostic-call-stack-frames-virtualized-per-coroutine.md),
which establishes the frame mechanism and its coroutine virtualization; this
record replaces only that ADR's then-current statement that Nexus had not yet
been swept.
