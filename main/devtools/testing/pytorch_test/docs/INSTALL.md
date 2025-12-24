# AI Training Framework - Installation Guide

Complete guide to deploy and run the framework on your Debian 13 system.

## 📋 Prerequisites

### System Requirements
- ✅ 32GB RAM (you have this)
- ✅ GTX 1650 4GB VRAM (you have this)
- ✅ 1TB NVMe SSD (you have this)
- ✅ Debian 13 (Trixie) (you have this)
- ✅ CUDA 12.4 drivers installed (you have this)

### Software Requirements
- Python 3.11+
- Git
- sudo access
- Internet connection

---

## 🚀 Installation Methods

### Method 1: Manual Deployment (Recommended for Claude)

Since you're getting these files from Claude, save each artifact individually:

#### Step 1: Create Directory Structure

```bash
mkdir -p $HOME/WORKSPACE/ai/setup/framework/pytorch/{core,src,templates,docs,logs}
cd $HOME/WORKSPACE/ai/setup/framework/pytorch
```

#### Step 2: Save Main Entry Point

Create `main.py`:
```bash
nano main.py
```
Paste the content from the "Framework Setup - main.py" artifact, save and exit.

#### Step 3: Save Core Modules

```bash
cd core

# Save each core module
nano config.py      # Paste "Core Config - core/config.py"
nano paths.py       # Paste "Core Paths - core/paths.py"
nano types.py       # Paste "Core Types - core/types.py"
nano packages.py    # Paste "Core Packages - core/packages.py"
nano logic.py       # Paste "Core Logic - core/logic.py"

cd ..
```

#### Step 4: Save Source Modules

```bash
cd src

# Save each source module
nano helpers.py     # Paste "Helpers - src/helpers.py"
nano handlers.py    # Paste "Handlers - src/handlers.py"
nano validators.py  # Paste "Validators - src/validators.py"
nano utils.py       # Paste "Utils - src/utils.py"
nano generate.py    # Paste "Generate - src/generate.py"

cd ..
```

#### Step 5: Create Python Package Markers

```bash
touch __init__.py
touch core/__init__.py
touch src/__init__.py
```

#### Step 6: Make Main Executable

```bash
chmod +x main.py
```

#### Step 7: Verify Structure

```bash
tree $HOME/WORKSPACE/ai/setup/framework/pytorch
```

Expected output:
```
$HOME/WORKSPACE/ai/setup/framework/pytorch/
├── main.py
├── __init__.py
├── core/
│   ├── __init__.py
│   ├── config.py
│   ├── paths.py
│   ├── types.py
│   ├── packages.py
│   └── logic.py
├── src/
│   ├── __init__.py
│   ├── helpers.py
│   ├── handlers.py
│   ├── validators.py
│   ├── utils.py
│   └── generate.py
├── templates/
├── docs/
└── logs/
```

---

### Method 2: Using Deployment Script

If you have all files in a directory:

```bash
# Make deploy script executable
chmod +x deploy.sh

# Run deployment
./deploy.sh
```

---

## ⚙️ Configuration (Before Running)

### Step 1: Edit Core Configuration

```bash
nano $HOME/WORKSPACE/ai/setup/framework/pytorch/core/config.py
```

**Key settings to verify:**

```python
# Line 20-23: Versions
self.PYTHON_VERSION = "3.11"  # ✓ Good for Debian 13
self.CUDA_VERSION = "13.0"    # Change to "12.4" if you want to use existing
self.PYTORCH_VERSION = "2.5.1"

# Line 62-65: Build settings
self.SKIP_CUDA_CHECK = False       # Set to True if CUDA already working
self.SKIP_PYTORCH_BUILD = True     # Set to True if you already compiled PyTorch
self.MAX_JOBS = 4                  # Safe for GTX 1650

# Line 52: Jupyter
self.JUPYTER_ENABLE = True         # Set to False if you don't want Jupyter
self.JUPYTER_PORT = 8888
```

### Step 2: Install Python Dependencies

The framework needs these Python packages to run itself:

```bash
pip3 install pyyaml
```

---

## 🎬 Running the Setup

### Interactive Mode (Recommended First Time)

```bash
cd $HOME/WORKSPACE/ai/setup/framework/pytorch
python3 main.py
```

**What happens:**
1. System validation (checks RAM, disk, GPU)
2. Prompts before each major step
3. Updates package manager
4. Installs system packages
5. Configures memory
6. Verifies CUDA
7. Creates 5 virtual environments
8. Installs Python packages in each environment
9. Sets up Jupyter Lab
10. Generates training templates
11. Creates documentation

**Expected duration:** 20-40 minutes (without PyTorch build)

### Force Mode (No Prompts)

```bash
python3 main.py --force
```

Use this if you've already reviewed the configuration and want it to run unattended.

### Dry Run Mode (Test Without Changes)

```bash
python3 main.py --dry-run
```

Shows what would happen without actually doing it. Great for testing.

### With Custom Log File

```bash
python3 main.py --log /path/to/custom.log
```

### Verbose Output

```bash
python3 main.py --verbose
```

---

## 📝 Monitoring the Setup

### Watch Progress

