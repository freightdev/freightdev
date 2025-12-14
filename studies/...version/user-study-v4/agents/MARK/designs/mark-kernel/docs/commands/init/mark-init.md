# Purpose

The `mark init` command is the **zero-boot directive**. It assumes the user is initializing a new MARK-controlled environment. Here's what happens step by step:

---

## ✅ 1. **Directory Assessment + Bootstrap**

MARK scans the **current working directory** recursively to determine if any of the following exist:

```txt
./beats/
./bets/
./books/
./markers/
./marks/
./memory/
./ribbons/
./trails/
```

If none exist, it proceeds to:

* Create a full scaffold (empty) of all top-level semantic folders:

  ```
  ./beats/
  ./bets/
  ./books/user/
  ./markers/
  ./marks/
  ./memory/
  ./ribbons/
  ./trails/
  ```
* Injects `README.md` files or `intro.md` stubs into each subfolder of `docs/`, explaining their semantic purpose (optional unless `--docs` flag passed).
* Places a default `user.bet`, `system.bet`, and `user.book.md` in place.
* A fresh `marker.mrkr` is placed in `books/user/markers/system.mrkr`.

---

## ✅ 2. **System Self-Marking**

MARK then **self-marks** the environment:

* Injects a default `boot.mrk` mark in `marks/`.
* Writes a `boot.trl` entry in `trails/tmp/` noting time, user, location, and result.
* Signs the trail using `signing.mrkr` and `system.bet` context.

---

## ✅ 3. **Linking to the User**

MARK creates:

* A `memory/store/user.mem` file initialized to an empty dictionary.
* A `book.mrk` mark into `user/book.md`, marking this session as the first trail.
* A `welcome.rib` ribbon with `cache: allow`, `use: unlimited`, and default use cost of `0.00`.

---

## ✅ 4. **Handshake Trail**

The first trail (`boot.trl`) logs the creation of:

```yaml
- user.book created
- system.bet accepted
- system.beat undefined
- memory store: user.mem initialized
- trail session: boot.trl created
- ribbon: welcome.rib assigned
```

---

## ✅ 5. **Summary Beat Creation (if allowed)**

If the `system.bet` allows caching:

* A `summary.beat` is scaffolded with a blank template.
* A `summary.mrkr` is placed in `markers/` or `books/user/markers/`.

---

## ✅ 6. **Output**

After initialization:

```
✔ MARK Initialized
→ Book: ./books/user/book.md
→ Marker: ./books/user/markers/system.mrkr
→ Trail: ./trails/tmp/boot.trl
→ Ribbon: ./ribbons/store/welcome.rib
→ Memory: ./memory/store/user.mem
```

The user is now marked.

---

### 🧠 Behind the Scenes

* All initialized files are marked using `.mrk` marks.
* The `init` process guarantees the system will boot even if **offline**, **headless**, or **sandboxed**.
* Nothing is connected until a beat is defined.
* No agent can dispatch until `system.bet` is accepted and a `*.beat` is registered.

---

### 🔁 Future Runs of `mark init`

If folders already exist:

* MARK validates the folder structure.
* Reads `index.json` if present in `memory/`, `trails/`, or `ribbons/`.
* Logs the second (or nth) trail with a new `.trl` timestamped in `trails/tmp/`.
* Verifies `boot.mrk` against the original checksum if ribbon caching is enabled.

