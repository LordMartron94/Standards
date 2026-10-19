# Conventions Quick Reference

Terse, mechanical rules only — no rationale, no philosophy. This is the single
place they're written down; nowhere else in this repo (or in any consuming
repo's Claude setup) should restate them — link here instead.

For the *why* behind any rule, see `STYLE_GUIDE.md` (§ heading noted per
section below). For the process templates these rules feed, see the
`*_template.md` files in this directory.

## Naming

- **Functions:** `<library/module>_<system>_<action>[_suffix]`
  — example: `nexus_paths_is_directory`
  — source file: `src/<prefix>_<system>.c` — example: `src/n_paths.c`
  — internal (`static`) functions: prefixed with the **system**, not the full
    library name — example: `n_path_resolve`
  — internal names may additionally take a single leading underscore to mark
    "not part of the public API" at the call site — example:
    `_n_path_resolve`. See `.clang-tidy`'s `FunctionIgnoredRegexp` /
    `bugprone-reserved-identifier` (+ cert aliases) `AllowedIdentifiers`
    exemptions, both `^_[a-z][a-z0-9_]*$`.
  — STYLE_GUIDE.md § Naming
- **One system = one file (exported functions).** `src/<prefix>_<system>.c`
  contains ONLY exported functions whose `<system>` part is that file's
  system. "Exported" means used outside the file: declared in the public
  header (`<library>_<system>_*`) or in the internal header
  (`<prefix>_internal.h`, `<prefix>_<system>_*`). An exported function that
  belongs to a different system goes in that system's file (created if
  needed), however small the file or however related the two systems feel. A
  small backend/type specialization is part of the system name and gets its own
  file: `s_rendering_foo.c` holds `splash_rendering_foo_*`. A backend big enough
  to need several subsystems gets a subfolder instead, `src/<backend>/`, one
  file per subsystem, `src/<backend>/<prefix>_<system>.c` (prefix = library
  letter + backend letter, e.g. `sv_device.c`) holding
  `<library>_<backend>_<system>_*` (`splash_vulkan_device_create`). The backend
  has two headers: `<prefix>_backend.h`, its entry points and free of
  backend-API types, the only thing the rest of the library includes; and
  `<prefix>_internal.h`, what the backend's own files share. Name the
  *function* for the system it belongs to (`splash_adapter_select` in
  `s_adapter.c`), never for the caller's system. **`static` file-private
  functions are exempt** — they exist only within one file, so they may be
  named and placed freely. Mechanically checked (non-static definitions only)
  by `infra/standards/check_file_system_naming.sh`, run by the post-edit hook.
  — STYLE_GUIDE.md § Naming
- **Types:** library-prefixed, full or abbreviated per library
  — full: `NexusPath` (Nexus) — abbreviated: `LLibrary` (Loom)
  — STYLE_GUIDE.md § Naming
- **Enums:** named like a type; members prefixed with the enum's abbreviation
  — example: `NTP_MICRO_SECOND` in `NexusTimePrecision`
  — STYLE_GUIDE.md § Naming
- **Macros:** `UPPER_CASE` by default. May instead be styled like a function
  (`lower_case`, optionally `_`-prefixed per the function rule above) when the
  macro is meant to read like a function call at its use site. An `UPPER_CASE`
  macro may additionally take one or more trailing underscores to mark
  "internal helper, not for direct use" — example: `C_PRAGMA_` (helper behind
  `C_POISON`) — since a leading underscore before an uppercase letter is a
  reserved identifier and can't fill that role the way it does for functions.
  Not covered in STYLE_GUIDE.md's prose; enforced via `.clang-tidy`'s
  `MacroDefinitionIgnoredRegexp` =
  `^_?[a-z][a-z0-9_]*$|^[A-Z][A-Z0-9]*(_[A-Z0-9]+)*_+$`.

## Casing

