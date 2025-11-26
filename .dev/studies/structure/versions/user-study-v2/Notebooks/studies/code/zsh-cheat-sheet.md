╔══════════════════════════════════════════════╗
║                ZSH CHEAT SHEET               ║
╚══════════════════════════════════════════════╝

| Flag | Meaning                                                   |
| ---- | --------------------------------------------------------- |
| `i`  | **Interactive shell** (terminal session)                  |
| `v`  | **Verbose mode** — prints each line as it’s read          |
| `x`  | **Debug mode** — prints each command as it’s executed     |
| `e`  | Exit immediately if a pipeline fails (`set -e`)           |
| `n`  | **No execution** — parses but doesn’t execute commands    |
| `f`  | **Disable filename globbing** (`noglob`)                  |
| `h`  | Remember the location of commands (`hash`)                |
| `m`  | Job control is enabled                                    |
| `B`  | Enable brace expansion                                    |
| `H`  | Enable **! style history expansion**                      |
| `s`  | Reading commands from a **script file** (non-interactive) |

---

### **1. Text Attributes (Styles)**

| Name      | Code | Description                    |
| --------- | ---- | ------------------------------ |
| Reset     | 0    | Reset all attributes           |
| Bold      | 1    | Bold / Bright                  |
| Dim       | 2    | Dim / Faint                    |
| Italic    | 3    | Italic                         |
| Underline | 4    | Underlined                     |
| Blink     | 5    | Slow blink                     |
| BlinkFast | 6    | Fast blink                     |
| Reverse   | 7    | Invert foreground & background |
| Hidden    | 8    | Conceal text                   |
| Strike    | 9    | Strike-through                 |

**Usage example:**

```zsh
echo -e "\e[1mBold Text\e[0m"
echo -e "\e[4;31mUnderlined Red Text\e[0m"
```

---

### **2. Foreground Colors (Text Color)**

| Color          | Code | ANSI Escape |
| -------------- | ---- | ----------- |
| Black          | 30   | `\e[30m`    |
| Red            | 31   | `\e[31m`    |
| Green          | 32   | `\e[32m`    |
| Yellow         | 33   | `\e[33m`    |
| Blue           | 34   | `\e[34m`    |
| Magenta        | 35   | `\e[35m`    |
| Cyan           | 36   | `\e[36m`    |
| White          | 37   | `\e[37m`    |
| Bright Black   | 90   | `\e[90m`    |
| Bright Red     | 91   | `\e[91m`    |
| Bright Green   | 92   | `\e[92m`    |
| Bright Yellow  | 93   | `\e[93m`    |
| Bright Blue    | 94   | `\e[94m`    |
| Bright Magenta | 95   | `\e[95m`    |
| Bright Cyan    | 96   | `\e[96m`    |
| Bright White   | 97   | `\e[97m`    |

---

### **3. Background Colors**

| Color          | Code | ANSI Escape |
| -------------- | ---- | ----------- |
| Black          | 40   | `\e[40m`    |
| Red            | 41   | `\e[41m`    |
| Green          | 42   | `\e[42m`    |
| Yellow         | 43   | `\e[43m`    |
| Blue           | 44   | `\e[44m`    |
| Magenta        | 45   | `\e[45m`    |
| Cyan           | 46   | `\e[46m`    |
| White          | 47   | `\e[47m`    |
| Bright Black   | 100  | `\e[100m`   |
| Bright Red     | 101  | `\e[101m`   |
| Bright Green   | 102  | `\e[102m]`  |
| Bright Yellow  | 103  | `\e[103m`   |
| Bright Blue    | 104  | `\e[104m`   |
| Bright Magenta | 105  | `\e[105m`   |
| Bright Cyan    | 106  | `\e[106m`   |
| Bright White   | 107  | `\e[107m`   |

---

### **4. 256-Color Mode (Advanced)**

* **Foreground:** `\e[38;5;<n>m`
* **Background:** `\e[48;5;<n>m`
* `<n>` = 0–255 color code

