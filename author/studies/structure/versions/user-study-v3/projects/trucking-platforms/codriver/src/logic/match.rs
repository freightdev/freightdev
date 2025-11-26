// Pattern matchers (file type → strategy)

pub fn match_file_type(path: &Path) -> Option<Lang> {
    if path.ends_with(".rs") { Some(Lang::Rust) }
    else if path.ends_with(".py") { Some(Lang::Python) }
    else { None }
}
