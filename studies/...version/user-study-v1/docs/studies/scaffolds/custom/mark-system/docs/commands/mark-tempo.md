# 🎼 Purpose

This command shows or modifies the **beat transition map**, which determines the sequence of beats executed by `mark beat`.

---

### ✅ What It Does (by Default)

If run with no flags:

```sh
mark tempo
```

It simply **prints the current tempo map** defined in:

```bash
beats/tempo.beat
```

Example output:

```json
{
  "summary": "routing",
  "routing": "writing",
  "writing": "summary"
}
```

This tells MARK:

* after `summary` → do `routing`
* after `routing` → do `writing`
* after `writing` → loop to `summary`

This is how `mark beat` knows what comes next.

---

## 🛠️ Editable via Flags

You can edit the tempo mapping directly:

### ➕ Add or Update a Transition

```sh
mark tempo set summary cleanup
```

This updates `beats/tempo.beat`:

```json
{
  "summary": "cleanup"
}
```

### ❌ Remove a Transition

```sh
mark tempo unset summary
```

Deletes the key `"summary"` from the `tempo.beat`.

---

## 🔎 View as Table

```sh
mark tempo --view table
```

Output:

```
╔═══════════╦═══════════╗
║  From     ║   To      ║
╠═══════════╬═══════════╣
║ summary   ║ routing   ║
║ routing   ║ writing   ║
║ writing   ║ summary   ║
╚═══════════╩═══════════╝
```

---

## 🧠 Memory Integration

This file is **stored and indexed** inside:

```bash
memory/store/agent.mem
```

As:

```json
"tempo_map": {
  "summary": "routing",
  ...
}
```

So `mark beat` never needs to reload the file every time — unless edited.

---

## 🧩 Why It Matters

* Tempo is the **glue** between `beats`.
* It enforces **flow constraints**.
* It is **editable by markers** if `marker.beat` allows tempo mutation.

---

## 🧬 Summary

| Command              | Action                                  |
| -------------------- | --------------------------------------- |
| `mark tempo`         | Print current beat flow                 |
| `mark tempo set A B` | Set A → B transition                    |
| `mark tempo unset A` | Remove A’s next beat                    |
| `mark tempo --view`  | Pretty-print the tempo map              |
| `mark beat`          | Uses this map to auto-trigger next beat |
