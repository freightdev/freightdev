Below is a **decision framework** you can use every time you add a new command, sub‑command, or flag. Keep it handy so the *entire* CLI grows in a predictable, atomic way and you never have to rename or split later.

---

## 1 Choose a Primary Axis: *Verb‑Noun* vs *Noun‑Verb*

| Style         | Call Pattern                           | When to Pick                                                                                 |
| ------------- | -------------------------------------- | -------------------------------------------------------------------------------------------- |
| **Verb‑Noun** | `mark create tree`<br>`mark list book` | • When actions are few and resources are many<br>• Reads like shell verbs (`git clone repo`) |
| **Noun‑Verb** | `mark tree create`<br>`mark book list` | • When resources are few and actions multiply<br>• Mirrors k8s (`kubectl pod delete`)        |

**Lock this in up front** and stick to it.
For MARK most people lean **verb‑noun** (`mark create tree`) because you’ll keep adding resources (tree, book, ribbon, page…).

---

## 2 Define Your **Atomic Resources**

A resource is something that can be **created, shown, updated, deleted, or generated**.

| Resource (noun) | Atomic Responsibility | Likely Actions (verbs)      |
| --------------- | --------------------- | --------------------------- |
| **tree**        | Physical FS skeleton  | create, list, scan, clean   |
| **book**        | High‑level container  | create, assign, bind, spine |
| **page**        | Single markdown file  | create, tare, split         |
| **ink**         | Render style / theme  | create, burn, assign        |
| **trail**       | Execution history     | record, replay, prune       |
| **marker**      | Metadata pointer      | create, stroke, bind        |

If something needs its own life‑cycle, it’s a resource. Otherwise it becomes a *flag* or *argument* on an existing resource.

---

## 3 Choose **Core Verbs**

Keep verbs **few, generic, orthogonal**. They should map cleanly to your atomic resources.

Classic set:

| Verb            | Purpose                                | Notes                                |
| --------------- | -------------------------------------- | ------------------------------------ |
| `create`        | Materialize a new resource             | never mutates existing               |
| `assign`        | Attach one resource to another         | idempotent                           |
| `bind` / `link` | Hard link (strong) vs soft link (weak) | pick one                             |
| `list`          | Enumerate resources                    | additive, no flags mutate            |
| `show`          | Display one resource                   | pure read                            |
| `scan`          | Inspect & validate                     | read‑only diagnostics                |
| `clean`         | Remove temp artifacts                  | safe by default, `--force` to delete |

Stick to \~5‑8 verbs. **Don’t invent new verbs** unless the action truly doesn’t fit an existing one.

---

## 4 Flag Taxonomy

### 4.1 Global Flags (apply to every command)

| Flag             | Short | Meaning                                     |
| ---------------- | ----- | ------------------------------------------- |
| `--verbose`      | `-v`  | extra logging                               |
| `--target <dir>` | `-T`  | output root                                 |
| `--fast`         | `-f`  | skip safety checks                          |
| `--safe`         | `-s`  | strict safety, cannot combine with `--fast` |
| `--dry-run`      | `-n`  | simulate, no writes                         |

### 4.2 Command‑Scoped Flags

Attach only to commands that truly need them.

Example for `mark create tree`:

| Flag                | Short | Meaning                      |
| ------------------- | ----- | ---------------------------- |
| `--indent <n>`      | `-i`  | override spaces‑per‑level    |
| `--template <file>` |       | inject default file contents |

---

## 5 Directory Layout Guideline

```
cli/
├── src/
│   ├── main.rs              # clap::Parser → dispatch
│   ├── args.rs              # root clap structs
│   ├── flags/               # reusable global flag parsers
│   └── commands/            # one module per resource
│       ├── tree/
│       │   ├── create.rs
│       │   ├── list.rs
│       │   └── scan.rs
│       ├── book/
│       ├── page/
│       └── mod.rs           # re‑exports every sub‑command enum
└── core/                    # pure logic crates per resource
```

*Keep CLI glue (clap) out of `core/`.  The same `core::tree::create()` can be reused by tests, REPLs, or a future HTTP API.*

---

## 6 Decision Checklist (use every new addition)

1. **Is it a new resource?**
   • Yes → add folder under `commands/` and `core/`.
   • No → continue.
2. **Does an existing verb cover this action?**
   • Yes → add sub‑command file (e.g., `tree/scan.rs`).
   • No → define a genuinely new verb and add it to the small verb table.
3. **Are any new flags global?**
   • If the flag influences *every* command (`--verbose`), put it in `flags/`.
   • Otherwise, keep it local to the sub‑command module.
4. **Does this break orthogonality?**
   • If a command mutates & reads, split it (e.g., `scan` vs `clean`).

---

## 7 Example Walk‑Through

> “We need a command to render all pages of a book into HTML.”

1. **Resource?** — That’s `page` (already exists).
2. **Verb?** — `render` (doesn’t exist). Is it generic? Possibly; pages could also be rendered to PDF, so *yes* it’s worth adding.
3. **Placement:**

   ```
   commands/page/render.rs       # CLI glue
   core/page/render.rs           # engine
   docs/mark/cli/commands/page/render.md
   ```
4. **Flags:** `--format html|pdf` (local flag), maybe `--output <dir>`.

---

### TL;DR Naming Rule

> **One noun, one verb, one job.**
> If a command needs two fundamentally different jobs, split them.

---

With this framework you can brainstorm new commands or flags and instantly know where they belong—zero refactors later. Keep this checklist in your dev notes and extend only when something *truly* can’t fit.
