# Mr. Hoorn's Programming Philosophy & Style Guide

Current version: 1.0.0

---

## PREAMBLE

This file contains my personally written style guide and philosophy for proper software engineering.

I started to write this because I thought it would be useful to have a centralized place for my own programming philosophy, which others contributing can benefit from, whether they are human or LLM.

### Style of the Style Guide

This document is broken up in several meaningful and logical sections outlined in the [table of contents](#table-of-contents). 

Because I am not just a programmer but also a researcher and thinker, I include rigorous references where applicable and I also clearly define my terminology where necessary (this is the logician and intellectual inside of me). For some this "pedanticness" might be too much, in which case, feel free to skip over such explanations; however, do not complain that you then do not understand my substance.

For external references one can visit the [references block](#references), however, by no means is this list complete. Because my overall programming knowledge is crystallized over time, often without direct source attributions through experience, conversation, etc.

When there is a specific source to thank for something I list it in the reference section with a number and refer to it in the document using the ^x syntax where `x` represents the source number.

---

## TABLE OF CONTENTS

**Content:**
- [The Core](#core-principle)
	- [Language Features](#language-features)
	- [Adaptation](#adapation)
		- [MACRO: Intersystemic Resilience](#macro-intersystemic-resilience)
		- [MICRO: Inner Resilience](#micro-inner-resilience)
- [Operation](#operation)
	- [Black-Box Modules](#black-box-modules)
	- [Dependency Management](#dependency-management)
		- [Insulation](#insulation)
		- [Dependability](#dependability)
	- [Rewriting vs. Refactoring](#rewriting-vs-refactoring)
	- [Style](#style)
		- [Locality of Behavior](#locality-of-behavior)
		- [Naming](#naming)
		- [Casing](#casing)
	- [Quality Assurance](#quality-assurance)
		- [Error Handling](#error-handling)
		- [Testing and Validation](#testing-and-validation)

**Additional Information:**
- [Definitions](#definitions)
- [Mentors](#mentors)
- [References](#references)
- [Extra](#extra)
	- [Luhmannian Systems Theory](#luhmannian-systems-theory)

**Post-Content:**
- [Changelog](#changelog)

---

## The Core

At the epicenter of my programming philosophy stands the concept of *resilience*. What do I mean by resilience? For this we first need to take a look at the actual definitions for the term, before I can explain how I use it.

Resilience, means, according to the American Heritage Dictionary of the English Language (5th edition):
> "The ability to recover quickly from illness, change, or misfortune; buoyancy"
> ^1

To be resilient is described as:
> "Able to recover readily, as from misfortune."
> ^2

To me, the greatest goal of developing any software is to ensure it **lasts as long as possible**, ideally without significant (manual) intervention. Having a resilient codebase makes this possible. While creating unbreakable code is the end-goal, there can be no unbreakable code without the capacity to bend. Steel is strong, but it can break. Elastic is not strong per se, but it rarely breaks from pressure because it bends. So how does this come together? By creating code that is *clear*, *readable*, *validated*, and *debuggable*, we create the very mechanisms that ensure when something fails, we know as soon as possible what the precise cause is and can come up with a solution very quickly. 

All decisions and principles for the style guide and philosophy flow from this single maxim of maximum code resilience. In case of a design issue which is not explicitly defined in the philosophy, we can weigh approaches based on how much it aids or detriments the overall resilience of the codebase.

### Language Features
Because the ultimate goal for a codebase is to remain as long as possible without breaking, I adhere to Steenberg's notion of Dependable C, which is (a subset of) C89 (^8).

The main benefit is that code written in this way will work on virtually any system for decades to come.

### Adaptation
> Perfection does not exist, but what is optimal is that which constantly approaches perfection.

Colonel John Boyd famously said: 
> "Any system that does not have an inherent capacity to change [and thus evolve] is doomed to fail."
> ^3
> 
> Note: I am not sure whether this appears verbatim in the source, but I remember having heard/read this quote at some point and it is most likely here.

Because of this principle, in order to ensure our codebase is not just strong, but also bendable, we need to build specific mandates that ensure our systems keep operating on the optimal state they can at that point in time. In order to achieve this state of excellence, I draw on systems theory from two sources, Boyd's OODA loop (^3) and Luhmann's functionally differentiated systems theory (^4, ^5, ^6, ^7) (note: see [Luhmannian Systems Theory](#luhmannian-systems-theory) for a quick primer on this subject).

The core mechanism that will ensure this continuous adaptation is Boyd's OODA loop, which dictates the sequence: Observe, Orient, Decide, and Act. 

When integrated with the systemic principles outlined previously, the synthesis operates as follows:
- Luhmann's systems theory provides the *structural blueprint* for a resilient system, dictating operationally closed, black-box modules that effectively reduce environmental complexity.
- Boyd's OODA loop provides the *temporal engine* to ensure the system constantly evolves, preventing the entropy that inevitably degrades closed systems that fail to interact with their external reality.

Across various scales of architecture, distinct procedures apply to implement this iterative loop. Note that the boundaries between macro and micro levels are inherently permeable in practical design; it is the prerogative of the engineer to determine the precise operational context at any given moment.

#### MACRO Intersystemic Resilience

On the macro level, resilience is defined by how effectively our sovereign architecture interacts with, and insulates itself from, external systems and third-party dependencies within the broader environment.

**Observe:**
We monitor the execution and integration of specific interfaces and external APIs within our systemic environment. This observation yields critical physical feedback signals, such as identifying an API that introduces excessive friction, recognizing an external dependency that frequently violates its contract, or noting a systemic boundary that has become overly complex and obfuscated.

**Orient:**
We process these feedback signals to comprehend the mismatch between our system's operational requirements and the external environment's reality. We evaluate this friction against our foundational principles of absolute control and dependency insulation, synthesizing our prior experiences, domain knowledge, and potential architectural alternatives to update our mental model of the system's structural integrity.

**Decide:**
We formulate a structural hypothesis to resolve the observed friction. Because our modules must operate as strictly encapsulated black boxes, we may decide to execute a complete rewrite of the underlying module, design a new upfront communication format, construct a rigid custom wrapper to fully insulate our core codebase, or sever a third-party dependency entirely to replace it with a bespoke solution. We may also decide to defer action until later and instead note down the friction and potential resolutions.

**Act:**
We implement the architectural modification and deploy the new boundary. This physical deployment serves as a strict empirical test of our structural hypothesis, perturbing the systemic environment and generating fresh interactions that feed directly back into the Observation phase to validate whether systemic friction has been successfully eradicated.


#### MICRO Inner Resilience

On the micro level, resilience is defined by the internal structural integrity of the implementation, most notably measured by how debuggable, explicit, readable, optimized, and predictably the code responds to failure.

Note that the demarcation becomes blurry here, as a micro-level implementation can define a new systemic environment by incorporating new subsystems, thus generating a novel macro context.

**Observe:**
We execute the software and actively seek out physical feedback. This involves looking for hard, loud failures during development, such as triggered assertions, runtime traps, or deliberate memory seeding patterns. Furthermore, we observe the system's operational characteristics by running automated test suites, executing profiling tools to monitor memory and execution paths, and benchmarking performance metrics.

**Orient:**
We process these signals—whether they are crash dumps, test failures, or profiling data—to reconcile our inherently flawed mental model of the software with its actual physical execution. We pinpoint the exact locus of a malfunction or bottleneck, determining whether the failure is a programmer error violating a strict internal invariant, a user error requiring handled return codes, or an implementation flaw causing cache misses and performance degradation.

**Decide:**
We formulate a highly specific mechanical intervention to permanently eradicate the defect or improve the implementation. Depending on the high-level observation, we may decide to introduce a new combination of explicit assertions, mandate the creation of a new automated test to lock down expected behavior, or decide to continuously refactor and optimize a sequential block of code to restore locality of behavior and operational efficiency.

**Act:**
We apply the precise syntactical correction, continuous refactoring, or optimization. We then immediately re-execute the software, its validation suite, or its benchmarks. If the code operates flawlessly and meets performance criteria, inner resilience is restored; if it fails, our aggressive debugging constraints and testing tools will trigger an immediate fault, rapidly accelerating our return to the Observation phase.

## Operation

With the core out of the way, we now dive into the operationalization of said core.

### Black-Box Modules

To align ourselves with operationally closed systems, all our libraries and all our systems are black boxes. Clients will never need to know of the internals of said system and only communicate through shared linguistics (API). This also has the benefit of eradicating bugs where the client accidentally modifies internal state.

On the library level this is done through defining a single public header file for the entire library, which contains all available functions and their documentation as well as all the types clients need to have access to. Internal types are void pointers or structural forwards (incomplete types) so that the client cannot know what is going on (opaque pattern).

Internally, each of these API functions is implemented in various (sub-)systems which can communicate through shared data format understanding (internal headers) and publicly declared API.

Dependency inversion can also be applied when it directly aids overall codebase resilience. For example, a core library might declare an abstract assert failure reporter interface that clients can set to i.e., a logger. This way, the core library does not depend on the logging library.

### Dependency Management

#### Insulation

The architecture mandates a policy of zero unwrapped external dependencies. Relying upon uninsulated third-party code introduces unacceptable vulnerability to upstream volatility, API alterations, and technological obsolescence. Where third-party integration is unavoidable, it must be strictly encapsulated behind a custom interface wrapper owned and controlled entirely by the developer. This ensures that if the external dependency breaks its API contract, the required modifications are localized to a single translation unit rather than cascading throughout the entire codebase. 

#### Dependability

The structural integrity of all modules within the system is formally governed by the Dependable Dependencies Principle. This principle dictates that the more a specific unit of code is relied upon across the overarching architecture, the lower its probability of failure must inherently be. The enforcement of this principle is achieved by computationally evaluating a module's dependency rank alongside its cyclomatic complexity and assurance metrics. Foundational libraries must remain structurally flawless. This does require a tool which computes it.

### Rewriting vs Refactoring

A core dilemma in building resilient code is whether to rewrite something from scratch or to incrementally improve it. 
Many developers assert that this is a binary choice, however, I think that is dumb. Both rewriting and refactoring incrementally have tremendous value.

As noted earlier, we have different temporal contexts going on; the macro and the micro. On the macro level we can notice it is bad to interact with certain APIs, even if we wrote them ourselves, which can eventually warrant a full rewrite, sometimes sooner than later. However, on the micro level, we have full freedom to incrementally refactor to make code more debuggable, clear, or readable, in essence, more resilient; this is possible because the external API is stable.

It is important to note when refactoring turns into "treating the symptom rather than the disease". When this happens, one is no longer aiding codebase resilience but detrimenting it, and in that case an API rewrite is warranted. Depending on the complexity and scope, sometimes a surgical API rewrite is enough, but at other times a complete library rewrite is necessary.

> In order to truly master something, you must understand the why behind the how.

Often when designing an initial API without domain experience, you don't know that *why* yet, so the initial API is bad. Later you realize the domain problems, bottlenecks, etc., and can implement a far better architecture from the start. Then rewriting gives significantly more gains in the long run.

### Style

As mentioned, we use Dependable C. 

A core principle for resilient code is: **explicit is better than implicit**, even if it costs significantly more keystrokes. 
> Typing is never the problem, debugging is.

The central mandate for writing code that is resilient is the fact that **code is a communication platform for making intentions clear**; ambiguity is one of the greatest enemies of resilience.

#### Locality of Behavior

To preserve the locality of behavior, the default architectural stance is to utilize explicit, sequential, sometimes lengthy functions. Code must execute in a linear narrative from top to bottom. Deeply nested call stacks and orchestrator functions that merely manage other functions severely fragment the codebase, forcing the developer to navigate highly disjointed logic to comprehend a single operation. Extracting logic into smaller sub-routines is permitted as a pragmatic exception, solely when a lengthy procedure actively obscures the core narrative of the operation. 

In essence, keep in mind the overall resilience (debuggability, clarity, readability).

#### Naming
Variables, types, and functions must be highly descriptive, leveraging wide and explicit naming conventions. The architecture mandates a rigid naming taxonomy for functions, adhering to the module, subject, and action format, accompanied by an optional suffix. This methodology inherently constructs a globally searchable directory structure within the source text itself. By typing the module prefix, the developer can instantly navigate the capabilities of the system without reliance on external Integrated Development Environment parsing tools. Symmetrical consistency in naming is required; operations must utilize standardized vocabulary to prevent semantic confusion. 

#### Casing
```
- functions: 	snake_case
- variables: 	snake_case
- parameters: 	snake_case
- structs: 		PascalCase
- enum-members: SCREAMING_SNAKE_CASE
```

### Quality Assurance

Quality assurance bridges the gap between the programmer's mental model of the software and the actual physical execution of the software. The approach to validation is fundamentally empirical and aggressively crash-oriented.

#### Error Handling

Programmer errors and invariant violations must trigger immediate, hard, and highly visible failures during the development phase. Gracefully swallowing errors, relying on default zero-initialization, or permitting a system to silently fail introduces subtle, time-traveling bugs that are exceptionally difficult to trace. Memory should be deliberately seeded with specific, recognizable byte patterns upon allocation to guarantee that unauthorized access to uninitialized state causes an immediate fault.

Errors are strictly bifurcated into programmer errors and user errors. Programmer errors mandate explicit assertions that halt execution loud and fast. User errors, which are inevitable occurrences during runtime, must return clear, explicit error codes that force the client architecture to consciously handle the failure state. 

#### Testing and Validation

Here again many programmers present a false choice: "either go for full test coverage or test only by usage".
I think both approaches have merit.

Not all code is created equal. Not all code has the same complexity, or risk.

By computing the [DDP](#dependability) factor mentioned earlier, we can identify high-risk high-complexity targets that are bound to benefit from extensive testing. In general, the more complex a system or mechanic is, and the more other systems depend on it, the more important it is to have great validation. A one-off utility function does not need a big test dedicated to it.

Because it is impossible to predict all future anomalies, the architecture demands a strict protocol for regression management. Whenever an unforeseen behavioral bug is encountered in the field, it must immediately be integrated into the validation infrastructure. This is achieved by either authoring a new, dedicated test to capture the exact failure state or by introducing a new combination of explicit assertions. This methodology ensures the specific defect is permanently eradicated from the solution stack and can never silently repeat itself. 

---

## Definitions
- **Resilience & being resilient:** To be able to recover from failure as quickly as possible.
- **Systemic environment:** In the context of programming, I think a systemic environment is best described as a *layer*. For example, the *application layer*, which houses various subsystems to execute its logic (i.e., physics, audio, etc.)

## Mentors
The biggest inspirations and mentors for my programming philosophy, in no particular order are:
- Eskil Steenberg
- Robert C. Martin
- Dale Hagglund

## References
This is an incomplete list of references that guided this document. For more detail, see the [preamble](#preamble)

1. [resilience definition - wordnik](https://wordnik.com/words/resilience)
2. [being resilient definition - wordnik](https://wordnik.com/words/resilient)
3. Richards, C. (2004). Certain to Win: The Strategy of John Boyd, Applied to Business. Xlibris, Corp.
4. Carefree Wandering (Director). (2023a, September 25). Niklas Luhmann: A Super Theory of Society [Video recording]. https://www.youtube.com/watch?v=exPOPm8qQsY
5. Carefree Wandering (Director). (2023b, October 12). Niklas Luhmann: Function, Code, and Ontology of the Media [Video recording]. https://www.youtube.com/watch?v=6Bw1PY0jUzg
6. Carefree Wandering (Director). (2023c, November 1). Luhmann’s Media Theory: The Specifics [Video recording]. https://www.youtube.com/watch?v=9ZSOsaiQGD0
7. Moeller, H.-G. (2012). The radical Luhmann. Columbia University Press.
8. Steenberg, E. (n.d.). Dependable C. Retrieved June 13, 2026, from https://dependablec.org/

---

## Extra

### Luhmannian Systems Theory
I am by no means an expert on Luhmann's systems theory, but I have had e-mail discourse with a scholar (Hans-Georg Moeller) specializing in this subject in July 2024, who confirmed my understanding.

I will not explain Luhmann's systems theory in detail as it is not vital to this document. However, I will briefly explain its concepts. For a more in-depth understanding, I recommend watching references: 4, 5, and 6 and/or reading reference 7.

As a contextual note: Luhmann developed his systems theory in the context of sociology, where he viewed society as a "society of societies", in other words, a system of systems. As such, his framework for systems theory is *descriptive* in nature, because it describes society. However, I, at the time I conversed with Dr. Moeller, extrapolated his concepts of functionally differentiated systems theory into a prescriptive framework for the design of proper systems. This framework is what I draw on loosely here.

The core idea of this theory, as its name implies is that each system is described in terms of its *function*. Luhmann asserted each system had a *unique binary operational code* which the system uses to evaluate its own mechanisms. For instance, the law system uses 'legal vs. illegal', the science system uses 'known vs. unknown'. 

The moment a system starts using a different operational code to evaluate its mechanisms, systemic corruption occurs. Moeller explains this through analogy, if in sports paying money in a match affects the outcome, then this is using the wrong code (the economy system's code rather than the sport system's code, or the larger entertainment system as a whole).

A system obviously does not exist in a vacuum, Luhmann noted how each system operates within an *environment* of other systems (its siblings so to speak). Within a system, any number of sub-systems can exist, which again form an environment. 

According to Luhmann, a system is *operationally closed but structurally coupled*; what this means is that each system has its own set of rules, routines, code, etc., which forms a language only this system uniquely understands. The combination of these rules, routines, etc., is what Luhmann called a system's *program*. Because only the system itself understands its own *program*, no system directly *controls* any other system but instead *irritates* it.

Through this *system-environment* relationship, there are interdependencies between systems in the same environment. For example, a media production (media system) influences the prices of an item (economy system) which in turn causes politicians to be upset at the price change (political system) which then requires the passing of a new law (legal system). 

In Luhmann's view, a system's environment is always infinitely more complex than the system itself, which can be proven because to comprehend the environment fully, one must understand the language of the environment in its entirety, but because each system by definition has a parent system (for the parent system holds the environment), there is an infinite number of parents to understand. As such, the system has internal mechanisms (defined in the program), distincting which environmental signals are processed and in what ways, and which are discarded; this is how the infinite complexity problem is solved, and why it is necessary to have operational closure.

However, the core idea remains the same, that one system cannot directly control other systems. Luhmann famously said "only education can educate", and the reason for this is that only the education system knows how to educate. 

In this way, systems are also autopoietic and self-referential (they refer to themselves and produce themselves or their own operation), one education operation leads to the next education operation and so on; one legal decision leads to the next legal decision, and so on. Self-referential in the sense that systems steer themselves in different directions based on the input it receives from external feedback (environment) and internal feedback (their operations, routines, etc., as evaluated by their binary code).

In other words, the system reproduces itself through its own internal communications (the execution of the program). One could even say that the *function* of a system is determined directly by the complex ways its internals communicate, which is to say, the program.


---

## Changelog

### 13 June 2026
- Complete rewrite (v1)
- Rewrite section on testing

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
