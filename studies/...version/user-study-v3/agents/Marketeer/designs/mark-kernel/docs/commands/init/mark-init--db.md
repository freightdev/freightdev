# 🧠 Purpose

`mark init --db` **indexes** and **caches** all `.beat`, `.bet`, `.mrkr`, `.mrk`, `.rib`, `.trl`, `.mem`, and Markdown (`*.md`) files across the MARK tree into a formalized **local knowledge database**.

This gives MARK agent-native systems rapid access to everything **without reading from disk** on every call.

---

## ✅ What It Does (Step by Step)

### 1. 📡 Scan All Valid Schema Objects

Recursively crawls the project directory, collecting all files matching:

* `**/*.beat`
* `**/*.bet`
* `**/*.mrkr` / `**/*.mrk`
* `**/*.rib`
* `**/*.trl`
* `**/*.mem`
* `**/*.md` in `books/**/pages/` or `docs/`
* `marks/*.mrk`
* `ribbons/store/*.rib`
* `memory/store/*.mem`

> ⚙️ Only files matching known `schema/*.schema.json` structures are parsed and indexed.

---

### 2. 🧱 Build `memory/index.json`

A global database index is written to:

```bash
memory/index.json
```

This JSON contains structured mappings like:

```json
{
  "beats": ["beats/summary.beat", "beats/tempo.beat", ...],
  "bets": ["bets/system.bet", ...],
  "markers": ["markers/system.mrkr", ...],
  "books": {
    "agent": {
      "pages": ["books/agent/pages/logging.md", ...],
      "ribbons": ["books/agent/ribbons/summary.rib", ...],
      "trails": ["books/agent/trails/agent-session.trl", ...]
    }
  },
  "ribbons": {
    "index": "ribbons/index.json",
    "cache": ["ribbons/store/summary.rib", "ribbons/store/intro.rib"]
  },
  "trails": {
    "index": "trails/index.json",
    "tmp": ["trails/tmp/abc123.trl"]
  },
  "marks": ["marks/boot.mrk", "marks/ink.mrk", ...],
  "memory": {
    "store": ["memory/store/user.mem", "memory/store/mark.mem"]
  }
}
```

---

### 3. 🔍 Validate Schema (Optional)

If `schema/*.schema.json` is present, the init will:

* Validate each file against its matching schema.
* Add `invalid_files[]` block to the index if mismatches found.
* Optionally log trail errors in `trails/tmp/schema-failure.trl`.

---

### 4. 🧠 Create Summary Ribbons

For each `book.md` in:

```bash
books/*/book.md
```

It looks for:

* `pages/*.md` → summarized
* `markers/*.mrkr` → counted
* `trails/*.trl` → indexed by length
* `ribbons/*.rib` → hashed

Then it writes a `summary.rib` like this:

```json
{
  "book": "user",
  "page_count": 2,
  "marker_count": 1,
  "trail_count": 1,
  "last_modified": "2025-07-18T14:42:10Z",
  "hash": "ea39c5a..."
}
```

---

### 5. 🏁 Cache All `*.mrk` Anchors

Any file in `marks/*.mrk` is treated as a static anchor. These are indexed and recorded in-memory by pointer name.

Example:

```json
{
  "boot": "marks/boot.mrk",
  "connect": "marks/connect.mrk"
}
```

---

### 6. 🧾 Write DB Log Trail

A new `.trl` is written to:

```bash
trails/tmp/db-init-[timestamp].trl
```

It logs:

* Total files indexed
* Time taken
* Files failed validation
* Memory store update status

---

## 🧩 End Result

After `mark init --db`, your system is now:

* **Fully cache-aware**
* **Schema-validated**
* **Anchor-resolved**
* **Rib-indexed**
* **Ready for agent-native parsing at runtime**

Agents no longer need to crawl the FS—they query the `memory/index.json`.

