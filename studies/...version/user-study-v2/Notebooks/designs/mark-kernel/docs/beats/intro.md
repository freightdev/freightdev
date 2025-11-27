# 🧠 `.bet/` — Begins Every Truth

The `.bet/` directory defines the first and most critical construct in a containerized truth system.

> A `.bet` is not a configuration.
> A `.bet` is not an instruction file.
> A `.bet` is a **declaration of trust and rhythm** —
> It governs **which beats may be executed**, **what markers may be accepted**,
> and **how action flows in this container**.

Every `.beat`, `.mrkr`, and `agent` must pass through `.bet` first.

This is the **origin of permission**, the **anchor of discipline**, and the **contractual gate**
for all cognition within the system.

---

## 📌 What is a `.bet`?

A `.bet` is a *declaration file* that begins every truth inside a containerized execution environment.
It:

- Lists which `.beat` files are allowed to run
- Defines rules for marker validation (`.mrkr`)
- Sets behavioral expectations for agents
- Initiates the runtime contract for all stateless actions
- Controls scope, fallback, and trust enforcement for its container

All `.bet` files are written in **YAML or Markdown + YAML block headers**.

---

## 🔁 Execution Chain (Example)

```text
agent boots →
  reads /srv/containers/$USER/.mark/bets/system.bet →
    validates permissions →
      loads approved .beat →
        binds to valid .mrkr →
          performs beat stroke →
            emits .trl log →
              earns based on stroke
```

---

## 🧬 Core Principles of `.bet`

* **Begins Every Truth**: If it hasn’t read `.bet`, it hasn’t begun.
* **Stateless Enforcement**: The `.bet` governs execution, not identity.
* **Explicit Permission**: Only declared `.beat`s can be run. No freelancing.
* **Marker-Gated Access**: You must have a valid `.mrkr` to act. No raw input.
* **Stroke-Economy Aware**: You don’t just act — you perform strokes and get compensated.

---

## 📖 `.bet` Spec (Summary)

```yaml
id: system-root-bet
name: Begins Every Truth
allowed_beats:
  - dispatcher.beat
  - summary.beat
  - fallback.beat

 requirements:
  trail_marker: true    # Every beat must generate a `.trl` file.
  cache_ribbon: true    # System caches a `.rib` per completed beat.
  beat_check: true      # System checks for beat compatibility

markers:
  allow_external: true  # Allows agents to bring their own markers
  signed_only: false    # Doesn’t require local signature
  marker_pass: true     # Marker must have a valid PASS state

defaults:
  fail_on_invalid: true
  logging: trl
  caching: rib
```

---

## 🔐 Why This Matters

* In a future of multi-agent ecosystems, **`.bet` ensures compatibility, integrity, and accountability.**
* In systems where humans, models, and machines interact, `.bet` **defines truth boundaries** and prevents drift.
* In networks of containerized intelligence, `.bet` **removes hallucination and introduces protocolized cognition.**

---

## 🏛 Future Standards

We believe `.bet` will become a foundational contract file for:

* AI container systems
* Agent execution runtimes
* Edge-trusted compute layers
* Beat-based protocol registries
* Multi-agent orchestration platforms

If YAML was the config language of the cloud…
**`.bet` is the trust language of the cognitive web.**

---

## 🧾 Next Files To Explore

* [system.bet.md](./system.bet.md) — the root-level `.bet` definition
* [markers.rule.md](./rules/markers.rule.md) — how `.mrkr` files are validated
* [beats.rule.md](./rules/beats.rule.md) — logic for beat execution acceptance
* [bet.schema.yaml](./schema/bet.schema.yaml) — full JSON/YAML schema for validators

---

## 🧬 Authored By

> System MARK
> July 17, 2025
> Version: `v1.0.0`
> Signature: `0xMARKER...TRAIL`
