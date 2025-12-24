Ahhh, now I get you —
you’re asking for the **full low-level permission & control map** for files/scripts on Linux, including:

* How to **remove execution ability** (un-runnable).
* How to control read/write access (chmod numbers + symbolic).
* How to change ownership and groups.
* How to lock with `chattr` (immutable files).
* How to hide or obfuscate.
* How to require **auth** (GPG) before a script can be run.
* How certain perms are required for specific services (SSH, Git, etc.).

Basically — a **permissions, attributes, ownership, and security master guide** so you know *exactly* what you can do to a file to change how/when/who can run it.

---

## **1️⃣ Permissions Basics — `chmod`**

Linux permissions are split into:

```
[ owner ][ group ][ others ]
  rwx      rwx      rwx
```

* **r** = read
* **w** = write
* **x** = execute

You can set these either with **symbolic** (letters) or **numeric** (octal) modes.

---

### **Symbolic:**

```bash
chmod u-x file.sh   # remove execute for owner
chmod g-w file.sh   # remove write for group
chmod o-r file.sh   # remove read for others
chmod a-x file.sh   # remove execute for all
chmod u+x file.sh   # add execute for owner
```

**u** = user/owner, **g** = group, **o** = others, **a** = all

---

### **Numeric (octal)**:

Each permission = number:

* r = 4
* w = 2
* x = 1
  Add them up for each section.

| Mode | Owner | Group | Others | Meaning                                   |
| ---- | ----- | ----- | ------ | ----------------------------------------- |
| 777  | rwx   | rwx   | rwx    | Full access for everyone                  |
| 755  | rwx   | r-x   | r-x    | Common for executables/scripts            |
| 700  | rwx   | ---   | ---    | Only owner can read/write/run             |
| 644  | rw-   | r--   | r--    | Common for configs/text files             |
| 600  | rw-   | ---   | ---    | Only owner can read/write (private files) |
| 000  | ---   | ---   | ---    | No one can do anything                    |

Example:

```bash
chmod 000 script.sh   # makes it un-runnable, unreadable, unwritable
chmod 644 script.sh   # readable by everyone, writable by owner, no exec
chmod 755 script.sh   # common run permission
```

---

## **2️⃣ Ownership — `chown`**

```bash
chown user file.sh        # change owner
chown user:group file.sh  # change owner & group
```

This is key for controlling who can even *attempt* to run/edit a file.

---

## **3️⃣ Attributes — `chattr`**

Special filesystem flags for **locking** a file:

```bash
chattr +i file.sh   # immutable — can't delete, modify, rename (even as root unless removed)
chattr -i file.sh   # remove immutable
chattr +a file.sh   # append-only — can only be added to, not rewritten
```

These can be checked with:

```bash
lsattr file.sh
```

---

## **4️⃣ Make a Script “Un-runnable”**

* Remove execute bit:

```bash
chmod a-x file.sh
```

* Remove read bit too (so they can’t even open it):

```bash
chmod a-r file.sh
```

* Make it immutable:

```bash
chattr +i file.sh
```

* Or change ownership to a non-login system user so no one can run it:

```bash
chown nobody:nogroup file.sh
```

---

## **5️⃣ Require GPG to Run**

Encrypt the script with your GPG key:

```bash
gpg -e -r yourname@example.com script.sh
```

Now the file is `script.sh.gpg` and unreadable/unrunnable without your key.

To run:

```bash
gpg -d script.sh.gpg | bash
```

You’ll be prompted for your GPG passphrase, meaning **only you** can run it.

---

## **6️⃣ Hide Scripts**

* Prefix with `.` (dotfile):

```bash
mv script.sh .script.sh
```

It won’t appear in normal `ls` output unless you use `ls -a`.

* Put it in a hidden directory (`.hidden/`).
* If you really want to obfuscate, store it as compressed or encrypted.

---

## **7️⃣ Special Cases for Services**

* **SSH keys** → must be `600` (private key) and `644` (public key) or SSH will refuse them.
* **Git hooks** → must be executable (`755`) or Git ignores them.
* **Systemd services** → scripts must be executable and usually `root`-owned.
* **Web server CGI** → needs `755` so the server user can execute it.

---

If you want, I can put all of this into a **“Linux File Control Bible”** doc for you, with:

* Every chmod/chown/chattr combo explained.
* Security patterns (read-only, owner-only, encrypted-only, etc.).
* Quick lookup table for “how do I make this un-runnable / private / require password”.

Do you want me to make that full doc?
Because this is only the condensed version.
