#!/bin/bash

# Enterprise Leptos Application Structure Generator
# This script creates a complete enterprise-grade Leptos application structure

set -e

PROJECT_NAME="${1:-enterprise-leptos-app}"
echo "Creating enterprise Leptos application: $PROJECT_NAME"

# Create main project directory
mkdir -p "$PROJECT_NAME"
cd "$PROJECT_NAME"

# Create root-level directories and files
mkdir -p .github/workflows docs/{api,deployment,development} scripts migrations tests/{integration,e2e,load}
mkdir -p config k8s terraform/modules/{database,cache,storage} monitoring/{prometheus,grafana/dashboards,alertmanager}

# Create crates directory structure
mkdir -p crates/{app,shared,api,database,auth,notification,analytics,storage,cache,search,queue,monitoring,integration,cli,testing}

# Create app crate structure
mkdir -p crates/app/src/{routes,components/{layout,forms,charts,tables,modals,ui},pages/{auth,dashboard,portal,admin,profile,errors},hooks,stores,utils}
mkdir -p crates/app/{style/{components,pages,themes},assets/{images,icons,fonts},public}

# Create shared crate structure
mkdir -p crates/shared/src/{types,dto,validation,constants,utils}

# Create api crate structure
mkdir -p crates/api/src/{config,handlers,middleware,services,repositories,models,extractors,utils}

# Create other crate structures
mkdir -p crates/database/src
mkdir -p crates/auth/src
mkdir -p crates/notification/src/templates
mkdir -p crates/analytics/src
mkdir -p crates/storage/src
mkdir -p crates/cache/src
mkdir -p crates/search/src
mkdir -p crates/queue/src/{jobs,workers}
mkdir -p crates/monitoring/src
mkdir -p crates/integration/src/{payment,crm,social}
mkdir -p crates/cli/src/{commands,utils}
mkdir -p crates/testing/src/{fixtures,helpers,factories}

echo "📁 Directory structure created!"

# Generate root Cargo.toml
cat > Cargo.toml << 'EOF'
[workspace]
members = [
    "crates/app",
    "crates/shared",
    "crates/api",
    "crates/database",
    "crates/auth",
    "crates/notification",
    "crates/analytics",
    "crates/storage",
    "crates/cache",
    "crates/search",
    "crates/queue",
    "crates/monitoring",
    "crates/integration",
    "crates/cli",
    "crates/testing"
]

[workspace.dependencies]
leptos = { version = "0.5", features = ["nightly"] }
leptos_axum = "0.5"
leptos_meta = "0.5"
leptos_router = "0.5"
axum = "0.7"
tokio = { version = "1", features = ["full"] }
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
sqlx = { version = "0.7", features = ["runtime-tokio-rustls", "postgres", "chrono", "uuid"] }
uuid = { version = "1.0", features = ["serde", "v4"] }
chrono = { version = "0.4", features = ["serde"] }
anyhow = "1.0"
thiserror = "1.0"
tracing = "0.1"
tracing-subscriber = { version = "0.3", features = ["env-filter"] }
jsonwebtoken = "9.0"
bcrypt = "0.15"
config = "0.14"
redis = "0.24"

[profile.release]
lto = true
codegen-units = 1
panic = "abort"
EOF

# Generate main app Cargo.toml
cat > crates/app/Cargo.toml << 'EOF'
[package]
name = "app"
version = "0.1.0"
edition = "2021"

[lib]
crate-type = ["cdylib", "rlib"]

[dependencies]
leptos = { workspace = true, features = ["nightly", "ssr"] }
leptos_axum = { workspace = true, optional = true }
leptos_meta = { workspace = true, features = ["ssr"] }
leptos_router = { workspace = true, features = ["ssr"] }
axum = { workspace = true, optional = true, features = ["macros", "tower-log"] }
tokio = { workspace = true, optional = true }
tower = { version = "0.4", optional = true }
tower-http = { version = "0.5", features = ["fs"], optional = true }
wasm-bindgen = "0.2"
console_log = "1"
console_error_panic_hook = "0.1"
serde = { workspace = true }
serde_json = { workspace = true }
shared = { path = "../shared" }

[features]
csr = ["leptos/csr", "leptos_meta/csr", "leptos_router/csr"]
hydrate = ["leptos/hydrate", "leptos_meta/hydrate", "leptos_router/hydrate"]
ssr = [
    "dep:axum",
    "dep:tokio",
    "dep:tower",
    "dep:tower-http",
    "dep:leptos_axum",
    "leptos/ssr",
    "leptos_meta/ssr",
    "leptos_router/ssr",
]

[package.metadata.cargo-all-features]
denylist = ["axum", "tokio", "tower", "tower-http", "leptos_axum"]
skip_feature_sets = [["csr", "ssr"], ["csr", "hydrate"], ["ssr", "hydrate"]]

[package.metadata.leptos]
output-name = "enterprise-app"
site-root = "target/site"
site-pkg-dir = "pkg"
style-file = "style/main.scss"
assets-dir = "assets"
site-addr = "127.0.0.1:3000"
reload-port = 3001
browserquery = "defaults"
watch = false
env = "DEV"
bin-features = ["ssr"]
bin-default-features = false
lib-features = ["hydrate"]
lib-default-features = false
lib-profile-release = "wee_alloc"
EOF

