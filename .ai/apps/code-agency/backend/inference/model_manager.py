import logging
from pathlib import Path

import requests.exceptions
import shutil
import json

import torch
from threading import Lock
from transformers import AutoTokenizer, AutoModelForCausalLM
from llama_cpp import Llama

from ..app.config import settings

logger = logging.getLogger(__name__)

class ModelManager:
    def __init__(self):
        self.model = None
        self.tokenizer = None
        self.device = "cuda" if torch.cuda.is_available() else "cpu"
        self.model_name = None
        self.loaded_model_path = None
        self.lock = Lock()

    def download_model(self, model_json_path: str, progress_callback=None) -> Path:
        try:
            meta_file = Path(model_json_path)
            if not meta_file.exists():
                raise FileNotFoundError(f"Model JSON not found: {meta_file}")
    
            with open(meta_file) as f:
                meta = json.load(f)
    
            model_source = meta["source"]
            model_local_path = Path(meta["path"])
            model_local_path.parent.mkdir(parents=True, exist_ok=True)
    
            if model_local_path.exists():
                logger.info(f"Model already exists locally: {model_local_path}")
                return model_local_path
    
            logger.info(f"Downloading model from {model_source} → {model_local_path}")
            with requests.get(model_source, stream=True) as r:
                r.raise_for_status()
                total = int(r.headers.get("content-length", 0))
                downloaded = 0
                with open(model_local_path, "wb") as f:
                    for chunk in r.iter_content(chunk_size=8192):
                        if chunk:
                            f.write(chunk)
                            downloaded += len(chunk)
                            if progress_callback:
                                progress_callback(downloaded, total)
    
            logger.info(f"Model downloaded: {model_local_path}")
            return model_local_path

        except requests.exceptions.RequestException as e:
            logger.error(f"Download error: {e}")
            raise
        except Exception as e:
            logger.exception(f"Unexpected error: {e}")
            raise

    def load_model(self, model_json_path: str, progress_callback=None) -> bool:
        with self.lock:
            try:
                if self.loaded_model_path:
                    self.unload_model()
                model_path = self.download_model(model_json_path, progress_callback)
                logger.info(f"Loading model from: {model_path}")
                if model_path.suffix == ".gguf":
                    self.load_gguf_model(model_path)
                else:
                    self.load_huggingface_model(model_path)
                self.model_name = Path(model_json_path).parent.name
                self.loaded_model_path = model_path
                logger.info(f"Model loaded successfully: {self.model_name} on {self.device}")
                return True
            except Exception as e:
                logger.exception(f"Failed to load model: {e}")
                return False

    def load_gguf_model(self, model_path: Path):
        self.model = Llama(
            model_path=str(model_path),
            n_ctx=4096,
            n_threads=8,
        )
        self.tokenizer = None 

    def load_huggingface_model(self, model_path: Path):
        self.tokenizer = AutoTokenizer.from_pretrained(model_path, trust_remote_code=True)
        self.model = AutoModelForCausalLM.from_pretrained(
            model_path,
            torch_dtype=torch.float16 if self.device == "cuda" else torch.float32,
            device_map="auto" if self.device == "cuda" else None,
            trust_remote_code=True,
            low_cpu_mem_usage=True
        )
        if self.device == "cpu":
            self.model = self.model.to(self.device)

    def unload_model(self):
        if self.model:
            logger.info(f"Unloading model: {self.model_name}")
            del self.model
            self.model = None
        if self.tokenizer:
            logger.info(f"Unloading tokenizer for model: {self.model_name}")
            del self.tokenizer
            self.tokenizer = None
        self.model_name = None
        self.loaded_model_path = None
        torch.cuda.empty_cache()
        logger.info("Model unloaded")

    def is_loaded(self) -> bool:
        return self.model is not None and self.tokenizer is not None

model_manager = ModelManager()
