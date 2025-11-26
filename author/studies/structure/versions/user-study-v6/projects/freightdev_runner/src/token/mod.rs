use crate::{
    context::Context,
    error::{Error, Result},
    constants::*,
};

pub mod batch;
pub mod decode;
pub mod encode;
pub mod tokenize;
pub mod _utils;

pub use batch::TokenBatch;
pub use decode::TokenDecoder;
pub use encode::TokenEncoder;
pub use tokenize::Tokenizer;

pub struct TokenProcessor {
    tokenizer: Tokenizer,
    encoder: TokenEncoder,
    decoder: TokenDecoder,
}

impl TokenProcessor {
    pub fn new(context: &Context) -> Result<Self> {
        let tokenizer = Tokenizer::new(context)?;
        let encoder = TokenEncoder::new(context)?;
        let decoder = TokenDecoder::new(context)?;

        Ok(Self {
            tokenizer,
            encoder,
            decoder,
        })
    }

    pub fn tokenize(&self, text: &str) -> Result<Vec<i32>> {
        self.tokenizer.tokenize(text)
    }

    pub fn tokenize_with_special(&self, text: &str, add_bos: bool, parse_special: bool) -> Result<Vec<i32>> {
        self.tokenizer.tokenize_with_special(text, add_bos, parse_special)
    }

    pub fn detokenize(&self, tokens: &[i32]) -> Result<String> {
        self.decoder.detokenize(tokens)
    }

    pub fn encode(&self, text: &str) -> Result<Vec<i32>> {
        self.encoder.encode(text)
    }

    pub fn decode(&self, tokens: &[i32]) -> Result<String> {
        self.decoder.decode(tokens)
    }

    pub fn token_to_piece(&self, token: i32) -> Result<String> {
        self.decoder.token_to_piece(token)
    }

    pub fn piece_to_token(&self, piece: &str) -> Result<i32> {
        self.encoder.piece_to_token(piece)
    }

    pub fn vocab_size(&self) -> usize {
        self.tokenizer.vocab_size()
    }

    pub fn is_special_token(&self, token: i32) -> bool {
        matches!(token, BOS_TOKEN | EOS_TOKEN | UNK_TOKEN | PAD_TOKEN)
    }

    pub fn is_bos_token(&self, token: i32) -> bool {
        token == BOS_TOKEN
    }

    pub fn is_eos_token(&self, token: i32) -> bool {
        token == EOS_TOKEN
    }

    pub fn is_unk_token(&self, token: i32) -> bool {
        token == UNK_TOKEN
    }

    pub fn is_pad_token(&self, token: i32) -> bool {
        token == PAD_TOKEN
    }

    pub fn bos_token(&self) -> i32 {
        BOS_TOKEN
    }

    pub fn eos_token(&self) -> i32 {
        EOS_TOKEN
    }

    pub fn unk_token(&self) -> i32 {
        UNK_TOKEN
    }

    pub fn pad_token(&self) -> i32 {
        PAD_TOKEN
    }

    pub fn create_batch(&self, capacity: usize) -> TokenBatch {
        TokenBatch::new(capacity)
    }

    pub fn add_to_batch(&self, batch: &mut TokenBatch, tokens: &[i32], positions: &[i32]) -> Result<()> {
        if tokens.len() != positions.len() {
            return Err(Error::TokenError("Token and position arrays must have same length".to_string()));
        }

        for (i, (&token, &pos)) in tokens.iter().zip(positions.iter()).enumerate() {
            let logit = i == tokens.len() - 1; // Only last token needs logits
            batch.add(token, pos, &[0], logit);
        }

        Ok(())
    }

    pub fn clear_batch(&self, batch: &mut TokenBatch) {
        batch.clear();
    }
}

pub trait TokenTrait {
    fn tokenize(&self, text: &str) -> Result<Vec<i32>>;
    fn detokenize(&self, tokens: &[i32]) -> Result<String>;
    fn vocab_size(&self) -> usize;
}

#[derive(Debug, Clone)]
pub struct TokenInfo {
    pub token: i32,
    pub piece: String,
    pub score: f32,
    pub token_type: TokenType,
}

#[derive(Debug, Clone, PartialEq)]
pub enum TokenType {
    Normal,
    Unknown,
    Control,
    UserDefined,
    Unused,
    Byte,
}

impl Default for TokenType {
    fn default() -> Self {
        TokenType::Normal
    }
}

pub struct TokenStats {
    pub total_tokens: usize,
    pub unique_tokens: usize,
    pub special_tokens: usize,
    pub avg_token_length: f32,
}

impl TokenStats {
    pub fn new() -> Self {
        Self {
            total_tokens: 0,
            unique_tokens: 0,
            special_tokens: 0,
            avg_token_length: 0.0,
        }
    }

    pub fn update(&mut self, tokens: &[i32], processor: &TokenProcessor) {
        self.total_tokens = tokens.len();
        self.unique_tokens = tokens.iter().collect::<std::collections::HashSet<_>>().len();
        self.special_tokens = tokens.iter().filter(|&&t| processor.is_special_token(t)).count();
        
        let total_length: usize = tokens.iter()
            .filter_map(|&token| processor.token_to_piece(token).ok())
            .map(|piece| piece.len())
            .sum();
        
        self.avg_token_length = if self.total_tokens > 0 {
            total_length as f32 / self.total_tokens as f32
        } else {
            0.0
        };
    }
}