# Generate shared crate Cargo.toml
cat > crates/shared/Cargo.toml << 'EOF'
[package]
name = "shared"
version = "0.1.0"
edition = "2021"

[dependencies]
serde = { workspace = true }
serde_json = { workspace = true }
uuid = { workspace = true }
chrono = { workspace = true }
anyhow = { workspace = true }
thiserror = { workspace = true }
validator = { version = "0.16", features = ["derive"] }

[features]
default = []
EOF

# Generate API crate Cargo.toml
cat > crates/api/Cargo.toml << 'EOF'
[package]
name = "api"
version = "0.1.0"
edition = "2021"

[dependencies]
axum = { workspace = true, features = ["macros", "tower-log", "multipart"] }
tokio = { workspace = true }
serde = { workspace = true }
serde_json = { workspace = true }
sqlx = { workspace = true }
uuid = { workspace = true }
chrono = { workspace = true }
anyhow = { workspace = true }
thiserror = { workspace = true }
tracing = { workspace = true }
tracing-subscriber = { workspace = true }
jsonwebtoken = { workspace = true }
bcrypt = { workspace = true }
config = { workspace = true }
tower = "0.4"
tower-http = { version = "0.5", features = ["cors", "fs"] }
shared = { path = "../shared" }
database = { path = "../database" }
auth = { path = "../auth" }
EOF

# Generate database crate Cargo.toml
cat > crates/database/Cargo.toml << 'EOF'
[package]
name = "database"
version = "0.1.0"
edition = "2021"

[dependencies]
sqlx = { workspace = true, features = ["migrate"] }
anyhow = { workspace = true }
shared = { path = "../shared" }
EOF

# Generate auth crate Cargo.toml
cat > crates/auth/Cargo.toml << 'EOF'
[package]
name = "auth"
version = "0.1.0"
edition = "2021"

[dependencies]
jsonwebtoken = { workspace = true }
bcrypt = { workspace = true }
serde = { workspace = true }
chrono = { workspace = true }
anyhow = { workspace = true }
thiserror = { workspace = true }
shared = { path = "../shared" }
EOF

# Generate notification crate Cargo.toml
cat > crates/notification/Cargo.toml << 'EOF'
[package]
name = "notification"
version = "0.1.0"
edition = "2021"

[dependencies]
tokio = { workspace = true }
serde = { workspace = true }
anyhow = { workspace = true }
lettre = "0.11"
reqwest = { version = "0.11", features = ["json"] }
tera = "1.19"
shared = { path = "../shared" }
EOF

# Generate other crate Cargo.toml files
for crate in analytics storage cache search queue monitoring integration cli testing; do
cat > "crates/$crate/Cargo.toml" << EOF
[package]
name = "$crate"
version = "0.1.0"
edition = "2021"

[dependencies]
serde = { workspace = true }
anyhow = { workspace = true }
shared = { path = "../shared" }
EOF
done

echo "📦 Cargo.toml files generated!"

# Generate main app files
cat > crates/app/src/main.rs << 'EOF'
#[cfg(feature = "ssr")]
#[tokio::main]
async fn main() {
    use app::*;
    use axum::Router;
    use leptos::*;
    use leptos_axum::{generate_route_list, LeptosRoutes};

    simple_logger::init_with_level(log::Level::Debug).expect("couldn't initialize logging");

    let conf = get_configuration(None).await.unwrap();
    let leptos_options = conf.leptos_options;
    let addr = leptos_options.site_addr;
    let routes = generate_route_list(App);

    let app = Router::new()
        .leptos_routes(&leptos_options, routes, App)
        .fallback(file_and_error_handler)
        .with_state(leptos_options);

    println!("🚀 Server starting at http://{}", &addr);
    let listener = tokio::net::TcpListener::bind(&addr).await.unwrap();
    axum::serve(listener, app.into_make_service())
        .await
        .unwrap();
}

#[cfg(not(feature = "ssr"))]
pub fn main() {
    // This is required so that wasm-pack works
}
EOF

cat > crates/app/src/lib.rs << 'EOF'
pub mod app;
pub mod error_template;
#[cfg(feature = "ssr")]
pub mod fileserv;
pub mod routes;
pub mod components;
pub mod pages;
pub mod hooks;
pub mod stores;
pub mod utils;

#[cfg(feature = "hydrate")]
#[wasm_bindgen::prelude::wasm_bindgen]
pub fn hydrate() {
    use crate::app::*;
    console_error_panic_hook::set_once();
    leptos::mount_to_body(App);
}
EOF

cat > crates/app/src/app.rs << 'EOF'
use leptos::*;
use leptos_meta::*;
use leptos_router::*;
use crate::error_template::{AppError, ErrorTemplate};
use crate::pages::{home::HomePage, auth::login::LoginPage};

#[component]
pub fn App() -> impl IntoView {
    provide_meta_context();

    view! {
        <Stylesheet id="leptos" href="/pkg/app.css"/>
        <Title text="Enterprise Leptos App"/>

        <Router fallback=|| {
            let mut outside_errors = Errors::default();
            outside_errors.insert_with_default_key(AppError::NotFound);
            view! {
                <ErrorTemplate outside_errors/>
            }.into_view()
        }>
            <main>
                <Routes>
                    <Route path="" view=HomePage/>
                    <Route path="/login" view=LoginPage/>
                </Routes>
            </main>
        </Router>
    }
}
EOF

