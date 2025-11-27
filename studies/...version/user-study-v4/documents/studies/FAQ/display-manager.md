A **display manager (DM)** is basically the **login screen system** for Linux/Unix desktops.

When your system boots into graphical mode, the display manager is the first thing you see: the window where you type your username and password (or select a session). After you log in, the display manager starts your desktop environment or window manager.

---

### What a display manager does

* **Starts the X server or Wayland compositor** (graphical backend).
* **Presents the login interface** (GUI or sometimes text).
* **Authenticates the user** (checks your password or login method).
* **Launches the chosen session** (e.g., GNOME, KDE Plasma, XFCE, i3).
* **Handles session switching** (let’s you log in multiple users and swap between them).

---

### Examples of popular display managers

* **GDM** (GNOME Display Manager) → used by GNOME.
* **SDDM** (Simple Desktop Display Manager) → used by KDE Plasma.
* **LightDM** → lightweight, works with many environments.
* **LXDM** → for LXDE/LXQt.
* **XDM** → the original, very basic.

---

### Without a display manager

If you don’t want one, you can boot into a **TTY login** (console text login) and then start your desktop manually with commands like:

```bash
startx
```

or

```bash
exec sway
```

This gives you more control, which is why some Arch/Alpine users skip display managers entirely.

---

👉 So in short:
A display manager is **just the login screen program for graphical sessions**. If you don’t care about pretty logins, you don’t need one at all.