### “CLI glue” vs. “CLI engine”

| Layer          | Nickname          | What it really is                                                                                    | Responsibilities                                                                                                                                                                                           |
| -------------- | ----------------- | ---------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **CLI glue**   | *front‑end*       | **All code that touches the command line parser** (e.g. `clap`, `structopt`, `argh`)                 | • Define flags, sub‑commands, help text<br>• Parse `std::env::args()` into structs/enums<br>• Convert those structs into calls to the engine<br>• Handle user‑facing I/O (colorized println!, error codes) |
| **CLI engine** | *back‑end / core* | **Pure business logic** for each command, with **no dependency on the CLI library or stdout/stderr** | • Perform the actual work (create tree, render page, etc.)<br>• Take normal Rust types/structs as input, return `Result<T, E>`<br>• Unit‑testable without any command‑line context                         |

---

#### Why split them?

1. **Testability**
   *Engine* functions can be unit‑tested like any other library code—no need to fake CLI arguments.

2. **Reusability**
   The same engine can be reused in a GUI, a web service, or another CLI.

3. **Maintenance**
   When `clap` releases v5, only the *glue* changes. Your engine stays untouched.

---

#### Mini Example

```
crates/
├── core/          # ENGINE
│   └── src/tree.rs
└── cli/           # GLUE
    └── src/commands/tree/create.rs
```

**core/src/tree.rs**

```rust
pub fn create_from_stub(stub: &str, target: &Path) -> anyhow::Result<()> {
    // parse stub, build FS — no clap, no println!
}
```

**cli/src/commands/tree/create.rs**

```rust
use clap::Args;
use core::tree;            // ← call the engine

#[derive(Args)]
pub struct CreateCmd {
    /// Path to markdown stub
    #[arg(long)]
    stub: PathBuf,
    /// Output directory
    #[arg(long, short = 'T', default_value = ".")]
    target: PathBuf,
    /// Dry‑run flag
    #[arg(long)]
    dry_run: bool,
}

pub fn run(cmd: CreateCmd) -> anyhow::Result<()> {
    let text = std::fs::read_to_string(&cmd.stub)?;
    if cmd.dry_run {
        println!("(dry‑run) would create tree at {}", cmd.target.display());
        return Ok(());
    }
    tree::create_from_stub(&text, &cmd.target)?;   // ← engine call
    println!("✅ tree written to {}", cmd.target.display());
    Ok(())
}
```

* **`CreateCmd` + `run()`** = *CLI glue* (clap parsing, println!).
* **`tree::create_from_stub`** = *engine* (pure logic).

Keep that boundary clean and the CLI scales without pain.