# Generate basic component files
cat > crates/app/src/components/mod.rs << 'EOF'
pub mod layout;
pub mod forms;
pub mod charts;
pub mod tables;
pub mod modals;
pub mod ui;
EOF

cat > crates/app/src/components/ui/mod.rs << 'EOF'
pub mod button;
pub mod card;
pub mod spinner;
pub mod alert;
pub mod tooltip;
EOF

cat > crates/app/src/components/ui/button.rs << 'EOF'
use leptos::*;

#[component]
pub fn Button(
    #[prop(into)] text: String,
    #[prop(optional)] variant: Option<String>,
    #[prop(optional)] on_click: Option<Box<dyn Fn() + 'static>>,
) -> impl IntoView {
    let variant = variant.unwrap_or_else(|| "primary".to_string());

    view! {
        <button
            class=format!("btn btn-{}", variant)
            on:click=move |_| {
                if let Some(ref handler) = on_click {
                    handler();
                }
            }
        >
            {text}
        </button>
    }
}
EOF

# Generate page files
cat > crates/app/src/pages/mod.rs << 'EOF'
pub mod home;
pub mod auth;
pub mod dashboard;
pub mod portal;
pub mod admin;
pub mod profile;
pub mod errors;
EOF

cat > crates/app/src/pages/home.rs << 'EOF'
use leptos::*;
use crate::components::ui::button::Button;

#[component]
pub fn HomePage() -> impl IntoView {
    view! {
        <div class="home-page">
            <h1>"Welcome to Enterprise Leptos App"</h1>
            <p>"A scalable, enterprise-grade web application built with Leptos and Rust"</p>
            <Button text="Get Started".to_string() />
        </div>
    }
}
EOF

cat > crates/app/src/pages/auth/mod.rs << 'EOF'
pub mod login;
pub mod register;
pub mod forgot_password;
pub mod reset_password;
EOF

cat > crates/app/src/pages/auth/login.rs << 'EOF'
use leptos::*;
use crate::components::ui::button::Button;

#[component]
pub fn LoginPage() -> impl IntoView {
    let (username, set_username) = create_signal(String::new());
    let (password, set_password) = create_signal(String::new());

    view! {
        <div class="login-page">
            <div class="login-form">
                <h2>"Sign In"</h2>
                <form>
                    <div class="form-group">
                        <label for="username">"Username"</label>
                        <input
                            type="text"
                            id="username"
                            prop:value=username
                            on:input=move |ev| {
                                set_username(event_target_value(&ev));
                            }
                        />
                    </div>
                    <div class="form-group">
                        <label for="password">"Password"</label>
                        <input
                            type="password"
                            id="password"
                            prop:value=password
                            on:input=move |ev| {
                                set_password(event_target_value(&ev));
                            }
                        />
                    </div>
                    <Button text="Sign In".to_string() />
                </form>
            </div>
        </div>
    }
}
EOF

# Generate shared types
cat > crates/shared/src/lib.rs << 'EOF'
pub mod types;
pub mod dto;
pub mod validation;
pub mod constants;
pub mod utils;

pub use types::*;
pub use dto::*;
EOF

cat > crates/shared/src/types/mod.rs << 'EOF'
pub mod user;
pub mod auth;
pub mod dashboard;
pub mod admin;
pub mod portal;
pub mod api_response;
pub mod error;
EOF

