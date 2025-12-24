# 🗑️ ZBOX Trash Bin System

## Overview
Safe file deletion with full restore capability. Files moved to trash instead of permanently deleted.

**Location**: `~/.local/share/Trash/`

## Quick Commands

### Delete Files (Move to Trash)
```bash
trash file.txt                    # Move single file
trash *.log                       # Move multiple files
del myfile.txt                    # Alias for trash
```

### List Trash Contents
```bash
trash -l                          # Full listing
lstrash                           # Alias
```

### Restore Files
```bash
trash -r filename                 # Restore by name
undel filename                    # Alias
```

### Empty Trash (Permanent Delete)
```bash
trash -e                          # Asks for confirmation
emptytrash                        # Alias
```

### Help
```bash
trash -h                          # Show help
```

## Features

✅ **Metadata Tracking**
- Original file path stored
- Deletion timestamp recorded
- Easy restoration to original location

✅ **Smart Restore**
- Restores to original path
- Handles missing directories
- Prevents accidental overwrites
- Interactive prompts for conflicts

✅ **Timestamped Names**
- Files renamed with timestamp: `file.txt.20251122_194527`
- Prevents naming conflicts
- Multiple versions of same filename

✅ **Safety**
- Confirmation before permanent deletion
- Interactive mode for overwrites
- Preserves file permissions

## Configuration

### Auto-Trash on rm (Optional)
Edit `~/.env.d/config/defaults/aliases.zsh`:

```bash
# Uncomment this line to make 'rm' use trash by default
alias rm='trash'
```

Then reload:
```bash
ZBOX_FORCE_RELOAD=1 zsh
```

### Trash Directory Structure
```
~/.local/share/Trash/
├── files/              # Actual trashed files
└── info/               # Metadata (.trashinfo files)
```

## Examples

### Example 1: Accidental Delete → Restore
```bash
$ trash important-file.txt
Moved to trash: important-file.txt → important-file.txt.20251122_143022

$ lstrash
📄 important-file.txt.20251122_143022
   Original: /home/admin/important-file.txt
   Deleted:  2025-11-22T14:30:22

$ undel important-file.txt
✓ Restored: /home/admin/important-file.txt
```

### Example 2: Clean Up Old Logs
```bash
$ trash *.log
Moved to trash: app.log → app.log.20251122_150000
Moved to trash: error.log → error.log.20251122_150000

$ lstrash
# Review what was deleted...

$ emptytrash
⚠️  WARNING: This will permanently delete all files in trash!
Continue? (yes/no)
> yes
✓ Trash emptied
```

## Implementation
- **Source**: `~/.env.d/source/helpers/trash.zsh`
- **Aliases**: `~/.env.d/config/defaults/aliases.zsh`

## Notes
- Trash is user-specific (not system-wide)
- Works with files and directories
- Follows XDG Base Directory specification
- Metadata format compatible with freedesktop.org Trash spec

## Safety Tips
1. Always use `trash` instead of `rm` for recoverable deletion
2. Periodically review trash with `lstrash`
3. Empty trash when confident files aren't needed
4. Enable `alias rm='trash'` for extra protection
