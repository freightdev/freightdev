import logging
import logging.handlers
import sys
from pathlib import Path
from datetime import datetime
from typing import Optional, Dict, Any
import json
import traceback

class ColoredFormatter(logging.Formatter):
    """Colored formatter for console output"""
    
    # ANSI color codes
    COLORS = {
        'DEBUG': '\033[36m',     # Cyan
        'INFO': '\033[32m',      # Green
        'WARNING': '\033[33m',   # Yellow
        'ERROR': '\033[31m',     # Red
        'CRITICAL': '\033[35m',  # Magenta
        'RESET': '\033[0m'       # Reset
    }
    
    def format(self, record):
        # Add color to levelname
        if record.levelname in self.COLORS:
            record.levelname = f"{self.COLORS[record.levelname]}{record.levelname}{self.COLORS['RESET']}"
        
        return super().format(record)

class JSONFormatter(logging.Formatter):
    """JSON formatter for structured logging"""
    
    def format(self, record):
        log_entry = {
            'timestamp': datetime.utcnow().isoformat(),
            'level': record.levelname,
            'logger': record.name,
            'message': record.getMessage(),
            'module': record.module,
            'function': record.funcName,
            'line': record.lineno
        }
        
        # Add exception info if present
        if record.exc_info:
            log_entry['exception'] = {
                'type': record.exc_info[0].__name__,
                'message': str(record.exc_info[1]),
                'traceback': traceback.format_exception(*record.exc_info)
            }
        
        # Add extra fields
        for key, value in record.__dict__.items():
            if key not in ['name', 'msg', 'args', 'levelname', 'levelno', 'pathname', 
                          'filename', 'module', 'lineno', 'funcName', 'created', 
                          'msecs', 'relativeCreated', 'thread', 'threadName', 
                          'processName', 'process', 'getMessage', 'exc_info', 
                          'exc_text', 'stack_info']:
                log_entry[key] = value
        
        return json.dumps(log_entry)

