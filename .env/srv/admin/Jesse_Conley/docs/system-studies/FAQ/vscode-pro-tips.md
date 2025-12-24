Gotcha — you’re talking about going **all in on VS Code keyboard mastery** so you can skip the clumsy “mouse, drag, click” dance and just fly through editing, selecting, spacing, moving, and reshaping code purely from the keys.

Let’s break it into **selection/navigation**, **editing**, **multi-cursor magic**, **code formatting**, and **workspace/session control** — and I’ll make sure to give the *less obvious advanced stuff*, not just “Ctrl+C” level basics.

---

## **1. Navigation & Selection (Move Without the Mouse)**

| Action                                | Windows/Linux            | Mac                       |
| ------------------------------------- | ------------------------ | ------------------------- |
| Go to beginning/end of line           | `Home` / `End`           | `Cmd+Left` / `Cmd+Right`  |
| Go to start/end of file               | `Ctrl+Home` / `Ctrl+End` | `Cmd+Up` / `Cmd+Down`     |
| Move by word                          | `Ctrl+Left/Right`        | `Option+Left/Right`       |
| Select by word                        | `Ctrl+Shift+Left/Right`  | `Option+Shift+Left/Right` |
| Select whole line                     | `Ctrl+L`                 | `Cmd+L`                   |
| Expand selection to matching brackets | `Shift+Alt+→`            | `Shift+Option+→`          |
| Expand selection to next scope        | `Shift+Ctrl+Alt+→`       | `Shift+Cmd+Option+→`      |
| Select entire file                    | `Ctrl+A`                 | `Cmd+A`                   |
| Jump to line                          | `Ctrl+G`                 | `Cmd+G`                   |
| Jump to matching bracket              | `Ctrl+Shift+\`           | `Cmd+Shift+\`             |

---

## **2. Multi-Cursor & Column Editing (Mouse-Free Power Moves)**

| Action                                   | Windows/Linux                                     | Mac                                                    |
| ---------------------------------------- | ------------------------------------------------- | ------------------------------------------------------ |
| Add next match of selection              | `Ctrl+D`                                          | `Cmd+D`                                                |
| Skip next match                          | `Ctrl+K Ctrl+D`                                   | `Cmd+K Cmd+D`                                          |
| Add cursor at next occurrence            | `Ctrl+Shift+L`                                    | `Cmd+Shift+L`                                          |
| Add cursor above/below                   | `Ctrl+Alt+Up/Down`                                | `Option+Cmd+Up/Down`                                   |
| Select column/block                      | `Shift+Alt+Drag` (mouse) / `Ctrl+Shift+Alt+Arrow` | `Shift+Option+Drag` (mouse) / `Cmd+Shift+Option+Arrow` |
| Insert cursor at every line of selection | `Ctrl+Shift+L`                                    | `Cmd+Shift+L`                                          |

---

## **3. Editing & Movement (Rapid Code Shaping)**

| Action                   | Windows/Linux                             | Mac                    |
| ------------------------ | ----------------------------------------- | ---------------------- |
| Move line up/down        | `Alt+Up/Down`                             | `Option+Up/Down`       |
| Copy line up/down        | `Shift+Alt+Up/Down`                       | `Shift+Option+Up/Down` |
| Delete line              | `Ctrl+Shift+K`                            | `Cmd+Shift+K`          |
| Trim trailing whitespace | `Ctrl+Shift+X` (custom binding)           | *Set in keybindings*   |
| Join lines               | `Ctrl+J`                                  | `Cmd+J`                |
| Wrap with snippet        | `Ctrl+Shift+P → “Wrap With Abbreviation”` | same                   |
| Comment/uncomment line   | `Ctrl+/`                                  | `Cmd+/`                |
| Block comment            | `Shift+Alt+A`                             | `Shift+Option+A`       |
| Indent/outdent           | `Ctrl+]` / `Ctrl+[ `                      | `Cmd+]` / `Cmd+[ `     |

---

## **4. Code Formatting & Cleanup**

| Action           | Windows/Linux           | Mac                    |
| ---------------- | ----------------------- | ---------------------- |
| Format document  | `Shift+Alt+F`           | `Shift+Option+F`       |
| Format selection | `Ctrl+K Ctrl+F`         | `Cmd+K Cmd+F`          |
| Organize imports | `Ctrl+Shift+O` then `@` | `Cmd+Shift+O` then `@` |
| Rename symbol    | `F2`                    | `F2`                   |
| Peek definition  | `Alt+F12`               | `Option+F12`           |
| Go to definition | `F12`                   | `F12`                  |

---

## **5. Workspace / Session Control**

| Action               | Windows/Linux  | Mac           |
| -------------------- | -------------- | ------------- |
| Quick Open file      | `Ctrl+P`       | `Cmd+P`       |
| Command Palette      | `Ctrl+Shift+P` | `Cmd+Shift+P` |
| Toggle terminal      | `` Ctrl+` ``   | `` Cmd+` ``   |
| Split editor         | `Ctrl+\`       | `Cmd+\`       |
| Focus next editor    | `Ctrl+1/2/3`   | `Cmd+1/2/3`   |
| Close editor         | `Ctrl+W`       | `Cmd+W`       |
| Reopen closed editor | `Ctrl+Shift+T` | `Cmd+Shift+T` |
| Search all files     | `Ctrl+Shift+F` | `Cmd+Shift+F` |
| Replace in all files | `Ctrl+Shift+H` | `Cmd+Shift+H` |

---

## **6. Selection + Space/Tab Tricks for Your “Spacing Out” Goal**

If your goal is *"select all these lines and space them over"*:

* **Select All & Indent Right**:
  `Ctrl+A` → `Tab` (indents all selected lines)
  `Shift+Tab` (outdents)

* **Column Space Insert** (perfect for aligning code):

  * Hold `Alt` and drag mouse vertically, or use `Ctrl+Shift+Alt+Arrow` to select a column, then press `Space` to add space to all lines.

* **Reindent Automatically**:
  Select text → `Ctrl+Shift+P` → type `Reindent Selected Lines`

* **Transform Whole Session Quickly**:
  Use `Ctrl+Shift+L` (select all occurrences of selection) then type `Space` or `Tab`.

---

## **7. Extra Pro Moves**

* **Keyboard Shortcuts Cheat Sheet**: `Ctrl+K Ctrl+S` opens the keybindings editor.
* **Custom Multi-Step Commands**: Install **Macros** extension to bind multiple actions to one shortcut.
* **Emmet Everywhere**: Works in plaintext too — type `ul>li*5` then `Tab`.
* **Zen Mode**: `Ctrl+K Z` hides everything but the editor.

---

If you want, I can build you a **"VS Code Keyboard Command Map"** — basically a one-screen printable with all of this arranged visually so you don’t even have to remember which category something’s in.

Do you want me to make that cheat sheet next so you can just tape it near your desk?
