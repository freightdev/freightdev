# Flutter App - Quick Reference Guide

## Project Structure at a Glance

```
App is organized as:
- Core: Infrastructure (auth, routing, theme, services)
- Features: 11 independent modules (auth, dispatch, compliance, etc.)
- Shared: Reusable components (mostly empty, needs building)
- Data: Global network/storage layer
```

## Implementation Status - By Feature

| Feature | Status | Key Files | Notes |
|---------|--------|-----------|-------|
| Auth | 95% | login_screen.dart (276L), register_screen.dart (211L) | Zitadel OIDC ready |
| Onboarding | 80% | company_screen.dart (419L) | Multi-step wizard implemented |
| Dispatch | 40% | drivers_model.dart, calendar_screen.dart (252L) | Models done, API pending |
| Compliance | 35% | documents_model.dart (151L), rate_confirmation_form.dart (249L) | Models done, integration needed |
| Accounting | 30% | invoice_model.dart (115L), invoicing_screen.dart (114L) | UI skeleton with stats |
| Settings | 50% | settings_page.dart (146L) | Basic screens present |
| Notifications | 20% | message_model.dart (153L) | Structure only |
| Payment | 10% | payment_model.dart (49L) | Structure only |
| Agent/Chat | 5% | Structure only | Not started |
| Training | 15% | training_page.dart (130L) | Structure only |

## State Management Pattern

**Current Approach:** Riverpod + GoRouter

Example usage found in screens:
```dart
class DriversScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driversAsync = ref.watch(filteredDriversProvider);  // Watch provider
    // ...
  }
}
```

**What's Missing:** Provider implementations (filteredDriversProvider, etc.)

## Data Models Implemented

| Model | Size | Enums | Key Fields |
|-------|------|-------|-----------|
| User | 89L | role (admin/dispatcher/driver/manager) | id, name, email, phone |
| Driver | 132L | status (online/away/offline/on_break/driving) | location, loads, CDL, vehicle |
| Load | 137L | status (pending/booked/in_transit/delivered/cancelled) | coordinates, rate, progress, ETA |
| Document | 151L | type (license/insurance/bill/etc), status (verified/pending/expired/rejected) | file, expiry, calculated properties |
| Invoice | 115L | status (draft/pending/paid/partial/cancelled/overdue) | amount, dates, driver/load link |
| Company | 127L | None | legal name, EIN, MC#, DOT#, address |

## Critical Missing Pieces

### 1. Routing System
File: `core/routing/app_router.dart` - CURRENTLY A PLACEHOLDER
Screens reference routes like `/dashboard`, `/drivers/{id}`, `/invoicing/{id}`
Need: Full GoRouter configuration with all named routes

### 2. Riverpod Providers
Files referenced in UI but not implemented:
- `filteredDriversProvider`
- `documentStatsProvider`
- `invoiceStatsProvider`
- `authNotifierProvider`
- And many others

### 3. API Layer Integration
All API files are empty:
- `features/*/data/apis/*.dart`
- Need Dio HTTP client setup
- Need proper error handling
- Need request/response models

### 4. Repository Implementations
Only exists for auth. Need for:
- dispatch (DriversRepository, LoadRepository)
- compliance (DocumentRepository)
- accounting (InvoiceRepository)
- All other features

### 5. Shared Widgets
File: `shared/widgets/` - ALL PLACEHOLDERS
Need to implement:
- AppButton with variants
- AppCard with styles
- AppIcon unified icon system
- AppLoader with variants
- Status chips
- Stat cards

## Key Services Available

### Authentication Service
Location: `core/services/auth_service.dart` (109 lines)
- Zitadel OIDC login/logout
- Token refresh
- Secure token storage
- JWT claims parsing

### Theme System
Location: `core/theme/`
- Custom AppTheme class (NEEDS IMPLEMENTATION)
- colors.dart (color palette)
- spacing.dart (tokens)
- typography.dart (text styles)

## Development Workflow

### To Add a New Feature:
1. Create `features/feature_name/` with data/domain/presentation
2. Add models in `data/models/`
3. Add API in `data/apis/`
4. Create repository in `data/`
5. Add use cases in `domain/usecases/`
6. Create UI screens in `presentation/`
7. Wire up Riverpod providers
8. Add routes to app_router.dart

### To Add a New Screen:
1. Create file in `features/feature/presentation/screens/`
2. Extend `ConsumerWidget` or `ConsumerStatefulWidget`
3. Reference providers with `ref.watch()`
4. Add route in `app_router.dart`

## Code Generation Requirements

Run these after adding models:
```bash
dart run build_runner build
# For watching files during development:
dart run build_runner watch
```

This generates:
- `.g.dart` files for JSON serialization
- Hive type adapters for models with @HiveType()

## Testing Approach Needed

Currently: ZERO test coverage
Priority order:
1. Unit tests for models and validators
2. Widget tests for screens
3. Integration tests for API calls
4. E2E tests for user flows

## Environment Setup

Three flavors available:
- dev (development environment)
- staging (testing environment)  
- prod (production environment)

Configuration in:
- `core/configs/env.dart` - environment variables
- `core/configs/flavors.dart` - flavor definitions
- `main_dev.dart`, `main_staging.dart`, `main_prod.dart`

## Dependencies Overview

**State:** Riverpod 3.0.3 (primary), Provider 6.1.1 (legacy)
**UI:** Flutter Material, table_calendar, flutter_form_builder
**Network:** Dio 5.4.0
**Storage:** Hive 2.2.3, SharedPreferences 2.2.2
**Security:** flutter_appauth, flutter_secure_storage
**Maps:** google_maps_flutter, geolocator, geocoding
**Serialization:** freezed, json_serializable, equatable

## Next Immediate Actions

1. Complete `app_router.dart` with all routes
2. Implement Riverpod providers for each feature
3. Complete shared widgets library
4. Implement API layer with Dio
5. Fill in repository implementations
6. Add data layer integration to screens

## File Locations Cheat Sheet

```
Core infrastructure:       lib/core/
Feature modules:           lib/features/[feature_name]/
Shared components:         lib/shared/
Global data layer:         lib/data/
Authentication service:    lib/core/services/auth_service.dart
Routing:                   lib/core/routing/app_router.dart (EMPTY)
Theme:                     lib/core/theme/app_theme.dart (EMPTY)
```

