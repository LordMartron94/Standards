# System Design Template

In this template I will provide a practical blueprint for designing systems and thinking through them before engaging with the development of the API and implementing it.

It makes use of Luhmann's functionally differentiated systems theory as described in the [Style Guide](./STYLE_GUIDE.md)
Be aware that filling this in properly and thinking about it is a skill on its own, which you will get better at over time.
It helps to understand Luhmann's systems theory on a decent level, but you don't need to be an expert at it.

I can guarantee that mastering this skill of systems design brings incredible and exponential improvements to both architecting your projects and ensuring the internal implementations are highly *resilient* as well. The latter is because internal implementations of complex systems are orchestrated by multiple *sub-systems*, which can utilize the same template; of course, this is not always necessary to do explicitly if a (sub-system) is sufficiently simple. 

One of the primary benefits of using this template upfront, even before diving into the API, is that you get a far better idea of the *scope* of a library or system. Utilizing Luhmann's framework demands you can *differentiate* between systems, which means you must be able to define both what something *is* and what it *is not*; which is very important when building complex systems that should last forever.

Not being able to determine scope is what results in bloated and messy APIs as well as overall just spaghetti codebases.

## Template Block
Copy the block here into your document and then start filling it in:

```md
## System Design 
In here I will explain the blueprint of the system using Luhmann's functionally differentiated systems theory.
Note that this section is not meant to be eternalized in stone, but can be iteratively improved during development.

### 1. System/Environment Distinction
*Describe the fundamental boundary of this system. What constitutes the internal operations of the system, and what is strictly relegated to the environment? Detail how this system reduces the overwhelming complexity of its environment by selecting only relevant inputs.*

### 2. Operational Code (Binary Distinction)
*Identify the unique binary code that governs the identity and evaluation mechanisms of this system (e.g., tracked/untracked, valid/invalid, executing/suspended). What is the singular operative lens through which this system observes and categorizes reality?*

### 3. System Programs (Rules and Routines)
*Specify the internal routines, invariants, and algorithms that dictate how the operational code is applied. What are the "decision premises" that absorb uncertainty and guide internal state transitions?*

### 4. Internal Differentiation
*Outline the specialized subsystems generated within this architecture to manage internal complexity. How do these subsystems maintain operational cohesion while executing specific delegated responsibilities?*

### 5. Autopoietic Execution (Internal Communication)
*Define the primitive data formats, events, and state structures that circulate strictly within the system. How does the system continuously reproduce its own operational state through its own operationally closed communications?*

### 6. Structural Coupling (API and Interfaces)
*Detail how this system interacts with other operationally closed systems. What external "irritations" (signals, callbacks, data streams) does it observe? Describe the explicit, opaque interfaces that allow structural coupling without violating the system's operational closure.*
```

## Example

Here is an example that I developed when designing my `Synapse` library. Note how the internal datastructures are not up-to-date with what it actually ended up being; but the point of spending time to fill this template is to think and define as mentioned earlier. It is not as important to keep it up-to-date with the growth of a library.