| Kind         | Case                                                |
|--------------|------------------------------------------------------|
| functions    | `snake_case`                                          |
| variables    | `snake_case`                                          |
| parameters   | `snake_case`                                          |
| structs      | `PascalCase`                                          |
| enum members | `SCREAMING_SNAKE_CASE`, prefixed with enum abbreviation |
| macros       | `UPPER_CASE` (or function-styled — see Naming above)  |

STYLE_GUIDE.md § Casing

## Includes

Ordered **lowest layer → highest layer**, not alphabetical
(`SortIncludes` off in `.clang-format`). Example order:

```
<nexus.h>                 (foundation)
<echo.h>                  (logging)

<blaze.h>                 (numerical computing)
<engram.h>                (AI library)

<aegis.h>                 (telemetry / reporting)

"../<library>.h"          (current library public header)
"./<prefix>_internal.h"   (current library internal header)
```

**Include what you use.** A file includes every header whose symbols it uses itself, third-party and
project alike (`<GL/glx.h>`, `<X11/Xlib.h>`, `<xcb/xcb.h>`, `<vulkan/vulkan.h>`, `<blaze.h>`, ...), even when
one of the library's own headers (`<prefix>_internal.h`, `<backend>_internal.h`) already includes it: an
include chain hides what a file depends on and breaks when an internal header is reshaped. The one exception
is what Nexus provides (`NULL`, `size_t`, the fixed-width types): those are not re-included from standard
headers. `misc-include-cleaner` ("no header providing X is directly included") is the check.

STYLE_GUIDE.md § Includes

## Function shape

Long, explicit, sequential, top-to-bottom narrative. No orchestrator
functions, no deep nesting. Extract a sub-routine only when a long procedure
genuinely obscures its core narrative — don't default to helpers.

STYLE_GUIDE.md § Locality of Behavior

## Inlining

A function whose entire body is trivial and cheap — a fixed, small number of
shifts/masks/comparisons, no loop bound by caller-supplied data, no
allocation, no syscall — is defined `static`, directly in the library's
public header, not declared there and defined in a source file. Everything
else (a loop over caller-supplied length, an allocation, a syscall) still
belongs in a source file.

Mark each such header-defined function so an including translation unit that
never calls it doesn't warn under `-Wall`'s `-Wunused-function` — see
`NEXUS_MAYBE_UNUSED` in `libs/nexus/nexus.h` for the pattern (a library
without a `NexusFoo`-shaped macro name already reserved defines its own
equivalent the same way).

STYLE_GUIDE.md § Inlining

## Modules

One public header per library; internal types opaque (void pointers /
incomplete types). External dependencies always wrapped behind an
owned interface, confined to one translation unit.

Headers use `#pragma once`; do not use macro include guards.

STYLE_GUIDE.md § Black-Box Modules, § Insulation

## Errors

Programmer error → immediate hard assert that halts. User error → explicit
return code the caller must handle. No silent failure, no reliance on
zero-init. Fresh allocations seeded with a recognizable byte pattern.

STYLE_GUIDE.md § Error Handling

## Documentation

Terse rules only; rationale in STYLE_GUIDE.md § Documentation. Fork record:
[`adr/0001-prose-first-labeled-doc-comments`](./adr/0001-prose-first-labeled-doc-comments.md).

### Form

- One block comment (`/* ... */`, C89) directly above the symbol it
  documents — no blank line between the block and the declaration.
- `/*` alone on the opening line, `*/` alone on the closing line. No leading
  `*` on interior lines. Labels and prose flush-left; continuation lines
  within a slot indented two spaces.
- Hand-wrapped prose is authoritative — `.clang-format` has
  `ReflowComments: false` so the formatter never re-flows a block
  (adr/0001). Match the file's own wrap width (Nexus wraps ~76); keep every
  line well under 100 regardless.
- **Banned:** `//`; `/**` and `/*!`; every `@tag` / `\tag` (`@param`,
  `@return`, `@brief`, `@note`, `@see`, `@pre`, `@post`, `@warning`, ...);
  commented-out code; author / date / change-history lines (git owns that).

### Slots — closed vocabulary, fixed order

