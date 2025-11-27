# 🧠 Purpose

`mark init --agent` initializes **agent context**, **permissions**, and **markers** for runtime execution. This command loads an agent into the MARK kernel environment using the system rules, trail logs, and marker bindings — preparing it to **beat**, **route**, **mark**, and **write**.

It **does not launch the agent** — it *registers and prepares* it.

---

## ✅ What It Does (Step by Step)

### 1. 🧾 Load `.bet` Contracts

Scans the working path and core `bets/` directory for:

* `agent.bet`
* `user.bet`
* `system.bet`

Each `.bet` declares what agents are **allowed** to do. It sets top-level **access control** for all future actions.

Parsed into:

```json
{
  "allow": ["routing", "signing", "tempo"],
  "deny": ["scanning", "external-tracing"],
  "origin": "agent"
}
```

Agents may only load markers or perform actions allowed by the current `.bet`.

---

### 2. 🎯 Register Markers

Loads every file matching:

```bash
markers/*.mrkr
books/**/markers/*.mrkr
```

Each `.mrkr` file is mapped by name and function:

```json
{
  "summary": "markers/summary.mrkr",
  "routing": "books/mark/markers/signing.mrkr"
}
```

Markers **must match allowed beats** in the `.bet`.

If a marker exists for a disallowed beat → ⚠️ Rejected.

---

### 3. 🧭 Validate Beat Paths

Cross-validates registered markers against available `.beat` files:

* Every `.mrkr` must reference a valid `.beat`
* Invalid or missing `.beat` → Logged in `trails/tmp/agent-init-errors.trl`

Example mapping:

```json
{
  "routing.mrkr": "beats/routing.beat",
  "tempo.mrkr": "beats/tempo.beat"
}
```

---

### 4. 🧠 Link Agent Memory

Initializes the agent's memory file:

```bash
memory/store/agent.mem
```

If not found, it creates a blank one with:

```json
{
  "id": "agent-[uuid]",
  "last_seen": null,
  "beats_used": [],
  "markers_used": [],
  "bookmarks": [],
  "status": "initialized"
}
```

---

### 5. 🧵 Trail Binding

Looks inside:

```bash
books/agent/trails/*.trl
```

and:

```bash
trails/store/agent.trl
```

It links trail history to the agent's memory, so beats can **append** to or **follow** prior sessions.

If `--replay` is passed later, these trails are walked.

---

### 6. 🪶 Register Default Ribbon

Sets the agent’s ribbon cache to:

```bash
books/agent/ribbons/summary.rib
```

If not found, it uses `ribbons/store/summary.rib`.

This lets the agent remember the **summary of what it just did**, a.k.a. cognitive breadcrumbing.

---

### 7. 🛠️ Write Agent Kernel Ready

Final state is committed to a temp file:

```bash
trails/tmp/agent-ready-[uuid].trl
```

And added to:

```bash
memory/store/agent.mem
```

With:

```json
"status": "ready"
```

---

## 🧩 End Result

After `mark init --agent`:

* The agent is registered to **beat** and **mark**
* All `.bet` and `.mrkr` rules are validated
* Memory is preloaded
* Ribbon is loaded
* Trail is wired
* Agent is ready to **enter dispatch phase**
