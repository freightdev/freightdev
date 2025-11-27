//! macros.rs - Global CoDriver macros for logging, formatting, and terminal output.

#[macro_export]
macro_rules! co_log {
    ($msg:expr) => {
        println!("🔹 {}", $msg);
    };
    ($fmt:expr, $($arg:tt)*) => {
        println!(concat!("🔹 ", $fmt), $($arg)*);
    };
}

#[macro_export]
macro_rules! co_warn {
    ($msg:expr) => {
        eprintln!("⚠️  {}", $msg);
    };
    ($fmt:expr, $($arg:tt)*) => {
        eprintln!(concat!("⚠️  ", $fmt), $($arg)*);
    };
}

#[macro_export]
macro_rules! co_fail {
    ($msg:expr) => {{
        eprintln!("❌ {}", $msg);
        std::process::exit(1);
    }};
    ($fmt:expr, $($arg:tt)*) => {{
        eprintln!(concat!("❌ ", $fmt), $($arg)*);
        std::process::exit(1);
    }};
}
