# 🛠 _dev

This folder is the **experimental zone** for scripts, helpers, and ideas that are **NOT production-ready**.  
If it’s here, **assume it is untested, unfinished, untrusted, and potentially unsafe**.

---

## 📂 Structure & Danger Levels

### `sandbox/`
- Low-risk experiments and proof-of-concepts.
- May not work, but unlikely to damage your system.
- Safe for tinkering.

### `drafts/`
- Half-finished scripts or logic.
- Not fully tested.
- Could cause unexpected results, but not intended to be destructive.

### `unsafe/`
- High chance of messing with configs, deleting files, or affecting services.
- Review carefully before running.

### `hazard/`
- **Danger zone.**
- Could cause catastrophic data loss, system instability, or unrecoverable changes.
- Only run if you know exactly what it does and have backups.

---

## 📝 Usage Rules
1. **Never** assume a script here is safe.
2. Always read the code before running.
3. Run in a **virtual machine**, container, or isolated environment when possible.
4. Move scripts to their proper location **only after** they are stable, tested, and trusted.

---

## 🚧 Workflow
1. New AI-generated or scratch scripts → `drafts/`
2. Stable enough to test interactively → `sandbox/`
3. Confirmed risky → `unsafe/` or `hazard/` depending on severity
4. Fully working, trusted → Move to your main logic/helpers folders.

---

> 💡 _If you are here, you are in the wild west. Proceed with caution._
