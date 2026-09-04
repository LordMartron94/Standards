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
- **Types:** library-prefixed, full or abbreviated per library
  — full: `NexusPath` (Nexus) — abbreviated: `LLibrary` (Loom)
  — STYLE_GUIDE.md § Naming
- **Enums:** named like a type; members prefixed with the enum's abbreviation
  — example: `NTP_MICRO_SECOND` in `NexusTimePrecision`
  — STYLE_GUIDE.md § Naming
- **Macros:** `UPPER_CASE` by default. May instead be styled like a function
  (`lower_case`, optionally `_`-prefixed per the function rule above) when the
  macro is meant to read like a function call at its use site. Not covered in
  STYLE_GUIDE.md's prose; enforced via `.clang-tidy`'s
  `MacroDefinitionIgnoredRegexp` = `^_?[a-z][a-z0-9_]*$`.

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

STYLE_GUIDE.md § Includes

## Function shape

Long, explicit, sequential, top-to-bottom narrative. No orchestrator
functions, no deep nesting. Extract a sub-routine only when a long procedure
genuinely obscures its core narrative — don't default to helpers.

STYLE_GUIDE.md § Locality of Behavior

## Modules

One public header per library; internal types opaque (void pointers /
incomplete types). External dependencies always wrapped behind an
owned interface, confined to one translation unit.

STYLE_GUIDE.md § Black-Box Modules, § Insulation

## Errors

Programmer error → immediate hard assert that halts. User error → explicit
return code the caller must handle. No silent failure, no reliance on
zero-init. Fresh allocations seeded with a recognizable byte pattern.

STYLE_GUIDE.md § Error Handling

## Testing

Investment is proportional to Dependable Dependencies Principle rank ×
complexity, not uniform. Foundational or complex code → thorough coverage.
One-off utilities → no dedicated test required. Every field bug that reaches
production becomes either a new regression test or a new assertion
combination — never left to recur silently.

STYLE_GUIDE.md § Testing and Validation, § Dependability

## Templates & meta-files (this repo)

- `infra/standards/<subject>_template.md` — a copy-into-your-document
  template. Existing: `system_design_template.md`, `adr_template.md`.
- **ADR convention** (full detail: `adr_template.md`) — each repo keeps its
  architectural decisions in `adr/NNNN-title-slug.md`, one shared ID sequence
  across the Full and Lite tiers, IDs never reused, cross-referenced by ID
  **and** relative Markdown link. Full tier for real alternatives / API or
  dependency impact; Lite (Y-statement) for small reversible calls. Both carry
  an optional Framework Hook back to the resilience/OODA framework below.

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
