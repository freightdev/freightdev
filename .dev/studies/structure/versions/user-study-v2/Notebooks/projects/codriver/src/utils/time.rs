use chrono::Utc;

pub fn now_utc_string() -> String {
    Utc::now().to_rfc3339()
}
