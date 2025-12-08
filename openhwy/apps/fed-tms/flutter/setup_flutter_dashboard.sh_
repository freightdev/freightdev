#!/bin/bash
# OpenHWY Flutter Dashboard Setup

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🚛 OpenHWY Flutter Dashboard Setup${NC}"
echo ""

PROJECT_NAME="openhwy_dashboard"
PROJECT_DIR="$HOME/WORKSPACE/openhwy/$PROJECT_NAME"

# Create Flutter project
if [ ! -d "$PROJECT_DIR" ]; then
    echo -e "${BLUE}[1/7]${NC} Creating Flutter project..."
    cd "$HOME/WORKSPACE/openhwy"
    flutter create $PROJECT_NAME
    cd $PROJECT_DIR
else
    echo -e "${GREEN}✓${NC} Project directory exists"
    cd $PROJECT_DIR
fi

# Create directory structure
echo -e "${BLUE}[2/7]${NC} Creating directory structure..."
mkdir -p lib/{models,services,screens,widgets,theme}
mkdir -p lib/proto
mkdir -p assets/{images,icons}

# Copy files
echo -e "${BLUE}[3/7]${NC} Copying source files..."
cp ~/flutter_main.dart lib/main.dart
cp ~/flutter_theme.dart lib/theme/app_theme.dart
cp ~/flutter_api_service.dart lib/services/api_service.dart
cp ~/flutter_websocket_service.dart lib/services/websocket_service.dart
cp ~/flutter_system_model.dart lib/models/system.dart
cp ~/flutter_agent_model.dart lib/models/agent.dart
cp ~/flutter_dashboard_screen.dart lib/screens/dashboard_screen.dart
cp ~/pubspec.yaml pubspec.yaml

# Install dependencies
echo -e "${BLUE}[4/7]${NC} Installing dependencies..."
flutter pub get

# Generate protobuf files
echo -e "${BLUE}[5/7]${NC} Setting up protobuf..."
if command -v protoc &> /dev/null; then
    cp ~/openhwy.proto lib/proto/
    protoc --dart_out=lib/proto lib/proto/openhwy.proto
    echo -e "${GREEN}✓${NC} Protobuf files generated"
else
    echo -e "${BLUE}ℹ${NC}  protoc not found, skipping protobuf generation"
    echo "   Install: apt-get install protobuf-compiler"
    echo "   Then run: protoc --dart_out=lib/proto lib/proto/openhwy.proto"
fi

# Create README
echo -e "${BLUE}[6/7]${NC} Creating documentation..."
cat > README.md << 'EOF'
# OpenHWY Dashboard

Flutter-based control center for OpenHWY infrastructure.

## Features

- Real-time system monitoring across 5 boxes
- Agent lifecycle management (start/stop/monitor)
- WebSocket updates for live data
- 3D panel interface
- Sliding bottom control panel
- Protobuf integration with Rust/Go backends

## Architecture

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── system.dart          # System model
│   └── agent.dart           # Agent model
├── services/                 # Backend communication
│   ├── api_service.dart     # REST API
│   └── websocket_service.dart # WebSocket
├── screens/                  # UI screens
│   └── dashboard_screen.dart
├── widgets/                  # Reusable components
├── theme/                    # App theme
│   └── app_theme.dart
└── proto/                    # Protobuf generated files
    └── openhwy.proto
```

## Backend Integration

### REST API Endpoints

```
GET  /api/systems              # List all systems
POST /api/execute              # Execute command
POST /api/agents/launch        # Launch agent
POST /api/agents/kill          # Kill agent
GET  /api/logs                 # Get logs
```

### WebSocket

```
ws://localhost:8080/ws

Message types:
- system_update: System stats update
- agent_update: Agent status update
- log: Log entry
```

### Protobuf

See `lib/proto/openhwy.proto` for message definitions.

## Running

```bash
# Desktop
flutter run -d linux

# Mobile (with USB debugging)
flutter run -d <device-id>

# Web
flutter run -d chrome
```

## Building

```bash
# Desktop
flutter build linux --release

# Android
flutter build apk --release

# iOS
flutter build ios --release
```

## Backend Setup

### Rust Backend (recommended)

```rust
// main.rs
use actix_web::{web, App, HttpServer};
use actix_web_actors::ws;

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    HttpServer::new(|| {
        App::new()
            .route("/api/systems", web::get().to(list_systems))
            .route("/api/execute", web::post().to(execute_command))
            .route("/api/agents/launch", web::post().to(launch_agent))
            .route("/api/agents/kill", web::post().to(kill_agent))
            .route("/ws", web::get().to(websocket))
    })
    .bind(("0.0.0.0", 8080))?
    .run()
    .await
}
```

### Go Backend

```go
// main.go
package main

import (
    "github.com/gin-gonic/gin"
    "github.com/gorilla/websocket"
)

func main() {
    r := gin.Default()
    
    r.GET("/api/systems", listSystems)
    r.POST("/api/execute", executeCommand)
    r.POST("/api/agents/launch", launchAgent)
    r.POST("/api/agents/kill", killAgent)
    r.GET("/ws", websocketHandler)
    
    r.Run(":8080")
}
```

## Configuration

Edit `lib/services/api_service.dart`:

```dart
static const String baseUrl = 'http://YOUR_SERVER:8080';
static const String wsUrl = 'ws://YOUR_SERVER:8080/ws';
```

EOF

# Create run script
echo -e "${BLUE}[7/7]${NC} Creating run scripts..."
cat > run_desktop.sh << 'EOF'
#!/bin/bash
flutter run -d linux
EOF

cat > run_mobile.sh << 'EOF'
#!/bin/bash
flutter run
EOF

chmod +x run_desktop.sh run_mobile.sh

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}🚛 OpenHWY Dashboard Ready!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Project location: $PROJECT_DIR"
echo ""
echo "Next steps:"
echo "  1. ${BLUE}cd $PROJECT_DIR${NC}"
echo "  2. ${BLUE}flutter run -d linux${NC}  (or run_desktop.sh)"
echo ""
echo "Backend requirements:"
echo "  • REST API at http://localhost:8080"
echo "  • WebSocket at ws://localhost:8080/ws"
echo "  • See README.md for API spec"
echo ""
echo "Files created:"
echo "  • lib/main.dart"
echo "  • lib/models/*.dart"
echo "  • lib/services/*.dart"
echo "  • lib/screens/dashboard_screen.dart"
echo "  • lib/proto/openhwy.proto"
echo "  • pubspec.yaml"
echo "  • README.md"
