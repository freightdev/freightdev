import logging
from typing import List, Dict
from pathlib import Path

import hashlib
import numpy as np
import faiss
import pickle

from sentence_transformers import SentenceTransformer

from ..app.config import settings

logger = logging.getLogger(__name__)

class EmbeddingManager:
    def __init__(self, similarity_threshold: float = 0.7):
        self.similarity_threshold = similarity_threshold
        self.model: SentenceTransformer | None = None
        self.index: faiss.Index | None = None
        self.id_to_metadata: Dict[int, Dict] = {}
        self.embedding_dim: int = settings.embedding_dim
        self.index_path = Path("data/embeddings/faiss_index.bin")
        self.metadata_path = Path("data/embeddings/metadata.pkl")
        
    def initialize(self) -> bool:
        """Initialize embedding model and FAISS index"""
        try:
            self.model = SentenceTransformer('all-MiniLM-L6-v2')
            self.embedding_dim = self.model.get_sentence_embedding_dimension()
            self._load_or_create_index()
            logger.info(f"Embedding manager initialized with dim={self.embedding_dim}")
            return True
        except Exception as e:
            logger.error(f"Failed to initialize embeddings: {e}")
            return False
    
    def _load_or_create_index(self):
        """Load existing FAISS index or create a new one"""
        self.index_path.parent.mkdir(parents=True, exist_ok=True)
        
        if self.index_path.exists():
            try:
                self.index = faiss.read_index(str(self.index_path))
                if self.metadata_path.exists():
                    with open(self.metadata_path, 'rb') as f:
                        self.id_to_metadata = pickle.load(f)
                logger.info(f"Loaded FAISS index with {self.index.ntotal} vectors")
                return
            except Exception as e:
                logger.warning(f"Failed to load existing index: {e}")
        
        self.index = faiss.IndexFlatIP(self.embedding_dim)
        logger.info("Created new FAISS index")
    
    def encode_text(self, texts: List[str]) -> np.ndarray:
        """Generate normalized embeddings for a list of texts"""
        if not self.model:
            raise RuntimeError("Embedding model not initialized")
        embeddings = self.model.encode(texts, convert_to_numpy=True)
        embeddings = embeddings / np.linalg.norm(embeddings, axis=1, keepdims=True)
        return embeddings
    
    def add_embeddings(self, texts: List[str], metadata: List[Dict]) -> List[int]:
        """Add text embeddings to the FAISS index with metadata"""
        embeddings = self.encode_text(texts)
        start_id = self.index.ntotal
        self.index.add(embeddings.astype(np.float32))
        
        for i, meta in enumerate(metadata):
            vector_id = start_id + i
            self.id_to_metadata[vector_id] = {
                **meta,
                'text': texts[i],
                'content_hash': hashlib.sha256(texts[i].encode()).hexdigest()
            }
        
        self._save_index()
        return list(range(start_id, start_id + len(texts)))
    
    def search_similar(self, query: str, k: int = 5) -> List[Dict]:
        """Search for similar text chunks"""
        if not self.index or self.index.ntotal == 0:
            return []
        
        query_embedding = self.encode_text([query])
        scores, indices = self.index.search(query_embedding.astype(np.float32), k)
        
        results = []
        for score, idx in zip(scores[0], indices[0]):
            if idx == -1 or score < self.similarity_threshold:
                continue
            metadata = self.id_to_metadata.get(idx, {})
            results.append({
                'similarity': float(score),
                'text': metadata.get('text', ''),
                'metadata': metadata,
                'index': int(idx)
            })
        return results
    
    def _save_index(self):
        """Save FAISS index and metadata to disk"""
        try:
            faiss.write_index(self.index, str(self.index_path))
            with open(self.metadata_path, 'wb') as f:
                pickle.dump(self.id_to_metadata, f)
        except Exception as e:
            logger.error(f"Failed to save index: {e}")

# Global embedding manager instance
embedding_manager = EmbeddingManager()
