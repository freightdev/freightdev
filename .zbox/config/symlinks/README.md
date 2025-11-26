# zBox Shell Initialization Files

These files are symlinked to `$HOME` to initialize zBox in all shell types.

## File Purposes

### `.zshenv` ✅ **MAIN LOADER**
- **When**: Sourced for ALL shell types (interactive, login, non-interactive, scripts)
- **Purpose**: Loads the zBox environment (`main.zsh`)
- **Use for**: Environment variables, PATH, core initialization
- **Symlink**: `~/.zshenv -> ~/.zbox/config/symlinks/.zshenv`

### `.zprofile`
- **When**: Sourced for LOGIN shells only
- **Purpose**: Login-specific setup (PATH additions, etc.)
- **Use for**: Commands that should run once at login
- **Symlink**: `~/.zprofile -> ~/.zbox/config/symlinks/.zprofile`

### `.zshrc`
- **When**: Sourced for INTERACTIVE shells only
- **Purpose**: Interactive shell customizations
- **Use for**: Aliases, prompts, keybindings, interactive functions
- **Symlink**: `~/.zshrc -> ~/.zbox/config/symlinks/.zshrc`

## zsh Initialization Order

### Non-Interactive Shell (scripts)
```
1. .zshenv  ✅ Loads zBox
```

### Interactive Non-Login Shell (new terminal)
```
1. .zshenv  ✅ Loads zBox
2. .zshrc   (interactive customizations)
```

### Interactive Login Shell (ssh, login)
```
1. .zshenv   ✅ Loads zBox
2. .zprofile (login setup)
3. .zshrc    (interactive customizations)
```

## Why `.zshenv` Loads zBox

We load zBox in `.zshenv` because:

1. ✅ **Available everywhere** - Works in scripts, cron jobs, interactive shells
2. ✅ **No duplication** - Only loaded once, regardless of shell type
3. ✅ **Conditional loading** - zBox's built-in guards prevent double-loading
4. ✅ **Fast** - Lazy loading means minimal performance impact

## Creating the Symlinks

```bash
cd ~
ln -sf .zbox/config/symlinks/.zshenv .zshenv
ln -sf .zbox/config/symlinks/.zprofile .zprofile
ln -sf .zbox/config/symlinks/.zshrc .zshrc
```

## Verification

```bash
# Check symlinks exist
ls -la ~/.zshenv ~/.zprofile ~/.zshrc

# Test non-interactive shell
zsh -c 'echo $ZBOX_DIR'

# Test login shell
zsh -l -c 'echo $ZBOX_DIR'

# Test interactive shell
zsh -i -c 'echo $ZBOX_DIR'
```

All three should show: `/home/admin/.zbox`

## Customization

### For ALL shell types
Edit: `~/.zbox/config/symlinks/.zshenv`
```bash
# Add environment variables, PATH, etc.
export MY_VAR="value"
```

### For LOGIN shells only
Edit: `~/.zbox/config/symlinks/.zprofile`
```bash
# Add login-specific commands
```

### For INTERACTIVE shells only
Edit: `~/.zbox/config/symlinks/.zshrc`
```bash
# Add aliases, prompts, etc.
alias myalias='command'
```

## Important Notes

1. **Don't load zBox twice**: `.zshenv` already loads it, so `.zshrc` and `.zprofile` don't need to
2. **Use zBox's conditional loading**: The `ZBOX_FUNCTIONS_LOADED` guard prevents re-sourcing
3. **Keep these files minimal**: Most config should go in `~/.zbox/config/` directories
4. **These files are managed by zBox**: Don't edit the symlink targets directly

## Troubleshooting

### "zBox not loading in scripts"
```bash
# Check .zshenv sources main.zsh
cat ~/.zshenv

# Should contain:
# . "${HOME}/.zbox/main.zsh"
```

### "Variables not set in new terminals"
```bash
# Check symlink is correct
ls -la ~/.zshenv

# Should point to .zbox/config/symlinks/.zshenv
```

### "Double loading errors"
```bash
# Check zBox's conditional loading
echo $ZBOX_FUNCTIONS_LOADED

# Should only load once, timestamp won't change
```

---

**Status**: Configured for all shell types ✅
**Loaded by**: `.zshenv` (all shells)
**Customizable via**: `.zshrc` (interactive), `.zprofile` (login)
