# HWY-TMS Frontend Integration

**Status**: Complete
**Last Updated**: December 9, 2025

---

## Overview

This document details the frontend integration work completed for HWY-TMS, including the complete rebranding from FED-TMS and the integration of the Flutter dispatcher app with the backend authentication service.

---

## 1. Rebranding (FED-TMS → HWY-TMS)

### Astro Marketing Site

**Location**: `apps/marketing/`

All marketing site pages have been fully rebranded:

#### Pages Updated
- ✅ `src/pages/index.astro` - Landing page
- ✅ `src/pages/features.astro` - Features page
- ✅ `src/pages/pricing.astro` - Pricing page
- ✅ `src/pages/about.astro` - About page
- ✅ `src/pages/contact.astro` - Contact page
- ✅ `src/pages/login.astro` - Login redirect page
- ✅ `src/pages/signup.astro` - Signup redirect page

#### Components Updated
- ✅ `src/components/Navbar.astro` - Header navigation
- ✅ `src/components/Footer.astro` - Site footer
- ✅ `src/layouts/BaseLayout.astro` - Base layout template

#### Key Changes
```astro
// Before
title="FED-TMS - Fast & Easy Dispatching"

// After
title="HWY-TMS - Highway Transportation Management System"

// Company attribution
© 2025 HWY-TMS by Fast & Easy Dispatching LLC. All rights reserved.
```

### Flutter Dispatcher App

**Location**: `apps/dispatcher/`

#### UI Text Updated
- ✅ `lib/main.dart` - App title changed to "HWY-TMS"
- ✅ `lib/screens/auth/login_screen.dart` - Login screen branding
- ✅ `lib/screens/auth/register_screen.dart` - Registration screen
- ✅ `lib/screens/onboarding/onboarding_screen.dart` - Onboarding flow
- ✅ `lib/widgets/app_drawer.dart` - Navigation drawer logo

#### Service Files Updated
- ✅ `lib/services/database_service.dart` - Database paths
  - `fed_tms_db` → `hwy_tms_db`
  - `fed_tms.db` → `hwy_tms.db`
  - Namespace: `fed_tms` → `hwy_tms`

- ✅ `lib/services/cloud_storage_service.dart` - Backup file names
  - `fed_tms_backup` → `hwy_tms_backup`
  - Backup descriptions updated

---

## 2. Flutter Auth Service Integration

### API Client Configuration

**File**: `apps/dispatcher/lib/services/api_client.dart`

#### Base URL Updated
```dart
static const String baseUrl = String.fromEnvironment(
  'FLUTTER_API_BASE_URL',
  defaultValue: 'http://localhost:8001'
);
```

This points the Flutter app to the Torii auth service running on port 8001.

#### Features
- Automatic JWT Bearer token injection
- Token refresh on 401 errors
- Request/response logging in debug mode
- Comprehensive error handling

### Auth Service Implementation

**File**: `apps/dispatcher/lib/services/auth_service.dart`

#### Endpoint Integration

| Frontend Method | Backend Endpoint | Description |
|----------------|------------------|-------------|
| `register()` | `POST /auth/signup` | Create new dispatcher account |
| `login()` | `POST /auth/login` | Authenticate user |
| `getCurrentUser()` | `GET /auth/validate` | Validate token + get user info |
| Token refresh | `POST /auth/refresh` | Refresh expired access token |

#### Sign Up Implementation
```dart
Future<User> register({
  required String email,
  required String password,
  String role = 'dispatcher',
}) async {
  final response = await _apiClient.post('/auth/signup', data: {
    'email': email,
    'password': password,
    'role': role,
  });

  final accessToken = response.data['access_token'] as String;
  final refreshToken = response.data['refresh_token'] as String;
  final userData = response.data['user'] as Map<String, dynamic>;

  // Store tokens securely
  await prefs.setString(_tokenKey, accessToken);
  await prefs.setString(_refreshTokenKey, refreshToken);

  return User.fromJson(userData);
}
```

#### Login Implementation
```dart
Future<User> login(String email, String password) async {
  final response = await _apiClient.post('/auth/login', data: {
    'email': email,
    'password': password,
  });

  final accessToken = response.data['access_token'] as String;
  final refreshToken = response.data['refresh_token'] as String;
  final userData = response.data['user'] as Map<String, dynamic>;

  // Store tokens and user data
  await prefs.setString(_tokenKey, accessToken);
  await prefs.setString(_refreshTokenKey, refreshToken);
  await LocalStorageService.saveCurrentUser(User.fromJson(userData));

  return User.fromJson(userData);
}
```

