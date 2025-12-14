# 🥁 Purpose

This command **manually advances** the MARK system’s execution flow by invoking the **next eligible beat** based on current memory, rules, and beats defined in `.bet`.

---

## ✅ What It Does (Step by Step)

### 1. 📂 Load Current Agent State

Reads from:

```bash
memory/store/agent.mem
```

If `agent.mem` does **not exist** → throws `NoActiveAgentError`.

From the agent memory it pulls:

* `last_beat`
* `allowed_beats`
* `context`
* `tempo` (if available)

---

### 2. 🪘 Resolve the Next Beat

Based on the last executed beat (e.g. `summary`, `routing`, etc.), it looks at:

```bash
beats/tempo.beat
```

The `tempo.beat` defines the logical progression of beats. Example:

```json
{
  "summary": "routing",
  "routing": "writing",
  "writing": "summary"
}
```

So if `last_beat == "summary"` → next = `routing`.

If `tempo.beat` is missing → falls back to `beats/fallback.beat`.

---

### 3. 🧬 Check Permissions Against `.bet`

Loads:

```bash
bets/agent.bet
```

Validates that `next_beat` is allowed under:

```json
{
  "allow": ["summary", "routing", "writing"]
}
```

If not allowed → throws `BeatPermissionDenied`.

---

### 4. 🛠 Trigger `mark exec`

Once the next beat is resolved and allowed, `mark beat` becomes:

```bash
mark exec --beat <next_beat>
```

Which means the system:

* Locates the correct `.mrkr`
* Executes the action
* Writes a `.trl`
* Updates `.rib` (if caching is enabled)

---

### 5. 🧾 Update Trails

Appends to:

```bash
trails/store/agent.trl
```

With beat metadata:

```json
{
  "timestamp": "2025-07-18T17:50:00Z",
  "trigger": "mark beat",
  "beat": "routing",
  "status": "executed"
}
```

---

### 6. 📍 Optionally Mark the Progress

Creates or updates a `.mrk` in:

```bash
marks/<beat>.mrk
```

If the beat or marker includes `auto_mark: true`.

---

### 7. 🔁 Loop Ready

After this beat, the system updates `agent.mem`:

```json
{
  "last_beat": "routing",
  ...
}
```

Now ready for another `mark beat` or manual `mark exec`.

---

## Summary

`mark beat` is how MARK flows.

> It reads the `tempo`, checks `bet`, and runs the next `beat`.

If `mark exec` is the heartbeat,
then `mark beat` is **the metronome** that keeps time.
