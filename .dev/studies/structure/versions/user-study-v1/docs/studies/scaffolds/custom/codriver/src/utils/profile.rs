use std::time::{Duration, Instant};

/// Lightweight profiler for measuring scoped operations
pub struct Profiler {
    label: &'static str,
    start: Instant,
}

impl Profiler {
    pub fn start(label: &'static str) -> Self {
        println!("⏱️  Starting: {}", label);
        Self {
            label,
            start: Instant::now(),
        }
    }

    pub fn end(self) -> Duration {
        let elapsed = self.start.elapsed();
        println!(
            "✅ {} completed in {:.3}s",
            self.label,
            elapsed.as_secs_f64()
        );
        elapsed
    }
}

/// One-liner scoped profiler
#[macro_export]
macro_rules! profile {
    ($label:literal, $block:block) => {{
        let __p = $crate::profile::Profiler::start($label);
        let __result = $block;
        __p.end();
        __result
    }};
}
