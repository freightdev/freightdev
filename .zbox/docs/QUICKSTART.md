# zBox Quick Start Guide

## Installation Complete! ✅

Your zBox environment is now set up and ready to use.

## Quick Test

```bash
# Open a new terminal or reload your shell
exec zsh

# Or force reload current shell
ZBOX_FORCE_RELOAD=1 zsh
```

## Verify Everything Works

```bash
# Check zBox is loaded
echo $ZBOX_DIR        # Should show: /home/admin/.zbox
echo $ZBOX_READY      # Should show: 1

# Check what's loaded
echo $ZBOX_CURRENT_PROFILE      # Should show: workspace
echo $ZBOXXY_DIR                # Should show: /home/admin/.zbox/.ai/agents/zboxxy
```

## Essential Commands

### Profile Management
```bash
# List all profiles
zbox_list_profiles

# Show current profile info
zbox_profile_info

# Switch profiles
zbox_switch_profile <profile-name>

# Load specific profile
ZBOX_PROFILE=my-profile zsh
```

### Trash System (Safe Delete)
```bash
# Delete files safely
trash myfile.txt

# List what's in trash
trash -l

# Restore a file
trash -r myfile.txt

# Empty trash
trash -e
```

### Reload & Debug
```bash
# Force reload everything
ZBOX_FORCE_RELOAD=1 zsh

# Enable debug mode
ZBOX_DEBUG=1 zsh

# Both at once
ZBOX_FORCE_RELOAD=1 ZBOX_DEBUG=1 zsh
```

## Directory Quick Reference

```
~/.zbox/
├── .ai/agents/zboxxy/    # zBoxxy routing agent
├── apps/                  # Your applications
├── config/                # Shell configuration
├── profiles/              # Environment profiles
│   └── workspace/        # Default profile
├── source/                # Functions & helpers
├── tools/                 # Utility tools
└── main.zsh              # Master loader
```

## Helpful Variables

```bash
# Core paths
$ZBOX_DIR          # /home/admin/.zbox
$ZBOX_CFG          # /home/admin/.zbox/config
$ZBOX_SRC          # /home/admin/.zbox/source
$ZBOX_PROFILES     # /home/admin/.zbox/profiles

# Current state
$ZBOX_CURRENT_PROFILE    # Active profile name
$ZBOX_READY              # 1 when loaded
$ZBOX_FUNCTIONS_LOADED   # Timestamp
```

## Next Steps

1. **Explore your profile**:
   ```bash
   cat $ZBOX_PROFILES/workspace/manifest.yaml
   ```

2. **Try helper functions**:
   ```bash
   # These should be available:
   scana    # Scan and analyze
   finda    # Find files
   senda    # Send/transfer
   serva    # Server ops
   ```

3. **Create a custom profile**:
   ```bash
   # Copy the base template
   mkdir -p ~/.zbox/profiles/my-profile
   cp ~/.zbox/profiles/manifest.base.yaml ~/.zbox/profiles/my-profile/manifest.yaml

   # Edit it
   nano ~/.zbox/profiles/my-profile/manifest.yaml

   # Load it
   ZBOX_PROFILE=my-profile zsh
   ```

4. **Read the full docs**:
   ```bash
   less ~/.zbox/README.md
   less ~/.zbox/.ai/agents/zboxxy/README.md
   ```

## Common Tasks

### Adding a New Function

1. Create file in `~/.zbox/source/helpers/myfunction.zsh`
2. Add your function
3. Reload: `ZBOX_FORCE_RELOAD=1 zsh`

### Customizing Your Profile

1. Edit: `~/.zbox/profiles/workspace/manifest.yaml`
2. Add configs to: `~/.zbox/profiles/workspace/config/`
3. Reload: `ZBOX_FORCE_RELOAD=1 zsh`

### Adding an Alias

Edit `~/.zbox/config/defaults/aliases.zsh`:
```bash
alias myalias='echo "Hello from zBox!"'
```

Then reload: `ZBOX_FORCE_RELOAD=1 zsh`

## Troubleshooting

### "Command not found"
```bash
# Reload environment
ZBOX_FORCE_RELOAD=1 zsh

# Check functions loaded
echo $ZBOX_FUNCTIONS_LOADED
```

### "Manifest not loading"
```bash
# Check manifest exists
ls -la $ZBOX_PROFILES/$ZBOX_PROFILE/manifest.yaml

# Manually load
zbox_load_manifest workspace
```

### Need Help?
```bash
# Check the README
less ~/.zbox/README.md

# Check zBoxxy docs
less ~/.zbox/.ai/agents/zboxxy/README.md
```

## Performance Tips

- Normal startup: ~10-20ms (cached)
- First load: ~100-200ms (loads everything)
- Use `ZBOX_FORCE_RELOAD=1` only when needed

## What's Next?

The foundation is complete! Next up:
- zBoxxy routing logic implementation
- TUI interface in Rust
- Agent isolation enforcement
- Multi-agent communication

---

**Welcome to zBox! 🎉**

Built by Jesse E.E.W. Conley over 1+ years
