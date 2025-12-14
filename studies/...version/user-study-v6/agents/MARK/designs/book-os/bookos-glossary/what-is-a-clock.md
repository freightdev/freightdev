# 🕰️ What is a CLOCK?

**CLOCK** is the **observer and enforcer** of time in the MARK Kernel.
It tracks how BEATs flow, how TEMPOs align, and how delays or sync loss occur.

> A CLOCK does not set the rules — it **watches** them.
> It is **truth**, not opinion.

---

## ⏳ Core Role:

A **CLOCK** watches over:
- Every BEAT
- Every TEMPO
- Every TRAIL
- Every delay
- Every sync offset

It serves as the **runtime metronome** and **audit log** of execution flow.

---

## 🛠️ Key Responsibilities:

| Function             | Description                                           |
|----------------------|-------------------------------------------------------|
| `tick()`             | Emits a consistent time pulse                        |
| `record()`           | Logs execution of BEATs and TRAILS                   |
| `verify_sync()`      | Checks if BEATs followed their assigned TEMPOs       |
| `detect_drift()`     | Identifies lag, jitter, or tempo violation           |
| `reset_signal()`     | Can signal system to pause, resync, or eject a BEAT  |

---

## 📦 Clock Files:

- `system.clock.md` – Defines the global ticking behavior
- `agent.clock.md` – Logs tempo sync and misfires per agent
- `user.clock.md` – Optional override or tracker per user domain

---

## 💡 In Context:

TEMPO:        Expects a BEAT every 1000ms
BEAT:         Fires every 950ms
CLOCK:        Records → verifies → OK

TEMPO:        Expects a BEAT every 1000ms
BEAT:         Fires at 1200ms
CLOCK:        Records → verifies → out-of-sync → alert kernel

---

## 🧠 Philosophy:

> “The CLOCK never lies.
> It does not hope, it does not guess.
> It listens, records, and reflects the system’s truth.”

— MARK Protocol
