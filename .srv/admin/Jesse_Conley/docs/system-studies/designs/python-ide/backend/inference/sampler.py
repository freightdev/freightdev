import logging
from typing import Dict, Any
from dataclasses import dataclass

logger = logging.getLogger(__name__)

@dataclass
class SamplingConfig:
    """Configuration for text generation sampling."""
    temperature: float = 0.7
    top_p: float = 0.9
    top_k: int = 50
    repetition_penalty: float = 1.1
    max_new_tokens: int = 512
    do_sample: bool = True
    early_stopping: bool = True

    def to_dict(self) -> Dict[str, Any]:
        """Convert the sampling config to a dictionary."""
        return {
            "temperature": self.temperature,
            "top_p": self.top_p,
            "top_k": self.top_k,
            "repetition_penalty": self.repetition_penalty,
            "max_new_tokens": self.max_new_tokens,
            "do_sample": self.do_sample,
            "early_stopping": self.early_stopping,
        }

    @classmethod
    def for_code(cls) -> "SamplingConfig":
        """Optimized settings for code generation."""
        return cls(
            temperature=0.3,
            top_p=0.95,
            top_k=40,
            repetition_penalty=1.05,
            max_new_tokens=1024,
            do_sample=True
        )

    @classmethod
    def for_chat(cls) -> "SamplingConfig":
        """Optimized settings for conversational AI."""
        return cls(
            temperature=0.8,
            top_p=0.9,
            top_k=50,
            repetition_penalty=1.1,
            max_new_tokens=512,
            do_sample=True
        )

    @classmethod
    def for_reasoning(cls) -> "SamplingConfig":
        """Optimized settings for logical reasoning tasks."""
        return cls(
            temperature=0.4,
            top_p=0.95,
            top_k=30,
            repetition_penalty=1.08,
            max_new_tokens=800,
            do_sample=True
        )


class StoppingCriteria:
    """Custom stopping criteria for text generation to avoid loops or repetition."""

    @staticmethod
    def detect_repetition(text: str, window_size: int = 50) -> bool:
        """Detect repeated patterns in generated text."""
        if len(text) < window_size * 2:
            return False
        recent = text[-window_size:]
        previous = text[-window_size*2:-window_size]
        return recent == previous

    @staticmethod
    def should_stop(generated_text: str, max_repetitions: int = 3) -> bool:
        """
        Determine if generation should stop due to repetition.
        Currently, stops if immediate repetition is detected.
        """
        return StoppingCriteria.detect_repetition(generated_text)
