// Event-based or reactive triggers (file opened, user paused, file changed)

on_signal(Signal::FileOpened(path)) {
    if path.ends_with(".rs") {
        Flow::load_index_explain(path)
    }
}