A slot is a line beginning `Label: `. Its body runs to the next slot line or
`*/` (blank and indented lines belong to the current slot). Each slot at most
once, in this order. Omit a slot only when its trigger is unmet.

| Slot             | Present when                                                            |
|------------------|------------------------------------------------------------------------|
| `Summary:`       | always — one line; should name the symbol                               |
| `Description:`   | behavior needs more than the summary line                               |
| `Params:`        | a parameter carries a non-obvious fact — copied / borrowed / retained / nullable / out / must-not-alias. One line each, `name  text`; omit the slot when no parameter does (the signature already lists them). Not a per-parameter checklist |
| `Returns:`       | return type is non-`void` and not `NexusError`                          |
| `Ownership:`     | any pointer or handle crosses the boundary (in or out)                  |
| `Errors:`        | the symbol can fail — states the assert cases and the returned codes separately |
| `Thread-safety:` | it touches shared / owned mutable state, installs a callback, or needs a quiescent period |
| `Complexity:`    | DDP-foundational and it loops over caller data or allocates (optional otherwise) |
| `See:`           | optional — cross-references                                             |
| `Example:`       | optional — only when call sequencing is non-obvious                     |

Types use `Summary:` / `Description:` / `Ownership:` / `Thread-safety:` /
`See:`, plus one of:

| Slot       | For                                                                  |
|------------|--------------------------------------------------------------------|
| `Fields:`  | a transparent struct whose fields need more than a short trailing `/* */` |
| `Values:`  | an enum whose members need more than a short trailing `/* */`         |

Short struct fields / enum members: trailing `/* */` on the member line, no
slot.

### Depth — proportional to DDP rank × complexity (as § Testing)

- foundational or complex public symbol → every triggered slot, full `Description:`
- ordinary public symbol → `Summary:` + triggered `Params:` / `Returns:` /
  `Ownership:` / `Errors:`
- internal (`static`) symbol, not obvious from name + signature → `Summary:` line only
- internal symbol obvious from name + signature → no block
- header-inlined trivial `static` (§ Inlining) → `Summary:` line only

### `Errors:` slot ↔ assertions

Every "... is a programmer error" clause in an `Errors:` slot has a matching
`NEXUS_PRECONDITION` / `NEXUS_POSTCONDITION` in the implementation, and every
such assertion is named in the `Errors:` slot. Two encodings of one contract;
they must agree.

### Implementation (`.c`) files

- No doc block above a definition whose contract is already in the public
  header (one contract, one place).
- A file-local `static` gets a `Summary:` line only if its purpose is not
  obvious from name + signature.
- Inline `/* */` comments explain *why*, the non-obvious mechanism, or the
  invariant held — never restate the header contract, never narrate what the
  code plainly says.
- Section banner between sections of any file that has more than one:

  ```
  /* ---------------------------------------------------------------------------- */
  /* SECTION TITLE                                                                 */
  /* ---------------------------------------------------------------------------- */
  ```

### Cross-reference forms (`See:` and inline)

| Target          | Form                                              |
|-----------------|-------------------------------------------------|
| ADR             | `adr/NNNN-slug` — the file's own repo's `adr/`    |
| research report | `results/research/<report-stem>`                 |
| sibling symbol  | bare identifier, e.g. `nexus_paths_normalize`     |
| style guide     | `STYLE_GUIDE.md § <Heading>`                      |
| design doc      | `DESIGN.md § <Heading>`                           |

### Library header file block

Top of `<lib>/<lib>.h`: `Summary:` (the library's essence / operational
code), `Layer:` (its place in the include order), `See:` (`DESIGN.md`,
load-bearing ADRs). Source files need no file block.

### Worked example

