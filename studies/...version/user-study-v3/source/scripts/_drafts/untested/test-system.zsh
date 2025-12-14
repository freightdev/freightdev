#!/usr/bin/env zsh
# systest.zsh  ── incremental health‑check logger for Arch / Lenovo

set -euo pipefail


SYSCHK=${SYSCHK:-$(dirname $0)/syscheck.zsh}   # path to main probe
LOGDIR=${LOGDIR:-$HOME/devbelt/workspace/tmp/syscheck}              # where logs live
F_PAT='(missing|failed|failure|refused|error)'  # grep filter


[[ $EUID -eq 0 ]] && { print -P "%F{red}✖  Run this **without** sudo.%f"; exit 2 }

[[ -x $SYSCHK ]] || { print -P "%F{red}✖  Cannot find executable syscheck.zsh at $SYSCHK%f"; exit 2 }

mkdir -p "$LOGDIR"
NOW=$(date +'%Y-%m-%d_%H%M')
CUR="$LOGDIR/$NOW.log"
PREV="$LOGDIR/last.log"

$SYSCHK > "$CUR"

print -P "%F{cyan}\n••• New run logged to $CUR •••%f"

grep -Ei "$F_PAT" "$CUR" || print -P "%F{green}✓  No error keywords detected.%f"

if [[ -f $PREV ]]; then
  DIFF=$(diff --color=always -u "$PREV" "$CUR" || true)
  if [[ -n $DIFF ]]; then
    print -P "%F{yellow}\n••• Changes since last run •••%f"
    print -- "$DIFF"
    CHANGED=1
  else
    print -P "%F{green}\n✓  No changes since previous run.$%f"
    CHANGED=0
  fi
else
  print -P "%F{magenta}\n(first run - nothing to diff yet)%f"
  CHANGED=0
fi

ln -sf "$(basename "$CUR")" "$PREV"  # update 'last.log' symlink

exit $CHANGED
