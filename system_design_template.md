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