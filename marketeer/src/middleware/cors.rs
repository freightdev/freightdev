use anyhow::Result;

pub struct CorsMiddleware {
    pub allow_origins: Vec<String>,
    pub allow_methods: Vec<String>,
    pub allow_headers: Vec<String>,
    pub max_age: Option<u64>,
}

impl CorsMiddleware {
    pub fn new(
        allow_origins: Vec<String>,
        allow_methods: Vec<String>,
        allow_headers: Vec<String>,
        max_age: Option<u64>,
    ) -> Self {
        Self {
            allow_origins,
            allow_methods,
            allow_headers,
            max_age,
        }
    }

    pub fn is_origin_allowed(&self, origin: &str) -> bool {
        self.allow_origins.iter().any(|o| o == "*" || o == origin)
    }

    pub fn allow_origin(&self, origin: &str) -> bool {
        self.is_origin_allowed(origin)
    }

    pub fn get_allow_methods(&self) -> String {
        self.allow_methods.join(", ")
    }

    pub fn get_allow_headers(&self) -> String {
        self.allow_headers.join(", ")
    }

    pub fn get_max_age(&self) -> String {
        self.max_age.unwrap_or(86400).to_string()
    }
}