```c
/*
Summary: spawn a child process from a validated specification.
Description:
  Runs the spawn transaction: static validation, then a fork and an
  async-signal-safe child path that execs or reports failure back over a
  close-on-exec pipe. Commits fully or rolls back leaving nothing.
Params:
  specification  validated spec; borrowed, not retained
  out_process    out; on success owns one running process, NULL on failure
  out_streams    out; requested pipe endpoints, NULL if none were requested
Ownership:
  Caller owns *out_process and releases it with nexus_process_destroy.
  Streams in *out_streams are owned by that process and freed by that destroy.
Errors:
  A NULL specification or out_process is a programmer error (asserts).
  Returns a NEC_PROCESS reason on any spawn failure; on failure no child
  runs and every descriptor Nexus opened is closed.
Thread-safety: safe to call concurrently for distinct specifications.
See: adr/0032-fork-exec-spawn-with-error-pipe
*/
NEXUS_ERRORS_NODISCARD extern NexusError nexus_process_spawn(const NexusProcessSpecification *specification, NexusProcess **out_process,
                                                             NexusProcessStreams *out_streams);
```

STYLE_GUIDE.md § Documentation

## Compiler validation after edits

After every C/C++ source or header edit batch, including Python/shell edits,
format touched C files with PATH `clang-format`, then run the affected
translation units' exact `compile_commands.json` commands with
`-fsyntax-only`. Remove only compilation/output/dependency-emission switches
(`-c`, `-o`, `-MD`, `-MMD`, `-MF`, `-MT`, `-MQ`, `-MP`) and their operands.
Keep every compiler, dialect, warning, optimization, ABI, definition, and
include-path option; never substitute hand-written flags or add suppressions.

Run `clang-tidy -p .` with the project's configuration as well. Inspect full
current diagnostics, without a baseline diff. Fix introduced warnings/errors,
report any pre-existing include-cleaner noise, and recheck after fixes before
another edit batch or completion. Header edits require checking their owning
library and affected consumers, not compiling an isolated header blindly.

Regenerate the MergeSource database with `make configure` (CMake export) when
new translation units or changed build settings make it stale. Missing exact
commands are a validation blocker; do not invent approximate flags.
Successful build-system output, formatter checks, tests, and sanitizer runs do not
establish compiler-warning cleanliness. Report what actually ran.

Reusable checker: `python3 tools/scripts/check_c_changes.py <source-or-library>`
(`--report <path>` retains exact commands and full diagnostics). For a header
edit, pass its owning library plus affected consumer translation units. The
checker reports the known Nexus-owned NULL include-cleaner noise explicitly;
it never hides compiler warnings or baseline-diffs new findings.

## Testing

Investment is proportional to Dependable Dependencies Principle rank ×
complexity, not uniform. Foundational or complex code → thorough coverage.
One-off utilities → no dedicated test required. Every field bug that reaches
production becomes either a new regression test or a new assertion
combination — never left to recur silently.

STYLE_GUIDE.md § Testing and Validation, § Dependability

## Architecture Decision Records

Rationale: STYLE_GUIDE.md § Architecture Decision Records. Numbering,
cross-reference forms, and the Full / Lite template blocks:
[`adr_template.md`](./adr_template.md). This section is the mechanical
threshold only — when a decision earns a record at all, and which tier.

### Write one — both halves must hold

- **Surface** — the decision touches at least one of:
  - structure — a module boundary, a layer, an architectural pattern
  - a public interface or published contract
  - a dependency edge — add / remove / wrap / sever an external or
    cross-library dependency
  - a non-functional profile — throughput, footprint, resilience, portability
  - cross-cutting reach — one change rippling through many translation units
    or every caller
- **Friction** — at least one of:
  - hard or expensive to reverse
  - a real alternative was on the table and lost
  - first-of-a-kind for this codebase
  - a knowing deviation from the style guide (the `infra/agents/AGENT.md`
    violation-and-alternatives flow)

Clears surface but not friction → no record; the code already carries it.

### Never write one for

- a detail already fixed by an accepted ADR, `DESIGN.md`, or the style guide
  — no new decision was made
- a routine application of an established pattern where no alternative was
  weighed
- a purely local, cheaply reversible call — one symbol's name, one loop's
  shape, one private helper's extraction
- a decision already written up in a research report or design doc —
  cross-link, don't restate

