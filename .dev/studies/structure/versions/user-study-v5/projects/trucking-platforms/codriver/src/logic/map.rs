// Turns raw signals into actionables

pub fn handle(signal: Signal) {
    match signal {
        Signal::FileOpened(p) => flow::load_index_explain(&p),
        Signal::ModelNeedHelp => flow::ask_model_for_explanation(),
        _ => {}
    }
}
