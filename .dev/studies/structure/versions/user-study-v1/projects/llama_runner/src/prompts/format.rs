//! prompt/format.rs — formats raw input into model-ready prompt strings

pub fn format_user_prompt(input: &str) -> String {
    format!("[INST] {} [/INST]\n", input.trim())
}