### Tier

- **Full** — two or more alternatives worth comparing, **or** the decision
  changes a public API, a dependency edge, or a non-functional profile.
- **Lite** (Y-statement) — any other decision that clears the bar.

One ID sequence across both tiers (`adr_template.md`).

### Granularity

- One coherent design is one ADR — however many sub-choices it settles. A
  genuine sub-fork is a **section** of that ADR, not its own file.
- A *Considered Option* is an alternative someone actually advocated — not an
  earlier draft of the chosen design listed as what it was refined away from.
  Design history goes in the prose.

### Timing

- Drafted when the decision is made; in the branch before it merges to
  master.
- A decision that clears the bar, visible in a diff with no record, is a
  deep-review finding — the merge gate (superproject
  `adr/0001-deep-review-gate-on-master-merges`) blocks on it like any other.

### Immutability

- An ADR becomes immutable when the change it records reaches `master`. From
  then on, a changed premise is a **new** record that supersedes the old by
  ID + link; the original is never edited away, and IDs are never reused.
- Before that — while the subject is only privately implemented (a
  development branch, unpushed, unmerged) — the ADR has no observers to
  protect and may be rewritten, merged with a sibling, split, renumbered, or
  deleted directly. ADRs preserve the reasoning behind *persisted* changes to
  established behaviour or structure; a decision that has not persisted has
  nothing to preserve it against.

STYLE_GUIDE.md § Architecture Decision Records, § Adaptation

## Templates & meta-files (this repo)

- `infra/standards/<subject>_template.md` — a copy-into-your-document
  template. Existing: `system_design_template.md`, `adr_template.md`.
- **ADR convention** (full detail: `adr_template.md`) — each repo keeps its
  architectural decisions in `adr/NNNN-title-slug.md`, one shared ID sequence
  across the Full and Lite tiers, IDs never reused once on master,
  cross-referenced by ID
  **and** relative Markdown link — except a reference to an ADR in *another*
  repo, which is ID + repo-qualified path and no link (see `adr_template.md`).
  The write / don't-write threshold and the Full vs Lite rule are in
  § Architecture Decision Records above. Both tiers carry an optional
  Framework Hook back to the resilience/OODA framework below.

## Git Commits

Header: `(type): Short description` — type in parens, colon, one space, then
an imperative-mood, capitalized short line. Example: `(feat): Add X to Y`.

Types:

| Type       | For                                                       |
|------------|------------------------------------------------------------|
| `feat`     | a new capability or behavior                                |
| `fix`      | a bug fix                                                    |
| `refactor` | internal restructuring, no behavior change                  |
| `perf`     | a performance or footprint improvement                      |
| `test`     | tests added or changed, no production behavior change       |
| `docs`     | documentation only (`STYLE_GUIDE.md`, `CONVENTIONS.md`, templates, comments) |
| `chore`    | dependency bumps, submodule updates, housekeeping            |
| `build`/`ci` | build system, toolchain, or CI/packaging changes           |

`feat`/`fix`/`refactor`/`chore`/`docs` are already in use across this
monorepo's history (`git log`); `perf`/`test`/`build`/`ci` extend the same
family for cases that haven't come up yet.

Body: one or more lines below the header, blank-line separated, for whatever
the header line can't carry — rationale, what else changed, and critically
any **API change, breaking change, or usage warning** the commit introduces.
Say it explicitly in the body; don't rely on the short line to carry it, so
it survives a `git log --oneline` skim and shows up in `git blame`.

A commit with no body is fine for a genuinely self-explanatory change. A
commit that breaks or changes a public API, or carries a usage warning, is
never header-only.

## Framework (for "Framework Hook" / DDP / resilience references above)

Resilience-centered. Dependable C (C89 subset). Boyd's OODA loop +
Luhmann's functionally differentiated systems theory. Dependable Dependencies
Principle (dependency rank × complexity → required assurance). Full
treatment, including the Adaptation/MACRO/MICRO model: `STYLE_GUIDE.md`.
