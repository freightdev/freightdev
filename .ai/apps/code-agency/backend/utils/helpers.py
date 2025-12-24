import time
import logging
from typing import Any, Dict, List, Optional, Union
from datetime import datetime, timezone
from pathlib import Path

import hashlib
import uuid
import re
import json
import asyncio
import functools


logger = logging.getLogger(__name__)

# String utilities
def truncate_string(text: str, max_length: int = 100, suffix: str = "...") -> str:
    """Truncate string to max length with suffix"""
    if len(text) <= max_length:
        return text
    return text[:max_length - len(suffix)] + suffix

def clean_string(text: str) -> str:
    """Clean string for safe processing"""
    if not text:
        return ""
    
    # Remove null bytes and control characters
    text = re.sub(r'[\x00-\x08\x0b\x0c\x0e-\x1f\x7f-\x9f]', '', text)
    
    # Normalize whitespace
    text = re.sub(r'\s+', ' ', text.strip())
    
    return text

def extract_code_blocks(text: str) -> List[Dict[str, str]]:
    """Extract code blocks from markdown-style text"""
    pattern = r'```(\w+)?\n(.*?)```'
    matches = re.findall(pattern, text, re.DOTALL)
    
    code_blocks = []
    for language, code in matches:
        code_blocks.append({
            'language': language.strip() if language else 'text',
            'code': code.strip()
        })
    
    return code_blocks

def count_tokens_rough(text: str) -> int:
    """Rough token count estimation (words * 1.3)"""
    if not text:
        return 0
    return int(len(text.split()) * 1.3)

def sanitize_filename(filename: str) -> str:
    """Sanitize filename for safe filesystem operations"""
    # Remove or replace unsafe characters
    unsafe_chars = r'[<>:"/\\|?*]'
    filename = re.sub(unsafe_chars, '_', filename)
    
    # Remove leading/trailing dots and spaces
    filename = filename.strip('. ')
    
    # Limit length
    if len(filename) > 255:
        name, ext = Path(filename).stem, Path(filename).suffix
        filename = name[:255-len(ext)] + ext
    
    return filename

# Hash and ID utilities
def generate_id(prefix: str = "") -> str:
    """Generate unique ID with optional prefix"""
    unique_id = str(uuid.uuid4())
    return f"{prefix}_{unique_id}" if prefix else unique_id

def hash_string(text: str, algorithm: str = "sha256") -> str:
    """Hash string using specified algorithm"""
    if algorithm == "md5":
        return hashlib.md5(text.encode()).hexdigest()
    elif algorithm == "sha1":
        return hashlib.sha1(text.encode()).hexdigest()
    elif algorithm == "sha256":
        return hashlib.sha256(text.encode()).hexdigest()
    else:
        raise ValueError(f"Unsupported hash algorithm: {algorithm}")

def hash_dict(data: Dict[str, Any]) -> str:
    """Create consistent hash of dictionary"""
    # Sort keys for consistency
    json_str = json.dumps(data, sort_keys=True, default=str)
    return hash_string(json_str)

# Time utilities
def now_iso() -> str:
    """Get current time as ISO string"""
    return datetime.now(timezone.utc).isoformat()

def parse_iso_time(iso_string: str) -> datetime:
    """Parse ISO time string to datetime"""
    return datetime.fromisoformat(iso_string.replace('Z', '+00:00'))

def time_ago(dt: datetime) -> str:
    """Human readable time ago string"""
    now = datetime.now(timezone.utc)
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    
    diff = now - dt
    seconds = diff.total_seconds()
    
    if seconds < 60:
        return f"{int(seconds)} seconds ago"
    elif seconds < 3600:
        minutes = int(seconds / 60)
        return f"{minutes} minute{'s' if minutes != 1 else ''} ago"
    elif seconds < 86400:
        hours = int(seconds / 3600)
        return f"{hours} hour{'s' if hours != 1 else ''} ago"
    else:
        days = int(seconds / 86400)
        return f"{days} day{'s' if days != 1 else ''} ago"

# File utilities
def ensure_directory(path: Union[str, Path]) -> Path:
    """Ensure directory exists, create if not"""
    path = Path(path)
    path.mkdir(parents=True, exist_ok=True)
    return path

def get_file_size_human(size_bytes: int) -> str:
    """Convert bytes to human readable format"""
    if size_bytes == 0:
        return "0 B"
    
    size_names = ["B", "KB", "MB", "GB", "TB"]
    i = 0
    while size_bytes >= 1024 and i < len(size_names) - 1:
        size_bytes /= 1024.0
        i += 1
    
    return f"{size_bytes:.1f} {size_names[i]}"

def is_text_file(file_path: Union[str, Path]) -> bool:
    """Check if file is likely a text file"""
    try:
        with open(file_path, 'rb') as f:
            chunk = f.read(1024)
            # If null bytes present, likely binary
            if b'\0' in chunk:
                return False
            
            # Check for high ratio of printable characters
            printable = sum(1 for byte in chunk if 32 <= byte <= 126 or byte in [9, 10, 13])
            return printable / len(chunk) > 0.7 if chunk else True
            
    except Exception:
        return False

