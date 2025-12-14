use crate::{
    context::Context,
    core::Engine,
    error::{Error, Result},
    model::Model,
    token::TokenProcessor,
};

pub mod batch;
pub mod interactive;
pub mod streaming;
pub mod websocket;
pub mod _utils;

pub use interactive::Interactive;
pub use batch::Batch;
pub use streaming::Streaming;
pub use websocket::WebSocket;

pub enum RuntimeMode {
    Interactive,
    Batch,
    Streaming,
    WebSocket,
}

pub struct Runtime {
    engine: Engine,
    model: Model,
    context: Context,
    token_processor: TokenProcessor,
    mode: RuntimeMode,
}

impl Runtime {
    pub fn new(
        engine: Engine,
        model: Model,
        context: Context,
        token_processor: TokenProcessor,
    ) -> Result<Self> {
        Ok(Self {
            engine,
            model,
            context,
            token_processor,
            mode: RuntimeMode::Interactive,
        })
    }

    pub fn with_mode(mut self, mode: RuntimeMode) -> Self {
        self.mode = mode;
        self
    }

    pub fn set_mode(&mut self, mode: RuntimeMode) {
        self.mode = mode;
    }

    pub fn run(&self) -> Result<()> {
        match self.mode {
            RuntimeMode::Interactive => self.run_interactive(),
            RuntimeMode::Batch => self.run_batch(),
            RuntimeMode::Streaming => self.run_streaming(),
            RuntimeMode::WebSocket => self.run_websocket(),
        }
    }

    fn run_interactive(&self) -> Result<()> {
        let interactive = Interactive::new(&self.engine, &self.model, &self.context, &self.token_processor)?;
        interactive.run()
    }

    fn run_batch(&self) -> Result<()> {
        let batch = Batch::new(&self.engine, &self.model, &self.context, &self.token_processor)?;
        batch.run()
    }

    fn run_streaming(&self) -> Result<()> {
        let streaming = Streaming::new(&self.engine, &self.model, &self.context, &self.token_processor)?;
        streaming.run()
    }

    fn run_websocket(&self) -> Result<()> {
        let websocket = WebSocket::new(&self.engine, &self.model, &self.context, &self.token_processor)?;
        websocket.run()
    }
}

pub trait RuntimeTrait {
    fn new(
        engine: &Engine,
        model: &Model,
        context: &Context,
        token_processor: &TokenProcessor,
    ) -> Result<Self> where Self: Sized;
    
    fn run(&self) -> Result<()>;
    fn stop(&mut self) -> Result<()>;
    fn is_running(&self) -> bool;
}