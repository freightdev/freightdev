# AI Framework - Quick Start (TL;DR)

## 30-Second Setup

```bash
# 1. Create structure
mkdir -p $HOME/WORKSPACE/ai/setup/framework/pytorch/{core,src}
cd $HOME/WORKSPACE/ai/setup/framework/pytorch

# 2. Save all Python files from Claude artifacts to correct locations:
#    - main.py → here
#    - core/*.py → core/
#    - src/*.py → src/

# 3. Create package markers
touch __init__.py core/__init__.py src/__init__.py

# 4. Install PyYAML
pip3 install pyyaml

# 5. Run setup
python3 main.py --force
```

## File Locations

| File | Save To |
|------|---------|
| `main.py` | `$HOME/WORKSPACE/ai/setup/framework/pytorch/main.py` |
| `core/config.py` | `$HOME/WORKSPACE/ai/setup/framework/pytorch/core/config.py` |
| `core/paths.py` | `$HOME/WORKSPACE/ai/setup/framework/pytorch/core/paths.py` |
| `core/types.py` | `$HOME/WORKSPACE/ai/setup/framework/pytorch/core/types.py` |
| `core/packages.py` | `$HOME/WORKSPACE/ai/setup/framework/pytorch/core/packages.py` |
| `core/logic.py` | `$HOME/WORKSPACE/ai/setup/framework/pytorch/core/logic.py` |
| `src/helpers.py` | `$HOME/WORKSPACE/ai/setup/framework/pytorch/src/helpers.py` |
| `src/handlers.py` | `$HOME/WORKSPACE/ai/setup/framework/pytorch/src/handlers.py` |
| `src/validators.py` | `$HOME/WORKSPACE/ai/setup/framework/pytorch/src/validators.py` |
| `src/utils.py` | `$HOME/WORKSPACE/ai/setup/framework/pytorch/src/utils.py` |
| `src/generate.py` | `$HOME/WORKSPACE/ai/setup/framework/pytorch/src/generate.py` |

## After Setup

```bash
# Activate environment
source activate.zsh
activate-training

# Test PyTorch
python3 -c "import torch; print(torch.cuda.is_available())"

# Start Jupyter
jupyter lab --port 8888

# Read docs
cat docs/COMMANDS.md
```

## Common Commands

| Command | Purpose |
|---------|---------|
| `python3 main.py` | Interactive setup |
| `python3 main.py --force` | No prompts |
| `python3 main.py --dry-run` | Test run |
| `python3 main.py --resume` | Resume failed setup |
| `source activate.zsh` | Load environments |
| `activate-training` | Switch to training env |
| `activate-tuning` | Switch to tuning env |

## Quick Edits

**Change versions:**
```bash
nano core/config.py
# Edit lines 20-23 (PYTHON_VERSION, CUDA_VERSION, etc.)
```

**Skip PyTorch build:**
```bash
nano core/config.py
# Set: self.SKIP_PYTORCH_BUILD = True
```

**Add packages:**
```bash
nano core/packages.py
# Add to PYTHON_PACKAGES dict
```

## Structure at a Glance

```
framework/
├── main.py              # Run this
├── core/                # Edit these
│   ├── config.py       # ← Versions, settings
│   ├── paths.py        # ← Directory paths
│   ├── types.py
│   ├── packages.py     # ← Package lists
│   └── logic.py
├── src/                 # Don't edit
│   ├── helpers.py
│   ├── handlers.py
│   ├── validators.py
│   ├── utils.py
│   └── generate.py
├── templates/           # Generated
├── docs/                # Generated
└── logs/                # Logs here
```

## Troubleshooting One-Liners

```bash
# Permission issues
sudo python3 main.py

# Resume after failure
python3 main.py --resume

# Check logs
tail -f logs/setup-*.log

# Verify CUDA
nvidia-smi && nvcc --version

# Test environment
source activate.zsh && activate-training && python3 -c "import torch"

# Clean restart
rm -rf $HOME/WORKSPACE/ai/environments/* && python3 main.py --force
```

## Your System (Already Detected)

- ✅ GTX 1650 (4GB) → Use QLoRA
- ✅ 32GB RAM → Excellent
- ✅ Debian 13 → Supported
- ✅ CUDA 12.4 → Working

## Expected Duration

- Setup: ~30 minutes
- With PyTorch build: ~90 minutes

## Minimal Working Setup

If you just want to test immediately:

```bash
# 1. Create main.py ONLY
cd $HOME/WORKSPACE/ai/setup/framework/pytorch
nano main.py  # Paste from Claude

# 2. Create core/config.py ONLY
mkdir core
nano core/config.py  # Paste from Claude

# 3. Run dry-run to see what it would do
python3 main.py --dry-run
```

---

**That's it! Now go save those files and run it.** 🚀