class LoggerManager:
    """Centralized logger management"""
    
    def __init__(self):
        self.loggers: Dict[str, logging.Logger] = {}
        self.handlers: Dict[str, logging.Handler] = {}
        self.log_dir = Path("../data/logs")
        self.log_dir.mkdir(parents=True, exist_ok=True)
        
        # Default configuration
        self.default_level = logging.INFO
        self.console_format = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
        self.file_format = "%(asctime)s - %(name)s - %(levelname)s - %(module)s:%(funcName)s:%(lineno)d - %(message)s"
        
    def setup_logging(self, 
                     level: str = "INFO",
                     console: bool = True,
                     file_logging: bool = True,
                     json_logging: bool = False,
                     max_file_size: int = 10 * 1024 * 1024,  # 10MB
                     backup_count: int = 5):
        """Setup application-wide logging configuration"""
        
        # Convert string level to logging constant
        numeric_level = getattr(logging, level.upper(), logging.INFO)
        
        # Configure root logger
        root_logger = logging.getLogger()
        root_logger.setLevel(numeric_level)
        
        # Clear existing handlers
        root_logger.handlers.clear()
        
        # Console handler
        if console:
            console_handler = logging.StreamHandler(sys.stdout)
            console_handler.setLevel(numeric_level)
            
            # Use colored formatter for console
            console_formatter = ColoredFormatter(self.console_format)
            console_handler.setFormatter(console_formatter)
            
            root_logger.addHandler(console_handler)
            self.handlers['console'] = console_handler
        
        # File handler
        if file_logging:
            log_file = self.log_dir / "app.log"
            file_handler = logging.handlers.RotatingFileHandler(
                log_file,
                maxBytes=max_file_size,
                backupCount=backup_count
            )
            file_handler.setLevel(numeric_level)
            
            file_formatter = logging.Formatter(self.file_format)
            file_handler.setFormatter(file_formatter)
            
            root_logger.addHandler(file_handler)
            self.handlers['file'] = file_handler
        
        # JSON structured logging
        if json_logging:
            json_log_file = self.log_dir / "app.json"
            json_handler = logging.handlers.RotatingFileHandler(
                json_log_file,
                maxBytes=max_file_size,
                backupCount=backup_count
            )
            json_handler.setLevel(numeric_level)
            
            json_formatter = JSONFormatter()
            json_handler.setFormatter(json_formatter)
            
            root_logger.addHandler(json_handler)
            self.handlers['json'] = json_handler
        
        logging.info(f"Logging configured: level={level}, console={console}, file={file_logging}, json={json_logging}")
    
    def get_logger(self, name: str, level: Optional[str] = None) -> logging.Logger:
        """Get or create a logger with specified name and level"""
        if name in self.loggers:
            return self.loggers[name]
        
        logger = logging.getLogger(name)
        
        if level:
            numeric_level = getattr(logging, level.upper(), self.default_level)
            logger.setLevel(numeric_level)
        
        self.loggers[name] = logger
        return logger
    
    def setup_component_logging(self):
        """Setup logging for specific application components"""
        
        # AI Core components
        ai_loggers = [
            "ai_assistant.inference",
            "ai_assistant.memory", 
            "ai_assistant.agents",
            "ai_assistant.ide"
        ]
        
        for logger_name in ai_loggers:
            logger = self.get_logger(logger_name)
            
            # Add component-specific file handler
            component_name = logger_name.split('.')[-1]
            log_file = self.log_dir / f"{component_name}.log"
            
            handler = logging.handlers.RotatingFileHandler(
                log_file,
                maxBytes=5 * 1024 * 1024,  # 5MB
                backupCount=3
            )
            handler.setLevel(logging.DEBUG)
            
            formatter = logging.Formatter(self.file_format)
            handler.setFormatter(formatter)
            
            logger.addHandler(handler)
        
        # Database logging
        db_logger = self.get_logger("ai_assistant.database", "WARNING")
        
        # External library logging
        external_loggers = [
            ("uvicorn", "WARNING"),
            ("fastapi", "WARNING"),
            ("transformers", "WARNING"),
            ("sentence_transformers", "WARNING"),
            ("sqlalchemy", "WARNING")
        ]
        
        for logger_name, level in external_loggers:
            logger = logging.getLogger(logger_name)
            logger.setLevel(getattr(logging, level))
    
    def add_custom_handler(self, name: str, handler: logging.Handler):
        """Add custom logging handler"""
        root_logger = logging.getLogger()
        root_logger.addHandler(handler)
        self.handlers[name] = handler
    
    def remove_handler(self, name: str):
        """Remove logging handler"""
        if name in self.handlers:
            handler = self.handlers[name]
            root_logger = logging.getLogger()
            root_logger.removeHandler(handler)
            handler.close()
            del self.handlers[name]
    
    def get_log_stats(self) -> Dict[str, Any]:
        """Get logging statistics"""
        stats = {
            'active_loggers': len(self.loggers),
            'active_handlers': len(self.handlers),
            'log_directory': str(self.log_dir),
            'log_files': []
        }
        
        # Get log file information
        if self.log_dir.exists():
            for log_file in self.log_dir.glob("*.log"):
                try:
                    file_stat = log_file.stat()
                    stats['log_files'].append({
                        'name': log_file.name,
                        'size': file_stat.st_size,
                        'size_human': self._human_readable_size(file_stat.st_size),
                        'modified': datetime.fromtimestamp(file_stat.st_mtime).isoformat()
                    })
                except Exception as e:
                    stats['log_files'].append({
                        'name': log_file.name,
                        'error': str(e)
                    })
        
        return stats
    
    def _human_readable_size(self, size_bytes: int) -> str:
        """Convert bytes to human readable format"""
        if size_bytes == 0:
            return "0 B"
        
        size_names = ["B", "KB", "MB", "GB"]
        i = 0
        while size_bytes >= 1024 and i < len(size_names) - 1:
            size_bytes /= 1024.0
            i += 1
        
        return f"{size_bytes:.1f} {size_names[i]}"

# Global logger manager instance
logger_manager = LoggerManager()

# Convenience functions
def setup_logging(**kwargs):
    """Setup application logging"""
    logger_manager.setup_logging(**kwargs)
    logger_manager.setup_component_logging()

def get_logger(name: str, level: Optional[str] = None) -> logging.Logger:
    """Get logger instance"""
    return logger_manager.get_logger(name, level)

# Context manager for temporary log level changes
class temporary_log_level:
    """Context manager to temporarily change log level"""
    
    def __init__(self, logger: logging.Logger, level: str):
        self.logger = logger
        self.new_level = getattr(logging, level.upper())
        self.old_level = None
    
    def __enter__(self):
        self.old_level = self.logger.level
        self.logger.setLevel(self.new_level)
        return self.logger
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        if self.old_level is not None:
            self.logger.setLevel(self.old_level)

# Performance logging decorator
def log_performance(logger_name: str = "performance"):
    """Decorator to log function performance"""
    def decorator(func):
        logger = get_logger(logger_name)
        
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            start_time = time.time()
            try:
                result = func(*args, **kwargs)
                return result
            except Exception as e:
                logger.error(f"{func.__name__} failed: {e}", exc_info=True)
                raise
            finally:
                end_time = time.time()
                duration = end_time - start_time
                logger.info(f"{func.__name__} completed in {duration:.3f}s")
        
        return wrapper
    return decorator