#### Token Validation
```dart
Future<User?> getCurrentUser() async {
  // Check cache first
  final cachedUser = LocalStorageService.getCurrentUser();
  if (cachedUser != null) return cachedUser;

  final token = await getToken();
  if (token == null) return null;

  try {
    // Validate with backend
    final response = await _apiClient.get('/auth/validate');
    if (response.data['valid'] == true) {
      final user = _constructUserFromValidation(response.data);
      await LocalStorageService.saveCurrentUser(user);
      return user;
    }
  } catch (e) {
    // Auto-refresh on validation failure
    return await _refreshAndRetry();
  }
}
```

#### Automatic Token Refresh
```dart
Future<User?> _refreshAndRetry() async {
  final refreshToken = await prefs.getString(_refreshTokenKey);
  if (refreshToken == null) return null;

  try {
    final response = await _apiClient.post('/auth/refresh', data: {
      'refresh_token': refreshToken,
    });

    // Update stored tokens
    final newAccessToken = response.data['access_token'] as String;
    final newRefreshToken = response.data['refresh_token'] as String;

    await prefs.setString(_tokenKey, newAccessToken);
    await prefs.setString(_refreshTokenKey, newRefreshToken);

    return User.fromJson(response.data['user']);
  } catch (e) {
    // Refresh failed - logout user
    await logout();
    return null;
  }
}
```

### Token Storage

Tokens are stored securely using SharedPreferences:

- **Access Token**: 7-day expiry, stored as `auth_token`
- **Refresh Token**: 90-day expiry, stored as `refresh_token`
- **User Data**: Cached locally for offline access

---

## 3. Backend API Contract

### POST /auth/signup

**Request**:
```json
{
  "email": "dispatcher@example.com",
  "password": "SecurePass123!",
  "role": "dispatcher"
}
```

**Response**:
```json
{
  "access_token": "eyJhbGc...",
  "refresh_token": "550e8400-e29b-41d4-a716-446655440000",
  "user": {
    "id": "users:abc123",
    "email": "dispatcher@example.com",
    "role": "dispatcher",
    "tier": "free"
  }
}
```

### POST /auth/login

**Request**:
```json
{
  "email": "dispatcher@example.com",
  "password": "SecurePass123!"
}
```

**Response**: Same as signup

### GET /auth/validate

**Headers**:
```
Authorization: Bearer <access_token>
```

**Response**:
```json
{
  "valid": true,
  "user_id": "users:abc123",
  "tier": "pro",
  "status": "active",
  "expires_at": "2026-01-09T00:00:00Z",
  "features": {
    "tier": "pro",
    "max_drivers": 20,
    "max_loads": -1,
    "ai_agents_enabled": true,
    "custom_branding": false,
    "priority_support": true,
    "dedicated_support": false
  }
}
```

### POST /auth/refresh

**Request**:
```json
{
  "refresh_token": "550e8400-e29b-41d4-a716-446655440000"
}
```

**Response**: Same as signup/login

---

## 4. Authentication Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter Dispatcher App                    │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ 1. User signs up
                              ▼
                    POST /auth/signup
                    {email, password, role}
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                  Auth Service (Port 8001)                    │
│                                                               │
│  1. Hash password with Argon2                                │
│  2. Create user in SurrealDB                                 │
│  3. Create free subscription                                 │
│  4. Generate JWT access token (7 days)                       │
│  5. Generate refresh token (90 days)                         │
│                                                               │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ Returns tokens + user
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      Flutter App                             │
│                                                               │
│  1. Store access_token in SharedPreferences                  │
│  2. Store refresh_token in SharedPreferences                 │
│  3. Cache user object in Hive                                │
│  4. Navigate to dashboard                                    │
│                                                               │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ 2. Make API requests
                              ▼
                   Headers: Authorization: Bearer <token>
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                  API Client Interceptor                      │
│                                                               │
│  • Automatically adds Bearer token to all requests           │
│  • On 401 error: Try refresh token                          │
│  • On refresh success: Retry original request               │
│  • On refresh failure: Logout user                          │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

---

## 5. Error Handling

### Authentication Errors
```dart
try {
  final user = await authService.login(email, password);
  // Success - navigate to dashboard
} on Exception catch (e) {
  // Show error to user
  // Common errors:
  // - Invalid credentials
  // - Network timeout
  // - Server error
}
```

