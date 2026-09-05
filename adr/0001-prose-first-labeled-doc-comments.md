# 0001. Prose-first labeled doc comments; no Doxygen

## Status
Accepted

## Context and Problem Statement

Every library in the monorepo publishes a single public header (STYLE_GUIDE.md
§ Black-Box Modules). That header carries not just declarations but the whole
contract a client integrates against — ownership, failure behavior, threading
rules. `libs/nexus/nexus.h` had settled into a consistent house style for
those comments (inherited from Eskil Steenberg's Forge): a flush-left
`/* */` block above each symbol, name-first prose, no markup. It was never
written down, it was inconsistent with itself in three places (name-first vs
implicit subject, enum members as an aligned list vs trailing comments,
cross-reference spelling), and it is not reliably machine-readable.

Mr. Hoorn intends to write an in-house documentation generator later. That
forces the question now: what exactly is the comment format, and is it
structured enough for a generator to extract a symbol's summary, parameters,
ownership rules, error contract, and threading notes without guessing.

## Decision Drivers

- **Header-as-documentation** (§ Black-Box Modules) — the comment format is a
  first-class part of the API surface, not an afterthought; its shape must be
  as predictable as the API's (Cheng).
- **Explicit-over-implicit at the failure boundary** (§ Error Handling) — a
  reader must see which misuses abort and which return a code without opening
  the implementation.
- **Machine-readable** — a future in-house generator must parse it with simple
  anchored rules, not a model of C semantics.
- **Readability** — the comment exists to be read; markup that fights reading
  is a net loss.
- **Dependable C / C89** — `/* */` only.
- **No new build-time dependency** — no Doxygen in the toolchain.
- **DDP-scaled effort** (§ Testing and Validation) — the format must let a
  one-off `static` carry one line and a foundational entry point carry a full
  contract, not force a uniform template.

## Considered Options

1. Doxygen / Javadoc markup (`@param`, `@return`, `@brief`, ...).
2. Unlabeled prose in a fixed paragraph order — the existing house style,
   formalized.
3. Prose with a fixed, closed set of labeled slots (`Summary:`, `Params:`,
   `Ownership:`, `Errors:`, `Thread-safety:`, `Complexity:`, `See:`, ...).
4. A sidecar format — a structured block (YAML-ish) per symbol, or separate
   Markdown docs alongside the header.

## Decision Outcome

**Option 3 — prose with labeled slots.** The labels are ordinary English
lead-ins that read aloud as sentences, so readability is preserved; they are
also stable anchors, so a generator keys on `^<Label>: ` against a closed
vocabulary with no C parsing. The slot set is fixed and ordered, which gives
the header face the familiarity the Cheng/Ch'i split demands — the ownership
rule and the failure behavior of every function are found in the same place.
`Errors:` is mandatory for any fallible function and names both halves of the
bifurcation.

Decisive driver: machine-readability *without* sacrificing readability or
adding a toolchain dependency — which is exactly what disqualified options 1
and 2.

Recorded in `STYLE_GUIDE.md § Documentation` (rationale) and
`CONVENTIONS.md § Documentation` (mechanics).

### Pros and Cons of the Options

**1. Doxygen / Javadoc markup**
- Good: a de facto standard; off-the-shelf generators exist; unambiguous to
  parse.
- Bad: `@param name` restates type information the signature already carries;
  reduces a contract to a per-parameter checklist and discourages describing
  behavior that spans parameters; `@`-noise degrades reading; pulls a
  generator into the build or a doc-site pipeline nobody wants; `/**` is a
  markup convention the C89 prose style otherwise avoids.

**2. Unlabeled prose, fixed order**
- Good: zero notation; exactly today's nexus.h; nothing to learn.
- Bad: slot boundaries are ambiguous — a generator must infer "this paragraph
  is the ownership rule" from cue words; the fixed order is unenforceable and
  already drifts; no reliable structure to extract.

**3. Prose with labeled slots** *(chosen)*
- Good: reads as English; parses with one anchored rule and a closed word
  list; fixed order gives a familiar header face; scales from one line to a
  full contract; no toolchain.
- Bad: heavier to write than free prose; the label vocabulary is a small
  standard that must be maintained in one place and kept closed; existing
  nexus.h blocks need a retrofit pass.

**4. Sidecar format**
- Good: maximally structured; a generator's job becomes trivial.
- Bad: violates Locality of Behavior — the contract no longer lives next to
  the symbol; two artefacts to keep in sync, which per § Documentation is the
  exact failure mode to avoid; a reader of the header no longer has the whole
  picture.

## Consequences

- Every public symbol now carries a heavier, structured comment. Writing a
  header is slower; reading and auditing one is faster and more uniform.
- The label vocabulary is a closed set owned by `CONVENTIONS.md § Documentation`.
  Adding a label is a deliberate edit there, not an ad hoc choice at a call
  site.
- `.clang-format` needs `ReflowComments: false`: with reflow on, a
  slot line pushed over `ColumnLimit` is re-wrapped and the following slot
  line is pulled up onto it, merging two slots. Disabling reflow makes the
  hand-wrapping authoritative; verified to leave every existing comment block
  in `nexus.h` unchanged.
- `nexus.h` needs a one-pass retrofit of all pre-existing blocks. Done as its
  own commit(s), coordinated so it does not collide with the in-flight
  ENVIRONMENT / TERMINAL / FILESYSTEM sections (which are written to the new
  format directly).
- No generated HTML/reference docs until the in-house generator is built —
  accepted; the header itself remains the reference in the meantime.
- Review gains a concrete checklist: slot presence per trigger, closed
  vocabulary, banned tokens, and the `Errors:`-slot ↔ precondition-assertion
  correspondence. Wired into `deep-review`, `style-check`, `api-surface`,
  `performance-review`; no post-edit hook (review-only).
- The `Errors:` slot and the function's `NEXUS_PRECONDITION` /
  `NEXUS_POSTCONDITION` set become two views of one contract that must agree —
  a new, checkable invariant.

## Framework Hook

Serves § Black-Box Modules (the header is the complete interface, so its prose
is part of the interface), § Error Handling (the bifurcation is made visible
at the point of use), § Testing and Validation (documentation effort scales
with DDP rank × complexity, not uniformly), and § Second-Order Observation
(the doc states the contract; the assertions are the lens that observes it
holding; the two must not diverge). Cost knowingly accepted: more keystrokes
per symbol and a small vocabulary to maintain — "typing is never the problem,
debugging is."

## Related Decisions

- Related to the deep-review merge gate (superproject
  `adr/0001-deep-review-gate-on-master-merges`), whose hooks live in this
  repo's `git-hooks/` — the review skills that gate runs now also check
  documentation conformance.
