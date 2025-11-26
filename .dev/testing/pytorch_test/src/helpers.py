"""
Helper Functions
Logging, colors, formatting, and display utilities
"""

import sys
from pathlib import Path
from datetime import datetime
from typing import Optional


class Colors:
    """ANSI color codes"""
    RESET = "\033[0m"
    BOLD = "\033[1m"
    DIM = "\033[2m"
    
    # Colors
    BLACK = "\033[30m"
    RED = "\033[31m"
    GREEN = "\033[32m"
    YELLOW = "\033[33m"
    BLUE = "\033[34m"
    MAGENTA = "\033[35m"
    CYAN = "\033[36m"
    WHITE = "\033[37m"
    
    # Bright colors
    BRIGHT_RED = "\033[91m"
    BRIGHT_GREEN = "\033[92m"
    BRIGHT_YELLOW = "\033[93m"
    BRIGHT_BLUE = "\033[94m"
    BRIGHT_MAGENTA = "\033[95m"
    BRIGHT_CYAN = "\033[96m"
    
    @classmethod
    def strip(cls, text: str) -> str:
        """Remove color codes from text"""
        import re
        return re.sub(r'\033\[\d+m', '', text)


class Logger:
    """Logging utility with colors and file output"""
    
    def __init__(
        self,
        verbose: bool = False,
        log_file: Optional[str] = None,
        script_dir: Optional[Path] = None
    ):
        self.verbose = verbose
        self.log_file = None
        
        if log_file:
            self.log_file = Path(log_file)
        elif script_dir:
            logs_dir = Path(script_dir) / "logs"
            logs_dir.mkdir(exist_ok=True)
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            self.log_file = logs_dir / f"setup-{timestamp}.log"
        
        if self.log_file:
            self._write_log_header()
    
    def _write_log_header(self):
        """Write log file header"""
        with open(self.log_file, 'w') as f:
            f.write(f"={'='*80}\n")
            f.write(f"AI Training Framework Setup Log\n")
            f.write(f"Started: {datetime.now().isoformat()}\n")
            f.write(f"{'='*80}\n\n")
    
    def _log(self, level: str, message: str, color: str = ""):
        """Internal logging method"""
        timestamp = datetime.now().strftime("%H:%M:%S")
        colored_msg = f"{color}{message}{Colors.RESET}"
        plain_msg = Colors.strip(message)
        
        # Print to console
        print(f"[{timestamp}] {colored_msg}")
        
        # Write to log file
        if self.log_file:
            with open(self.log_file, 'a') as f:
                f.write(f"[{timestamp}] [{level}] {plain_msg}\n")
    
    def info(self, message: str):
        """Info message"""
        self._log("INFO", message, Colors.CYAN)
    
    def success(self, message: str):
        """Success message"""
        self._log("SUCCESS", message, Colors.BRIGHT_GREEN)
    
    def warn(self, message: str):
        """Warning message"""
        self._log("WARN", message, Colors.BRIGHT_YELLOW)
    
    def error(self, message: str):
        """Error message"""
        self._log("ERROR", message, Colors.BRIGHT_RED)
    
    def debug(self, message: str):
        """Debug message (only if verbose)"""
        if self.verbose:
            self._log("DEBUG", message, Colors.DIM)
    
    def phase(self, message: str):
        """Phase header"""
        print(f"\n{Colors.BOLD}{Colors.BRIGHT_BLUE}{'='*80}{Colors.RESET}")
        self._log("PHASE", message, f"{Colors.BOLD}{Colors.BRIGHT_MAGENTA}")
        print(f"{Colors.BOLD}{Colors.BRIGHT_BLUE}{'='*80}{Colors.RESET}\n")
    
    def command(self, cmd: str):
        """Log command execution"""
        self._log("CMD", f"$ {cmd}", Colors.BRIGHT_CYAN)


class Banner:
    """ASCII art and banners"""
    
    @staticmethod
    def print_welcome():
        """Print welcome banner"""
        banner = f"""
{Colors.BRIGHT_CYAN}
╔════════════════════════════════════════════════════════════════════════════╗
║                                                                            ║
║              🚀 AI TRAINING FRAMEWORK - SETUP WIZARD 🚀                    ║
║                                                                            ║
║                    PyTorch + CUDA 13 + LoRA/QLoRA                          ║
║                   Vision & Language Model Training                         ║
║                                                                            ║
╚════════════════════════════════════════════════════════════════════════════╝
{Colors.RESET}
"""
        print(banner)
    
    @staticmethod
    def print_success():
        """Print success banner"""
        banner = f"""
{Colors.BRIGHT_GREEN}
╔════════════════════════════════════════════════════════════════════════════╗
║                                                                            ║
║                        ✅ SETUP COMPLETED! ✅                              ║
║                                                                            ║
║                  Your AI training environment is ready!                    ║
║                                                                            ║
║              Run: source activate.zsh to get started                       ║
║              Docs: cat docs/COMMANDS.md                                    ║
║                                                                            ║
╚════════════════════════════════════════════════════════════════════════════╝
{Colors.RESET}
"""
        print(banner)


class ProgressBar:
    """Simple progress bar"""
    
    def __init__(self, total: int, prefix: str = "", width: int = 50):
        self.total = total
        self.prefix = prefix
        self.width = width
        self.current = 0
    
    def update(self, amount: int = 1):
        """Update progress"""
        self.current = min(self.current + amount, self.total)
        self._draw()
    
    def _draw(self):
        """Draw progress bar"""
        percent = self.current / self.total
        filled = int(self.width * percent)
        bar = "█" * filled + "░" * (self.width - filled)
        percent_str = f"{percent*100:.1f}%"
        
        sys.stdout.write(f"\r{self.prefix} [{bar}] {percent_str}")
        sys.stdout.flush()
        
        if self.current >= self.total:
            sys.stdout.write("\n")


class Formatter:
    """Text formatting utilities"""
    
    @staticmethod
    def bytes_to_human(bytes_val: int) -> str:
        """Convert bytes to human readable format"""
        for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
            if bytes_val < 1024.0:
                return f"{bytes_val:.2f} {unit}"
            bytes_val /= 1024.0
        return f"{bytes_val:.2f} PB"
    
    @staticmethod
    def duration_to_human(seconds: float) -> str:
        """Convert seconds to human readable duration"""
        if seconds < 60:
            return f"{seconds:.1f}s"
        elif seconds < 3600:
            return f"{seconds/60:.1f}m"
        else:
            hours = int(seconds / 3600)
            minutes = int((seconds % 3600) / 60)
            return f"{hours}h {minutes}m"
    
    @staticmethod
    def center_text(text: str, width: int = 80) -> str:
        """Center text within given width"""
        padding = (width - len(text)) // 2
        return " " * padding + text
    
    @staticmethod
    def table_row(columns: list, widths: list) -> str:
        """Format table row"""
        row = ""
        for col, width in zip(columns, widths):
            row += f"{str(col):<{width}} "
        return row.rstrip()