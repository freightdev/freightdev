#!/bin/bash
# Quick setup for debugging on phone

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}📱 OpenHWY Phone Debug Setup${NC}"
echo ""

# Check if phone is connected
if ! command -v adb &> /dev/null; then
    echo -e "${RED}✗${NC} adb not found. Installing..."
    sudo apt install -y android-tools-adb android-tools-fastboot
fi

# Wait for device
echo -e "${BLUE}Waiting for device...${NC}"
echo "  1. Enable USB Debugging on your phone:"
echo "     Settings → About Phone → Tap 'Build Number' 7 times"
echo "     Settings → Developer Options → USB Debugging → Enable"
echo "  2. Connect phone via USB"
echo "  3. Accept the debugging prompt on your phone"
echo ""

adb wait-for-device

DEVICE=$(adb devices | grep -w "device" | awk '{print $1}')

if [ -z "$DEVICE" ]; then
    echo -e "${RED}✗${NC} No device found"
    exit 1
fi

echo -e "${GREEN}✓${NC} Device connected: $DEVICE"
echo ""

# Get device info
MANUFACTURER=$(adb shell getprop ro.product.manufacturer | tr -d '\r')
MODEL=$(adb shell getprop ro.product.model | tr -d '\r')
ANDROID_VERSION=$(adb shell getprop ro.build.version.release | tr -d '\r')

echo "Device: $MANUFACTURER $MODEL"
echo "Android: $ANDROID_VERSION"
echo ""

# Check Flutter
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}✗${NC} Flutter not found"
    echo "Install: https://docs.flutter.dev/get-started/install/linux"
    exit 1
fi

echo -e "${GREEN}✓${NC} Flutter detected: $(flutter --version | head -n1)"
echo ""

# List Flutter devices
echo -e "${BLUE}Available Flutter devices:${NC}"
flutter devices
echo ""

# Ask what to do
echo "What would you like to do?"
echo "  1) Run app on phone (hot reload enabled)"
echo "  2) Install APK (if already built)"
echo "  3) Build & install APK"
echo "  4) Setup wireless debugging"
echo "  5) View live logs"
echo ""
read -p "Choice (1-5): " choice

case $choice in
    1)
        echo -e "${BLUE}Running app with hot reload...${NC}"
        cd ~/WORKSPACE/openhwy/openhwy_dashboard
        flutter run
        ;;
    2)
        APK="$HOME/WORKSPACE/openhwy/openhwy_dashboard/build/app/outputs/flutter-apk/app-debug.apk"
        if [ -f "$APK" ]; then
            echo -e "${BLUE}Installing APK...${NC}"
            adb install -r "$APK"
            echo -e "${GREEN}✓${NC} Installed"
        else
            echo -e "${RED}✗${NC} APK not found. Run: flutter build apk"
        fi
        ;;
    3)
        echo -e "${BLUE}Building APK...${NC}"
        cd ~/WORKSPACE/openhwy/openhwy_dashboard
        flutter build apk --debug
        echo -e "${BLUE}Installing...${NC}"
        adb install -r build/app/outputs/flutter-apk/app-debug.apk
        echo -e "${GREEN}✓${NC} Built and installed"
        ;;
    4)
        echo -e "${BLUE}Setting up wireless debugging...${NC}"
        adb tcpip 5555
        sleep 2
        IP=$(adb shell ip addr show wlan0 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1 | tr -d '\r')
        if [ -z "$IP" ]; then
            echo -e "${YELLOW}⚠${NC}  Could not detect IP. Check manually:"
            echo "    Settings → About → Status → IP Address"
            read -p "Enter phone IP: " IP
        fi
        echo ""
        echo -e "${GREEN}✓${NC} Phone IP: $IP"
        echo ""
        echo "You can now disconnect USB and run:"
        echo -e "  ${BLUE}adb connect $IP:5555${NC}"
        echo ""
        read -p "Disconnect USB and press Enter to connect wirelessly..."
        adb connect $IP:5555
        sleep 2
        if adb devices | grep -q "$IP"; then
            echo -e "${GREEN}✓${NC} Wireless debugging enabled!"
            echo ""
            echo "Now you can:"
            echo "  flutter run"
            echo "  flutter logs"
            echo "  adb install app.apk"
        else
            echo -e "${RED}✗${NC} Connection failed. Make sure phone and computer are on same WiFi"
        fi
        ;;
    5)
        echo -e "${BLUE}Viewing live logs (Ctrl+C to stop)...${NC}"
        echo ""
        adb logcat | grep -i flutter
        ;;
    *)
        echo "Invalid choice"
        ;;
esac
