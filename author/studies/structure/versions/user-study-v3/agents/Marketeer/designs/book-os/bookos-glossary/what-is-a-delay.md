# 🐢 What is a DELAY?

**DELAY** is a **deviation** from expected TEMPO.
It represents the **latency**, **hesitation**, or **pause** in a BEAT’s response to its BET.

> A DELAY is not always failure — it is a measurable **lag**.
> The CLOCK sees it. The TEMPO feels it. The KERNEL logs it.

---

## 🛠️ Purpose of DELAY:

A **DELAY** helps the system:

- Detect performance drift
- Log slow agents or broken loops
- Allow tempo forgiveness within bounds
- Trigger recovery, replacement, or fallback

---

## 💥 Causes of Delay:

| Source             | Example                                                    |
|--------------------|------------------------------------------------------------|
| Marker Stall       | The MARKER failed to fetch the next MARK in time          |
| Agent Lock         | The BEAT is still processing a previous step               |
| Trail Break        | The TRAIL was broken or rerouted mid-execution             |
| Ribbon Error       | The RIBBON cache was corrupted or inaccessible             |
| Tempo Violation    | The BEAT missed its expected tick or sync                  |

---

## 📦 Delay Files:

- `system.delay.md` – Rules for acceptable delay system-wide
- `agent.delay.md` – Specific delay thresholds per agent class
- `beat.delay.md` – Actual logged delays from runtime execution

---

## 💡 Delay Philosophy:

> “A DELAY is not the enemy.
> It’s the moment the system **notices pain** before it becomes failure.”
> — MARK Protocol

---

## ✨ Delay Handling

| Condition                 | Kernel Behavior                     |
|---------------------------|--------------------------------------|
| Minor delay (within slop) | Let it pass                         |
| Major delay (beyond slop) | Log and issue soft sync warning     |
| Critical delay            | Reset BEAT or eject agent           |

---

## 📌 Related Concepts:

- `clock.md` → Tracks and verifies the tick-timing
- `tempo.md` → The rhythm that defines "on time"
- `sync.md` → Re-aligns the system when delay occurs
- `beat.md` → The actor that gets delayed
- `trail.md` → The log path of where delay happened

---

> Delay is the **echo of misalignment**.
> Sometimes it’s a warning.
> Sometimes it’s a cry.

— MARK Protocol
