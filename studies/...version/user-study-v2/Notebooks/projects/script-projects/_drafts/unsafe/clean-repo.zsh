#!/usr/bin/env zsh

# clean-repo.zsh
# Cleans all common build, temp, binary, cache, log, and project clutter from a repo
# Usage:
#   ./clean-repo.zsh [--dry-run|-n] [/T <target_dir>] [<target_dir>]
# Examples:
#   ./clean-repo.zsh           # cleans current directory
#   ./clean-repo.zsh --dry-run # dry run, shows what would be deleted
#   ./clean-repo.zsh /T subdir # targets subdir

set -euo pipefail

############### PATTERNS TO CLEAN ###############
dir_patterns=(
  node_modules
  .next
  .turbo
  .parcel-cache
  .cache
  .coverage
  .nyc_output
  .pytest_cache
  .mypy_cache
  .tox
  .eggs
  .gradle
  .idea
  .vscode
  .DS_Store
  .appledouble
  .fseventsd
  .Spotlight-V100
  .Trash-*
  __pycache__
  dist
  build
  out
  target
  debug
  release
  coverage
  logs
  tmp
  temp
  log
  .sass-cache
  .eslintcache
  .nuxt
  .cache-loader
  .expo
  .expo-shared
  pip-wheel-metadata
  *.egg-info
  *.egg
  .pnp
  .pnp.js
  .yarn/cache
  .yarn/unplugged
  .yarn/build-state.yml
  .yarn/install-state.gz
)
file_patterns=(
  '*.o'
  '*.obj'
  '*.exe'
  '*.dll'
  '*.so'
  '*.dylib'
  '*.bin'
  '*.log'
  '*.tmp'
  '*.pyc'
  '*.class'
  '*.lock'
  '*.db'
  '*.pid'
  '*.seed'
  '*.pid.lock'
  '*.swo'
  '*.swp'
  '*.bak'
  '*.orig'
  '*.rej'
  '*.coverage'
  '*.prof'
  '*.gcda'
  '*.gcno'
  '*.map'
  '*.pdb'
  '*.env.local'
  '*.env.*.local'
  '.DS_Store'
)
# These are strictly files/dirs that can be safely removed before git push.
#################################################

################# ARGUMENTS #####################
DRY_RUN=0
TARGET_DIR="."
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run|-n)
      DRY_RUN=1
      shift
      ;;
    /T)
      TARGET_DIR="$2"
      shift 2
      ;;
    *)
      TARGET_DIR="$1"
      shift
      ;;
  esac
done
#################################################

if [[ ! -d "$TARGET_DIR" ]]; then
  echo "❌ Target directory '$TARGET_DIR' does not exist."
  exit 1
fi

cd "$TARGET_DIR"

################## COLLECT ITEMS #################
typeset -a items

# Directories
for dp in "${dir_patterns[@]}"; do
  # If pattern contains * treat as glob, else literal
  if [[ "$dp" == *\** ]]; then
    items+=($(find . -type d -name "${dp}" -prune -print 2>/dev/null))
  else
    items+=($(find . -type d -name "${dp}" -prune -print 2>/dev/null))
  fi
done

# Files
for fp in "${file_patterns[@]}"; do
  items+=($(find . -type f -name "${fp}" -print 2>/dev/null))
done

# Deduplicate and sort
items=(${(u)items})

if [[ ${#items[@]} -eq 0 ]]; then
  echo "✔ No build artifacts or project clutter found."
  exit 0
fi

################## SHOW/DELETE ###################
total_bytes=0
echo "🧹 CleanRepo: The following items will be removed:"
for item in "${items[@]}"; do
  if [[ -d "$item" ]]; then
    size_bytes=$(du -sb "$item" | awk '{print $1}')
    size_human=$(du -sh "$item" | awk '{print $1}')
    printf "  [DIR]  %8s  %s\n" "$size_human" "$item"
  else
    size_bytes=$(stat -c%s "$item" 2>/dev/null || stat -f%z "$item")
    size_human=$(numfmt --to=iec --suffix=B $size_bytes 2>/dev/null || echo "$size_bytes"B)
    printf "  [FILE] %8s  %s\n" "$size_human" "$item"
  fi
  (( total_bytes += size_bytes ))
done

total_human=$(numfmt --to=iec --suffix=B $total_bytes 2>/dev/null || echo "$total_bytes"B)
echo "-----------------------------------------"
echo "Total size to be cleaned: $total_human"
echo "-----------------------------------------"

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "DRY RUN: No files or folders were deleted."
  exit 0
fi

read "REPLY?Proceed with deletion? [y/N]: "
if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 1
fi

for item in "${items[@]}"; do
  if [[ -d "$item" ]]; then
    rm -rf "$item"
  elif [[ -f "$item" ]]; then
    rm -f "$item"
  fi
done

echo "✔ Clean complete."
