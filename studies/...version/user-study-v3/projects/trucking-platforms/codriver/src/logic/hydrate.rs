// Turns file → context

pub fn hydrate_from_file(path: &Path) -> HydratedContext {
    let content = fs::read_to_string(path)?;
    let tokens = tokenize(content);
    build_context_tree(tokens)
}