**Example:**

```zsh
echo -e "\e[38;5;208mOrange Text\e[0m"
echo -e "\e[48;5;27mBlue Background\e[0m"
```

**256-color chart (basic groups):**

* 0–7: Standard colors
* 8–15: High-intensity colors
* 16–231: 6×6×6 RGB cube
* 232–255: Grayscale ramp

---

### **5. Combine Attributes**

```zsh
# Bold + Red + Yellow Background
echo -e "\e[1;31;43mBold Red on Yellow\e[0m"

# Underline + Cyan
echo -e "\e[4;36mUnderlined Cyan\e[0m"

# Reverse Video + Green
echo -e "\e[7;32mGreen Reversed\e[0m"
```

---

### **6. Quick Reference Table**

| Attr | FG | BG | Example                       |
| ---- | -- | -- | ----------------------------- |
| 0    | 37 | 40 | Reset, White on Black         |
| 1    | 31 | 43 | Bold Red on Yellow            |
| 3    | 36 | 44 | Italic Cyan on Blue           |
| 4    | 35 | 45 | Underlined Magenta on Magenta |
| 7    | 32 | 47 | Reverse Green on White        |

---

You can **wrap these in Zsh functions** for quick usage:

```zsh
color_echo() {
  echo -e "\e[$1m$2\e[0m"
}

color_echo "1;31;43" "Bold Red on Yellow"
```


1️⃣ BASIC WILDCARDS
──────────────────────────────────────────────
*        → match any string (incl. empty)
?        → match exactly one char
[abc]    → match any one char in set
[!abc]   → match any one char NOT in set
{a,b,c}  → brace expansion (alternatives)
~pattern → exclude pattern

Examples:
*.txt      → all .txt files
file?.txt  → file1.txt, fileA.txt
file[12].txt → file1.txt or file2.txt
*~*.bak   → everything except .bak files

──────────────────────────────────────────────
2️⃣ EXTENDED GLOBBING (setopt extended_glob)
──────────────────────────────────────────────
?(pattern)  → zero or one occurrence
*(pattern)  → zero or more occurrences
+(pattern)  → one or more occurrences
@(pattern)  → exactly one of the patterns
!(pattern)  → anything except the pattern

Example:
file+(1|2).txt → file1.txt, file11.txt, file2.txt

──────────────────────────────────────────────
3️⃣ RECURSIVE GLOBBING
──────────────────────────────────────────────
**           → match directories recursively
**/*.txt     → all .txt files in all subfolders

──────────────────────────────────────────────
4️⃣ DOTFILES
──────────────────────────────────────────────
.[^.]*       → hidden files excluding . ..
..?*         → hidden files with ≥2 chars

──────────────────────────────────────────────
5️⃣ QUALIFIERS (append in parentheses)
──────────────────────────────────────────────
.   → regular files
/   → directories
@   → symlinks
*   → executable files
N   → nullglob (no match = empty)
D   → include dotfiles
L   → follow symlinks
o+  → order by mod time ascending
om  → order by mod time descending

Example:
*.txt(.)      → only regular files
*/(/)         → only directories
.*(D)         → include hidden files
script(*x)    → executable files

──────────────────────────────────────────────
6️⃣ COMBINATION EXAMPLE
──────────────────────────────────────────────
# All executable hidden files recursively except .git*
**/.**(.x~.git*(.))

Breakdown:
**/.*     → all hidden files recursively
(.x)      → executable only
~.git*(.) → exclude anything starting with .git

──────────────────────────────────────────────
7️⃣ OPTIONS
──────────────────────────────────────────────
setopt extended_glob → enable extended globbing
setopt nullglob      → no match = empty string
setopt globdots      → include hidden files by default

──────────────────────────────────────────────
💡 TIP
──────────────────────────────────────────────
Use `ls -d **/*.txt(N)` for safe recursive listing
Use `(Ie)` array search to skip priority/ignore files




