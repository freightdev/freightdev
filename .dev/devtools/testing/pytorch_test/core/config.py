"""
Core Configuration Module
All hardcoded values and settings - EDIT THIS FOR INFRASTRUCTURE CHANGES
"""

from pathlib import Path
from typing import Dict, Any
import yaml
import os


class Config:
    """Configuration manager - single source of truth"""
    
    def __init__(self, config_dir: Path):
        self.config_dir = Path(config_dir)
        self.framework_root = Path.home() / "WORKSPACE" / "ai" / "setup" / "framework"
        self._load_defaults()
        self._load_overrides()
    
    def _load_defaults(self):
        """Load default configuration values"""
        
        # === CORE VERSIONS ===
        self.PYTHON_VERSION = "3.11"
        self.CUDA_VERSION = "13.0"
        self.PYTORCH_VERSION = "2.5.1"
        self.PYTORCH_COMMIT = "HEAD"  # or specific commit hash
        
        # === DIRECTORIES ===
        self.WORKSPACE_ROOT = Path.home() / "WORKSPACE" / "ai"
        self.FRAMEWORK_ROOT = self.WORKSPACE_ROOT / "setup" / "framework"
        self.PYTORCH_SOURCE = self.WORKSPACE_ROOT / "framework" / "pytorch"
        self.VENV_ROOT = self.WORKSPACE_ROOT / "environments"
        self.TEMPLATES_DIR = self.FRAMEWORK_ROOT / "templates"
        self.LOGS_DIR = self.FRAMEWORK_ROOT / "logs"
        self.DOCS_DIR = self.FRAMEWORK_ROOT / "docs"
        
        # === PYTHON ENVIRONMENTS ===
        self.VENVS = {
            "pytorch-training": "Training with LoRA/QLoRA",
            "pytorch-tuning": "Fine-tuning and experiments",
            "pytorch-experiments": "Research and prototyping",
            "pytorch-runtime": "Production inference",
            "pytorch-testing": "Unit and integration tests",
        }
        
        # === JUPYTER SETUP ===
        self.JUPYTER_PORT = 8888
        self.JUPYTER_PASSWORD = "auto"  # Set to auto-generate or specific password
        self.JUPYTER_ENABLE = True
        
        # === SYSTEM OPTIMIZATION ===
        self.SWAP_PERCENTAGE = 1
        self.VFS_CACHE_PRESSURE = 50
        self.DIRTY_RATIO = 80
        self.DIRTY_BACKGROUND_RATIO = 50
        self.MIN_FREE_KB = 1048576
        self.HUGEPAGES_GB = 16
        
        # === GPU/CUDA ===
        self.GPU_ARCH = "7.5"  # GTX 1650
        self.CUDA_HOME = Path("/usr/local/cuda-13.0")
        
        # === PACKAGE MANAGER ===
        self.AUTO_INSTALL_DEPS = True
        self.PACKAGE_MANAGER = self._detect_package_manager()
        
        # === PYTORCH BUILD ===
        self.USE_CUDA = True
        self.USE_CUDNN = True
        self.USE_MKLDNN = True
        self.MAX_JOBS = 4  # Conservative for GTX 1650
        self.BUILD_TEST = False
        self.USE_KINETO = True
        
        # === TRAINING DEFAULTS ===
        self.TRAIN_BATCH_SIZE = 4
        self.TRAIN_LEARNING_RATE = 2e-4
        self.TRAIN_EPOCHS = 3
        
        # === FLAGS ===
        self.SKIP_CUDA_CHECK = False
        self.SKIP_PYTORCH_BUILD = True  # Set to True if already compiled
        self.VERIFY_ONLY = False
    
    def _load_overrides(self):
        """Load overrides from .frameworkrc if exists"""
        rc_file = self.config_dir / ".frameworkrc"
        if rc_file.exists():
            try:
                with open(rc_file, 'r') as f:
                    overrides = yaml.safe_load(f) or {}
                    for key, value in overrides.items():
                        if hasattr(self, key.upper()):
                            setattr(self, key.upper(), value)
            except Exception as e:
                print(f"Warning: Could not load .frameworkrc: {e}")
    
    def _detect_package_manager(self) -> str:
        """Detect package manager for current distro"""
        if os.path.exists("/etc/debian_version"):
            return "apt"
        elif os.path.exists("/etc/fedora-release"):
            return "dnf"
        elif os.path.exists("/etc/arch-release"):
            return "pacman"
        elif os.path.exists("/etc/alpine-release"):
            return "apk"
        else:
            return "apt"  # Default fallback
    
    def get(self, key: str, default: Any = None) -> Any:
        """Get config value by key"""
        return getattr(self, key.upper(), default)
    
    def to_dict(self) -> Dict[str, Any]:
        """Export config as dictionary"""
        return {
            k: v for k, v in self.__dict__.items()
            if not k.startswith('_') and k.isupper()
        }
    
    def __repr__(self) -> str:
        return f"<Config: {self.PYTHON_VERSION} | CUDA {self.CUDA_VERSION} | PyTorch {self.PYTORCH_VERSION}>"