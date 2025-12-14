Rust’s compilation pipeline transforms your source code through several intermediate representations. After the AST (Abstract Syntax Tree), the two key stages are **HIR** (High-level Intermediate Representation) and **MIR** (Mid-level Intermediate Representation).

---

## 1. HIR (High-level IR)

* **What it is**
  A **cleaned-up**, simplified version of the AST that the compiler uses for type checking, name resolution, and borrow-checking.
* **Key characteristics**

  * **Desugared syntax**: high-level sugar (e.g. `for` loops, `?` operators) is expanded into more primitive constructs.
  * **Uniform structure**: eliminates macros, attributes, and raw token details—everything is expressed as core Rust constructs.
* **Uses**

  * **Type inference & checking**: the compiler resolves types and lifetimes here.
  * **Borrow checker**: enforces Rust’s ownership rules before moving on.
  * **Early error reporting**: most syntax or type errors are caught at the HIR stage.

---

## 2. MIR (Mid-level IR)

* **What it is**
  A **typed, SSA-based** IR that abstracts away source syntax entirely, focusing on control flow and data flow.
* **Key characteristics**

  * **Static Single Assignment (SSA)** form: each variable is assigned exactly once, making later analyses simpler.
  * **Control-flow graph**: functions are expressed as basic blocks connected by jumps and branches.
  * **Platform-agnostic**: not yet LLVM or machine code, but low-level enough for optimizations.
* **Uses**

  * **Optimizations**: inlining, dead code elimination, constant propagation, and more happen on MIR.
  * **Exhaustiveness checks**: e.g. for `match` statements.
  * **Exhaustive borrow-checking** (NLL, non-lexical lifetimes) is implemented here.
  * **Preparation for codegen**: MIR is translated to LLVM IR (or other backends) next.

---

## 3. Pipeline Summary

```text
Source Code
   ↓  (parsing)
AST (syntax + tokens)
   ↓  (desugar, resolve macros)
HIR (type-checked, borrow-checked)
   ↓  (lowering, borrow refinements)
MIR (SSA, optimized, borrow-checked)
   ↓  (translate)
LLVM IR (or Cranelift, etc.)
   ↓
Machine Code
```

* **AST → HIR**: clean up syntax, resolve names, infer types, enforce ownership.
* **HIR → MIR**: convert to SSA, build control-flow graphs, perform mid-level optimizations.
* **MIR → LLVM IR → Machine Code**: backend codegen and final optimizations.

---

### Why it matters

* **Tooling**: IDE features and linters often hook into HIR for precise diagnostics.
* **Performance**: MIR-level optimizations are where Rust achieves much of its zero-cost abstraction guarantees.
* **Metaprogramming**: procedural macros see the AST, but advanced compiler plugins (when available) would operate on HIR/MIR.

Understanding HIR and MIR gives you insight into how Rust enforces safety guarantees and optimizes your code under the hood.
