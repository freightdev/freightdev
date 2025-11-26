A **REPL** (“Read-Eval-Print Loop”) is an interactive programming environment that lets you:

1. **Read** a line (or block) of code you type
2. **Eval**uate/compile & run it immediately
3. **Print** the result or any output
4. **Loop** back and wait for your next input

---

### Why REPLs matter

* **Rapid experimentation**: try snippets of code, inspect types, tweak behavior without writing a full file.
* **Immediate feedback**: see results (or errors) instantly, which accelerates learning and debugging.
* **Prototyping**: explore APIs or algorithms interactively before committing to a module or crate.

---

### Common REPLs

| Language/Tool | Invocation                               | Notes                                                       |
| ------------- | ---------------------------------------- | ----------------------------------------------------------- |
| Python        | `python` or `ipython`                    | Ubiquitous; rich introspection and history                  |
| JavaScript    | `node`                                   | Built-in REPL in Node.js                                    |
| Ruby          | `irb`                                    | Interactive Ruby shell                                      |
| Rust          | `evcxr` (via `cargo install evcxr_repl`) | Community-maintained; supports snippets, multi-line editing |
| Lisp/Clojure  | `lein repl`                              | Lives at the heart of Lisp’s live coding ethos              |

---

### Anatomy of a REPL session

```text
>> let x = vec![1, 2, 3];
>> x.iter().map(|n| n * 2).collect::<Vec<_>>()
[2, 4, 6]
>> fn add(a: i32, b: i32) -> i32 { a + b }
>> add(5, 7)
12
>> // Loop back for more…
```

---

### Pros & Cons

* **Pros**

  * Zero ceremony: no `fn main`, no file saves
  * Great for quick tests, learning, and debugging
* **Cons**

  * Not a substitute for full project structure and tests
  * Limited multi-file workflows (though some REPLs support a `:load` command)

---

**In Rust**, `evcxr` is the go-to REPL. Once installed, run `evcxr` and you get immediate access to your standard library—and you can even `:dep serde_json` to pull in crates on the fly.
