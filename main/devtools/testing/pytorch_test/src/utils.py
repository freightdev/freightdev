"""
System Utilities
System operations, package management, file operations
"""

import os
import subprocess
import shutil
from pathlib import Path
from typing import List, Optional, Dict

from core.packages import PackageRegistry
from core.types import PackageManager
from src.helpers import Logger, ProgressBar


class SystemUtils:
    """System utility functions"""
    
    def __init__(self, config, logger: Logger):
        self.config = config
        self.logger = logger
        self.pkg_registry = PackageRegistry()
    
    def update_package_manager(self) -> bool:
        """Update package manager"""
        pkg_mgr = self.config.PACKAGE_MANAGER
        
        commands = {
            'apt': ['apt-get', 'update'],
            'dnf': ['dnf', 'check-update'],
            'pacman': ['pacman', '-Sy'],
            'apk': ['apk', 'update'],
        }
        
        cmd = commands.get(pkg_mgr)
        if not cmd:
            self.logger.error(f"Unknown package manager: {pkg_mgr}")
            return False
        
        self.logger.command(' '.join(cmd))
        try:
            result = subprocess.run(
                ['sudo'] + cmd,
                capture_output=True,
                text=True
            )
            return result.returncode == 0
        except Exception as e:
            self.logger.error(f"Failed to update package manager: {e}")
            return False
    
    def install_system_packages(self) -> bool:
        """Install required system packages"""
        pkg_mgr_enum = PackageManager[self.config.PACKAGE_MANAGER.upper()]
        packages = self.pkg_registry.get_system_packages(pkg_mgr_enum, optional=False)
        
        if not packages:
            self.logger.warn("No packages to install")
            return True
        
        pkg_names = []
        for pkg in packages:
            mapped_name = self.pkg_registry.get_mapped_name(pkg.name, pkg_mgr_enum)
            pkg_names.append(mapped_name)
        
        self.logger.info(f"Installing {len(pkg_names)} system packages...")
        
        commands = {
            'apt': ['apt-get', 'install', '-y'],
            'dnf': ['dnf', 'install', '-y'],
            'pacman': ['pacman', '-S', '--noconfirm'],
            'apk': ['apk', 'add'],
        }
        
        base_cmd = commands.get(self.config.PACKAGE_MANAGER)
        if not base_cmd:
            return False
        
        cmd = ['sudo'] + base_cmd + pkg_names
        self.logger.command(' '.join(cmd))
        
        try:
            result = subprocess.run(cmd, capture_output=True, text=True)
            if result.returncode != 0:
                self.logger.error(f"Package installation failed:\n{result.stderr}")
                return False
            return True
        except Exception as e:
            self.logger.error(f"Failed to install packages: {e}")
            return False
    
    def configure_system_memory(self) -> bool:
        """Configure system memory settings"""
        sysctl_conf = "/etc/sysctl.d/99-training-memory.conf"
        
        config_content = f"""# Memory optimization for AI training
vm.swappiness = {self.config.SWAP_PERCENTAGE}
vm.vfs_cache_pressure = {self.config.VFS_CACHE_PRESSURE}
vm.dirty_ratio = {self.config.DIRTY_RATIO}
vm.dirty_background_ratio = {self.config.DIRTY_BACKGROUND_RATIO}
vm.min_free_kbytes = {self.config.MIN_FREE_KB}
vm.nr_hugepages = {(self.config.HUGEPAGES_GB * 1024) // 2}
vm.overcommit_memory = 1
vm.overcommit_ratio = 100
"""
        
        try:
            with open('/tmp/training-memory.conf', 'w') as f:
                f.write(config_content)
            
            subprocess.run(
                ['sudo', 'cp', '/tmp/training-memory.conf', sysctl_conf],
                check=True
            )
            subprocess.run(['sudo', 'sysctl', '-p', sysctl_conf], check=True)
            
            self.logger.success("✓ Memory settings configured")
            return True
        except Exception as e:
            self.logger.error(f"Failed to configure memory: {e}")
            return False
    
    def configure_cuda_environment(self) -> bool:
        """Configure CUDA environment variables"""
        cuda_home = self.config.CUDA_HOME
        
        bashrc_content = f"""
# CUDA Environment (added by AI Framework Setup)
export CUDA_HOME={cuda_home}
export PATH=$CUDA_HOME/bin:$PATH
export LD_LIBRARY_PATH=$CUDA_HOME/lib64:$LD_LIBRARY_PATH
"""
        
        bashrc_path = Path.home() / '.bashrc'
        
        try:
            # Check if already configured
            with open(bashrc_path, 'r') as f:
                content = f.read()
                if 'CUDA_HOME' in content and str(cuda_home) in content:
                    self.logger.info("CUDA environment already configured")
                    return True
            
            # Append configuration
            with open(bashrc_path, 'a') as f:
                f.write(bashrc_content)
            
            # Set for current session
            os.environ['CUDA_HOME'] = str(cuda_home)
            os.environ['PATH'] = f"{cuda_home}/bin:{os.environ.get('PATH', '')}"
            os.environ['LD_LIBRARY_PATH'] = f"{cuda_home}/lib64:{os.environ.get('LD_LIBRARY_PATH', '')}"
            
            self.logger.success("✓ CUDA environment configured")
            return True
        except Exception as e:
            self.logger.error(f"Failed to configure CUDA environment: {e}")
            return False
    
    def build_pytorch(self) -> bool:
        """Build PyTorch from source"""
        pytorch_src = self.config.PYTORCH_SOURCE
        
        if not pytorch_src.exists():
            self.logger.info("Cloning PyTorch repository...")
            try:
                subprocess.run(
                    ['git', 'clone', '--recursive', 'https://github.com/pytorch/pytorch', str(pytorch_src)],
                    check=True
                )
            except Exception as e:
                self.logger.error(f"Failed to clone PyTorch: {e}")
                return False
        
        os.chdir(pytorch_src)
        
        # Set build environment
        build_env = os.environ.copy()
        build_env.update({
            'TORCH_CUDA_ARCH_LIST': self.config.GPU_ARCH,
            'USE_CUDA': '1' if self.config.USE_CUDA else '0',
            'USE_CUDNN': '1' if self.config.USE_CUDNN else '0',
            'USE_MKLDNN': '1' if self.config.USE_MKLDNN else '0',
            'MAX_JOBS': str(self.config.MAX_JOBS),
            'BUILD_TEST': '0',
            'USE_KINETO': '1',
        })
        
        self.logger.info("Starting PyTorch build (this will take 40-60 minutes)...")
        self.logger.command("python3 setup.py develop")
        
        try:
            result = subprocess.run(
                ['python3', 'setup.py', 'develop'],
                env=build_env,
                capture_output=True,
                text=True
            )
            
            if result.returncode != 0:
                self.logger.error(f"PyTorch build failed:\n{result.stderr}")
                return False
            
            self.logger.success("✓ PyTorch built successfully")
            return True
        except Exception as e:
            self.logger.error(f"Build error: {e}")
            return False
    
    def create_venv(self, venv_path: Path, venv_name: str) -> bool:
        """Create Python virtual environment"""
        try:
            subprocess.run(
                ['python3', '-m', 'venv', str(venv_path)],
                check=True,
                capture_output=True
            )
            
            # Upgrade pip
            pip_path = venv_path / 'bin' / 'pip'
            subprocess.run(
                [str(pip_path), 'install', '--upgrade', 'pip'],
                check=True,
                capture_output=True
            )
            
            self.logger.success(f"✓ Created {venv_name}")
            return True
        except Exception as e:
            self.logger.error(f"Failed to create {venv_name}: {e}")
            return False
    
    def install_python_packages(self, venv_path: Path, venv_name: str) -> bool:
        """Install Python packages in venv"""
        pip_path = venv_path / 'bin' / 'pip'
        
        packages = self.pkg_registry.get_python_packages(optional=False)
        package_names = [str(pkg) for pkg in packages]
        
        self.logger.info(f"Installing {len(package_names)} Python packages in {venv_name}...")
        
        try:
            result = subprocess.run(
                [str(pip_path), 'install'] + package_names,
                capture_output=True,
                text=True,
                timeout=1800  # 30 minutes timeout
            )
            
            if result.returncode != 0:
                self.logger.error(f"Package installation failed:\n{result.stderr}")
                return False
            
            self.logger.success(f"✓ Packages installed in {venv_name}")
            return True
        except Exception as e:
            self.logger.error(f"Failed to install packages: {e}")
            return False
    
    def setup_jupyter(self) -> bool:
        """Setup Jupyter Lab"""
        # Install in training environment
        venv_path = self.config.VENV_ROOT / "pytorch-training"
        pip_path = venv_path / 'bin' / 'pip'
        jupyter_path = venv_path / 'bin' / 'jupyter'
        
        try:
            # Install Jupyter
            subprocess.run(
                [str(pip_path), 'install', 'jupyterlab', 'ipykernel'],
                check=True,
                capture_output=True
            )
            
            # Configure Jupyter
            subprocess.run(
                [str(jupyter_path), 'lab', '--generate-config'],
                check=True,
                capture_output=True
            )
            
            self.logger.success("✓ Jupyter Lab installed")
            return True
        except Exception as e:
            self.logger.error(f"Jupyter setup failed: {e}")
            return False