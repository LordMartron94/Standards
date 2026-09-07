# 0002. The ADR admission threshold

## Status
Accepted

## Context and Problem Statement

The ADR practice was already in use across the monorepo — one numbered
sequence per repo, a Full and a Lite tier, cross-referenced by ID and link
([`adr_template.md`](../adr_template.md), `CONVENTIONS.md`). What was never
written down was the *threshold*: which decisions earn a record and which do
not. `AGENT.md` and `CLAUDE.local.md` named example triggers ("a dependency
severed, a rewrite-vs-refactor call, an API-boundary choice, a
tooling-convention change") but no test a decision could be held against, and
`adr_template.md` gave only a loose tier hint.

The gap showed up in two directions. At decision time: is this an ADR? And
over the life of the sequence: the well-documented "200 ADRs, nobody reads
them" failure mode, where the records that carry real orientation are buried
under records of decisions that were never in doubt. A threshold was needed —
explicit enough to apply without re-deriving it each time, and tight enough
that a record always repays the reader's attention.

## Decision Drivers

- **Resilience through legibility** — a settled decision must survive as a
  *decision premise* (Luhmann, via `STYLE_GUIDE.md § Rewriting vs
  Refactoring`): retrievable later without reconstructing it from a commit
  message. Argues for a low bar.
- **The log must stay readable** — every low-value record spends attention
  and dilutes the sequence. Argues for a high bar.
- **Testability** — the threshold has to be a checklist, not a feeling, so
  that the deep-review gate and a drafting assistant can both apply it the
  same way.
- **Solo-developer reality** — most ADR literature assumes teams (onboarding,
  stakeholder alignment, review boards). The surviving reasons here are
  future-self context recovery, protecting premises from re-litigation, and
  legibility for parallel Claude/Codex sessions and any eventual collaborator.

## Considered Options

1. **Significance + friction gate** — Nygard's "architecturally significant"
   surface set (structure, interface, dependency, non-functional,
   cross-cutting) *and* at least one friction condition (hard to reverse, real
   alternative lost, first-of-a-kind, style-guide deviation). Both halves
   required, plus an explicit never-write-one list.
2. **Architectural-fork test only** — record only when a named fork is
   resolved (dependency severed, rewrite-vs-refactor, API boundary, tooling
   convention); the pre-existing `AGENT.md` language made canonical.
3. **Zimmermann ASR checklist** — score every decision Y/N/? against seven
   criteria (business impact, stakeholder concern, quality-of-service
   deviation, uncontrolled external dependency, cross-cutting, first-of-a-kind,
   prior trouble); any Y means a record.
4. **"Almost always" (Spotify)** — any non-obvious decision not already
   captured elsewhere gets at least a Lite record.

## Decision Outcome

**Option 1, the significance + friction gate.** A decision earns an ADR when
it clears *both* a surface test (touches structure, a public interface, a
dependency edge, a non-functional profile, or is cross-cutting) and a friction
test (hard to reverse, a real alternative lost, first-of-a-kind for this
codebase, or a knowing style-guide deviation). Paired with an explicit
never-write-one list, an alternatives-or-surface rule for the Full/Lite
boundary, a timing rule that binds the record to the pre-merge review gate,
and an immutability rule scoped to the same `master` boundary — an ADR is
free to be rewritten or merged with a sibling while its subject is only
privately implemented, and becomes a supersede-don't-rewrite record only once
that subject reaches `master`.

A granularity rule was added after the first application of the gate (see
Consequences): the gate decides *whether* a design is recorded, and the
granularity rule decides *how many files* that record is. One coherent design
is one ADR however many sub-choices it settles; a genuine sub-fork is a
section, not its own file; and a Considered Option must be an alternative
someone actually advocated, not an earlier draft of the chosen design. Without
it the gate is satisfied per-decision while the sequence still inflates,
because a design worked out over a session accretes one record per checkpoint.

The decisive driver was testability under both competing pressures. The
two-part gate is the only option that is at once a mechanical checklist and
self-limiting: the surface test keeps out purely internal churn, and the
friction test keeps out the obvious-and-reversible decisions that Option 4
would sweep in. Option 2 is a subset of the surface test with no friction
filter and no exclusion list — it under-specifies. Option 3 is the closest
rival and its criteria are absorbed into the gate (cross-cutting, external
dependency, first-of-a-kind all appear), but its team-facing criteria
(business impact, stakeholder concern) carry little weight solo, and a
seven-way Y/N/? score per decision is heavier ceremony than the fork it often
guards.

Recorded in `STYLE_GUIDE.md § Architecture Decision Records` (rationale) and
`CONVENTIONS.md § Architecture Decision Records` (mechanics);
`adr_template.md`'s preamble defers its tier hint to those.

### Pros and Cons of the Options

**1. Significance + friction gate** *(chosen)*
- Good: a checklist, not a judgement call; self-limiting in both directions;
  the exclusion list names the exact failure mode; the friction conditions map
  onto forks that already matter here.
- Bad: a two-part test is more to remember than a one-line rule; "a real
  alternative was weighed" is still partly subjective; borderline decisions
  still need a call.

**2. Architectural-fork test only**
- Good: matches wording already in `AGENT.md`; fewest records; easy to state.
- Bad: no friction filter and no exclusion list, so it neither catches a quiet
  non-functional decision that had no dramatic "fork" moment nor rules
  anything out explicitly; "fork" is itself undefined.

**3. Zimmermann ASR checklist**
- Good: the most rigorous and explicit; forces the trade-off into the open;
  good conceptual fit with the DDP mindset.
- Bad: seven-criteria Y/N/? scoring per decision is real overhead; two
  criteria (business impact, stakeholder concern) are team-shaped and near
  dead weight for a solo monorepo.

**4. "Almost always"**
- Good: nothing of consequence is ever lost; lowest bar to clear; smallest
  decision at decision time.
- Bad: directly produces the log-nobody-reads outcome; the signal records
  drown; turns the sequence into a change log, which `git` already is.

## Consequences

- Every repo's `adr/` sequence now has a written admission test. A decision
  that fails either half is expected *not* to have a record, and that absence
  is correct, not an omission.
- Missing records become enforceable. A decision that clears the bar and
  appears in a diff without an ADR is a deep-review finding, and the existing
  merge gate (superproject `adr/0001-deep-review-gate-on-master-merges`)
  blocks the master merge until it is addressed.
- A one-time reconciliation. When this threshold lands, each repo's `adr/`
  sequence gets a single supervised pass against it *before that sequence
  next reaches master* — removing any sub-threshold record, re-tiering any
  mis-tiered one, filling any genuine gap, and **consolidating** any design
  that was recorded across several files into one ADR with sections —
  because the sequences are days old and still on unpushed development
  branches, so correcting a mistake then costs far less than carrying it
  forward.
- The first pass, over the Nexus (54-ADR) and Relay (11-ADR) logs: every record
  clears the surface × friction gate per-decision, but the Nexus corpus is
  over-granular — a coherent design (the memory tracker; the `NexusError`
  representation; the error-context model) is recorded as three to eight
  files each, and several "Considered Options" are earlier drafts of the
  chosen design rather than advocated alternatives. This is what surfaced
  the granularity rule. A consolidation pass merged the thin clusters into
  fewer ADRs with sections (reasoning preserved, nothing deleted), taking
  Nexus from 54 to 33, and the IDs were then closed up contiguously
  (0001–0033) in one renumber pass that updated every cross-reference in the
  repo, in `nexus.h` / `src`, and in `libs/relay`.
- After the pass the threshold is forward-looking. An ADR whose subject has
  reached `master` is immutable — a changed premise supersedes it by ID and
  link. An ADR whose subject is still privately implemented may be rewritten
  or merged in place; the supersede-don't-rewrite discipline exists to
  protect observers who have built on a premise, and before `master` there
  are none. This is why the consolidation pass is possible at all, and why
  it must finish before the Nexus and Relay branches merge.
- Borderline calls still exist. The gate narrows them but does not eliminate
  them; the tie-breaker is the friction question — "would a future reader
  have to reconstruct why the alternative lost?" — and a Lite record is the
  cheap default.
- `CONVENTIONS.md` gains an `Architecture Decision Records` section;
  `STYLE_GUIDE.md` gains the matching rationale section; `adr_template.md`'s
  preamble defers its tier hint to those; `AGENT.md` and `CLAUDE.local.md`
  stop restating a partial trigger and point at the gate.

## Framework Hook

An ADR is the persisted output of a *Decide* step in the OODA loop
(`STYLE_GUIDE.md § Adaptation`); this threshold decides which Decide steps are
consequential enough that skipping the persist step would cost future
orientation. It serves resilience by keeping settled premises retrievable and
protecting them from re-litigation (Luhmann's *Uncertainty Absorption*), and
serves the same goal in the other direction by refusing to let
low-consequence decisions dilute the record. The friction test is a
DDP-flavoured filter: the higher a decision's blast radius and
irreversibility, the more assurance — here, a written rationale — it must
carry.

## Related Decisions

- Related to [0001-prose-first-labeled-doc-comments](./0001-prose-first-labeled-doc-comments.md)
  — both set a documentation bar scaled to consequence rather than a uniform
  one.
- Related to superproject `adr/0001-deep-review-gate-on-master-merges` — the
  timing rule makes a missing ADR one of the findings that gate blocks on.