cat > crates/shared/src/types/user.rs << 'EOF'
use serde::{Deserialize, Serialize};
use uuid::Uuid;
use chrono::{DateTime, Utc};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct User {
    pub id: Uuid,
    pub email: String,
    pub username: String,
    pub first_name: String,
    pub last_name: String,
    pub is_active: bool,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreateUserRequest {
    pub email: String,
    pub username: String,
    pub password: String,
    pub first_name: String,
    pub last_name: String,
}
EOF

# Generate error template
cat > crates/app/src/error_template.rs << 'EOF'
use leptos::*;
use thiserror::Error;

#[derive(Clone, Debug, Error)]
pub enum AppError {
    #[error("Not Found")]
    NotFound,
    #[error("Internal Server Error")]
    InternalServerError,
}

impl AppError {
    pub fn status_code(&self) -> u16 {
        match self {
            AppError::NotFound => 404,
            AppError::InternalServerError => 500,
        }
    }
}

#[component]
pub fn ErrorTemplate(
    #[prop(optional)] outside_errors: Option<Errors>,
    #[prop(optional)] errors: Option<RwSignal<Errors>>,
) -> impl IntoView {
    let errors = match outside_errors {
        Some(e) => create_rw_signal(e),
        None => match errors {
            Some(e) => e,
            None => panic!("No Errors found and we expected errors!"),
        },
    };

    view! {
        <div class="error-template">
            <h1>"Something went wrong."</h1>
            {move || {
                errors.with(|errors| {
                    errors.iter()
                        .map(|(_, v)| view! { <p>{v.to_string()}</p> })
                        .collect_view()
                })
            }}
        </div>
    }
}
EOF

# Generate fileserv for SSR
cat > crates/app/src/fileserv.rs << 'EOF'
#[cfg(feature = "ssr")]
use axum::{
    body::Body as AxumBody,
    extract::State,
    http::{Request, Response, StatusCode, Uri},
    response::{IntoResponse, Response as AxumResponse},
};
use leptos::*;
use crate::error_template::{AppError, ErrorTemplate};

pub async fn file_and_error_handler(
    uri: Uri,
    State(options): State<LeptosOptions>,
    req: Request<AxumBody>,
) -> AxumResponse {
    let root = options.site_root.clone();
    let res = get_static_file(uri.clone(), &root).await.unwrap();

    if res.status() == StatusCode::OK {
        res.into_response()
    } else {
        let mut outside_errors = Errors::default();
        outside_errors.insert_with_default_key(AppError::NotFound);
        let handler = leptos_axum::render_app_to_stream(
            options.to_owned(),
            move || view! { <ErrorTemplate outside_errors/> },
        );
        handler(req).await.into_response()
    }
}

#[cfg(feature = "ssr")]
async fn get_static_file(
    uri: Uri,
    root: &str,
) -> Result<Response<AxumBody>, (StatusCode, String)> {
    use axum::http::HeaderValue;
    use tower::ServiceExt;
    use tower_http::services::ServeDir;

    let req = Request::builder()
        .uri(uri.clone())
        .body(AxumBody::empty())
        .unwrap();

    match ServeDir::new(root).oneshot(req).await {
        Ok(res) => Ok(res.map(AxumBody::new)),
        Err(err) => Err((
            StatusCode::INTERNAL_SERVER_ERROR,
            format!("Something went wrong: {err}"),
        )),
    }
}
EOF

# Generate remaining module files
touch crates/app/src/{routes/mod.rs,hooks/mod.rs,stores/mod.rs,utils/mod.rs}

# Generate basic API structure
cat > crates/api/src/main.rs << 'EOF'
use axum::{routing::get, Router};
use std::net::SocketAddr;

#[tokio::main]
async fn main() {
    tracing_subscriber::init();

    let app = Router::new()
        .route("/health", get(health_check));

    let addr = SocketAddr::from(([127, 0, 0, 1], 8080));
    println!("🚀 API Server listening on {}", addr);

    let listener = tokio::net::TcpListener::bind(addr).await.unwrap();
    axum::serve(listener, app).await.unwrap();
}

async fn health_check() -> &'static str {
    "OK"
}
EOF

cat > crates/api/src/lib.rs << 'EOF'
pub mod config;
pub mod handlers;
pub mod middleware;
pub mod services;
pub mod repositories;
pub mod models;
pub mod extractors;
pub mod utils;
EOF

# Generate lib.rs files for other crates
for crate in database auth notification analytics storage cache search queue monitoring integration cli testing; do
    echo "// $crate crate" > "crates/$crate/src/lib.rs"
done

# Generate configuration files
cat > config/development.toml << 'EOF'
[server]
host = "127.0.0.1"
port = 3000

[database]
url = "postgresql://user:password@localhost/enterprise_app_dev"

[redis]
url = "redis://127.0.0.1:6379"

[auth]
jwt_secret = "your-development-secret-key"
jwt_expiry = 3600

[email]
smtp_host = "localhost"
smtp_port = 1025
EOF

cat > config/production.toml << 'EOF'
[server]
host = "0.0.0.0"
port = 8080

[database]
url = "${DATABASE_URL}"

[redis]
url = "${REDIS_URL}"

[auth]
jwt_secret = "${JWT_SECRET}"
jwt_expiry = 3600

[email]
smtp_host = "${SMTP_HOST}"
smtp_port = 587
EOF

# Generate Docker files
cat > Dockerfile << 'EOF'
# Build stage
FROM rust:1.75-bullseye as builder

WORKDIR /app
RUN apt-get update && apt-get install -y pkg-config libssl-dev

COPY Cargo.toml Cargo.lock ./
COPY crates ./crates

RUN cargo build --release

# Runtime stage
FROM debian:bullseye-slim

RUN apt-get update && apt-get install -y \
    ca-certificates \
    libssl1.1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=builder /app/target/release/app /app/
COPY --from=builder /app/target/release/api /app/
COPY crates/app/assets ./assets
COPY crates/app/public ./public

EXPOSE 3000 8080
CMD ["./app"]
EOF

cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  app:
    build: .
    ports:
      - "3000:3000"
      - "8080:8080"
    environment:
      - DATABASE_URL=postgresql://postgres:password@db:5432/enterprise_app
      - REDIS_URL=redis://redis:6379
    depends_on:
      - db
      - redis

  db:
    image: postgres:15
    environment:
      POSTGRES_DB: enterprise_app
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: password
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

volumes:
  postgres_data:
EOF

# Generate basic GitHub Actions workflow
cat > .github/workflows/ci.yml << 'EOF'
name: CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

env:
  CARGO_TERM_COLOR: always

