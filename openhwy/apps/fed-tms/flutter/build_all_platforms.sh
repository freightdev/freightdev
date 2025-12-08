#!/bin/bash
# OpenHWY Flutter - Multi-platform build script

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

PROJECT_DIR="$HOME/WORKSPACE/openhwy/openhwy_dashboard"
BUILD_DIR="$PROJECT_DIR/builds"

echo -e "${BLUE}🚛 OpenHWY Multi-Platform Build${NC}"
echo ""

cd "$PROJECT_DIR"

# Clean previous builds
echo -e "${BLUE}[1/6]${NC} Cleaning previous builds..."
flutter clean
mkdir -p "$BUILD_DIR"

# Build Android APK
echo -e "${BLUE}[2/6]${NC} Building Android APK..."
flutter build apk --release
cp build/app/outputs/flutter-apk/app-release.apk "$BUILD_DIR/OpenHWY-android.apk"
echo -e "${GREEN}✓${NC} Android APK: $BUILD_DIR/OpenHWY-android.apk"

# Build Linux Desktop
echo -e "${BLUE}[3/6]${NC} Building Linux desktop..."
flutter build linux --release
cd build/linux/x64/release/bundle
tar -czf "$BUILD_DIR/OpenHWY-linux-x64.tar.gz" *
cd "$PROJECT_DIR"
echo -e "${GREEN}✓${NC} Linux build: $BUILD_DIR/OpenHWY-linux-x64.tar.gz"

# Build Web
echo -e "${BLUE}[4/6]${NC} Building web version..."
flutter build web --release
cd build/web
tar -czf "$BUILD_DIR/OpenHWY-web.tar.gz" *
cd "$PROJECT_DIR"
echo -e "${GREEN}✓${NC} Web build: $BUILD_DIR/OpenHWY-web.tar.gz"

# Create installation script for Linux
echo -e "${BLUE}[5/6]${NC} Creating installation script..."
cat > "$BUILD_DIR/install-linux.sh" << 'INSTALL_SCRIPT'
#!/bin/bash
# OpenHWY Dashboard Linux Installer

set -e

echo "Installing OpenHWY Dashboard..."

# Extract
tar -xzf OpenHWY-linux-x64.tar.gz -C /opt/openhwy-dashboard

# Create desktop entry
cat > ~/.local/share/applications/openhwy-dashboard.desktop << EOF
[Desktop Entry]
Name=OpenHWY Dashboard
Comment=Infrastructure Control Center
Exec=/opt/openhwy-dashboard/openhwy_dashboard
Icon=/opt/openhwy-dashboard/data/flutter_assets/assets/icons/app_icon.png
Terminal=false
Type=Application
Categories=Development;System;
EOF

# Make executable
chmod +x /opt/openhwy-dashboard/openhwy_dashboard

echo "✓ OpenHWY Dashboard installed"
echo "  Launch from applications menu or run: /opt/openhwy-dashboard/openhwy_dashboard"
INSTALL_SCRIPT

chmod +x "$BUILD_DIR/install-linux.sh"

# Generate build info
echo -e "${BLUE}[6/6]${NC} Generating build info..."
cat > "$BUILD_DIR/BUILD_INFO.txt" << EOF
OpenHWY Dashboard - Build Information
Generated: $(date)

FILES:
  OpenHWY-android.apk       - Android APK (release)
  OpenHWY-linux-x64.tar.gz  - Linux desktop (x64)
  OpenHWY-web.tar.gz        - Web application
  install-linux.sh          - Linux installer

INSTALLATION:

Android:
  1. Transfer OpenHWY-android.apk to your phone
  2. Install from file manager
  3. Enable "Install from unknown sources" if prompted

Linux:
  1. Extract: tar -xzf OpenHWY-linux-x64.tar.gz
  2. Run: ./openhwy_dashboard
  
  Or use installer:
  sudo mkdir -p /opt/openhwy-dashboard
  sudo ./install-linux.sh

Web:
  1. Extract: tar -xzf OpenHWY-web.tar.gz
  2. Serve with any web server:
     python3 -m http.server 8000
  3. Open: http://localhost:8000

DEBUGGING:

Android (USB):
  $ adb devices
  $ adb install OpenHWY-android.apk
  $ adb logcat | grep flutter

Android (Wireless):
  $ adb tcpip 5555
  $ adb connect <phone-ip>:5555

From source:
  $ flutter run -d <device-id>
  $ flutter logs

BUILD INFO:
  Flutter Version: $(flutter --version | head -n1)
  Build Date: $(date)
  Builder: $(whoami)@$(hostname)
EOF

# Show summary
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Build Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Output directory: $BUILD_DIR"
echo ""
ls -lh "$BUILD_DIR"
echo ""
echo "Next steps:"
echo "  Android: adb install $BUILD_DIR/OpenHWY-android.apk"
echo "  Linux:   tar -xzf $BUILD_DIR/OpenHWY-linux-x64.tar.gz && ./openhwy_dashboard"
echo "  Web:     cd web && python3 -m http.server"
echo ""
echo "See BUILD_INFO.txt for detailed instructions"
