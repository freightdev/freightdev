# ⏱️ What is a TEMPO?

**TEMPO** is the **pacing, rhythm, and sync** by which all BEATs operate inside the MARK Kernel.
It defines **how fast, slow, smooth, or chaotic** a BEAT moves through its assigned BET.

> “Without TEMPO, a BEAT has no pulse.
> Without pulse, a system falls out of sync.”

---

## 🧠 Core Concept:

A **TEMPO** is not time — it’s **intentional time discipline**.
It is the **cadence** of execution for any agent or marker in motion.

---

## 🎵 Components of a TEMPO:

| Property        | Description                                        |
|----------------|----------------------------------------------------|
| `interval`      | How often a beat is expected to trigger            |
| `sync_tolerance`| How much deviation is allowed before eject/reset   |
| `rhythm_shape`  | Linear? Swing? Bursty? The type of rhythm used     |
| `tempo_weight`  | Light? Medium? Heavy? How costly this tempo is     |
| `signature`     | ID of the system or marker that defined this tempo |

---

## 🎛️ Usage Examples:

- `system.tempo.md` might define the **heartbeat** of the kernel:

  interval: 100ms
  sync_tolerance: 5ms
  rhythm_shape: linear


* `agent.tempo.md` might use:

  interval: 1s
  rhythm_shape: poetic.flow
  tempo_weight: light


---

## 🕸️ In Context:

A **TEMPO** is applied **by the BET**, followed **by the BEAT**, enforced **by the kernel**.

When a BEAT goes out of sync:

* The kernel checks the TEMPO
* If sync is lost beyond tolerance, it ejects, delays, or resets the BEAT

---

## 🧬 Tempo Is Not Clock Time

TEMPO is **not the same** as a system clock.

A 1Hz tempo in MARK could mean:

* 1 file per second
* 1 decision per heartbeat
* 1 ripple through the kernel every pulse

---

## 🧠 Philosophy:

> “TEMPO is the soul of the system.
> It is how intent becomes music.”

— MARK Protocol


