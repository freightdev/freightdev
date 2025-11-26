use std::time::Instant;

/// Captures generation performance data
pub struct GenerationStats {
    pub tokens_generated: usize,
    pub elapsed_secs: f64,
}

impl GenerationStats {
    pub fn new(tokens_generated: usize, elapsed_secs: f64) -> Self {
        Self {
            tokens_generated,
            elapsed_secs,
        }
    }

    pub fn tokens_per_second(&self) -> f64 {
        if self.elapsed_secs <= 0.0 {
            0.0
        } else {
            self.tokens_generated as f64 / self.elapsed_secs
        }
    }
}

/// Measures time around generation or decoding segments
pub struct Timer {
    start: Instant,
}

impl Timer {
    pub fn start() -> Self {
        Self {
            start: Instant::now(),
        }
    }

    pub fn stop(&self, tokens_generated: usize) -> GenerationStats {
        let elapsed = self.start.elapsed().as_secs_f64();
        GenerationStats::new(tokens_generated, elapsed)
    }
}
