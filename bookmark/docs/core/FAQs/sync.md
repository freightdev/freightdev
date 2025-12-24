# 🧭 What is a SYNC?

**SYNC** stands for:
**System Yielded Node Clock**

A **SYNC** is the act of bringing a BEAT **back into alignment** with its assigned **TEMPO** and **BET**.

> A SYNC is not punishment — it’s recovery.
> It happens when a BEAT misses its step, drifts off-rhythm, or needs realignment with the CLOCK.

---

## 🔄 Core Purpose:

SYNC ensures that all MARKER actions, BEATS, and TRAILS remain coordinated under the MARK Kernel.

A SYNC:

- Detects tempo drift
- Re-aligns delayed or broken BEATS
- Updates RIBBON and TRAIL checkpoints
- Maintains integrity of ongoing execution

---

## ⚙️ When Does SYNC Trigger?

| Trigger                | Description                                      |
|------------------------|--------------------------------------------------|
| Delay Detected         | The BEAT did not fire on time                   |
| BET Broken             | Rules of the BET were not followed              |
| Ribbon Desync          | A cached trail can’t be verified or accessed    |
| Agent Drift            | BEAT logic diverges from expected path          |
| Kernel Update          | System-wide SYNC to realign all running BEATS   |

---

## 🗂️ SYNC Files:

- `system.sync.md` – Global sync handling rules
- `boot.sync.md` – Initial synchronization phase
- `agent.sync.md` – Agent-specific resync contracts
- `beat.sync.md` – Runtime beat resynchronization logic

---

## 🔐 Philosophy:

> A SYNC is trust renewed.
> You don't reboot the system — you restore its rhythm.

It gives a drifting BEAT a second chance to rejoin the rhythm **without being replaced or reset**.

---

## 🧠 Smart SYNCing:

- If sync fails once → warn
- If sync fails twice → checkpoint RIBBON
- If sync fails thrice → eject or reassign BEAT

---

## 🧵 Related Concepts:

- `tempo.md` → Defines the timing a BEAT must follow
- `clock.md` → The kernel-wide tick manager
- `delay.md` → Detects drift before SYNC is called
- `trail.md` → Logs sync attempts and positions
- `rib.md` → Cache layer that aids sync traceability

---

> “To sync is to **forgive the step** —
> so the dancer may return to the rhythm.”

— MARK Protocol
