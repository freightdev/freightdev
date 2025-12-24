"""
System Validators
Pre-flight checks and validation
"""

import os
import re
import subprocess
import shutil
from pathlib import Path
from typing import Dict, Any, List, Optional, Tuple

from src.helpers import Logger


class SystemValidator:
    """Validate system requirements"""
    
    def __init__(self, config, logger: Logger):
        self.config = config
        self.logger = logger
    
    def validate_system(self) -> Dict[str, Any]:
        """Complete system validation"""
        errors = []
        warnings = []
        
        # Check RAM
        ram_gb = self._get_ram_gb()
        if ram_gb < 8:
            errors.append(f"Insufficient RAM: {ram_gb}GB (minimum 8GB)")
        
        # Check disk space
        disk_gb = self._get_free_disk_gb()
        if disk_gb < 50:
            errors.append(f"Insufficient disk space: {disk_gb}GB (minimum 50GB)")
        
        # Check GPU
        gpu_info = self._get_gpu_info()
        if not gpu_info['found']:
            warnings.append("No NVIDIA GPU detected")
        elif gpu_info['vram_gb'] < 4:
            warnings.append(f"Low GPU VRAM: {gpu_info['vram_gb']}GB")
        
        # Check Python
        python_version = self._get_python_version()
        if not python_version or python_version < (3, 8):
            errors.append(f"Python 3.8+ required (found: {python_version})")
        
        # Check CUDA
        cuda_installed = self._check_cuda_installed()
        if not cuda_installed:
            warnings.append("CUDA not detected (required for GPU acceleration)")
        
        return {
            "passed": len(errors) == 0,
            "errors": errors,
            "warnings": warnings,
        }
    
    def get_system_info(self) -> Dict[str, Any]:
        """Get detailed system information"""
        return {
            "cpu": self._get_cpu_info(),
            "ram_gb": self._get_ram_gb(),
            "gpu": self._get_gpu_info()['name'],
            "vram_gb": self._get_gpu_info()['vram_gb'],
            "disk_gb": self._get_free_disk_gb(),
            "python": self._get_python_version_str(),
            "cuda": self._get_cuda_version(),
        }
    
    def check_cuda(self) -> Dict[str, Any]:
        """Check CUDA installation"""
        cuda_home = os.environ.get('CUDA_HOME') or '/usr/local/cuda'
        nvcc_path = shutil.which('nvcc')
        
        if not nvcc_path:
            return {
                "installed": False,
                "version": None,
                "cuda_home": None,
            }
        
        version = self._get_cuda_version()
        return {
            "installed": True,
            "version": version,
            "cuda_home": cuda_home,
            "nvcc_path": nvcc_path,
        }
    
    def check_existing_installation(self) -> bool:
        """Check if setup already exists"""
        venv_root = self.config.VENV_ROOT
        return venv_root.exists() and any(venv_root.iterdir())
    
    # === Private helper methods ===
    
    def _get_cpu_info(self) -> str:
        """Get CPU model"""
        try:
            with open('/proc/cpuinfo', 'r') as f:
                for line in f:
                    if 'model name' in line:
                        return line.split(':')[1].strip()
        except:
            pass
        return "Unknown CPU"
    
    def _get_ram_gb(self) -> int:
        """Get total RAM in GB"""
        try:
            with open('/proc/meminfo', 'r') as f:
                for line in f:
                    if 'MemTotal' in line:
                        kb = int(line.split()[1])
                        return kb // (1024 * 1024)
        except:
            return 0
    
    def _get_free_disk_gb(self) -> int:
        """Get free disk space in GB"""
        try:
            stat = shutil.disk_usage('/')
            return stat.free // (1024**3)
        except:
            return 0
    
    def _get_gpu_info(self) -> Dict[str, Any]:
        """Get GPU information"""
        try:
            result = subprocess.run(
                ['nvidia-smi', '--query-gpu=name,memory.total', '--format=csv,noheader'],
                capture_output=True,
                text=True,
                timeout=5
            )
            
            if result.returncode == 0:
                output = result.stdout.strip().split(',')
                name = output[0].strip()
                vram_mb = int(output[1].strip().split()[0])
                vram_gb = vram_mb / 1024
                
                return {
                    "found": True,
                    "name": name,
                    "vram_gb": round(vram_gb, 1),
                }
        except:
            pass
        
        return {
            "found": False,
            "name": "No GPU",
            "vram_gb": 0,
        }
    
    def _get_python_version(self) -> Optional[Tuple[int, int]]:
        """Get Python version as tuple"""
        try:
            result = subprocess.run(
                ['python3', '--version'],
                capture_output=True,
                text=True
            )
            match = re.search(r'(\d+)\.(\d+)', result.stdout)
            if match:
                return (int(match.group(1)), int(match.group(2)))
        except:
            pass
        return None
    
    def _get_python_version_str(self) -> str:
        """Get Python version as string"""
        version = self._get_python_version()
        if version:
            return f"{version[0]}.{version[1]}"
        return "Not found"
    
    def _check_cuda_installed(self) -> bool:
        """Check if CUDA is installed"""
        return shutil.which('nvcc') is not None
    
    def _get_cuda_version(self) -> Optional[str]:
        """Get CUDA version"""
        try:
            result = subprocess.run(
                ['nvcc', '--version'],
                capture_output=True,
                text=True
            )
            match = re.search(r'release (\d+\.\d+)', result.stdout)
            if match:
                return match.group(1)
        except:
            pass
        return None
    
    def validate_path_writable(self, path: Path) -> bool:
        """Check if path is writable"""
        try:
            path.mkdir(parents=True, exist_ok=True)
            test_file = path / '.write_test'
            test_file.touch()
            test_file.unlink()
            return True
        except:
            return False
    
    def validate_package_manager(self) -> bool:
        """Validate package manager is available"""
        pkg_mgr = self.config.PACKAGE_MANAGER
        
        managers = {
            'apt': 'apt-get',
            'dnf': 'dnf',
            'pacman': 'pacman',
            'apk': 'apk',
        }
        
        cmd = managers.get(pkg_mgr)
        return shutil.which(cmd) is not None
    
    def check_internet_connectivity(self) -> bool:
        """Check internet connectivity"""
        try:
            subprocess.run(
                ['ping', '-c', '1', '-W', '2', '8.8.8.8'],
                capture_output=True,
                timeout=3
            )
            return True
        except:
            return False