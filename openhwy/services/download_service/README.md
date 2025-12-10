# Download Service

App binary distribution service for HWY-TMS.

## Features

- Serve Flutter app binaries
- Platform detection from User-Agent
- Support for all platforms (Windows, macOS, Linux, Android, iOS)
- Authenticated downloads (future: JWT validation)

## API Endpoints

### GET /download/:app
Download app binary.

**Parameters:**
- `app`: "dispatcher" or "driver"
- `platform` (optional): "windows", "macos", "linux", "android", "ios"

**Example:**
```bash
# Auto-detect platform from User-Agent
curl http://localhost:8005/download/dispatcher -o dispatcher.exe

# Specify platform
curl "http://localhost:8005/download/driver?platform=android" -o driver.apk
```

## Expected Files

Place compiled binaries in `./binaries/`:

- `hwy-tms-dispatcher-windows.exe`
- `hwy-tms-dispatcher-macos.dmg`
- `hwy-tms-dispatcher-linux.AppImage`
- `hwy-tms-driver.apk`
- `hwy-tms-driver.ipa`

## Development

```bash
mkdir -p binaries
cp .env.example .env
cargo run
```

## Building Binaries

### Flutter Apps
```bash
# Dispatcher (Windows)
cd apps/dispatcher
flutter build windows

# Dispatcher (macOS)
flutter build macos

# Dispatcher (Linux)
flutter build linux

# Driver (Android)
cd apps/driver
flutter build apk

# Driver (iOS)
flutter build ios
```

## Future Enhancements

- JWT authentication
- Version management
- Differential updates
- Download progress tracking
- Checksum verification
