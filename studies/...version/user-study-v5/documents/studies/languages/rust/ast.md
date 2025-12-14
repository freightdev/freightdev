The **AST** (Abstract Syntax Tree) is Rust’s in-memory representation of your source code’s structure after it’s been parsed but before it’s been lowered to HIR/MIR. Think of it like a tree of Rust “nodes”—each node represents a language construct (a function, a `for` loop, a literal, a type, etc.).

---

### 1. Where you see it in practice

* **The Rust compiler** (`rustc`) parses `.rs` files into an AST, then transforms it into HIR (High-level IR) and MIR (Mid-level IR) before codegen.
* **The `syn` crate** re-exposes that AST (or a close approximation) so proc-macros can inspect and manipulate your code.

### 2. Core AST node types (in `syn`)

| Node             | Meaning                                                     |
| ---------------- | ----------------------------------------------------------- |
| `syn::File`      | The entire contents of a source file                        |
| `syn::Item`      | A top-level item: `fn`, `struct`, `mod`, `use`, etc.        |
| `syn::Expr`      | An expression: `1 + 2`, `foo(bar)`, `if`/`else`, etc.       |
| `syn::Stmt`      | A statement: `let x = 3;`, an `Expr` with a semicolon, etc. |
| `syn::Type`      | A type: `i32`, `Vec<String>`, `&'a str`, etc.               |
| `syn::Pat`       | A pattern: `Some(x)`, `ref mut y`, tuple patterns, etc.     |
| `syn::Attribute` | An attribute: `#[derive(Debug)]`, `#[my_macro]`             |

### 3. Rough workflow of parsing to AST

1. **Lexing**: raw text → token stream
2. **Parsing**: token stream → AST (`syn::parse_file` or compiler’s parser)
3. **Lowering**: AST → HIR → MIR → LLVM IR → machine code

Proc-macros tap in right after step 2: they get a `TokenStream`, convert it to `syn::DeriveInput` or similar, inspect or mutate the AST, then emit a new `TokenStream`.

---

### 4. Example: parsing a function

```rust
use syn::{parse_file, ItemFn};

let code = r#"
    pub fn add(a: i32, b: i32) -> i32 {
        a + b
    }
"#;

let syntax = parse_file(code).unwrap();
// syntax.items[0] is an Item::Fn
if let syn::Item::Fn(func) = &syntax.items[0] {
    // `func.sig` is a syn::Signature (name, inputs, output)
    println!("Function name: {}", func.sig.ident);
    // `func.block` is the function body (a syn::Block)
}
```

---

### 5. Why it matters

* **Code generation**: Proc-macros use the AST to know exactly what code structure they’re working with.
* **Refactoring tools**: IDEs use the AST to offer “rename symbol,” “go to definition,” etc.
* **Linting & formatting**: tools like `rustfmt` and `clippy` operate on AST-level representations.

---

In short, the **Rust AST** is the structured, tree-shaped representation of your program that sits at the heart of parsing, tooling, and codegen—an essential layer for any metaprogramming or compiler work.