The setup shows colored output:
- 🔵 **BLUE** - Phase headers
- 🟢 **GREEN** - Success messages
- 🟡 **YELLOW** - Warnings
- 🔴 **RED** - Errors
- 🟦 **CYAN** - Info messages

### Check Logs

```bash
# Real-time log monitoring (in another terminal)
tail -f $HOME/WORKSPACE/ai/setup/framework/pytorch/logs/setup-*.log
```

### Check System Resources

```bash
# GPU usage
watch -n 1 nvidia-smi

# RAM usage
watch -n 1 free -h

# Disk space
df -h /
```

---

## 🛠️ Post-Installation

### Step 1: Verify Installation

```bash
cd $HOME/WORKSPACE/ai/setup/framework/pytorch

# Check environments created
ls -la $HOME/WORKSPACE/ai/environments/

# Expected:
# pytorch-training/
# pytorch-tuning/
# pytorch-experiments/
# pytorch-runtime/
# pytorch-testing/
```

### Step 2: Test Environment Activation

```bash
# Source activation script
source activate.zsh

# Try activating an environment
activate-training

# Verify PyTorch
python3 -c "import torch; print(f'PyTorch: {torch.__version__}'); print(f'CUDA: {torch.cuda.is_available()}')"

# Expected output:
# PyTorch: 2.5.1+cu130 (or similar)
# CUDA: True
```

### Step 3: Test Training Template

```bash
activate-training
cd templates/

# Edit the template
nano lora_training.py
# Change model_name and dataset_name to your actual values

# Run a test (won't actually train without data)
python3 lora_training.py
```

### Step 4: Start Jupyter Lab (Optional)

```bash
activate-training
jupyter lab --port 8888 --no-browser --ip=0.0.0.0
```

Access at: `http://192.168.12.66:8888`

---

## 📚 Generated Documentation

After setup completes, you'll have:

```bash
# Command reference
cat $HOME/WORKSPACE/ai/setup/framework/pytorch/docs/COMMANDS.md

# Architecture guide
cat $HOME/WORKSPACE/ai/setup/framework/pytorch/docs/ARCHITECTURE.md
```

---

## ❌ Troubleshooting

### Setup Fails: "Permission Denied"

```bash
# Run as root or with sudo
sudo python3 main.py
```

### Setup Fails: "Package not found"

```bash
# Update package manager first
sudo apt update

# Retry
python3 main.py --resume
```

### Setup Fails: "Out of disk space"

```bash
# Check space
df -h /

# Clean up
sudo apt clean
rm -rf /tmp/*

# Retry
python3 main.py --resume
```

### Setup Interrupted (Ctrl+C)

```bash
# Resume from checkpoint
python3 main.py --resume
```

### CUDA Not Detected

```bash
# Verify CUDA
nvidia-smi
nvcc --version

# If working, skip CUDA check in config
nano core/config.py
# Set: self.SKIP_CUDA_CHECK = True

# Retry
python3 main.py --force
```

### PyTorch Build Fails

```bash
# Skip building, use pip version
nano core/config.py
# Set: self.SKIP_PYTORCH_BUILD = True

# Retry
python3 main.py --force
```

### Import Errors After Setup

```bash
# Ensure you're in activated environment
source activate.zsh
activate-training

# Reinstall packages
pip install --force-reinstall torch transformers peft
```

---

## 🔄 Re-running Setup

### To Update Configuration

1. Edit `core/config.py`
2. Run: `python3 main.py --force`

### To Add New Packages

1. Edit `core/packages.py`
2. Run: `python3 main.py --force`

### To Recreate Everything

```bash
# Remove old environments
rm -rf $HOME/WORKSPACE/ai/environments/*

# Run fresh setup
python3 main.py --force
```

---

## ✅ Verification Checklist

After installation, verify:

- [ ] All 5 environments created in `$HOME/$WORKSPACE/ai/environments/`
- [ ] `activate.zsh` exists and works
- [ ] Templates created in `templates/`
- [ ] Documentation generated in `docs/`
- [ ] PyTorch imports successfully
- [ ] CUDA available in PyTorch
- [ ] Jupyter Lab starts (if enabled)
- [ ] `nvidia-smi` shows GPU

---

## 🎯 Next Steps

1. **Read COMMANDS.md** - Learn all available commands
2. **Prepare your dataset** - Get data ready for training
3. **Customize templates** - Edit training scripts for your needs
4. **Start training!** - Run your first LoRA fine-tune

---

## 📞 Support

If you encounter issues:

1. Check logs: `logs/setup-*.log`
2. Check checkpoint: `logs/.last_checkpoint`
3. Run with verbose: `python3 main.py --verbose`
4. Review error messages and search for solutions

---

**Your System Specs:**
- CPU: AMD Ryzen 5 3550H (8 threads)
- RAM: 32GB DDR4 @ 2400MHz
- GPU: GTX 1650 Mobile (4GB VRAM)
- Storage: 1TB Micron NVMe SSD
- OS: Debian 13 (Trixie)
- Kernel: 6.12.48

**Recommended Training Settings:**
- QLoRA (4-bit) for 7B models
- Batch size: 4
- Gradient accumulation: 8
- Max sequence length: 1024