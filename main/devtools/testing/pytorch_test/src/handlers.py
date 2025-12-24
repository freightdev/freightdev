"""
Error Handlers
Error handling, recovery, rollback, and checkpointing
"""

import signal
import json
from pathlib import Path
from datetime import datetime
from typing import Optional, Dict, Any

from core.types import SetupPhase, SetupCheckpoint
from src.helpers import Logger


class ErrorHandler:
    """Handle errors, rollback, and recovery"""
    
    def __init__(self, logger: Logger):
        self.logger = logger
        self.checkpoint_file = None
        self.interrupted = False
    
    def setup_signal_handlers(self):
        """Setup signal handlers for graceful shutdown"""
        signal.signal(signal.SIGINT, self._signal_handler)
        signal.signal(signal.SIGTERM, self._signal_handler)
    
    def _signal_handler(self, signum, frame):
        """Handle interrupt signals"""
        self.interrupted = True
        self.logger.warn("\n⚠️  Interrupt signal received. Saving checkpoint...")
        raise KeyboardInterrupt
    
    def handle_error(
        self,
        error: Exception,
        phase: Optional[SetupPhase] = None
    ):
        """Handle setup error"""
        self.logger.error(f"Error during setup: {error}")
        
        if phase:
            self.logger.error(f"Failed at phase: {phase.value}")
            self.save_checkpoint(phase, status="failed", error=str(error))
        
        # Suggest recovery
        self._suggest_recovery(error, phase)
    
    def _suggest_recovery(
        self,
        error: Exception,
        phase: Optional[SetupPhase]
    ):
        """Suggest recovery actions"""
        self.logger.info("\n📋 Recovery suggestions:")
        
        if phase == SetupPhase.VALIDATION:
            self.logger.info("  • Check system requirements")
            self.logger.info("  • Ensure sufficient disk space")
        
        elif phase == SetupPhase.SYSTEM_PREP:
            self.logger.info("  • Run: sudo apt update")
            self.logger.info("  • Check internet connectivity")
        
        elif phase == SetupPhase.CUDA_SETUP:
            self.logger.info("  • Verify CUDA installation")
            self.logger.info("  • Check nvidia-smi output")
        
        elif phase == SetupPhase.PYTORCH_BUILD:
            self.logger.info("  • Clean build: rm -rf pytorch/build")
            self.logger.info("  • Check compiler errors in logs")
        
        elif phase == SetupPhase.VENV_CREATION:
            self.logger.info("  • Remove failed venv and retry")
            self.logger.info("  • Check Python installation")
        
        elif phase == SetupPhase.PACKAGE_INSTALL:
            self.logger.info("  • Check pip connectivity")
            self.logger.info("  • Try: pip install --upgrade pip")
        
        self.logger.info("\n  To resume: python3 main.py --resume")
    
    def save_checkpoint(
        self,
        phase: SetupPhase,
        status: str = "completed",
        error: Optional[str] = None
    ):
        """Save checkpoint for resuming"""
        checkpoint = {
            "phase": phase.value,
            "timestamp": datetime.now().isoformat(),
            "status": status,
            "error": error,
        }
        
        checkpoint_path = Path.home() / "WORKSPACE" / "ai" / "setups" / "framework" / "logs" / ".last_checkpoint"
        checkpoint_path.parent.mkdir(parents=True, exist_ok=True)
        
        with open(checkpoint_path, 'w') as f:
            json.dump(checkpoint, f, indent=2)
        
        self.logger.debug(f"Checkpoint saved: {checkpoint_path}")
    
    def load_checkpoint(self) -> Optional[SetupCheckpoint]:
        """Load last checkpoint"""
        checkpoint_path = Path.home() / "WORKSPACE" / "ai" / "setups" / "framework" / "logs" / ".last_checkpoint"
        
        if not checkpoint_path.exists():
            return None
        
        try:
            with open(checkpoint_path, 'r') as f:
                data = json.load(f)
            
            return SetupCheckpoint(
                phase=SetupPhase(data["phase"]),
                timestamp=data["timestamp"],
                status=data["status"],
                details=data
            )
        except Exception as e:
            self.logger.warn(f"Could not load checkpoint: {e}")
            return None
    
    def clear_checkpoint(self):
        """Clear checkpoint file"""
        checkpoint_path = Path.home() / "WORKSPACE" / "ai" / "setups" / "framework" / "logs" / ".last_checkpoint"
        if checkpoint_path.exists():
            checkpoint_path.unlink()


class RollbackManager:
    """Manage rollback operations"""
    
    def __init__(self, logger: Logger):
        self.logger = logger
        self.actions = []
    
    def add_action(
        self,
        description: str,
        rollback_func,
        *args,
        **kwargs
    ):
        """Add rollback action"""
        self.actions.append({
            "description": description,
            "func": rollback_func,
            "args": args,
            "kwargs": kwargs,
        })
    
    def execute_rollback(self):
        """Execute all rollback actions in reverse order"""
        self.logger.warn("Starting rollback...")
        
        for action in reversed(self.actions):
            try:
                self.logger.info(f"  Rolling back: {action['description']}")
                action['func'](*action['args'], **action['kwargs'])
            except Exception as e:
                self.logger.error(f"  Rollback failed: {e}")
        
        self.actions.clear()
        self.logger.success("Rollback complete")
    
    def clear(self):
        """Clear all rollback actions"""
        self.actions.clear()


class ValidationError(Exception):
    """Custom validation error"""
    pass


class SetupError(Exception):
    """Custom setup error"""
    pass