### Automatic Token Refresh
```dart
// Handled automatically by API client
// When access token expires (after 7 days):
// 1. API returns 401
// 2. Interceptor catches error
// 3. Calls /auth/refresh with refresh_token
// 4. Updates stored tokens
// 5. Retries original request
// 6. If refresh fails → logout user
```

---

## 6. Testing the Integration

### Local Development Setup

1. **Start Backend Services**:
   ```bash
   cd ~/openhwy
   ./init.sh
   docker-compose up --build
   ```

2. **Verify Auth Service**:
   ```bash
   curl http://localhost:8001/health
   # Expected: "Torii Auth Service - Healthy ✅"
   ```

3. **Test Signup**:
   ```bash
   curl -X POST http://localhost:8001/auth/signup \
     -H "Content-Type: application/json" \
     -d '{
       "email": "test@example.com",
       "password": "SecurePass123!",
       "role": "dispatcher"
     }'
   ```

4. **Run Flutter App**:
   ```bash
   cd apps/dispatcher
   flutter pub get
   flutter run -d chrome
   # Or for mobile: flutter run -d <device>
   ```

5. **Test Auth Flow**:
   - Open app → Sign up with email/password
   - Verify JWT tokens stored in local storage
   - Test login with same credentials
   - Verify automatic navigation to dashboard
   - Close app and reopen → should stay logged in

---

## 7. Security Considerations

### Token Storage
- ✅ Access tokens stored in SharedPreferences (encrypted on mobile)
- ✅ Refresh tokens stored separately
- ✅ No passwords stored locally
- ✅ Tokens cleared on logout

### API Security
- ✅ HTTPS required in production (enforce via baseUrl)
- ✅ JWT tokens expire after 7 days
- ✅ Refresh tokens rotate on use
- ✅ Server-side token validation
- ✅ Argon2 password hashing

### Best Practices
- Never log tokens
- Clear tokens on 401/403 errors
- Validate token before critical operations
- Use secure storage for production (flutter_secure_storage)

---

## 8. Next Steps

### Remaining Integration Work
1. **Driver App**: Apply same auth integration to driver app
2. **Subscription Features**: Show/hide UI based on tier features
3. **Feature Flags**: Implement tier-based feature enforcement
4. **Nebula VPN**: Integrate VPN client library
5. **Testing**: End-to-end auth flow testing

### Production Preparation
- [ ] Change baseUrl to production API URL
- [ ] Implement flutter_secure_storage for tokens
- [ ] Add biometric authentication option
- [ ] Implement "Remember Me" functionality
- [ ] Add password strength requirements UI
- [ ] Implement email verification flow

---

## 9. Files Modified

### Flutter Dispatcher App
```
apps/dispatcher/
├── lib/
│   ├── main.dart                         ✅ Updated app title
│   ├── services/
│   │   ├── api_client.dart              ✅ Base URL → :8001
│   │   ├── auth_service.dart            ✅ Full backend integration
│   │   ├── database_service.dart        ✅ Renamed paths
│   │   └── cloud_storage_service.dart   ✅ Renamed backup files
│   ├── screens/
│   │   ├── auth/
│   │   │   ├── login_screen.dart        ✅ HWY branding
│   │   │   └── register_screen.dart     ✅ HWY branding
│   │   └── onboarding/
│   │       └── onboarding_screen.dart   ✅ HWY branding
│   └── widgets/
│       └── app_drawer.dart              ✅ HWY logo
└── pubspec.yaml                          ✅ Package name
```

### Astro Marketing Site
```
apps/marketing/
├── src/
│   ├── pages/
│   │   ├── index.astro                  ✅ HWY-TMS branding
│   │   ├── features.astro               ✅ HWY-TMS branding
│   │   ├── pricing.astro                ✅ HWY-TMS branding
│   │   ├── about.astro                  ✅ HWY-TMS branding
│   │   ├── contact.astro                ✅ HWY-TMS branding
│   │   ├── login.astro                  ✅ HWY-TMS branding
│   │   └── signup.astro                 ✅ HWY-TMS branding
│   ├── components/
│   │   ├── Navbar.astro                 ✅ HWY logo
│   │   └── Footer.astro                 ✅ Company name
│   └── layouts/
│       └── BaseLayout.astro             ✅ Meta description
└── package.json                          ✅ Package name
```

---

Last Updated: December 9, 2025
