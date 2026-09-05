# Architecture Decision Record Template

An Architecture Decision Record (ADR) is the written trace of a single
**Decide** step from the Adaptation/OODA loop described in the
[Style Guide](./STYLE_GUIDE.md). You Observed some friction, Oriented against
the real alternatives, and this document *is* the decision — captured before
you Act, so nobody (including future you) has to re-derive the reasoning from
a commit message or a half-remembered conversation. In Luhmann's terms it is a
**decision premise**: once written, it absorbs the ambiguity of that moment
permanently.

This is a different tool than the
[System Design Template](./system_design_template.md). That template is
upfront, whole-system scoping, filled in once before a system exists. An ADR
is written *as* consequential decisions happen, one file per decision, and
accumulates over a system's life — a dependency severed, a rewrite-vs-refactor
call, an API-boundary choice, a tooling convention adopted. If you're
answering "what is this system", use the system design template. If you're
answering "why did we do X instead of Y, and what does that commit us to",
write an ADR.

Not every decision earns a full record. Use the **Full** tier for anything
with real alternatives on the table, anything touching dependency
insulation or an API boundary, anything a stranger to the moment would need
the "why" reconstructed for. Use the **Lite** tier — a single structured
sentence — for small, reversible, single-alternative calls that still deserve
a paper trail but not a page.

## Directory & numbering convention

Every repo that accumulates architectural decisions keeps them in `adr/` at
its root:

```
adr/
  0001-title-slug.md
  0002-title-slug.md
  0003-title-slug.md
```

- IDs are four-digit, zero-padded, and monotonically increasing across the
  whole repo (Full and Lite share one sequence — they're both decisions).
- An ID is never reused, even if the ADR it names is later deprecated or
  superseded. History stays intact.
- The filename is `NNNN-title-slug.md`; the `NNNN. Title` inside the file
  must match the filename's ID and slug.
- Cross-references (Status's "Superseded by", Related Decisions, or an inline
  mention elsewhere) always give **both** the ID and a relative Markdown link,
  so the reference reads standalone *and* is one click away:
  `Superseded by [0007-use-arena-allocator](./0007-use-arena-allocator.md)`.
- **Cross-repo references** — when the target ADR lives in a *different*
  repository (a submodule ADR citing a superproject decision, or vice versa),
  give the ID and a repo-qualified path but **no** Markdown link: a
  `../../../` link resolves only in a full checkout and breaks when either
  repo is browsed standalone. Form: ``<repo> `adr/NNNN-title-slug` `` — e.g.
  ``superproject `adr/0001-deep-review-gate-on-master-merges` ``. Name the
  concrete tie (a shared hook, a consuming script) so the link's absence
  doesn't lose the "why".
- Optional but recommended once a repo has more than a handful: a short
  `adr/README.md` listing ID, title, and status, newest last.

## Template Block — Full ADR

Copy the block here into `adr/NNNN-title-slug.md` and fill it in:

```md
# NNNN. <Title>

## Status
*Proposed / Accepted / Deprecated / Superseded by [NNNN-title-slug](./NNNN-title-slug.md)*

## Context and Problem Statement
*The situation, stated neutrally enough that someone with no memory of this
moment could still follow it. What forced a decision at all?*

## Decision Drivers
*The constraints or goals that actually shaped the choice — resilience,
dependency insulation, performance, portability, DDP rank, whatever was
load-bearing here. Not a generic list; the drivers specific to this call.*

## Considered Options
*Every option seriously on the table, one line each. An option nobody
seriously weighed doesn't belong here.*

## Decision Outcome
*The chosen option, and the decisive reason — which driver actually tipped
it, not just "it was best".*

### Pros and Cons of the Options
*One subsection per considered option: what was genuinely good about it,
what was genuinely bad. Include the option that lost; that's the point.*

## Consequences
*What becomes easier or harder as a result. State the negative consequences
honestly — a decision with no downside listed wasn't examined closely enough.*

## Framework Hook (optional)
*How does this decision serve — or knowingly complicate — resilience,
dependency insulation, DDP rank, or the OODA loop from STYLE_GUIDE.md? Omit
entirely if the decision is purely mechanical and doesn't touch the
philosophy.*

## Related Decisions (optional)
*Supersedes / Superseded by / Related to — each as ID + relative link.*
```

## Template Block — Lite ADR (Y-Statement)

For the smaller calls. Same file location and numbering, one shared sequence
with Full ADRs:

```md
# NNNN. <Title>

## Status
*Proposed / Accepted / Deprecated / Superseded by [NNNN-title-slug](./NNNN-title-slug.md)*

## Decision
*In the context of <use case / component>, facing <concern>, we decided for
<option> to achieve <quality or goal>, accepting <downside>.*

## Framework Hook (optional)
*Same as the Full tier — omit if it doesn't apply.*

## Related Decisions (optional)
*Same as the Full tier.*
```

## Example

A real one, small enough to be Lite, from tightening `infra/standards/.clang-tidy` to permit underscore-prefixed internal names:

```md
# 0001. Allow a leading underscore on internal function names

## Status
Accepted

## Decision
In the context of naming internal (`static`) helper functions across the
Dependable-C libraries, facing the need to visually mark "not part of the
public API" at the call site without a longer prefix, we decided for a
`readability-identifier-naming.FunctionIgnoredRegexp` /
`bugprone-reserved-identifier.AllowedIdentifiers` exemption of
`^_[a-z][a-z0-9_]*$` (applied to the `bugprone`, `cert-dcl37-c`, and
`cert-dcl51-cpp` check instances, which do not share options despite aliasing
the same underlying check) to achieve a terse internal-marker convention,
accepting that a leading underscore is technically a reserved identifier
under the C standard for file-scope names, which no mainstream compiler
currently exploits at that scope but is a knowing deviation from strict
portability purity.

## Framework Hook (optional)
Trades a small amount of Dependable-C portability purity (STYLE_GUIDE.md §
Language Features) for call-site clarity (§ Style, explicit-over-implicit).
Accepted because no realistic Dependable-C target reclaims `_lowercase`
identifiers at file scope; revisit if one ever does.
```
