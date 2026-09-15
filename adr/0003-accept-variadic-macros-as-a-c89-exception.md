# 0003. Accept variadic macros (and GNU comma-elision) as a deliberate C89 exception

## Status
Accepted

## Context and Problem Statement

Nexus's internal-function-plus-wrapper-macro convention — a `_leading_
underscore` function takes explicit `file`/`line` parameters, and a public
`NEXUS_*` macro is the only sanctioned caller, supplying `__FILE__`/`__LINE__`
itself — is used everywhere a call site's location needs to be captured
(`_nexus_program_context_push`, `_nexus_program_assert`, `_nexus_program_panic`,
`_nexus_program_errors_forward`, and others). `_nexus_program_errors_failure_create`
was the one exception: its public surface required callers to write
`__FILE__, __LINE__` by hand, because it is also variadic (a printf-style
`format` plus a variable tail of arguments), and no portable C89 mechanism
forwards a variable argument list to a function while also *prepending*
computed tokens like `__FILE__`/`__LINE__` into the middle of that list. The
classic pre-C99 "double-parentheses" trick (`#define M(args) func args`)
forwards an arbitrary argument list, but only ever splices the caller's own
parenthesized tuple in as-is — it cannot also inject fixed tokens ahead of a
variable tail. The only mechanism that does both is a C99 variadic macro
(`...` / `__VA_ARGS__`); making a call with zero trailing arguments
additionally compile requires the GNU `, ##__VA_ARGS__` comma-elision
extension, since a genuinely empty `__VA_ARGS__` otherwise leaves a dangling
comma. Both are outside C89 (`-Wvariadic-macros`, `-Wgnu-zero-variadic-macro-arguments`
under Clang), and this repo's own C89 discipline is otherwise strict, so
whether to admit them needed a deliberate decision rather than a quiet one.

## Decision Drivers

- Consistency with the internal-function/wrapper-macro convention already
  used everywhere else in Nexus — the gap wasn't a design choice, it was an
  inconsistency, and the fix should restore the pattern rather than carve
  out a permanent second convention for variadic cases.
- Ergonomics is the entire point of the convention: callers should never
  hand-supply `__FILE__`/`__LINE__`.
- C89 fidelity is a first-class value here, so a deviation from it must be
  explicit, disclosed, and narrow — never silent.
- Portability in practice, not just on paper: both features, though
  non-standard, are supported by every mainstream compiler this codebase
  realistically targets (GCC, Clang, MSVC), unlike more obscure extensions.

## Considered Options

1. **C99 variadic macro + GNU comma-elision** — accept both as disclosed,
   narrow exceptions, silenced where they'd otherwise warn.
2. **Numbered fixed-arity macros** — `_FAILURE_0(code, format)`,
   `_FAILURE_1(code, format, a1)`, `_FAILURE_2(..., a1, a2)`, and so on up to
   some small N. Fully C89-legal, no new warnings anywhere.
3. **Status quo** — keep the underlying function's name public for the
   formatted/variadic case specifically, accepting that callers write
   `__FILE__, __LINE__` by hand only there.

## Decision Outcome

**Option 1.** Matches existing precedent in this exact flag list —
`-Wno-long-long` already accepts `long long` (also not standard C89) on the
same reasoning: a feature outside the standard that every real compiler
supports anyway is a pragmatic, low-risk exception, not a portability risk.
Both new warnings are silenced at the two places they surface: Helmfile's
real compiler flags (`-Wno-variadic-macros`, `-Wno-gnu-zero-variadic-macro-arguments`,
in both `_COMMON_COMPILER_FLAGS` and `_THREAD_SANITIZER_COMMON_COMPILER_FLAGS`)
for actual builds, and this repo's `.clang-tidy`
(`-clang-diagnostic-variadic-macros`, `-clang-diagnostic-gnu-zero-variadic-macro-arguments`)
for the lint pass, since `clang-diagnostic-*` surfaces plain compiler
warnings through clang-tidy too and needs its own matching suppression.

### Pros and Cons of the Options

**1. C99 variadic macro + GNU comma-elision** *(chosen)*
- Good: restores the established convention exactly, verified working for
  both the with-arguments and zero-arguments call shapes; two flags to
  maintain, matching an already-accepted precedent.
- Bad: two more non-C89 features admitted into a codebase that otherwise
  holds a hard C89 line.

**2. Numbered fixed-arity macros**
- Good: zero new warnings, fully standard C89.
- Bad: does not scale — a hard cap on argument count, a family of
  near-duplicate macros, and every future variadic-shaped API in Nexus would
  need the same treatment repeated from scratch.

**3. Status quo**
- Good: nothing new to accept.
- Bad: does not solve the actual problem — this decision exists because the
  inconsistency was flagged as unwanted, not because a fix was optional.

## Consequences

- Two more `-Wno-*` flags in Helmfile and two more suppressions in
  `.clang-tidy`, alongside the existing `-Wno-long-long` precedent for the
  same class of pragmatic exception. Worth keeping an eye on this list not
  growing unbounded — each future exception should get the same explicit,
  disclosed treatment this one did, not silent accumulation.
- Any future Nexus (or client-library) function that wants both
  auto-injected call-site context and variadic forwarding can reuse this
  exact pattern without re-litigating it.

## Framework Hook

An explicit, narrow, disclosed exception is more resilient than either a
silent nonstandard-feature use or an ergonomic gap left unfixed — the
Dependable-C bar is about knowing exactly where and why a standard is
deviated from, not about a deviation never happening (STYLE_GUIDE.md §
Dependable C).

## Related Decisions

- Consumed by nexus `adr/0001-nexus-error-representation` — the concrete
  function (`_nexus_program_errors_failure_create` /
  `NEXUS_PROGRAM_ERROR_FAILURE`) this decision was made for.