╔════════════════════════════════════════════════════════════════╗
║                     ZSH NON-GLOBBING CHEAT SHEET              ║
╚════════════════════════════════════════════════════════════════╝

# ---------------- ZSH OPTIONS (setopt / unsetopt) ----------------
allexport         : automatically export all variables
autocd            : cd into a directory without typing cd
autolist          : automatically list ambiguous completions
autonamedirs      : cd to named directories with ~name
banghist          : ! for history expansion
cdablevars        : allow cd to variable values
correct           : spell correction for commands
extendedglob      : enable extended glob patterns (used above)
globdots          : include . and .. in globbing
hist_ignore_all_dups : skip duplicate entries in history
interactivecomments : allow comments in interactive shell
promptsubst       : allow prompt to evaluate commands

# ---------------- INTERACTIVE FLAGS ($-) ----------------
i  : interactive shell
v  : verbose (prints commands before executing)
x  : xtrace (prints commands with substitutions)
h  : hashcmds (tracks command locations)
r  : restricted shell
B  : brace expansion active
F  : function definition mode

# ---------------- PARAMETER EXPANSION ----------------
${var}                 : simple variable
${var:-default}        : default if unset or null
${var:=default}        : assign default if unset or null
${var:+alternate}      : alternate if set
${var:?error}          : print error if unset/null
${#var}                : length of variable
${var%pattern}         : remove shortest match from end
${var%%pattern}        : remove longest match from end
${var#pattern}         : remove shortest match from start
${var##pattern}        : remove longest match from start
${(flags)var}           : parameter flags
  (u) : uppercase
  (l) : lowercase
  (q) : quote
  (s:sep:) : split on sep
  (j:sep:) : join array with sep

# ---------------- ARITHMETIC EXPANSION ----------------
$(( expression ))       : evaluates arithmetic expression
$(( i++ ))              : post-increment
$(( ++i ))              : pre-increment
$(( i+=5 ))             : compound assignment
$(( i<j?i:j ))          : ternary

# ---------------- COMMAND SUBSTITUTION ----------------
$(command)              : capture command output
`command`               : legacy backticks
$(<file)                : faster file reading into string

# ---------------- REDIRECTION ----------------
> file         : stdout to file (overwrite)
>> file        : stdout append
<& file        : stdin from file
>& file        : duplicate fd
>&2            : redirect stdout to stderr
|             : pipe stdout to another command
|&            : pipe both stdout and stderr
<<< string     : here-string
<<EOF ... EOF  : here-document

# ---------------- HISTORY EXPANSION ----------------
!!          : last command
!n          : command number n
!-n         : nth previous command
!string     : last command starting with string
!?string?    : last command containing string
^old^new^   : quick substitution in last command
!:0        : command name
!:1-$      : arguments
!:*        : all arguments

# ---------------- PROMPT ESCAPES ----------------
%n : username
%m : hostname (up to first .)
%M : full hostname
%~ : current dir, ~ for home
%d : current dir (no ~)
%h : history number
%! : current event number
%j : number of jobs
%t : current time HH:MM:SS
%T : current time HH:MM
%* : current time HH:MM:SS
%# : prompt character (# for root, % for user)
%% : literal %

# ---------------- CONTROL STRUCTURES ----------------
if [[ condition ]]; then ... fi
if (( expr )); then ... fi
case $var in pattern) ... ;; esac
for var in list; do ... done
while [[ condition ]]; do ... done
until [[ condition ]]; do ... done
select var in list; do ... done
function name { ... }   : define function
name() { ... }          : alternative syntax
trap 'commands' SIGNAL  : handle signals

# ---------------- ARRAIES ----------------
array=(one two three)
${array[1]}       : first element
${array[-1]}      : last element
${#array[@]}      : length
${array[@]}       : all elements
${array[*]}       : all elements as single word
${array[@]:1:2}   : slice
array+=(four five) : append elements
unset array[2]    : remove element

# ---------------- KEY BUILTINS ----------------
echo        : print to stdout
printf      : formatted printing
read        : read input
typeset     : declare variables with attributes
declare     : synonym for typeset
let         : arithmetic evaluation
eval        : execute a string as command
source      : load a file
exec        : replace shell with command
pushd/popd  : directory stack
dirs        : show directory stack
cd         : change directory
pwd        : print working dir
alias/unalias: define/remove shortcuts
fc         : fix command from history
hash       : track command paths
compgen    : generate completions (requires compinit)
autoload   : define functions for later load

# ---------------- FILE TESTS ----------------
-f file  : regular file
-d dir   : directory
-L file  : symlink
-r file  : readable
-w file  : writable
-x file  : executable
-s file  : non-empty
-e file  : exists

# ---------------- MISC ----------------
$RANDOM    : random number
$SECONDS   : seconds since shell started
$0         : script name
$#         : number of args
$*         : all args as a single word
$@         : all args as separate words
$?         : last command exit status
$_         : last arg of previous command
$!         : pid of last background command


┌───────────────────────────────────────────────┐
│ BASIC PATTERNS                                │
├─────────────┬─────────────────────────────────┤
│ *           │ Any string, including empty      │
│ ?           │ Single character                 │
│ [abc]       │ Any character in set             │
│ [a-z]       │ Range of characters              │
│ [!a-z]      │ Not in range                     │
│ [[:class:]] │ POSIX class (alnum, digit, etc.)│
└─────────────┴─────────────────────────────────┘

┌───────────────────────────────────────────────┐
│ RECURSIVE / EXTENDED                          │
├─────────────┬─────────────────────────────────┤
│ **          │ Recursive directories           │
│ **/*        │ All files recursively           │
│ **/*(.)     │ Regular files recursively       │
│ **/*(/)     │ Directories recursively         │
│ **/*(@)     │ Symlinks recursively            │
│ **/*(D)     │ Include hidden files            │
│ (foo|bar)   │ Alternatives                    │
│ (foo|bar)#  │ One or more repetitions         │
│ (foo|bar)## │ Two or more repetitions         │
│ (foo|bar)^  │ Zero or more repetitions        │
│ (foo|bar)?  │ Zero or one repetition          │
│ ^pattern    │ Negate match                     │
│ pattern~exclude │ Exclude pattern               │
│ *(#i)       │ Case-insensitive                 │
│ *(#cN)      │ Limit matches to N               │
│ *(#bN)      │ Limit recursion depth N          │
└─────────────┴─────────────────────────────────┘

┌───────────────────────────────────────────────┐
│ QUALIFIERS                                    │
├─────────────┬─────────────────────────────────┤
│ (.)         │ Regular files                    │
│ (/)         │ Directories                      │
│ (@)         │ Symlinks                          │
│ (=)         │ Executable files                 │
│ (|)         │ Pipes/FIFOs                      │
│ (%)         │ Sockets                           │
│ (D)         │ Include dotfiles                  │
│ (L)         │ Follow symlinks recursively       │
│ (l)         │ Symlinks themselves               │
└─────────────┴─────────────────────────────────┘

┌───────────────────────────────────────────────┐
│ SORTING                                       │
├─────────────┬─────────────────────────────────┤
│ *(On)       │ Numeric sort                      │
│ *(Om)       │ Modification time                  │
│ *(Oa)       │ Access time                        │
│ *(Oc)       │ Creation time                      │
│ *(Os)       │ Size                               │
│ *(Ou)       │ UID                                │
│ *(Og)       │ GID                                │
│ *(Ol)       │ Name length                        │
│ *(Oe)       │ Extension                          │
│ *(Of)       │ File type                           │
└─────────────┴─────────────────────────────────┘

┌───────────────────────────────────────────────┐
│ EXPRESSIONS                                   │
├─────────────┬─────────────────────────────────┤
│ *(e:'[[ -f $REPLY ]]':)  │ Regular files only        │
│ *(e:'[[ -x $REPLY ]]':)  │ Executables only          │
│ *(e:'[[ -s $REPLY ]]':)  │ Non-empty files           │
│ *(e:'[[ -d $REPLY ]]':)  │ Directories only          │
└─────────────┴─────────────────────────────────┘

┌───────────────────────────────────────────────┐
│ MODIFIERS / SAFETY                             │
├─────────────┬─────────────────────────────────┤
│ N           │ Nullglob (empty if no match)     │
│ D           │ Include dotfiles                 │
│ ^           │ Negate match                     │
│ ~           │ Exclude pattern                  │
│ #           │ Repetition (one or more)         │
│ ##          │ Repetition (two or more)         │
│ (e:'expr:') │ Expression filter using $REPLY   │
└─────────────┴─────────────────────────────────┘

┌───────────────────────────────────────────────┐
│ EXAMPLE COMBINATIONS                          │
├─────────────┬─────────────────────────────────┤
│ **/*(.D)     │ All regular files including hidden recursively │
│ **/*.txt(.N) │ All .txt files, nullglob enabled                  │
│ *(~README~LICENSE) │ All except README & LICENSE                    │
│ (foo|bar)#  │ One or more foo/bar repetitions                  │
│ *(e:'[[ -x $REPLY ]]':) │ Executable files only                       │
│ **/*(/Om)   │ All directories recursively, sorted by mtime      │
└─────────────┴─────────────────────────────────┘


| Pattern                   | Recursion | Qualifier | Modifier | Sorting | Expression | Description                                 |                           |
| ------------------------- | --------- | --------- | -------- | ------- | ---------- | ------------------------------------------- | ------------------------- |
| `*`                       | None      | None      | None     | None    | None       | Any string, including empty                 |                           |
| `?`                       | None      | None      | None     | None    | None       | Any single character                        |                           |
| `[abc]`                   | None      | None      | None     | None    | None       | Character set                               |                           |
| `[!abc]`                  | None      | None      | None     | None    | None       | Negated character set                       |                           |
| `[a-z]`                   | None      | None      | None     | None    | None       | Character range                             |                           |
| `**`                      | Recursive | None      | None     | None    | None       | Any directory recursively                   |                           |
| `**/*`                    | Recursive | None      | None     | None    | None       | All files recursively                       |                           |
| `**/*(.)`                 | Recursive | `.`       | None     | None    | None       | All regular files recursively               |                           |
| `**/*(/)`                 | Recursive | `/`       | None     | None    | None       | All directories recursively                 |                           |
| `**/*(@)`                 | Recursive | `@`       | None     | None    | None       | All symlinks recursively                    |                           |
| `*(D)`                    | None      | `D`       | None     | None    | None       | Include dotfiles                            |                           |
| `*(.)`                    | None      | `.`       | None     | None    | None       | Regular files only                          |                           |
| `*(/)`                    | None      | `/`       | None     | None    | None       | Directories only                            |                           |
| `*(e:'[[ -x $REPLY ]]':)` | None      | `.`       | None     | None    | Expression | Executable files only                       |                           |
| `*(Om)`                   | None      | None      | `O`      | `m`     | None       | Sorted by modification time                 |                           |
| `*(On)`                   | None      | None      | `O`      | `n`     | None       | Numeric sort                                |                           |
| `pattern~exclude`         | None      | None      | None     | None    | None       | Exclude pattern                             |                           |
| \`(foo                    | bar)\`    | None      | None     | None    | None       | None                                        | Alternatives (foo or bar) |
| \`(foo                    | bar)#\`   | None      | None     | None    | None       | None                                        | One or more repetitions   |
| \`(foo                    | bar)##\`  | None      | None     | None    | None       | Two or more repetitions                     |                           |
| `*(#i)`                   | None      | None      | `#i`     | None    | None       | Case-insensitive                            |                           |
| `^pattern`                | None      | None      | `^`      | None    | None       | Negate match                                |                           |
| `*(N)`                    | None      | None      | `N`      | None    | None       | Nullglob enabled (return empty if no match) |                           |
