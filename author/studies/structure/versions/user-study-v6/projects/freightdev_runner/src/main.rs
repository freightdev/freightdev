use echo_ops::{
    context::Context,
    core::Engine,
    error::Result,
    model::Model,
    runtime::Runtime,
    token::TokenProcessor,
};

fn main() -> Result<()> {
    let engine = Engine::new()?;
    let model = Model::load_from_path("../models/openchat-3.5-1210/Q4_K_M/openchat-3.5-1210.Q4_K_M.gguf")?;
    let context = Context::new(&model)?;
    let token_processor = TokenProcessor::new(&context)?;
    let runtime = Runtime::new(engine, model, context, token_processor)?;
    
    runtime.run()?;
    
    Ok(())
}