# Data structure utilities
def deep_merge(dict1: Dict, dict2: Dict) -> Dict:
    """Deep merge two dictionaries"""
    result = dict1.copy()
    
    for key, value in dict2.items():
        if key in result and isinstance(result[key], dict) and isinstance(value, dict):
            result[key] = deep_merge(result[key], value)
        else:
            result[key] = value
    
    return result

def flatten_dict(d: Dict, parent_key: str = '', sep: str = '.') -> Dict:
    """Flatten nested dictionary"""
    items = []
    for k, v in d.items():
        new_key = f"{parent_key}{sep}{k}" if parent_key else k
        if isinstance(v, dict):
            items.extend(flatten_dict(v, new_key, sep=sep).items())
        else:
            items.append((new_key, v))
    return dict(items)

def chunk_list(lst: List, chunk_size: int) -> List[List]:
    """Split list into chunks of specified size"""
    return [lst[i:i + chunk_size] for i in range(0, len(lst), chunk_size)]

# Async utilities
def async_timer(func):
    """Decorator to time async functions"""
    @functools.wraps(func)
    async def wrapper(*args, **kwargs):
        start_time = time.time()
        try:
            result = await func(*args, **kwargs)
            return result
        finally:
            end_time = time.time()
            logger.debug(f"{func.__name__} took {end_time - start_time:.3f}s")
    return wrapper

def sync_timer(func):
    """Decorator to time sync functions"""
    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        start_time = time.time()
        try:
            result = func(*args, **kwargs)
            return result
        finally:
            end_time = time.time()
            logger.debug(f"{func.__name__} took {end_time - start_time:.3f}s")
    return wrapper

async def run_with_timeout(coro, timeout: float):
    """Run coroutine with timeout"""
    try:
        return await asyncio.wait_for(coro, timeout=timeout)
    except asyncio.TimeoutError:
        logger.warning(f"Operation timed out after {timeout}s")
        raise

# Validation utilities
def validate_email(email: str) -> bool:
    """Basic email validation"""
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    return bool(re.match(pattern, email))

def validate_url(url: str) -> bool:
    """Basic URL validation"""
    pattern = r'^https?://[^\s/$.?#].[^\s]*$'
    return bool(re.match(pattern, url))

def validate_path_safe(path: str) -> bool:
    """Check if path is safe (no path traversal)"""
    # Normalize path
    normalized = Path(path).resolve()
    
    # Check for path traversal attempts
    dangerous_patterns = ['..', '~', '/etc', '/proc', '/sys']
    path_str = str(normalized).lower()
    
    return not any(pattern in path_str for pattern in dangerous_patterns)

# Error handling utilities
class SafeDict(dict):
    """Dictionary that returns None for missing keys instead of raising KeyError"""
    def __missing__(self, key):
        return None

def safe_json_loads(json_str: str, default=None):
    """Safely load JSON string"""
    try:
        return json.loads(json_str)
    except (json.JSONDecodeError, TypeError):
        return default

def safe_int(value: Any, default: int = 0) -> int:
    """Safely convert value to int"""
    try:
        return int(value)
    except (ValueError, TypeError):
        return default

def safe_float(value: Any, default: float = 0.0) -> float:
    """Safely convert value to float"""
    try:
        return float(value)
    except (ValueError, TypeError):
        return default

# Progress tracking
class ProgressTracker:
    """Simple progress tracking utility"""
    
    def __init__(self, total: int, description: str = "Processing"):
        self.total = total
        self.current = 0
        self.description = description
        self.start_time = time.time()
    
    def update(self, increment: int = 1):
        """Update progress"""
        self.current = min(self.current + increment, self.total)
        
        if self.current % max(1, self.total // 20) == 0:  # Log every 5%
            percent = (self.current / self.total) * 100
            elapsed = time.time() - self.start_time
            
            if self.current > 0:
                eta = elapsed * (self.total - self.current) / self.current
                logger.info(f"{self.description}: {percent:.1f}% ({self.current}/{self.total}) - ETA: {eta:.1f}s")
    
    def complete(self):
        """Mark as complete"""
        self.current = self.total
        elapsed = time.time() - self.start_time
        logger.info(f"{self.description}: Complete! ({elapsed:.2f}s total)")

# Configuration utilities
def load_config(config_path: Union[str, Path], default: Dict = None) -> Dict:
    """Load configuration from JSON/YAML file"""
    config_path = Path(config_path)
    
    if not config_path.exists():
        logger.warning(f"Config file not found: {config_path}")
        return default or {}
    
    try:
        with open(config_path, 'r') as f:
            if config_path.suffix.lower() in ['.yaml', '.yml']:
                import yaml
                return yaml.safe_load(f)
            else:
                return json.load(f)
    except Exception as e:
        logger.error(f"Error loading config from {config_path}: {e}")
        return default or {}

def save_config(config: Dict, config_path: Union[str, Path]):
    """Save configuration to JSON file"""
    config_path = Path(config_path)
    config_path.parent.mkdir(parents=True, exist_ok=True)
    
    try:
        with open(config_path, 'w') as f:
            json.dump(config, f, indent=2, default=str)
        logger.info(f"Config saved to {config_path}")
    except Exception as e:
        logger.error(f"Error saving config to {config_path}: {e}")