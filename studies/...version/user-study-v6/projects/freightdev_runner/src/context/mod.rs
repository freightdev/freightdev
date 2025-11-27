use crate::{
    error::{Error, Result},
    model::Model,
};
use std::ptr::NonNull;

pub mod context;
pub mod _utils;

pub use context::Context;

pub struct ContextConfig {
    pub n_ctx: u32,
    pub n_batch: u32,
    pub n_threads: i32,
    pub n_threads_batch: i32,
    pub rope_scaling_type: RopeScalingType,
    pub rope_freq_base: f32,
    pub rope_freq_scale: f32,
    pub yarn_ext_factor: f32,
    pub yarn_attn_factor: f32,
    pub yarn_beta_fast: f32,
    pub yarn_beta_slow: f32,
    pub mul_mat_q: bool,
    pub logits_all: bool,
    pub embedding: bool,
    pub offload_kqv: bool,
}

impl Default for ContextConfig {
    fn default() -> Self {
        Self {
            n_ctx: 2048,
            n_batch: 512,
            n_threads: -1,
            n_threads_batch: -1,
            rope_scaling_type: RopeScalingType::None,
            rope_freq_base: 0.0,
            rope_freq_scale: 0.0,
            yarn_ext_factor: -1.0,
            yarn_attn_factor: 1.0,
            yarn_beta_fast: 32.0,
            yarn_beta_slow: 1.0,
            mul_mat_q: true,
            logits_all: false,
            embedding: false,
            offload_kqv: true,
        }
    }
}

#[derive(Debug, Clone, Copy)]
pub enum RopeScalingType {
    None = 0,
    Linear = 1,
    Yarn = 2,
}

pub struct ContextState {
    pub n_past: usize,
    pub n_remain: i32,
    pub n_consumed: i32,
    pub n_session_consumed: i32,
    pub n_past_best: usize,
}

impl Default for ContextState {
    fn default() -> Self {
        Self {
            n_past: 0,
            n_remain: 0,
            n_consumed: 0,
            n_session_consumed: 0,
            n_past_best: 0,
        }
    }
}

pub trait ContextTrait {
    fn new(model: &Model) -> Result<Self> where Self: Sized;
    fn with_config(model: &Model, config: ContextConfig) -> Result<Self> where Self: Sized;
    fn eval(&mut self, tokens: &[i32], n_past: usize) -> Result<()>;
    fn decode(&mut self, batch: &TokenBatch) -> Result<()>;
    fn get_logits(&self) -> Option<&[f32]>;
    fn get_embeddings(&self) -> Option<&[f32]>;
    fn get_kv_cache_token_count(&self) -> i32;
    fn clear_kv_cache(&mut self);
    fn remove_kv_cache_tokens(&mut self, c0: i32, c1: i32);
    fn shift_kv_cache(&mut self, n_keep: i32, n_discard: i32, n_shift: i32);
    fn state(&self) -> &ContextState;
    fn state_mut(&mut self) -> &mut ContextState;
}

pub struct TokenBatch {
    pub tokens: Vec<i32>,
    pub positions: Vec<i32>,
    pub n_seq_id: Vec<i32>,
    pub seq_id: Vec<Vec<i32>>,
    pub logits: Vec<i8>,
}

impl TokenBatch {
    pub fn new(n_tokens: usize, n_seq_max: usize) -> Self {
        Self {
            tokens: Vec::with_capacity(n_tokens),
            positions: Vec::with_capacity(n_tokens),
            n_seq_id: Vec::with_capacity(n_tokens),
            seq_id: Vec::with_capacity(n_tokens),
            logits: Vec::with_capacity(n_tokens),
        }
    }

    pub fn clear(&mut self) {
        self.tokens.clear();
        self.positions.clear();
        self.n_seq_id.clear();
        self.seq_id.clear();
        self.logits.clear();
    }

    pub fn add(&mut self, token: i32, pos: i32, seq_ids: &[i32], logit: bool) {
        self.tokens.push(token);
        self.positions.push(pos);
        self.n_seq_id.push(seq_ids.len() as i32);
        self.seq_id.push(seq_ids.to_vec());
        self.logits.push(if logit { 1 } else { 0 });
    }

    pub fn len(&self) -> usize {
        self.tokens.len()
    }

    pub fn is_empty(&self) -> bool {
        self.tokens.is_empty()
    }
}