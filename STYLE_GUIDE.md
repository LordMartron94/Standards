# STYLE GUIDE

Current version: 0.1.3

---

This file contains my personally written style guide for proper software engineering.

I started to write this because I thought it would be useful to have a centralized place for my own programming philosophy, which others contributing can benefit from, whether they are human or LLM.

---

## Table of Contents
- [Philosophy](#philosophy)
- [Mechanics](#mechanics)
	- [API Design](#api-design)
		- [Boundaries](#boundaries)
		- [Internals](#internals)
		- [Separation of Concerns](#separation-of-concerns)
			- [C APIs](#c-apis)
		- [Method](#method)
	- [Functions](#functions)
		- [Functions vs. Methods](#functions-vs-methods)
		- [Function Length](#function-length)
	- [Error Handling](#error-handling)
	- [Typing](#typing)
	- [Naming](#naming)
		- [Length](#length)
		- [Style](#style)
			- [General Function Naming](#general-function-naming)
			- [C Naming Style](#c-naming-style)
			- [Implicit Access made Explicit](#implicit-access-made-explicit)
	- [Commenting](#commenting)
		- [Regular Comments](#regular-comments)
		- [Code Documentation](#code-documentation)
			- [Example](#example-documentation-format)
	- [ADR](#adr)
		- [Example](#adr-example)
	- [Usage of LLMs](#usage-of-llms)
	- [Testing & Benchmarking](#testing-and-benchmarking)
- [References](#references)
- [Changelog](#changelog)

## Philosophy

Overall my philosophy boils down to a few principles (which might be extended/refined in the future):
- **Explicit > Implicit**: even if explicit means writing more code, it makes it infinitely more readable and debuggable, magic is not allowed.
- **Control > Results**: As Eskil Steenberg always says: in the beginning all you want is results, in the end all you want is control (ref:1). As such, I prefer building my own solutions to using 3rd party solutions (except in certain specific contexts). 
	- And when using external dependencies out of your control (with the exception of standard library usually), it is adviced to *wrap* the method so that if the dependency breaks the API contract on an update, you only have one place to adjust, and not hundreds spread around your application.
	- This wrapping idea can also be used when you require another library you built in another library, but this is not always useful. It depends on how often you break/refactor API contracts (which is generally a bad thing to do).
- **Learning > Efficiency**: In line with the previous principle, I also prefer gaining deep mastery over what might potentially be the more efficient approach. This is another reason why I often "reinvent" the wheel.
- **Performance is a Must**: Good software is not just functional, it is also performant. This means that most of the stuff I write is profiled and benchmarked to be as optimized as it can be (relative to the context). This does not limit itself to speed, but also memory consumption.
- **Embrace Complexity**: By taking the philosophy to design your own solutions, you take full control of the process, but also full responsibility. Do not delegate to tomorrow what can be done today. When designing a system, really think what the core features are that the system needs, even if the current project does not necessarily rely on them, and implement them properly.
	- Some features might be optional/advanced and don't need to be there in the first iteration but can be extended later.
- **Rewriting > Refactoring**: A lot of times, rewriting a library/system from scratch is a better solution than refactoring the current version, even if it is highly complex and contains thousands of lines of code. Why? Because when rewriting you have a far better idea of the edge-cases, invariants, bugs, performance bottlenecks, design goals/constraints, etc., than when you started out. Thus rewriting from scratch results in a far better architecture. 
	- In short: *rewriting is treating the disease*, *refactoring is treating the symptom*.
	- Of course this is contextual, a small issue might not require an entire rewrite. 

I often say: "If you truly want to master something, you need to understand the *why* behind the *how*".

The `why` here refers to two different things:
1. Why something is important (the reasons behind it).
2. Why something functions the way it does.
	- This includes why certain decisions were made.
	
Building something from scratch is one of the best, if not the only, way to properly get a feeling for that second definition, especially to understand why there are certain constraints, perhaps because of running into X issue.

Shameless sideplug: My main ambitions have to do with education and learning, so I do a lot of research into neurocognitive educational science. For a look into that, check out [The Mind Academy Discord community](https://discord.gg/cvd8gUdukj), we have around 600 members interested in metacognition and learning.

## Mechanics

### API Design
The core principle of API design is that consumers / clients must not be aware of internal complexity. As such, in Go, all functionality lives inside the special `internal` subpackage. APIs only provide thin facades delegating to that internal complexity. Sometimes, APIs provide thin wrappers around internal functionality to provide some additional ergonomics, but this is not always the case.

#### Boundaries
To be able to fully re-use written infrastructure and code as much as I can, each piece of code is put inside a dedicated library. Each of these libraries has clear boundaries that define:
- What it does
- What it does NOT

I try to define these boundaries, and as consequence the library names, as flexibly as possible, allowing growth, while not becoming too broad. The only exception to this is my [foundation](https://github.com/LordMartron94/Foundation) library, as it purely houses some logic common almost all of my libraries. As such, foundation has no external dependencies. But in all other cases, libraries have clearly defined boundaries. 

#### Internals
Following from the core API Design principle that clients must not be aware of internal complexity, it also means that clients should not have to know about *how* a library or system functions in order to use it. This is to say, they should NOT have to look into the source code of the library to understand why something behaves a certain way. The API should make it clear, see also: [code documentation](#code-documentation).

In short: from the client/consumer's perspective, a library or system must be a *black box*. (ref:2,3)

#### Separation of Concerns
As stated in the boundaries section, I clearly separate logic between libraries... By extent, the result, when executed properly, is that most of code is re-usable, and this means that client projects (tools, programmes, etc.), should not have a lot of code; all it should do is "glue" the libraries and kits together. (ref:2,3)

The only thing that is plausible to put in client projects aside from glue code is domain-specific logic. However, even when putting that there, it is good to reflect and see whether that domain-specific logic can be abstracted and generalized and put in a library to be re-used elsewhere.

The first instinct must ALWAYS be to make systems re-usable. 

Similar to this, code that is part of the same (sub-)system should virtually always be put in the same file such that understanding it does not require a dozen or so jumps, or different files. See also: [function length](#function-length).

In my codebases, do not be afraid to find files of 1k+ or even 3k+ lines of code. I dislike fragmented codebases where every single piece of functionality is contained in its own file; it makes debugging, optimizing, and reading for flow an absolute hell.

The cohesion of a single file should be very high. 

However, if a file contains twenty functions where 12 of them have high cohesion with each other, and the other 8 have high cohesion with each other, but there is low cohesion between these groups, then this is a sign the file should be split up as it actually contains 2 separate (sub-)systems.

##### C APIs

When programming in C, I follow Eskil Steenberg's convention of having a single `<system>.h` file that encapsulates the entire API. This hides complexity from clients and avoids clients having to import a dozen different headers in their systems. When the internal source code needs to share types between systems, X number of different `<subsystem>_internal.h` files can be created, which won't be exposed to clients.

This already gives away also that I do not keep all functionality in a single *source file* as opposed to the API in a single *header file*, instead, each (sub-)system gets its own source file.

#### Method
Inspired by Eskil Steenberg and Dale, often when I am writing a new system or library, I actually *start* by designing the API rather than the actual implementation (this also helps with TDD). 

This results in a few very useful things when developing complex software:
- It requires knowing WHAT the library/system should do.
- It requires knowing WHAT the transformations will be (input x -> output y).
- It ensures ergonomics are thought of beforehand, preventing awkward refactors of internals later.
- It facilitates development of testing because you design the required behaviors upfront.

### Functions

#### Functions vs. Methods
Unlike C, higher level languages often have the capability to attach methods directly to objects. I explicitly do NOT use this approach. On the hardware level, data and execution are strictly separated, there are no mixed layers. For this reason, it is useful to keep data and method distinct on the source code level as well, for the proper mindset. Additionally, when using methods rather than free functions, it is far easier to hide side-effects implicitly, whereas if you use a free function, you clearly see what arguments it takes and potentially whether they will be mutated or not (ref vs. value).

An exception to this principle is fluent APIs/builder-like patterns. For chaining it makes sense to sometimes use methods in order to return the same object to chain. But this is virtually the only usecase where I implement a method rather than free function.

#### Function Length
While Bob Martin recommends splitting functions into those with a single reason to change (SRP) (ref:4), often very tiny functions, I do not keep myself to this guideline all the time. In general this is beneficial, however, as Eskil Steenberg says: "code should *do* something, it should not *manage* something." (not verbatim)... In other words, as soon as you get a function that only calls a bunch of other functions, you are doing something wrong. (ref:1)

One reason for this is that having a bunch of separate functions (whether one-liners or not) that are called from within one orchestrator function requires the developer to jump around a dozen calls, or even deep into a chain, in order to understand what is happening. This makes debugging and optimizing a nightmare. Thus the decision behind extracting a function or inlining its behavior at the cost of larger functions is not a real science, it is more an art that requires wisdom and experience.

### Error Handling

A paradigm that is prevailing in modern times (I am looking at you Go) is to return errors from most functions. This forces code that wants to be "resilient" to need to check for a whole bunch of errors, and in languages that support exception-like systems, also exceptions. This complicates designs needlessly for edge-cases that rarely happen, or at least should happen rarely.

I opt for a different approach to truly resilient code, inspired by Eskil Steenberg's principle of failing hard and loud during development. What I do instead is classify errors into two groups, which decide how to handle potential errors.
1: Programmer Errors / Invariant Violations
2: User Errors (direct or indirect)

For programmer errors or invariant violations, it is dumb to return an error-code. Programmers should know better than to break the invariant of the code they call/use, especially when they wrote it themselves. As such, for these I use my own written assertions that ensure invariants are correctly kept, if not, they CRASH hardly and loudly, while giving as much diagnostic information as possible. When this crash inevitably happens, I immediately fix it. Most of these asserts are not compiled in release mode, but some I might keep alive for really critical areas.

User errors on the other hand are both unexpected and expected at the same time. Unexpected because we cannot plan for them all and expected because they are guaranteed to happen. Such issues should return clear error codes so that client code can choose how to handle it. 

### Typing

This section serves to give a short overview of information on handling types in languages where applicable.

For example in C, standard code writes the pointer in the typedef, like:
```c
typedef void *Handle

void handle_do_something(Handle handle);
```

To me this is bad programming because it hides the fact that it is a pointer in the typedef, making it implicit.
Instead, I put the pointer on the usage.

```c
typedef void Handle

void handle_do_something(Handle *handle);
```

### Naming
In terms of naming, both Bob Martin and Eskil Steenberg agree that wide names are NOT an issue (ref:1,4).

The goal of an entity's name is to *describe* its essence. Its role is equivalent to `term` in natural language.

#### Length
In general, the length of an entity's name is a function of its scope and inherent complexity. A variable that is used only on one line can easily be just a single character (even though I generally avoid this); conversely, a constant that is accessed in a thousand places all over the repo should have a very meaningful name. `RecordOfFinancialInformationContentLengthLimit` would be far better than `ContentLengthLimit`, because we would not be able to infer the actual meaning from the latter. However, if we were working in a *scope* such as a struct describing the financial record configuration `FinancialInformationConfig`, we could name it `ContentLengthLimit` as a field, because the meaning is clearly inferable.

With functions, another axis is required, what it actually does. A specific function should have a specific name, whereas a broad function should have a broad name. `KillProgram` is a good specific name for a function that *only* kills the program. `Compute` can be an example of a proper broad name if the computation is actually determined by the configuration and arguments given to the function.

#### Style

##### General Function Naming

I tend to follow Eskil Steenberg's naming style for functions which means: `<system/module/component><subject><action><optional suffix>`.

An example of this is: `LexerConfigurationSetPatternCompiler` where:
- `Lexer` 			   refers to the system or module or component
- `Configuration`	   refers to the subject
- `SetPatternCompiler` is the action

Another example could be: `LexerCreateFromBinary` where:
- `Lexer` 	   refers to the system or module or component (in this case it is also the subject)
- `Create`	   is the action
- `FromBinary` is the optional suffix

As you can see, the optional suffix allows modification of the action to be made more specific.

The reason we do naming in this way is to make it readable at a glance *where* a certain function is located and comes from. Additionally, by leveraging this standardized way of writing functions, autocomplete becomes very easy because you can traverse the prefix set as a folder tree. Type `Lexer` and (depending on editor) you see all functions related to the lexer, type `Configuration` after and it will filter down to everything to do with the configuration.

One other thing that is useful to keep in mind is to be *consistent* with naming, as it makes grasping code at a glance far easier. For example, when using `get` and `set` in X places, don't use `retrieve` and `adjust` in Y other places, **unless it clearly means something semantically different**. In line with this, it is a bad idea to use asymmetric names like `retrieve` and `set`, because a `set` implies a `get` purely linguistically. 

##### C Naming Style

My naming style in C is not very different from what I said above. However, I formalize my casing and style here.

Functions:			snake_case
Variables:			snake_case
Struct types:		PascalCase
Enum types:			PascalCase
Function typedefs:	PascalCase
Macros:				SCREAMING_SNAKE_CASE

##### Implicit Access made Explicit
-- such as in Go

For unexported functions in a (sub)package, I adopt a convention since 03 June 2026 which indicates whether a function should be referenced outside a file.

p_* indicates the function is private to the file and should not be called outside.
i_* indicates the function is internal and can be used anywhere within the module. 

### Commenting

#### Regular Comments
Inline comments represent a failure to express intent through the code itself. The code dictates the *what*; comments exist solely to explain an unavoidable *why*. When you feel the need to write a comment, your first reflex must be to refactor the code to make the comment unnecessary (e.g., extracting logic into well-named helper methods or renaming variables).

When refactoring is impossible or insufficient, inline comments are strictly limited to the following use cases:

- **Algorithmic Context:** Explanations for highly complex, mathematically dense, or counter-intuitive logic that cannot be simplified or made self-evident through code alone.
- **Regression Warnings:** Critical warnings regarding non-obvious side effects, edge cases, or workarounds for third-party bugs (e.g., "Do not reorder this execution; function X relies on the mutated state of Y").
- **Structural Separators:** High-level section dividers within a file (e.g., separating Types, Interfaces, and Implementations).

#### Code Documentation
Code documentation exists to explain the *why* and *how* of an entity, as the code itself already dictates the *what*. Documentation must be written for every public-facing entity (types, functions, classes, etc.). It is equally critical for internal entities where business logic, state mutation, or non-obvious constraints exist. You only skip documentation if the code is genuinely self-explanatory. See also: [API Design](#api-design).

Depending on the scope and complexity of the entity, your documentation must define its operational contract. Include the following elements when applicable:

- **The "Why" (Context):** The underlying business logic, historical context, or external system constraints that dictated this specific implementation.
- **Examples of Usage:** Brief, copy-pasteable snippets demonstrating the entity in a standard scenario. Show, do not just tell.
- **Parameters & Return Values:** Explicit definitions of input ranges, null/undefined handling, and the exact state of the return value.
- **Exceptions & Errors:** Every specific error thrown or returned, and the precise conditions that trigger them.
- **Side Effects:** Explicit declarations of mutated global state, altered inputs, database writes, or external API calls. State explicitly if the function is pure.
- **Thread Safety & Concurrency:** Whether the entity is safe for simultaneous multi-thread access or modification.
- **Invariants:** Conditions that must remain true before and after the execution of the entity.
- **Edge Cases:** Non-standard inputs or environmental states and exactly how they are handled.
- **Known Bugs:** Unresolved issues or limitations tied to the current implementation.
- **Complexity:** Time and space complexity (Big O notation).
- **Algorithmic Approach:** A high-level summary of the algorithm used, if it is non-trivial.
- **Deprecation Notices:** Timelines for removal and the exact alternative developers must use.
- **ADR Links:** If applicable, one can link to a relevant entry in the ADR docs for more context behind a decision.

There should be NO blank lines between sentences unless it is a paragraph break, otherwise it becomes unreadable.

##### Go

In Go, the `//` is used for standard comments and the `/* */` syntax is used for code-docs.

I differentiate in this way because of my editor syntax highlighting setup.

##### Example Documentation Format

```typescript
/**
 * Calculates the starting database offset for a given page number.
 *
 * [Context]
 * Used to translate user-facing page numbers (1-indexed) into database
 * offsets (0-indexed) for the internal pagination queries. This ensures
 * UI elements decouple from raw database cursor logic.
 *
 * [Complexity]
 * Time: O(1)
 * Space: O(1)
 *
 * [Side Effects]
 * Pure function. No side effects. Does not mutate inputs.
 *
 * @param pageNumber - The 1-indexed page requested by the client.
 * @param pageSize - The maximum number of items per page.
 * @returns The 0-indexed integer offset for the database query.
 *
 * @throws {ValidationError} If pageNumber is less than 1.
 * @throws {ValidationError} If pageSize is less than 1 or exceeds 100.
 *
 * @example
 * // Fetching the 3rd page with 10 items per page starts at index 20
 * const offset = parsePaginationOffset(3, 10); 
 */
export function parsePaginationOffset(pageNumber: number, pageSize: number): number {
    if (pageNumber < 1) {
        throw new ValidationError("Page number must be >= 1");
    }
    
    if (pageSize < 1 || pageSize > 100) {
        throw new ValidationError("Page size must be between 1 and 100");
    }

    return (pageNumber - 1) * pageSize;
}
```

### ADR

Whenever I make a major architectural decision, I try to add an ADR (ref:5) entry to the `docs/adr` folder of that particular project. The reason for doing this despite being a solo developer is that it helps me to understand *why* I did things a certain way in the future if I ever need to debug something or optimize something. 

In addition, it helps me to stay in line with that particular project's *Schwerpunkt* (a term used in WW2 by the Blitzkrieg offensive, roughly meaning "the most important thing"). In other words, it ensures I don't deviate from the design decisions and architectural constraints I committed to.

Lastly, when I open source a repository and other people want to either contribute or understand my code, they can look at the ADR directory.

#### ADR Example
The following is the format I use for ADR records.
```
# <RECORD TITLE>

STATUS: <proposed> | <accepted> | <rejected> | <superseded>

SUPERSEDING: <optional link to the ADR record we supersede>
SUPERSEDED:  <optional link to future ADR superseding this one>

DECISION: <single line describing the decision>
DATE: <date of decision>

## RATIONALE
<explaining the rationale behind the decision>

## ALTERNATIVES CONSIDERED
<optional block of alternative approaches considered with rationale for why reject them>

## REFERENCES
<optional block of references if any>
```

In the standard ADR (ref:5), rejection status does not exist. I included this such that I don't follow in the same design traps. 

The ADR files follow the naming structure `<number>-<title>.md`, for example `0001-no-lexer-level-token-filtering.md`.

### Usage of LLMs
This section will likely be extended in the future.

As of now, all I say is that I don't like using LLMs for anything I want to master myself or enjoy doing. As such, I rarely delegate backend / systems engineering work to LLMs, except for large scale refactors. I do delegate most of my frontend work to LLMs as I absolutely hate that.

I also use LLMs for the following things:
- Code Reviews in line with the Style Guide
- Bug Hunting
- Debugging
- Writing Code Documentation
- Sometimes writing READMEs
- Brainstorming ideas
- Writing my tests

In the case of tests, I always pay significantly more attention to what the LLM does, since it has a tendency to write tests that just `assert true` for example, or to adjust the tests such that they pass, rather than the implementation.
 
### Testing and Benchmarking
Because I care about performance a lot, most of my software components are heavily benchmarked using my own Anvil framework (currently not available publicly), and profiled using my Shield framework (also not available). Under the hood they use the standard pprof tool as well as valgrind.

Whenever possible, I try to start out with writing my tests for the systems I want to create, which goes in conjunction with starting with the API (see: [API Design](#api-design)). My initial tests will fail, and only then do I start writing the code to make it pass. Once it is functional and I am done designing the overall functionality will I start benchmarking and profiling to ensure it behaves as performantly as I can make it.

Something that Dale once adviced me stood out to me, and that is to test *behaviour*, not *implementation*. In other words, the tests must use the exact same path as library consumers would, and thus not rely on intrinsic details of said library. You test the outcomes of a certain function, not *how* the function gets the outcome. 

---

## References
My overall references for my programming principles come from Eskil Steenberg and Bob Martin, as well as Dale from the ArjanCodes community.

1. [Eskil Steenberg: "How I program C"](https://www.youtube.com/watch?v=443UNeGrFoM)
2. [Eskil Steenberg: "Architecting LARGE Software Projects"](https://www.youtube.com/watch?v=sSpULGNHyoI)
3. [Eskil Steenberg: "You should finish your software – BSC 2025"](https://www.youtube.com/watch?v=EGLoKbBn-VI)
4. Bob Martin: Clean Code
5. [Martin Fowler: "Architecture Decision Record"](https://martinfowler.com/bliki/ArchitectureDecisionRecord.html)

## Changelog

### 11 June 2026
- Add section on error handling

### 07 June 2026
- Formalize C naming scheme
- Add information about C pointers
- Removed phrase about separating code into focused files (structural separators) since it does not fit my philosophy
- Add paragraph about consistency in naming to naming style section
- Add section on C API composition

### 03 June 2026
- Add note to naming about p_* vs i_*

### 02 April 2026
- First Release
