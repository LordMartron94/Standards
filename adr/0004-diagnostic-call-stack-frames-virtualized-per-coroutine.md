# 0004. Diagnostic call-stack frames, virtualized per coroutine

## Status
Accepted

## Context and Problem Statement

Nexus has carried `NEXUS_PROGRAM_CONTEXT_PUSH(label)`/`NEXUS_PROGRAM_CONTEXT_POP()`
since before this decision: a manual, per-OS-thread stack of `{label, file,
line}` frames (`_nexus_program_context_push`/`_pop` in `n_program.c`),
printed as "Call stack at panic:" by every assertion and panic
(`_nexus_program_log_violation`). It had zero call sites anywhere in Nexus,
Echo, or Multiplex. A panic in either library printed only its own violation
message — no caller-chain context at all, because nothing ever pushed a
frame.

Wiring it up is not simply a matter of sprinkling the existing macros
everywhere. Multiplex runs many coroutines cooperatively on one OS thread per
`MultiplexScheduler` (`multiplex adr/0001-stackful-cooperative-coroutine-
runtime`). `NEXUS_PROGRAM_CONTEXT_PUSH`/`POP` are scoped per OS thread
(`pthread_getspecific`/`setspecific` under `NEXUS_THREAD_SAFE`), so naively
instrumented, one coroutine's still-open frames (pushed, then left in place
while it is suspended mid-operation) would be silently overwritten by
whichever other coroutine the scheduler resumes next on that same thread. A
panic in the second coroutine would then print a trace splicing its own real
frames with corrupted leftovers from the first — worse than no trace, because
a wrong trace looks authoritative. `DESIGN.md`'s "Because stackful coroutines
share an OS thread, they also share actual C TLS" note had already flagged
this exact class of problem for `errno`, which Multiplex already virtualizes
at every scheduler↔coroutine context switch; the diagnostic stack is the same
kind of OS-thread-shared state and needed the same treatment.

Echo has no equivalent problem: it runs on plain OS threads (a producer
thread, and one dedicated worker thread per runtime), so the existing
per-thread scoping already matches its real call chains with no
virtualization needed.

## Decision Drivers

- A panic must attribute to a real, uncorrupted call chain — a misleading
  trace is worse than an absent one.
- Reuse the already-accepted `errno`-virtualization precedent
  (`multiplex adr/0001`) rather than inventing a second mechanism for the
  same class of problem.
- Minimize new public Nexus surface; Nexus has no standing allowlist entry,
  so any new surface here is a real, reviewed API-boundary decision, not
  incidental to Echo/Multiplex's own delegated implementation work.
- Investment in instrumentation should scale with DDP rank × complexity, the
  same principle `STYLE_GUIDE.md § Documentation` already applies to doc
  comments — not uniform coverage of every one-line internal helper.
- Accept that this has a real, non-zero cost on hot paths (a push/pop pair
  per call, including `echo_message_logv_at` and every coroutine context
  switch) in exchange for a trace that is actually there when a panic
  happens; this is a deliberate tradeoff, not an oversight, per
  `STYLE_GUIDE.md`'s performance-vs-resilience framing.

## Considered Options

- Rely on the native OS backtrace (`backtrace()`/`backtrace_symbols()`,
  already used once in `n_program.c`) instead of a manual stack.
- Wire up the existing `NEXUS_PROGRAM_CONTEXT_PUSH`/`POP` macros as plain
  per-OS-thread frames, with no coroutine awareness.
- Wire up the existing macros **and** add a small Nexus-level snapshot
  save/restore pair, swapped by Multiplex's scheduler at every
  coroutine context switch (chosen).
- Give Nexus a fully opaque, swappable `NexusProgramContext` handle type
  (create/destroy/current-get/current-set) instead of a plain copyable
  snapshot struct.

## Decision Outcome

Chosen option: wire up the existing macros, and add
`NexusProgramContextSnapshot` plus `_nexus_program_context_snapshot_save`/
`_nexus_program_context_snapshot_restore` to Nexus (`nexus.h`,
`n_program.c`) so a caller that multiplexes several logical call chains onto
one OS thread can save and restore the whole frame stack at each switch.
Multiplex's scheduler calls this pair at exactly the two points it already
swaps `errno` (`m_coroutines_suspend`, and the dispatch loop in
`multiplex_scheduler_run`), giving each coroutine an isolated diagnostic
stack across suspension with no new coroutine-side bookkeeping.

