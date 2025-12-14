
// Pronunciation optimization configuration
pub const PRONUNCIATION_CONFIG: &str = r#"{
    "special_tokens": {
        "proper_nouns": {
            "names": true,
            "places": true,
            "brands": true
        },
        "phonetic_hints": true,
        "stress_patterns": true
    },
    "tokenization": {
        "preserve_capitalization": true,
        "word_boundaries": true,
        "syllable_breaks": false
    },
    "generation": {
        "temperature": 0.1,
        "top_p": 0.9,
        "repetition_penalty": 1.1
    }
}"#;
