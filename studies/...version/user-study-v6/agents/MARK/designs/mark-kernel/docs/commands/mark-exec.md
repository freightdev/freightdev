# ⚡ Purpose

`mark exec` is the **command runner** of the MARK Kernel.

It **executes the active beat** using the linked marker, follows the allowed `.bet`, writes the trail, and summarizes the action in a `.rib`. It is the heartbeat.

Think:

> *“Use your marker, follow the beat, write the trail.”*

---

## ✅ What It Does (Step by Step)

### 1. 📂 Load Active Context

Loads from memory:

* `memory/store/agent.mem`
* `memory/store/user.mem`
* `memory/store/mark.mem`

If no active context exists → ❌ Throws `NoActiveAgentError`.

---

### 2. 🧬 Identify the Next Beat

Uses priority in this order:

1. Explicit `--beat <name>`
2. Last beat in `agent.mem`
3. Fallback to `beats/fallback.beat`

It then resolves:

```bash
beats/<beat>.beat
```

And loads the associated marker from:

```bash
markers/<beat>.mrkr
```

or

```bash
books/**/markers/<beat>.mrkr
```

---

### 3. 🧠 Validate Against .bet

Checks whether the `.bet` allows this beat.

If the beat is **not listed under `allow`** in:

```bash
bets/agent.bet
```

→ ❌ Throws `BeatPermissionDenied`.

---

### 4. 🛠 Execute the Marker

Parses the `.mrkr` for:

* `action`
* `path`
* `requirements`
* `inputs`
* `outputs`

Executes the action using either:

* Internal MARK routines (e.g. summarization, routing)
* External tools linked to the marker
* Custom dispatch instructions defined inside the marker

If marker is a stub → Logs that no action was taken.

---

### 5. 🧾 Write the Trail

Appends execution to:

```bash
trails/store/agent.trl
```

Format:

```json
{
  "timestamp": "2025-07-18T17:44:00Z",
  "beat": "summary",
  "marker": "summary.mrkr",
  "action": "summarize",
  "status": "success",
  "output": "summary.rib"
}
```

---

### 6. 🎗 Cache the Output Ribbon

Stores or updates the output in:

```bash
ribbons/store/<beat>.rib
```

Also updates:

```bash
ribbons/cache/summary_gpt4o.rib
```

If available, it passes it to next beat.

---

### 7. 📍 Create a Mark (Optional)

If a `--mark` flag is passed, or if the `.mrkr` outputs `create_mark: true`, it generates a pointer `.mrk` in:

```bash
marks/<beat>.mrk
```

Content:

```json
{
  "beat": "summary",
  "marker": "summary.mrkr",
  "location": "books/agent/pages/logging.md",
  "context": "after last write"
}
```

---

### 8. 📡 Emit Post-Beat Hooks

If hooks are enabled in:

```bash
system.bet
```

Then:

* Sends heartbeat to connected agents (sync markers)
* Updates user.session.trl
* May trigger `mark sync` or `mark beat`

---

## 🧩 End Result

After `mark exec`:

* The current beat is executed
* The marker defines what the action was
* Trails are written
* Ribbons are updated
* A mark may be created
* The system prepares for the next beat
