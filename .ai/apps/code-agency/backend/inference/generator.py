import logging
from typing import Generator, Any, Callable

import torch

from .model_manager import model_manager
from .sampler import SamplingConfig

logger = logging.getLogger(__name__)

class TextGenerator:
    def __init__(self):
        self.generation_config = {}
        self.setup_generation_config()

    def setup_generation_config(self):
        """Setup default generation parameters"""
        self.generation_config = {
            "max_new_tokens": 512,
            "temperature": 0.7,
            "top_p": 0.9,
            "top_k": 50,
            "repetition_penalty": 1.1,
            "do_sample": True,
            "pad_token_id": None,  # Will be set when model loads
        }

    def is_model_loaded(self) -> bool:
        return model_manager.is_loaded()

    # ----------------------
    # Model loading with progress
    # ----------------------
    def load_model(self, model_json_path: str, progress_callback: Callable[[int, int], None] = None) -> bool:
        """
        Load model with optional progress callback.
        progress_callback(downloaded_bytes, total_bytes)
        """
        if self.is_model_loaded():
            model_manager.unload_model()

        success = model_manager.load_model(model_json_path, progress_callback=progress_callback)
        if success:
            # Ensure pad_token_id is set
            self.generation_config["pad_token_id"] = model_manager.tokenizer.eos_token_id
        return success

    # ----------------------
    # Generate full response
    # ----------------------
    def generate_response(self, prompt: str, **overrides) -> str:
        """Generate a complete text response from prompt"""
        if not self.is_model_loaded():
            raise RuntimeError("No model loaded")

        gen_config = self.generation_config.copy()
        gen_config.update(overrides)

        try:
            inputs = model_manager.tokenizer.encode(
                prompt,
                return_tensors="pt",
                add_special_tokens=True
            ).to(model_manager.device)

            with torch.no_grad():
                outputs = model_manager.model.generate(inputs, **gen_config)

            response = model_manager.tokenizer.decode(
                outputs[0][inputs.shape[1]:],  # skip prompt tokens
                skip_special_tokens=True
            )
            return response.strip()

        except Exception as e:
            logger.error(f"Generation failed: {e}")
            return f"Error: {str(e)}"

    # ----------------------
    # Stream response token by token
    # ----------------------
    def stream_response(self, prompt: str, **overrides) -> Generator[str, None, None]:
        """
        Stream token-by-token generation.
        Yields each token as soon as it is generated.
        """
        if not self.is_model_loaded():
            raise RuntimeError("No model loaded")

        gen_config = self.generation_config.copy()
        gen_config.update(overrides)

        try:
            inputs = model_manager.tokenizer.encode(
                prompt,
                return_tensors="pt",
                add_special_tokens=True
            ).to(model_manager.device)

            # Generate with token-level streaming
            with torch.no_grad():
                outputs = model_manager.model.generate(
                    inputs,
                    **gen_config,
                    output_scores=True,
                    return_dict_in_generate=True
                )

            generated_ids = outputs.sequences[0][inputs.shape[1]:]  # skip prompt
            for token_id in generated_ids:
                token = model_manager.tokenizer.decode(token_id.unsqueeze(0), skip_special_tokens=True)
                yield token

        except Exception as e:
            logger.error(f"Streaming generation failed: {e}")
            yield f"Error: {str(e)}"

    # ----------------------
    # Unload current model
    # ----------------------
    def unload_model(self):
        model_manager.unload_model()
        self.generation_config["pad_token_id"] = None

# ----------------------
# Global instance
# ----------------------
text_generator = TextGenerator()