jobs:
  test:
    runs-on: ubuntu-latest

    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: password
          POSTGRES_DB: test_db
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
    - uses: actions/checkout@v4

    - name: Install Rust
      uses: actions-rs/toolchain@v1
      with:
        toolchain: stable
        override: true
        components: rustfmt, clippy

    - name: Cache cargo registry
      uses: actions/cache@v3
      with:
        path: ~/.cargo/registry
        key: ${{ runner.os }}-cargo-registry-${{ hashFiles('**/Cargo.lock') }}

    - name: Run tests
      run: cargo test --all-features

    - name: Check formatting
      run: cargo fmt --all -- --check

    - name: Run clippy
      run: cargo clippy --all-targets --all-features -- -D warnings
EOF

# Generate justfile
cat > justfile << 'EOF'
# List available commands
default:
    @just --list

# Install dependencies
install:
    cargo install trunk
    cargo install sqlx-cli
    npm install -g sass

# Run development server
dev:
    trunk serve --open

# Build for production
build:
    trunk build --release

# Run tests
test:
    cargo test

# Run API server
api:
    cargo run --bin api

# Database migrations
migrate:
    sqlx migrate run

# Generate new migration
migration name:
    sqlx migrate add {{name}}

# Format code
fmt:
    cargo fmt

# Run linter
lint:
    cargo clippy

# Clean build artifacts
clean:
    cargo clean
    rm -rf target/
EOF

# Generate README
cat > README.md << 'EOF'
# Enterprise Leptos Application

A scalable, enterprise-grade web application built with Leptos and Rust.

## Features

- 🚀 **Modern Stack**: Built with Leptos, Axum, and Rust
- 🔐 **Authentication**: JWT, OAuth, SAML, RBAC support
- 🏢 **Multi-Portal**: Customer, vendor, partner, and support portals
- 📊 **Analytics**: Comprehensive metrics and business intelligence
- 🔄 **Background Jobs**: Async task processing with queue system
- 🗄️ **Multiple Storage**: Local, S3, Azure, GCS support
- 🔍 **Search**: Elasticsearch, Algolia, PostgreSQL full-text search
- 📈 **Monitoring**: Health checks, metrics, tracing, alerts
- 🐳 **DevOps Ready**: Docker, Kubernetes, Terraform support

## Quick Start

### Prerequisites

- Rust 1.75+
- Node.js 18+
- PostgreSQL 15+
- Redis 7+

### Development Setup

1. **Clone and setup:**
   ```bash
   git clone <your-repo>
   cd enterprise-leptos-app
   just install
   ```

2. **Start services:**
   ```bash
   docker-compose up -d db redis
   ```

3. **Run migrations:**
   ```bash
   just migrate
   ```

4. **Start development server:**
   ```bash
   just dev
   ```

## Architecture

This application follows a modular, microservices-ready architecture:

- **Frontend**: Leptos with SSR/CSR support
- **Backend**: Axum REST API
- **Database**: PostgreSQL with SQLx
- **Caching**: Redis
- **Auth**: JWT with RBAC
- **Background Jobs**: Tokio-based queue system

## Available Commands

```bash
just dev          # Start development server
just api          # Run API server
just test         # Run tests
just migrate      # Run database migrations
just build        # Build for production
just fmt          # Format code
just lint         # Run linter
```

## Deployment

### Docker

```bash
docker-compose up -d
```

### Kubernetes

