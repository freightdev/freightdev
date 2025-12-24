## 🔑 Zsh’s Special Startup Files (in order of use)

1. **`~/.zshenv`**

   * **Always sourced**, no matter what kind of shell (interactive, login, script).
   * Happens **first**, before any other file.
   * Intended for setting environment variables (`PATH`, `EDITOR`, `LANG`, etc.).
   * That’s why in your case, the old `~/.zshenv` was being loaded **before** your generator script had a chance to run. Zsh doesn’t ask — it just does it.

---

2. **`~/.zprofile`**

   * Sourced **for login shells only** (e.g., when you log in via tty, ssh, or a display manager).
   * Similar to Bash’s `~/.bash_profile`.
   * Good for things you want only once per login session (like setting up PATHs, ssh-agents, etc.).

---

3. **`~/.zshrc`**

   * Sourced **for interactive shells only** (any time you open a terminal window/tab).
   * This is where you put interactive things: prompt configuration, aliases, keybindings, shell options, etc.
   * Equivalent to Bash’s `~/.bashrc`.

---

4. **`~/.zlogin`**

   * Also sourced **for login shells**, but *after* `~/.zprofile` and `~/.zshrc`.
   * Often used for things you want at the *end* of login, like `fortune` or `neofetch`.

---

5. **`~/.zlogout`**

   * Sourced **when a login shell exits**.
   * Use for cleanup (unmounting drives, killing background daemons, logging out of agents, etc.).

---

## 📂 “Local” overrides

Zsh also looks for **system-wide** versions of the same files (`/etc/zshenv`, `/etc/zprofile`, etc.), which apply to all users.
Then your user-specific ones (`~/.zshenv`, `~/.zprofile`, etc.) can override those.

There’s also a convention (not official Zsh core, but widely used) of splitting configs into directories like:

* `~/.zshrc.d/`
* `~/.zshenv.d/`

…and sourcing everything in there. That’s basically what you’re building with your `$ENV_SRC`.

---

## ⚖️ Summary: when each runs

| File            | Runs in...                                                  | Purpose                            |
| --------------- | ----------------------------------------------------------- | ---------------------------------- |
| **`.zshenv`**   | **Always** (login, non-login, interactive, non-interactive) | Set global env vars                |
| **`.zprofile`** | Login shells only                                           | Session-wide config (PATH, agents) |
| **`.zshrc`**    | Interactive shells only                                     | Aliases, prompt, interactive stuff |
| **`.zlogin`**   | Login shells (after `zshrc`)                                | Run-once startup messages, tools   |
| **`.zlogout`**  | On shell exit (login shells)                                | Cleanup                            |

---

👉 So in plain words:

* **`.zshenv` is special** because Zsh will **always** load it, first thing, before anything else.
* **`.zshrc` is special** because Zsh will load it **only for interactive sessions** (like opening a terminal).
* **`.zprofile` and `.zlogin` are special** because they run at login shells.
* **`.zlogout` is special** because it runs at logout.