The decisive driver was matching an already-accepted precedent
(`errno`-virtualization) with the smallest new surface that actually
prevents cross-coroutine corruption — not the opaque-handle option, which
would have added a second general-purpose "swappable context" concept to
Nexus for a need this snapshot struct already covers exactly.

### Pros and Cons of the Options

**Native OS backtrace.** Needs zero new code; already present as a fallback
in `_nexus_program_log_stack_trace`'s neighborhood. Rejected as the primary
mechanism: it shows only the current stack's native frames, which dead-end at
Multiplex's `ucontext` trampoline boundary and say nothing about which
*logical* operation (which `multiplex_*`/`echo_*` call) was in flight,
across suspension points a native walk cannot see.

**Naive per-thread push/pop, no virtualization.** Simplest correct fix for
Echo. Rejected as sufficient for Multiplex specifically: it is actively
wrong there, not just incomplete — see the corruption scenario above.

**Snapshot save/restore pair (chosen).** Mirrors the existing `errno` swap
almost exactly, so the change to `m_coroutines.c`/`m_scheduler.c` is two
symmetric lines at two call sites already doing the analogous `errno` dance.
Costs one `NexusProgramContextSnapshot` (a fixed ~1.3 KB copy of the frame
array, `NEXUS_PROGRAM_CONTEXT_MAX_STACK_SIZE` deep) per `MultiplexCoroutine`
and per `MultiplexScheduler` — a real, currently-unmeasured footprint
increase per coroutine that should be revisited if profiling shows it
matters, especially now that `multiplex adr/0002`'s `MultiplexOperation`
encourages spawning many short-lived coroutines.

**Opaque swappable handle type.** More general — could later serve other
per-task-context needs beyond this one. Rejected for now: it is a second
general-purpose concept (allocation, lifecycle, ownership rules) for a
problem the snapshot struct already solves completely, and nothing today
needs the extra generality.

## Consequences

Every public `multiplex_coroutines_*`/`multiplex_operations_*`/
`multiplex_scheduler_*` and `echo_*` function now pushes a frame before its
own precondition/assert checks and pops before every return, so a function
failing its own contract is attributed to itself in the trace, not left
invisible one frame up. Internal (`static`) helpers are instrumented only
where DDP-weighting judged them complex or failure-bearing enough to be worth
it (real branching, a failure path, or genuine suspension) — coverage there
is intentionally uneven, a judgment call per function rather than an
exhaustive sweep, and reviewable/extendable later the same way doc-comment
coverage is.

Nexus's own ~11 source files were not swept in this pass; only the two new
snapshot functions were added there. Whether and how far to extend
`NEXUS_PROGRAM_CONTEXT_PUSH`/`POP` into Nexus's own public surface is a
separate, larger scope decision, not yet made.

This is a real, accepted cost on hot paths: `echo_message_logv_at` (every log
attempt) and Multiplex's scheduler dispatch loop (every context switch) each
now do one push/pop pair (or the snapshot swap) that did not exist before.
No profiling has yet measured this; it should be revisited if a profile
shows it material, per `STYLE_GUIDE.md`'s "real optimization decisions are
driven by the profiler, not guesswork."

## Framework Hook

This is Second-Order Observation applied to the observation mechanism
itself: a first-order stack trace (the native backtrace) cannot see across
Multiplex's cooperative suspension points, so the lens itself — the pushed
frame stack — had to be built to observe the thing the OS-level view cannot.
Virtualizing it per coroutine is the same resilience move as virtualizing
`errno`: refusing to let two logically independent execution histories share
one physical resource just because they happen to share one OS thread.

## Related Decisions

Builds directly on the OS-thread-sharing problem named (for `errno`) in
multiplex `adr/0001-stackful-cooperative-coroutine-runtime`, and instruments
the `MultiplexOperation` type added in
multiplex `adr/0002-multiplex-operation-structured-concurrency` the same way
as every other public Multiplex entry point.
