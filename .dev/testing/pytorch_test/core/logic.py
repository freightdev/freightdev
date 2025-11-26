"""
Orchestration Logic
Main setup workflow orchestration - calls src modules
"""

import time
from datetime import datetime
from pathlib import Path
from typing import Optional

from core.config import Config
from core.paths import Paths
from core.types import SetupPhase, SetupResult

from src.helpers import Logger
from src.validators import SystemValidator
from src.handlers import ErrorHandler
from src.utils import SystemUtils
from src.generate import TemplateGenerator


class SetupOrchestrator:
    """Main orchestrator for setup process"""
    
    def __init__(
        self,
        config: Config,
        logger: Logger,
        force: bool = False,
        dry_run: bool = False,
        resume: bool = False
    ):
        self.config = config
        self.logger = logger
        self.force = force
        self.dry_run = dry_run
        self.resume = resume
        
        self.paths = Paths(config)
        self.validator = SystemValidator(config, logger)
        self.handler = ErrorHandler(logger)
        self.utils = SystemUtils(config, logger)
        self.generator = TemplateGenerator(config, self.paths, logger)
        
        self.start_time = None
        self.current_phase = None
    
    def execute(self) -> bool:
        """Execute complete setup"""
        self.start_time = time.time()
        
        try:
            # Setup signal handlers
            self.handler.setup_signal_handlers()
            
            # Ensure framework directories exist
            self._phase(SetupPhase.VALIDATION, "Creating framework directories")
            self.paths.ensure_all_exist()
            
            # Phase 1: Validation
            if not self._run_validation():
                return False
            
            # Phase 2: System Preparation
            if not self._run_system_prep():
                return False
            
            # Phase 3: CUDA Setup (if needed)
            if not self.config.SKIP_CUDA_CHECK:
                if not self._run_cuda_setup():
                    return False
            
            # Phase 4: PyTorch Build (if needed)
            if not self.config.SKIP_PYTORCH_BUILD:
                if not self._run_pytorch_build():
                    return False
            
            # Phase 5: Virtual Environment Creation
            if not self._run_venv_creation():
                return False
            
            # Phase 6: Package Installation
            if not self._run_package_install():
                return False
            
            # Phase 7: Jupyter Setup
            if self.config.JUPYTER_ENABLE:
                if not self._run_jupyter_setup():
                    return False
            
            # Phase 8: Template Generation
            if not self._run_template_generation():
                return False
            
            # Phase 9: Documentation
            if not self._run_documentation():
                return False
            
            # Phase 10: Cleanup
            self._run_cleanup()
            
            # Complete
            self._phase(SetupPhase.COMPLETE, "Setup complete!")
            return True
            
        except KeyboardInterrupt:
            self.logger.warn("\n⚠️  Setup interrupted by user")
            self.handler.save_checkpoint(self.current_phase)
            return False
        except Exception as e:
            self.logger.error(f"Fatal error in {self.current_phase}: {e}")
            self.handler.handle_error(e, self.current_phase)
            return False
    
    def _phase(self, phase: SetupPhase, message: str):
        """Start new phase"""
        self.current_phase = phase
        self.logger.phase(f"[{phase.value.upper()}] {message}")
    
    def _prompt(self, message: str, default: bool = True) -> bool:
        """Prompt user for confirmation"""
        if self.force:
            return True
        
        choice = "Y/n" if default else "y/N"
        response = input(f"{message} [{choice}]: ").strip().lower()
        
        if not response:
            return default
        
        return response in ['y', 'yes']
    
    def _run_validation(self) -> bool:
        """Phase 1: System validation"""
        self._phase(SetupPhase.VALIDATION, "Validating system requirements")
        
        # Check system specs
        self.logger.info("Checking system specifications...")
        sys_info = self.validator.get_system_info()
        self.logger.info(f"  CPU: {sys_info['cpu']}")
        self.logger.info(f"  RAM: {sys_info['ram_gb']} GB")
        self.logger.info(f"  GPU: {sys_info['gpu']}")
        self.logger.info(f"  VRAM: {sys_info['vram_gb']} GB")
        self.logger.info(f"  Disk: {sys_info['disk_gb']} GB free")
        
        # Validate requirements
        validation_result = self.validator.validate_system()
        if not validation_result['passed']:
            self.logger.error("System validation failed:")
            for error in validation_result['errors']:
                self.logger.error(f"  ❌ {error}")
            return False
        
        self.logger.success("✓ System validation passed")
        
        # Check for existing installation
        if self.validator.check_existing_installation():
            if not self._prompt("Existing installation detected. Continue?", default=False):
                return False
        
        return True
    
    def _run_system_prep(self) -> bool:
        """Phase 2: System preparation"""
        self._phase(SetupPhase.SYSTEM_PREP, "Preparing system")
        
        # Update package manager
        if self.config.AUTO_INSTALL_DEPS:
            self.logger.info("Updating package manager...")
            if not self.dry_run:
                self.utils.update_package_manager()
        
        # Install system packages
        self.logger.info("Installing system packages...")
        if not self.dry_run:
            result = self.utils.install_system_packages()
            if not result:
                self.logger.error("Failed to install system packages")
                return False
        
        # Configure system memory
        self.logger.info("Configuring system memory...")
        if not self.dry_run:
            self.utils.configure_system_memory()
        
        self.logger.success("✓ System preparation complete")
        return True
    
    def _run_cuda_setup(self) -> bool:
        """Phase 3: CUDA setup"""
        self._phase(SetupPhase.CUDA_SETUP, "Verifying CUDA installation")
        
        cuda_info = self.validator.check_cuda()
        if not cuda_info['installed']:
            self.logger.error("CUDA not found")
            return False
        
        self.logger.info(f"  CUDA Version: {cuda_info['version']}")
        self.logger.info(f"  CUDA Home: {cuda_info['cuda_home']}")
        
        # Configure CUDA environment
        if not self.dry_run:
            self.utils.configure_cuda_environment()
        
        self.logger.success("✓ CUDA setup complete")
        return True
    
    def _run_pytorch_build(self) -> bool:
        """Phase 4: PyTorch build"""
        self._phase(SetupPhase.PYTORCH_BUILD, "Building PyTorch from source")
        
        if self._prompt("Build PyTorch from source? (takes 40-60 mins)", default=False):
            self.logger.info("Starting PyTorch build...")
            if not self.dry_run:
                result = self.utils.build_pytorch()
                if not result:
                    self.logger.error("PyTorch build failed")
                    return False
            self.logger.success("✓ PyTorch build complete")
        else:
            self.logger.info("Skipping PyTorch build")
        
        return True
    
    def _run_venv_creation(self) -> bool:
        """Phase 5: Virtual environment creation"""
        self._phase(SetupPhase.VENV_CREATION, "Creating Python environments")
        
        for venv_name, description in self.config.VENVS.items():
            self.logger.info(f"Creating {venv_name}...")
            if not self.dry_run:
                venv_path = self.paths.get_venv(venv_name.replace('pytorch-', ''))
                result = self.utils.create_venv(venv_path, venv_name)
                if not result:
                    self.logger.error(f"Failed to create {venv_name}")
                    return False
        
        self.logger.success("✓ Virtual environments created")
        return True
    
    def _run_package_install(self) -> bool:
        """Phase 6: Package installation"""
        self._phase(SetupPhase.PACKAGE_INSTALL, "Installing Python packages")
        
        for venv_name in self.config.VENVS.keys():
            self.logger.info(f"Installing packages in {venv_name}...")
            if not self.dry_run:
                venv_path = self.paths.get_venv(venv_name.replace('pytorch-', ''))
                result = self.utils.install_python_packages(venv_path, venv_name)
                if not result:
                    self.logger.error(f"Failed to install packages in {venv_name}")
                    return False
        
        self.logger.success("✓ Package installation complete")
        return True
    
    def _run_jupyter_setup(self) -> bool:
        """Phase 7: Jupyter setup"""
        self._phase(SetupPhase.JUPYTER_SETUP, "Setting up Jupyter Lab")
        
        if not self.dry_run:
            result = self.utils.setup_jupyter()
            if not result:
                self.logger.error("Jupyter setup failed")
                return False
        
        self.logger.success("✓ Jupyter setup complete")
        return True
    
    def _run_template_generation(self) -> bool:
        """Phase 8: Template generation"""
        self._phase(SetupPhase.TEMPLATE_GENERATION, "Generating templates")
        
        if not self.dry_run:
            self.generator.generate_all_templates()
        
        self.logger.success("✓ Templates generated")
        return True
    
    def _run_documentation(self) -> bool:
        """Phase 9: Documentation"""
        self._phase(SetupPhase.DOCUMENTATION, "Generating documentation")
        
        if not self.dry_run:
            self.generator.generate_commands_md()
            self.generator.generate_architecture_md()
        
        self.logger.success("✓ Documentation generated")
        return True
    
    def _run_cleanup(self):
        """Phase 10: Cleanup"""
        self._phase(SetupPhase.CLEANUP, "Cleaning up")
        
        elapsed = time.time() - self.start_time
        self.logger.info(f"Total setup time: {elapsed:.1f} seconds")
        
        # Save final state
        if not self.dry_run:
            self.handler.save_checkpoint(SetupPhase.COMPLETE)