```md
## System Design
In here I will explain the blueprint of the system using Luhmann's functionally differentiated systems theory.
Note that this section is not meant to be eternalized in stone, but can be iteratively improved during development.

### 1. System/Environment Distinction
*Describe the fundamental boundary of this system. What constitutes the internal operations of the system, and what is strictly relegated to the environment? Detail how this system reduces the overwhelming complexity of its environment by selecting only relevant inputs.*

The primary boundary for this system is to facilitate connection between any number of systems. It acts as a smart router.
From its environment, it requires strictly the capabilities systems provide and the capabilities they need. For debugging, it also needs information about the identity of the system (i.e., name, description, etc.); this allows to create comprehensive reports if something goes wrong. In this way, environment complexity is reduced because the communication systems doesn't need to understand the *semantics* of the plugins it handles, only their structural descriptions.

It does not have logging functionality by itself, so this is something else the environment provides in the form of a callback.

Internal state is protected against corruption by exposing only *handles* the environment, by means of `void pointers`.

Versioning has been explicitly decided *against*; because it would require implementing a DAG system and more importantly it would imply that communication formats are highly volatile and can constantly break. Synapse is not a *plugin management* system, it is a *plugin communication* system. If a project requires strict versioning, a different system should be created that handles the resolution of versions, and *synapse* would handle the communication between these resolved plugins.

### 2. Operational Code (Binary Distinction)
*Identify the unique binary code that governs the identity and evaluation mechanisms of this system (e.g., tracked/untracked, valid/invalid, executing/suspended). What is the singular operative lens through which this system observes and categorizes reality?*

The binary code of this system is `routed/dropped`. The system observes an incoming capability request (an irritation) and evaluates it against its registry of provided capabilities. If a descriptor aligns, the communication is matched and thus routed; if it does not align with any known capability, it is unmatched and deliberately ignored or dropped.

### 3. System Programs (Rules and Routines)
*Specify the internal routines, invariants, and algorithms that dictate how the operational code is applied. What are the "decision premises" that absorb uncertainty and guide internal state transitions?*

- Any malformed or incomplete registration gets dropped.
- Any malformed or incomplete request gets dropped.

A sketch for a system structure (which is subject to change):

Note that these structures are defined *internally*, and not exposed to the environment (only in the form of handles).
For interaction in the APIs, we do not force a client to fill in a structure but instead request the specific arguments indiviudally.
``` 

```c
typedef struct DataType {
	uint32 type_id; /* In the case that size and alignment equal between different data-types, there still needs to be a semantic differentiator. */
	uint32 size;
	uint32 alignment;

	/* Note: we use uint32 instead of uint16 to be able to support more complex structs and such as well. */
} DataType;

/* Macros or datatype getters will be provided for common defaults (i.e., ints, floats, string, etc.) */

typedef struct SystemCapability {
	const char name[SYNAPSE_MAX_CAPABILITY_NAME_LENGTH]; /* Name is also the ID */
	const char description[SYNAPSE_MAX_CAPABILITY_DESCRIPTION_LENGTH];
	
	void *function_pointer;
	DataType *function_arguments;
	uint8 function_argument_count;
	DataType *function_return_values;
	uint8 function_return_value_count; /* While C only has 1 return value, allowing multiple from the start makes cross-language loading trivial. */

	/* For both arrays, the order of the array is the order defined in the signature. */
} SystemCapability;

typedef struct SystemInterface {
	const char name[SYNAPSE_MAX_SYSTEM_NAME_LENGTH]; /* Name is also the ID */
	const char description[SYNAPSE_MAX_SYSTEM_DESCRIPTION_LENGTH];

	SystemCapability *capabilities;
	uint16 capability_count; /* ~65k capabilities max should be more than enough */
} SystemInterface;
```

```md
Capabilities can be searched for by signature in a specific registered interface. Name-based and index-based accessors will also be provided, but those also demand a signature descriptor so that there is no way to bypass the type validation which could cause data corruption downstream.

### 4. Internal Differentiation
*Outline the specialized subsystems generated within this architecture to manage internal complexity. How do these subsystems maintain operational cohesion while executing specific delegated responsibilities?*

Note that these subsystems are theoretical subsystems and do not necessarily need to be implemented as actual subsystems.

- Type Validation Subsystem: ensures types match 
- Registry/Encapsulation Subsystem: contains all registered interfaces and such

### 5. Autopoietic Execution (Internal Communication)
*Define the primitive data formats, events, and state structures that circulate strictly within the system. How does the system continuously reproduce its own operational state through its own operationally closed communications?*

Several formats have been described in section 3.

### 6. Structural Coupling (API and Interfaces)
*Detail how this system interacts with other operationally closed systems. What external "irritations" (signals, callbacks, data streams) does it observe? Describe the explicit, opaque interfaces that allow structural coupling without violating the system's operational closure.*

See section 1.
```