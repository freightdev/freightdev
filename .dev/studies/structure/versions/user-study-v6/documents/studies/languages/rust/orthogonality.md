**Orthogonality (in software & CLI design)**

> Two features are **orthogonal** when they work **independently**—changing or using one has **no side‑effects** on the other.

### Why it matters

* **Predictable behavior** – you can reason about each piece alone.
* **Safe composition** – combine flags/commands in any order without surprises.
* **Maintainability** – fixing or extending one area never breaks an unrelated one.

### CLI example

1. Non‑orthogonal (bad) - `mark scan` both *validates* **and** *cleans* files based on a `--fix` flag.<br>Using the command might unexpectedly delete data.

2. Orthogonal (good) - `mark scan` → read‑only validation.<br>`mark clean` → deletes temp files.<br>Each verb has exactly one job; users choose the risk.

### Mental checklist

1. **Single responsibility** – does this command/flag do only one logical thing?
2. **No hidden coupling** – does turning it on affect other, unrelated behavior?
3. **Composable** – can you enable multiple flags together without conflict?

If you answer “no” to any, you’ve broken orthogonality and should split the feature.
