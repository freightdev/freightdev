// Orchestration logic (step-by-step logic runners)

pub fn load_index_explain(path: &Path) {
    hydrate_file(path);
    index_tree(path);
    explain_code(path);
}
