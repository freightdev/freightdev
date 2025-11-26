// Injects Codriver suggestions into files

pub fn inject_diff(original: &str, patch: &str) -> Result<()> {
    let merged = apply_patch(original, patch);
    fs::write(path, merged)?;
}
