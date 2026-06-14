# System Design Template

In this template I will provide a practical blueprint for designing systems and thinking through them before engaging with the development of the API and implementing it.

It makes use of Luhmann's functionally differentiated systems theory as described in the [Style Guide](./STYLE_GUIDE.md)

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