```bash
kubectl apply -f k8s/
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests: `just test`
5. Submit a pull request

## License

MIT License - see LICENSE file for details.
EOF

# Generate .gitignore
cat > .gitignore << 'EOF'
# Rust
target/
Cargo.lock
**/*.rs.bk

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Environment
.env
.env.local

# Logs
*.log
logs/

# Database
*.db
*.sqlite

# Node
node_modules/
npm-debug.log*

# Build artifacts
dist/
target/site/

# Leptos
pkg/
EOF

# Generate .env.example
cat > .env.example << 'EOF'
# Database
DATABASE_URL=postgresql://user:password@localhost/enterprise_app

# Redis
REDIS_URL=redis://127.0.0.1:6379

# Auth
JWT_SECRET=your-secret-key-change-in-production

# Email
SMTP_HOST=localhost
SMTP_PORT=1025
SMTP_USERNAME=
SMTP_PASSWORD=

# External APIs
STRIPE_SECRET_KEY=
PAYPAL_CLIENT_ID=
OAUTH_GOOGLE_CLIENT_ID=
OAUTH_GOOGLE_CLIENT_SECRET=

# Monitoring
SENTRY_DSN=
DATADOG_API_KEY=

# Storage
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_S3_BUCKET=
AWS_REGION=us-east-1
EOF

# Generate basic CSS
cat > crates/app/style/main.scss << 'EOF'
// Main styles for Enterprise Leptos App
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap');

// Variables
:root {
  --primary-color: #3b82f6;
  --secondary-color: #6b7280;
  --success-color: #10b981;
  --warning-color: #f59e0b;
  --error-color: #ef4444;
  --background-color: #f9fafb;
  --surface-color: #ffffff;
  --text-primary: #111827;
  --text-secondary: #6b7280;
  --border-color: #e5e7eb;
  --shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.1);
  --radius: 0.5rem;
}

// Reset and base styles
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: 'Inter', sans-serif;
  background-color: var(--background-color);
  color: var(--text-primary);
  line-height: 1.6;
}

// Components
.btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 0.5rem 1rem;
  border: none;
  border-radius: var(--radius);
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
  text-decoration: none;

  &.btn-primary {
    background-color: var(--primary-color);
    color: white;

    &:hover {
      opacity: 0.9;
    }
  }

  &.btn-secondary {
    background-color: var(--secondary-color);
    color: white;

    &:hover {
      opacity: 0.9;
    }
  }
}

.form-group {
  margin-bottom: 1rem;

  label {
    display: block;
    margin-bottom: 0.25rem;
    font-weight: 500;
    color: var(--text-primary);
  }

  input, select, textarea {
    width: 100%;
    padding: 0.5rem;
    border: 1px solid var(--border-color);
    border-radius: var(--radius);
    background-color: var(--surface-color);

    &:focus {
      outline: none;
      border-color: var(--primary-color);
      box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
    }
  }
}

.card {
  background-color: var(--surface-color);
  border-radius: var(--radius);
  box-shadow: var(--shadow);
  padding: 1.5rem;
  margin-bottom: 1rem;
}

// Pages
.home-page {
  max-width: 1200px;
  margin: 0 auto;
  padding: 2rem;
  text-align: center;

  h1 {
    font-size: 3rem;
    margin-bottom: 1rem;
    color: var(--text-primary);
  }

  p {
    font-size: 1.2rem;
    color: var(--text-secondary);
    margin-bottom: 2rem;
  }
}

.login-page {
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 100vh;
  padding: 1rem;

  .login-form {
    width: 100%;
    max-width: 400px;
    background-color: var(--surface-color);
    padding: 2rem;
    border-radius: var(--radius);
    box-shadow: var(--shadow);

    h2 {
      text-align: center;
      margin-bottom: 2rem;
    }
  }
}

.error-template {
  text-align: center;
  padding: 2rem;

  h1 {
    color: var(--error-color);
    margin-bottom: 1rem;
  }
}

// Responsive
@media (max-width: 768px) {
  .home-page h1 {
    font-size: 2rem;
  }

  .login-form {
    padding: 1.5rem;
  }
}
EOF

# Generate Kubernetes manifests
cat > k8s/namespace.yaml << 'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: enterprise-leptos
  labels:
    name: enterprise-leptos
EOF

cat > k8s/deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: enterprise-leptos-app
  namespace: enterprise-leptos
spec:
  replicas: 3
  selector:
    matchLabels:
      app: enterprise-leptos-app
  template:
    metadata:
      labels:
        app: enterprise-leptos-app
    spec:
      containers:
      - name: app
        image: enterprise-leptos-app:latest
        ports:
        - containerPort: 3000
        - containerPort: 8080
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: database-url
        - name: REDIS_URL
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: redis-url
        - name: JWT_SECRET
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: jwt-secret
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
EOF

cat > k8s/service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: enterprise-leptos-service
  namespace: enterprise-leptos
spec:
  selector:
    app: enterprise-leptos-app
  ports:
  - name: web
    protocol: TCP
    port: 80
    targetPort: 3000
  - name: api
    protocol: TCP
    port: 8080
    targetPort: 8080
  type: ClusterIP
EOF

cat > k8s/ingress.yaml << 'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: enterprise-leptos-ingress
  namespace: enterprise-leptos
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  tls:
  - hosts:
    - your-domain.com
    secretName: enterprise-leptos-tls
  rules:
  - host: your-domain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: enterprise-leptos-service
            port:
              number: 80
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: enterprise-leptos-service
            port:
              number: 8080
EOF

cat > k8s/secret.yaml << 'EOF'
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
  namespace: enterprise-leptos
type: Opaque
stringData:
  database-url: "postgresql://user:password@postgres:5432/enterprise_app"
  redis-url: "redis://redis:6379"
  jwt-secret: "your-production-jwt-secret-key-change-me"
EOF

cat > k8s/configmap.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: enterprise-leptos
data:
  app.toml: |
    [server]
    host = "0.0.0.0"
    port = 3000

    [database]
    pool_size = 10

    [redis]
    pool_size = 10

    [auth]
    jwt_expiry = 3600
EOF

# Generate Terraform configuration
cat > terraform/main.tf << 'EOF'
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Subnets
resource "aws_subnet" "public" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 1}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-${count.index + 1}"
    Type = "Public"
  }
}

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 10}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.project_name}-private-${count.index + 1}"
    Type = "Private"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

# RDS Database
module "database" {
  source = "./modules/database"

  vpc_id             = aws_vpc.main.id
  private_subnet_ids = aws_subnet.private[*].id
  project_name       = var.project_name
}

# ElastiCache Redis
module "cache" {
  source = "./modules/cache"

  vpc_id             = aws_vpc.main.id
  private_subnet_ids = aws_subnet.private[*].id
  project_name       = var.project_name
}

# S3 Storage
module "storage" {
  source = "./modules/storage"

  project_name = var.project_name
}
EOF

cat > terraform/variables.tf << 'EOF'
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "enterprise-leptos"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "redis_node_type" {
  description = "ElastiCache node type"
  type        = string
  default     = "cache.t3.micro"
}
EOF

cat > terraform/outputs.tf << 'EOF'
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "database_endpoint" {
  description = "RDS instance endpoint"
  value       = module.database.endpoint
  sensitive   = true
}

output "redis_endpoint" {
  description = "ElastiCache Redis endpoint"
  value       = module.cache.endpoint
  sensitive   = true
}

output "s3_bucket" {
  description = "S3 bucket name"
  value       = module.storage.bucket_name
}
EOF

# Generate Terraform modules
mkdir -p terraform/modules/{database,cache,storage}

cat > terraform/modules/database/main.tf << 'EOF'
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

resource "aws_security_group" "db" {
  name        = "${var.project_name}-db-sg"
  description = "Security group for RDS database"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-db-sg"
  }
}

resource "aws_db_instance" "main" {
  identifier     = "${var.project_name}-db"
  engine         = "postgres"
  engine_version = "15.3"
  instance_class = var.db_instance_class

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp2"
  storage_encrypted     = true

  db_name  = "enterprise_app"
  username = "postgres"
  password = var.db_password

  vpc_security_group_ids = [aws_security_group.db.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "Sun:04:00-Sun:05:00"

  skip_final_snapshot = true
  deletion_protection = false

  tags = {
    Name = "${var.project_name}-db"
  }
}
EOF

# Generate migration files
cat > migrations/001_initial.sql << 'EOF'
-- Initial database setup
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_crypto";

-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Roles table
CREATE TABLE roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Permissions table
CREATE TABLE permissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    resource VARCHAR(100) NOT NULL,
    action VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User roles junction table
CREATE TABLE user_roles (
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    role_id UUID REFERENCES roles(id) ON DELETE CASCADE,
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    PRIMARY KEY (user_id, role_id)
);

-- Role permissions junction table
CREATE TABLE role_permissions (
    role_id UUID REFERENCES roles(id) ON DELETE CASCADE,
    permission_id UUID REFERENCES permissions(id) ON DELETE CASCADE,
    granted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    PRIMARY KEY (role_id, permission_id)
);

-- Sessions table
CREATE TABLE sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    token_hash VARCHAR(255) NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_accessed TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Audit logs table
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(100) NOT NULL,
    resource_id UUID,
    old_values JSONB,
    new_values JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_sessions_token_hash ON sessions(token_hash);
CREATE INDEX idx_sessions_user_id ON sessions(user_id);
CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at);

-- Updated at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$ language 'plpgsql';

-- Apply updated_at trigger to users table
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
EOF

cat > migrations/002_seed_data.sql << 'EOF'
-- Insert default roles
INSERT INTO roles (id, name, description) VALUES
    (uuid_generate_v4(), 'super_admin', 'Super Administrator with all permissions'),
    (uuid_generate_v4(), 'admin', 'Administrator with most permissions'),
    (uuid_generate_v4(), 'manager', 'Manager with limited admin permissions'),
    (uuid_generate_v4(), 'user', 'Regular user with basic permissions'),
    (uuid_generate_v4(), 'guest', 'Guest user with read-only access');

-- Insert default permissions
INSERT INTO permissions (name, description, resource, action) VALUES
    -- User management
    ('users.create', 'Create new users', 'users', 'create'),
    ('users.read', 'View user information', 'users', 'read'),
    ('users.update', 'Update user information', 'users', 'update'),
    ('users.delete', 'Delete users', 'users', 'delete'),

    -- Role management
    ('roles.create', 'Create new roles', 'roles', 'create'),
    ('roles.read', 'View role information', 'roles', 'read'),
    ('roles.update', 'Update role information', 'roles', 'update'),
    ('roles.delete', 'Delete roles', 'roles', 'delete'),

    -- System administration
    ('system.config', 'Configure system settings', 'system', 'config'),
    ('system.monitoring', 'Access monitoring data', 'system', 'monitoring'),
    ('system.backup', 'Create system backups', 'system', 'backup'),

    -- Dashboard access
    ('dashboard.analytics', 'Access analytics dashboard', 'dashboard', 'analytics'),
    ('dashboard.reports', 'Generate and view reports', 'dashboard', 'reports'),

    -- Portal access
    ('portal.customer', 'Access customer portal', 'portal', 'customer'),
    ('portal.vendor', 'Access vendor portal', 'portal', 'vendor'),
    ('portal.partner', 'Access partner portal', 'portal', 'partner'),
    ('portal.support', 'Access support portal', 'portal', 'support');

-- Assign permissions to super_admin role (all permissions)
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.name = 'super_admin';

-- Assign permissions to admin role (most permissions, excluding system config)
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.name = 'admin' AND p.name NOT LIKE 'system.%';

-- Assign basic permissions to user role
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.name = 'user' AND p.action = 'read';

-- Create default super admin user (password: 'admin123')
INSERT INTO users (id, email, username, password_hash, first_name, last_name) VALUES
    (uuid_generate_v4(), 'admin@example.com', 'admin', '$2b$10$rQKvKjXqLpZZZn7dQBKXVeLmK5ZoKpZQKKZpZKZpZKZ', 'System', 'Administrator');

-- Assign super_admin role to the default user
INSERT INTO user_roles (user_id, role_id)
SELECT u.id, r.id
FROM users u
CROSS JOIN roles r
WHERE u.username = 'admin' AND r.name = 'super_admin';
EOF

# Generate monitoring configurations
cat > monitoring/prometheus/config.yml << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "rules/*.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093

scrape_configs:
  - job_name: 'enterprise-leptos-app'
    static_configs:
      - targets: ['app:8080']
    metrics_path: /metrics
    scrape_interval: 30s

  - job_name: 'postgres'
    static_configs:
      - targets: ['postgres_exporter:9187']

  - job_name: 'redis'
    static_configs:
      - targets: ['redis_exporter:9121']

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node_exporter:9100']
EOF

cat > monitoring/grafana/dashboards/app-dashboard.json << 'EOF'
{
  "dashboard": {
    "id": null,
    "title": "Enterprise Leptos App Dashboard",
    "tags": ["leptos", "rust"],
    "timezone": "browser",
    "panels": [
      {
        "id": 1,
        "title": "HTTP Requests per Second",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(http_requests_total[5m])",
            "legendFormat": "{{method}} {{status}}"
          }
        ]
      },
      {
        "id": 2,
        "title": "Response Time",
        "type": "graph",
        "targets": [
          {
            "expr": "http_request_duration_seconds",
            "legendFormat": "{{quantile}}"
          }
        ]
      },
      {
        "id": 3,
        "title": "Active Users",
        "type": "singlestat",
        "targets": [
          {
            "expr": "active_users_total",
            "legendFormat": "Active Users"
          }
        ]
      }
    ],
    "time": {
      "from": "now-1h",
      "to": "now"
    },
    "refresh": "10s"
  }
}
EOF

# Generate setup script
cat > scripts/setup.sh << 'EOF'
#!/bin/bash

# Enterprise Leptos App Setup Script
set -e

echo "🚀 Setting up Enterprise Leptos Application..."

# Check prerequisites
command -v cargo >/dev/null 2>&1 || { echo "❌ Rust/Cargo is required but not installed."; exit 1; }
command -v node >/dev/null 2>&1 || { echo "❌ Node.js is required but not installed."; exit 1; }
command -v docker >/dev/null 2>&1 || { echo "❌ Docker is required but not installed."; exit 1; }

# Install Rust tools
echo "📦 Installing Rust tools..."
cargo install trunk --version 0.17.5
cargo install sqlx-cli --no-default-features --features rustls,postgres

# Install Node.js dependencies
echo "📦 Installing Node.js dependencies..."
npm install -g sass

# Copy environment file
if [ ! -f .env ]; then
    echo "📝 Creating .env file..."
    cp .env.example .env
    echo "⚠️  Please update .env with your configuration"
fi

# Start services with Docker
echo "🐳 Starting services..."
docker-compose up -d db redis

# Wait for services to be ready
echo "⏳ Waiting for services to start..."
sleep 10

# Run migrations
echo "🗄️  Running database migrations..."
export DATABASE_URL="postgresql://postgres:password@localhost:5432/enterprise_app"
sqlx database create
sqlx migrate run

echo "✅ Setup complete!"
echo ""
echo "To start development:"
echo "  just dev"
echo ""
echo "To start API server:"
echo "  just api"
echo ""
echo "Application will be available at:"
echo "  Frontend: http://localhost:3000"
echo "  API: http://localhost:8080"
EOF

# Generate deploy script
cat > scripts/deploy.sh << 'EOF'
#!/bin/bash

# Deployment script for Enterprise Leptos App
set -e

ENVIRONMENT=${1:-staging}
echo "🚀 Deploying to $ENVIRONMENT environment..."

# Build application
echo "🔨 Building application..."
trunk build --release

# Build Docker image
echo "🐳 Building Docker image..."
docker build -t enterprise-leptos-app:latest .

# Tag for registry
if [ "$ENVIRONMENT" = "production" ]; then
    docker tag enterprise-leptos-app:latest your-registry.com/enterprise-leptos-app:latest
    docker tag enterprise-leptos-app:latest your-registry.com/enterprise-leptos-app:$(git rev-parse --short HEAD)

    # Push to registry
    echo "📤 Pushing to registry..."
    docker push your-registry.com/enterprise-leptos-app:latest
    docker push your-registry.com/enterprise-leptos-app:$(git rev-parse --short HEAD)
fi

# Deploy to Kubernetes
if command -v kubectl >/dev/null 2>&1; then
    echo "☸️  Deploying to Kubernetes..."
    kubectl apply -f k8s/
    kubectl rollout status deployment/enterprise-leptos-app -n enterprise-leptos
else
    echo "⚠️  kubectl not found, skipping Kubernetes deployment"
fi

echo "✅ Deployment complete!"
EOF

# Make scripts executable
chmod +x scripts/*.sh

echo ""
echo "🎉 Enterprise Leptos application structure created successfully!"
echo ""
echo "📁 Project: $PROJECT_NAME"
echo "📍 Location: $(pwd)"
echo ""
echo "🚀 Next steps:"
echo "1. cd $PROJECT_NAME"
echo "2. ./scripts/setup.sh"
echo "3. just dev"
echo ""
echo "📚 Available commands:"
echo "  just dev      - Start development server"
echo "  just api      - Start API server"
echo "  just test     - Run tests"
echo "  just migrate  - Run database migrations"
echo "  just build    - Build for production"
echo ""
echo "🌐 Access points:"
echo "  Frontend: http://localhost:3000"
echo "  API: http://localhost:8080"
echo ""
echo "Happy coding! 🦀✨"
