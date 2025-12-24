# AI Training Framework Setup

**Professional, modular Python framework for setting up PyTorch + CUDA 13 + LoRA/QLoRA training environments**

## 🎯 What This Does

Sets up a complete AI training environment with:
- ✅ PyTorch compiled with CUDA 13
- ✅ 5 separate Python environments (training, tuning, experiments, runtime, testing)
- ✅ LoRA/QLoRA fine-tuning support
- ✅ System memory optimization
- ✅ Jupyter Lab integration
- ✅ Ready-to-use training templates
- ✅ Works on all major Linux distros (Debian, Ubuntu, Fedora, Arch, Alpine)

## 📁 Project Structure

```
pytorch-setup/
├── main.py                      # Run this!
├── .frameworkrc                 # Optional config overrides
│
├── core/                        # EDIT THESE FOR CHANGES
│   ├── config.py               # Versions, paths, settings
│   ├── paths.py                # Directory structure
│   ├── types.py                # Type definitions
│   ├── packages.py             # Package lists
│   └── logic.py                # Orchestration
│
├── src/                         # DON'T TOUCH (unless extending)
│   ├── helpers.py              # Logging utilities
│   ├── handlers.py             # Error handling
│   ├── utils.py                # System operations
│   ├── validators.py           # Pre-flight checks
│   └── generate.py             # Template generation
│
├── templates/                   # AUTO-GENERATED
│   ├── lora_training.py
│   ├── qlora_training.py
│   └── inference.py
│
├── docs/                        # AUTO-GENERATED
│   ├── COMMANDS.md
│   └── ARCHITECTURE.md
│
└── logs/
    └── setup-TIMESTAMP.log
```

## 🚀 Quick Start

### 1. Deploy the Framework

```bash
# Create directory structure
mkdir -p $HOME/WORKSPACE/ai/frameworks/setup-pytorch/core
mkdir -p $HOME/WORKSPACE/ai/frameworks/setup-pytorch/src

# Copy all Python files to their locations:
# - main.py → $HOME/WORKSPACE/ai/frameworks/setup-pytorch/
# - core/*.py → $HOME/WORKSPACE/ai/frameworks/setup-pytorch/core/
# - src/*.py → $HOME/WORKSPACE/ai/frameworks/setup-pytorch/src/
```

### 2. Run Setup

```bash
cd $HOME/WORKSPACE/ai/frameworks/setup-pytorch
python3 main.py
```

**Interactive mode** - Prompts for confirmation at each step

### 3. Force Mode (No Prompts)

```bash
python3 main.py --force
```

### 4. Dry Run (Test Without Changes)

```bash
python3 main.py --dry-run
```

### 5. Resume from Failure

```bash
python3 main.py --resume
```

## ⚙️ Configuration

### Quick Config Changes

Edit `core/config.py`:

```python
# Change Python version
self.PYTHON_VERSION = "3.12"

# Change CUDA version
self.CUDA_VERSION = "13.0"

# Skip PyTorch build if already compiled
self.SKIP_PYTORCH_BUILD = True

# Disable Jupyter
self.JUPYTER_ENABLE = False

# Change batch size
self.TRAIN_BATCH_SIZE = 8
```

### Advanced: Override with .frameworkrc

Create `.frameworkrc` in framework root:

```yaml
python_version: "3.12"
cuda_version: "13.0"
skip_pytorch_build: true
jupyter_port: 9999
max_jobs: 8
```

## 🎨 Features

### ✅ Cross-Distro Support

Automatically detects and uses:
- **Debian/Ubuntu** → `apt`
- **Fedora/RHEL/CentOS** → `dnf`
- **Arch Linux** → `pacman`
- **Alpine** → `apk`

### ✅ Smart Package Management

All packages defined in `core/packages.py`:
- System packages (build tools, CUDA, etc.)
- Python packages (PyTorch, transformers, PEFT, etc.)
- Distro-specific name mappings

### ✅ Memory Optimization

Automatically configures:
- Swap settings
- Huge pages (16GB)
- Cache pressure
- Memory overcommit

### ✅ Error Handling

- **Checkpointing** - Resume from where it failed
- **Rollback** - Undo partial changes
- **Graceful interrupts** - Ctrl+C saves state
- **Detailed logging** - Everything logged to file

### ✅ Template Generation

Creates ready-to-use scripts:
- `lora_training.py` - Standard LoRA fine-tuning
- `qlora_training.py` - 4-bit quantized training
- `inference.py` - Model inference
- `activate.zsh` - Environment switcher

## 📚 After Setup

### Activate Environments

```bash
source activate.zsh
activate-training    # For training
activate-tuning      # For fine-tuning experiments
activate-runtime     # For production inference
```

### Start Training

```bash
activate-training
cd templates/
python3 lora_training.py
```

### Start Jupyter Lab

```bash
activate-training
jupyter lab --port 8888
```

### Read Documentation

```bash
cat docs/COMMANDS.md        # All commands
cat docs/ARCHITECTURE.md    # How to modify framework
```

## 🔧 Customization Examples

### Add New Environment

Edit `core/config.py`:

```python
self.VENVS = {
    "pytorch-training": "Training with LoRA/QLoRA",
    "pytorch-research": "Custom research env",  # NEW
}
```

Run: `python3 main.py --force`

### Add New Package

Edit `core/packages.py`:

```python
"flash-attn": Package(
    name="flash-attn",
    description="Flash Attention"
),
```

Run: `python3 main.py --force`

### Change Paths

Edit `core/paths.py`:

```python
"pytorch_source": Path("/custom/path/pytorch"),
```

## 📊 System Requirements

**Minimum:**
- 8GB RAM
- 50GB disk space
- Python 3.8+
- NVIDIA GPU with 4GB+ VRAM (for GPU training)

**Recommended:**
- 32GB RAM (like your system!)
- 100GB+ disk space
- Python 3.11+
- GTX 1650 or better

## 🐛 Troubleshooting

### Setup fails during package install
```bash
# Check logs
tail -f logs/setup-*.log

# Resume
python3 main.py --resume
```

### CUDA not detected
```bash
# Verify CUDA
nvidia-smi
nvcc --version

# Set SKIP_CUDA_CHECK in config.py
```

### PyTorch build fails
```bash
# Skip build (use pip PyTorch)
# Edit core/config.py:
self.SKIP_PYTORCH_BUILD = True

# Re-run
python3 main.py --force
```

### Out of disk space
```bash
# Clean up
rm -rf /tmp/*
apt clean
```

## 📝 Logs

All operations logged to:
```
logs/setup-YYYYMMDD_HHMMSS.log
```

Checkpoint saved to:
```
logs/.last_checkpoint
```

## 🎯 Your System

**Detected:**
- CPU: AMD Ryzen 5 3550H (8 threads)
- RAM: 32GB DDR4
- GPU: GTX 1650 (4GB VRAM)
- Storage: 1TB NVMe SSD
- OS: Debian 13 (Trixie)

**Optimized for:**
- 4GB VRAM → QLoRA recommended
- 32GB RAM → Excellent for CPU offloading
- Fast NVMe → Quick model loading

## 🚀 Next Steps

1. **Deploy** - Copy all files to `$HOME/WORKSPACE/ai/frameworks/setup-pytorch/`
2. **Run** - `python3 main.py`
3. **Train** - Use templates in `templates/`
4. **Monitor** - Check `docs/COMMANDS.md`

---

**Made for flexibility. Edit `core/` files, never touch `src/` files.**