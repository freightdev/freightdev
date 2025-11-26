# 🏺 What is an INKWELL?

**INKWELL** is the **source**, **reservoir**, or **refill policy** for `INK` within the MARK System.
It defines **where INK comes from**, **how it’s replenished**, and **who controls access** to it.

> “Without an inkwell, every stroke is a countdown.
> With it, the story flows forever.”

---

## 🧪 Definition:

An **INKWELL** is the **origin container** that distributes `INK` to `MARKERS`.
It may be personal, shared, system-defined, or dynamic.

It governs:

- 🔄 **Refill logic**: auto/manual, quota-based, tokenized
- 🔐 **Access control**: who may draw from it, and when
- 🧰 **Ink type support**: narrative, logic, visual, encrypted
- 🧠 **Memory-binding**: does the inkwell remember who drew what?

---

## ⚙️ INKWELL Properties:

Stored in files like `system.inkwell.md`, `user.inkwell.md`, or `marker.inkwell.md`
Each `.inkwell.md` may include:

- `inkwell_id`: unique reference
- `linked_marker`: which marker(s) may draw from it
- `capacity`: max ink it can hold
- `replenish_rate`: refill speed or triggers
- `refill_method`: auto | manual | earned | purchased
- `binding`: ephemeral | session | persistent
- `ink_style`: default formatting or tempo of the ink

---

## 🔁 Flow Logic:

1. A `MARKER` requests `INK`
2. If its linked `INKWELL`:
   - Has enough capacity → 🟢 Grants ink
   - Is empty → 🔴 Rejects request or triggers refill policy
3. Trail or Stroke is generated using ink drawn
4. `INKWELL` logs the transaction

---

## 🔐 Types of INKWELLS:

| Type        | Description                                   |
|-------------|-----------------------------------------------|
| `system`    | Global default inkwell shared by all markers  |
| `user`      | Private to one user, may be token-capped       |
| `marker`    | Assigned to one marker, scoped to its purpose  |
| `session`   | Temporary inkwell valid only per execution     |
| `virtual`   | Infinite source used in simulated or test runs |

---

## 🧠 Creative Principle:

- INKWELLS define **how much creativity, memory, or logic** a marker is allowed
- **Ink doesn't come from nowhere** — it’s budgeted, tracked, and permissioned
- A **dry inkwell** = a silent agent

---

## 💡 Example Use:

```yaml
# user.inkwell.md
inkwell_id: user/jesse/main
linked_marker: [cowgirl.summary.mrkr]
capacity: 120.0
replenish_rate: 5.0/min
refill_method: auto
binding: session
ink_style: narrative.rich
```

## 📜 Principle:

> “Give a marker infinite ink, and it will drown.
>  Give it a steady inkwell, and it will paint truth.”

— MARK Protocol
