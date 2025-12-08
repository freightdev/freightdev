#!/bin/bash
# OpenHWY Flutter - Mobile Build & Deploy Guide

cat << 'EOF'
╔══════════════════════════════════════════════════════════╗
║  OpenHWY Flutter - Mobile Deployment                    ║
╚══════════════════════════════════════════════════════════╝

📱 ANDROID DEPLOYMENT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. SETUP (One-time)
───────────────────────────────────────────────────────────

Install Android SDK:
  $ sudo apt install android-sdk
  $ flutter doctor --android-licenses  # Accept all

Configure app identity:
  Edit: android/app/build.gradle
  
  Change:
    applicationId "com.example.openhwy_dashboard"
  To:
    applicationId "com.openhwy.dashboard"
  
  Change:
    versionName "1.0.0"
  To:
    versionName "1.0.0+1"

Configure app name:
  Edit: android/app/src/main/AndroidManifest.xml
  
  Change:
    android:label="openhwy_dashboard"
  To:
    android:label="OpenHWY"

Add app icon:
  Place icon at: android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png
  Or use: flutter pub run flutter_launcher_icons

Add permissions (for networking):
  Edit: android/app/src/main/AndroidManifest.xml
  
  Add before <application>:
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>


2. DEVELOPMENT - USB DEBUGGING
───────────────────────────────────────────────────────────

Enable USB Debugging on phone:
  Settings → About Phone → Tap "Build Number" 7 times
  Settings → Developer Options → Enable USB Debugging

Connect phone via USB:
  $ lsusb  # Should see your phone
  $ flutter devices  # Should list your phone

Run on phone:
  $ flutter run
  
  or with hot reload:
  $ flutter run --debug

View logs:
  $ flutter logs
  
  or directly:
  $ adb logcat


3. BUILD APK (Debug)
───────────────────────────────────────────────────────────

Build debug APK:
  $ flutter build apk --debug

Output:
  build/app/outputs/flutter-apk/app-debug.apk

Install directly:
  $ flutter install
  
  or manually:
  $ adb install build/app/outputs/flutter-apk/app-debug.apk

Transfer to phone:
  $ adb push build/app/outputs/flutter-apk/app-debug.apk /sdcard/Download/
  
  Then install from phone's Downloads folder


4. BUILD APK (Release - Production)
───────────────────────────────────────────────────────────

Create signing key (one-time):
  $ keytool -genkey -v -keystore ~/openhwy-release-key.jks \
    -keyalg RSA -keysize 2048 -validity 10000 \
    -alias openhwy

  Save the password somewhere safe!

Configure signing:
  Create: android/key.properties
  
  Contents:
    storePassword=YOUR_PASSWORD
    keyPassword=YOUR_PASSWORD
    keyAlias=openhwy
    storeFile=/home/admin/openhwy-release-key.jks

  Edit: android/app/build.gradle
  
  Add before "android {":
    def keystoreProperties = new Properties()
    def keystorePropertiesFile = rootProject.file('key.properties')
    if (keystorePropertiesFile.exists()) {
        keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
    }

  Inside "android { ... buildTypes {":
    release {
        signingConfig signingConfigs.release
    }
  
  Inside "android {" after "defaultConfig {":
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile file(keystoreProperties['storeFile'])
            storePassword keystoreProperties['storePassword']
        }
    }

Build release APK:
  $ flutter build apk --release

Output:
  build/app/outputs/flutter-apk/app-release.apk

This APK can be:
  • Installed on any Android device
  • Shared via file transfer
  • Uploaded to Google Play Store


5. BUILD APP BUNDLE (For Play Store)
───────────────────────────────────────────────────────────

Build app bundle:
  $ flutter build appbundle --release

Output:
  build/app/outputs/bundle/release/app-release.aab

Upload this to Google Play Console


6. WIRELESS DEBUGGING (No USB)
───────────────────────────────────────────────────────────

Connect phone and computer to same WiFi

Enable ADB over WiFi:
  # First connect via USB
  $ adb tcpip 5555
  
  # Get phone IP (Settings → About → Status → IP address)
  # Or: adb shell ip addr show wlan0
  
  # Connect wirelessly
  $ adb connect 192.168.1.XXX:5555
  
  # Disconnect USB, should still work
  $ flutter devices

Now you can:
  $ flutter run
  $ flutter logs
  $ adb install app.apk


7. HOT RELOAD & DEBUGGING
───────────────────────────────────────────────────────────

While app is running:
  Press 'r' → Hot reload (instant)
  Press 'R' → Hot restart (full restart)
  Press 'p' → Toggle performance overlay
  Press 'o' → Toggle platform (Android/iOS style)
  Press 'q' → Quit

Debug tools:
  $ flutter run --debug
  
  Then open: http://localhost:9100
  Access Flutter DevTools (inspector, profiler, etc.)


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🍎 iOS DEPLOYMENT (Requires macOS)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Setup Xcode:
   $ open ios/Runner.xcworkspace

2. Configure bundle ID:
   Runner → General → Bundle Identifier: com.openhwy.dashboard

3. Sign the app:
   Runner → Signing & Capabilities → Team: (Your Apple ID)

4. Build:
   $ flutter build ios --release

5. Deploy:
   Xcode → Product → Archive → Upload to App Store


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📦 BUILDING FOR ALL PLATFORMS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Desktop (Linux):
  $ flutter build linux --release
  Output: build/linux/x64/release/bundle/

Desktop (Windows):
  $ flutter build windows --release
  Output: build/windows/runner/Release/

Web:
  $ flutter build web --release
  Output: build/web/

Android:
  $ flutter build apk --release
  Output: build/app/outputs/flutter-apk/app-release.apk

iOS (macOS only):
  $ flutter build ios --release


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔧 CHANGING APP NAME & IDENTITY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

App Name (what users see):
  Android: android/app/src/main/AndroidManifest.xml
    android:label="OpenHWY"
  
  iOS: ios/Runner/Info.plist
    <key>CFBundleName</key>
    <string>OpenHWY</string>

Package Name (unique identifier):
  Android: android/app/build.gradle
    applicationId "com.openhwy.dashboard"
  
  iOS: ios/Runner.xcodeproj
    Bundle Identifier: com.openhwy.dashboard

Version:
  pubspec.yaml:
    version: 1.0.0+1
    (1.0.0 = user sees, +1 = build number)


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 QUICK REFERENCE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Development:
  flutter run                    # Run on connected device
  flutter run -d linux           # Run on Linux desktop
  flutter run -d chrome          # Run in web browser
  flutter devices                # List available devices

Building:
  flutter build apk              # Android APK
  flutter build appbundle        # Android App Bundle
  flutter build linux            # Linux desktop
  flutter build web              # Web app

Installing:
  flutter install                # Install on connected device
  adb install app.apk            # Install APK manually

Debugging:
  flutter logs                   # View logs
  flutter doctor                 # Check setup
  flutter clean                  # Clean build files

EOF
