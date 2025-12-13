# Flutter App - Architecture Diagram

## 1. High-Level App Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         PRESENTATION LAYER                       │
│  (Screens, Widgets, UI Logic using ConsumerWidget)             │
├─────────────────────────────────────────────────────────────────┤
│  Auth Flow │ Dispatch │ Compliance │ Accounting │ Notifications │
│  Settings  │ Payment  │ Training   │ Agent      │ Onboarding   │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                    ref.watch(provider)
                           │
┌──────────────────────────▼──────────────────────────────────────┐
│                  STATE MANAGEMENT LAYER (RIVERPOD)              │
│           Providers, StateNotifiers, AsyncProviders             │
├──────────────────────────────────────────────────────────────────┤
│  authProvider │ driverProvider │ documentProvider │ etc.        │
│  (NOT YET IMPLEMENTED - CRITICAL)                              │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                  ref.read(repository)
                           │
┌──────────────────────────▼──────────────────────────────────────┐
│                    DOMAIN LAYER                                  │
│  (Entities, Repositories, UseCases)                             │
├──────────────────────────────────────────────────────────────────┤
│  AuthRepository │ DispatchRepository │ ComplianceRepository     │
│  (MOSTLY EMPTY - NEEDS IMPLEMENTATION)                          │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                   repository.method()
                           │
┌──────────────────────────▼──────────────────────────────────────┐
│                    DATA LAYER                                    │
│  (Models, APIs, Local Storage, Repositories Implementation)     │
├──────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐    ┌──────────────┐    ┌──────────────┐       │
│  │ API Classes │    │ Data Models  │    │ Repositories │       │
│  │ (EMPTY)     │    │ (JSON/Hive)  │    │ (EMPTY)      │       │
│  └─────────────┘    └──────────────┘    └──────────────┘       │
└──────────────────────────┬──────────────────────────────────────┘
                           │
          ┌────────────────┼────────────────┐
          │                │                │
    Dio HTTP         Hive Storage    SharedPrefs
      Client         (Local DB)      (Simple KV)
          │                │                │
          └────────────────┼────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────────┐
│                 EXTERNAL SERVICES                                │
│  ┌──────────┐  ┌──────────┐  ┌───────────┐  ┌────────────────┐ │
│  │ Backend  │  │ Maps API │  │ Analytics │  │ Secure Store   │ │
│  │ REST API │  │ Geocoding│  │  Service  │  │ (Flutter)      │ │
│  └──────────┘  └──────────┘  └───────────┘  └────────────────┘ │
└──────────────────────────────────────────────────────────────────┘
```

## 2. Feature Module Structure (Example: Dispatch)

```
dispatch/
├── data/
│   ├── apis/
│   │   ├── dispatch_api.dart      ← Empty (Dio calls will go here)
│   │   ├── drivers_api.dart       ← Empty
│   │   └── loadboard_api.dart     ← Empty
│   ├── models/
│   │   ├── drivers_model.dart     ✓ Implemented (132 lines)
│   │   ├── loadboard_model.dart   ✓ Implemented (137 lines)
│   │   └── dispatch_model.dart    ← Empty
│   └── [repositories]
│       └── dispatch_repository_impl.dart ← Empty (NEEDS IMPLEMENTATION)
│
├── domain/
│   ├── entities/
│   │   ├── driver.dart            ← Empty
│   │   ├── load.dart              ← Empty
│   │   └── dispatch.dart          ← Empty
│   ├── repositories/
│   │   ├── driver_repository.dart ← Empty (interface)
│   │   ├── load_repository.dart   ← Empty
│   │   └── dispatch_repository.dart
│   └── usecases/
│       ├── dispatch_usecase.dart  ← Empty
│       ├── drivers_usecase.dart   ← Empty
│       └── loadboard_usecase.dart ← Empty
│
└── presentation/
    ├── dispatch_page.dart
    ├── screens/
    │   ├── drivers_screen.dart       ✓ UI impl (57 lines) - watches provider
    │   ├── loadboard_screen.dart     ✓ UI impl (63 lines) - watches provider
    │   ├── calendar_screen.dart      ✓ Full impl (252 lines) - functional
    │   └── tracking_screen.dart      ✓ UI impl (78 lines)
    └── widgets/
        └── driver_detail_card.dart   ✓ Widget (63 lines)
```

## 3. Data Flow Example: Load Driver List

```
SCENARIO: User opens Drivers Screen and sees list of drivers

1. PRESENTATION:
   DriversScreen extends ConsumerWidget
   ↓
   Widget build(context, WidgetRef ref) {
     final driversAsync = ref.watch(filteredDriversProvider)
                              ↓
                         
2. STATE MANAGEMENT (RIVERPOD) - MISSING:
   final filteredDriversProvider = FutureProvider<List<Driver>>((ref) async {
     final repository = ref.watch(driverRepositoryProvider)
     return repository.getDrivers()  ← Needs to be created
   })
                              ↓

3. DOMAIN LAYER:
   abstract class DriverRepository {
     Future<List<Driver>> getDrivers();
   }
                              ↓

4. DATA LAYER:
   class DriverRepositoryImpl extends DriverRepository {
     final DriverApi _api;
     
     @override
     Future<List<Driver>> getDrivers() async {
       final response = await _api.getDrivers()
                              ↓
       
5. API LAYER:
   class DriverApi {
     Future<List<Driver>> getDrivers() async {
       final response = await dio.get('/drivers')
       return (response.data as List)
           .map((d) => Driver.fromJson(d))
           .toList()
     }
   }
                              ↓
   
6. EXTERNAL:
   HTTP Request → Backend API → Response → Model → UI
```

## 4. Current Implementation Coverage

```
PRESENTATION LAYER:
├── Screens: ████████░░ 80% (most have UI, missing state)
├── Widgets: ███░░░░░░░ 30% (shared widgets empty, feature-specific ok)
└── State:   ██░░░░░░░░ 20% (Riverpod not wired up)

DOMAIN LAYER:
├── Entities: ████░░░░░░ 40% (defined, mostly empty)
├── Repos:    ██░░░░░░░░ 20% (only auth impl)
└── UseCases: ███░░░░░░░ 30% (file structure, no impl)

DATA LAYER:
├── Models:   ████████░░ 80% (core models done, JSON/Hive ready)
├── APIs:     ░░░░░░░░░░  0% (all empty)
└── Storage:  █████░░░░░ 50% (setup exists, not integrated)

OVERALL: ░████░░░░░ 15-20% IMPLEMENTED
```

## 5. Routing Structure (EMPTY - NEEDS WORK)

```
Current app_router.dart is a placeholder!

Expected routes needed:
/                          → Splash/Auth check
/login                     → LoginScreen (implemented)
/register                  → RegisterScreen (implemented)
/onboarding                → OnboardingPage (implemented)
/dashboard                 → Main app shell
  /dispatch                → DispatchPage
    /drivers               → DriversScreen
    /drivers/:id           → Driver detail
    /loadboard             → LoadboardScreen
    /calendar              → CalendarScreen
    /tracking              → TrackingScreen
  /compliance              → CompliancePage
    /documents             → DocumentsScreen
    /eld                   → ELDScreen
    /reports               → ReportsScreen
  /accounting              → AccountingPage
    /invoicing             → InvoicingScreen
    /invoicing/:id         → Invoice detail
  /notifications           → NotificationsScreen
  /settings                → SettingsPage
    /profile               → ProfileScreen
    /company               → CompanyScreen
  /payment                 → PaymentPage
    /stripe                → StripeScreen
    /paypal                → PayPalScreen
  /training                → TrainingPage
    /courses               → CourseScreen
  /agent                   → AgentPage
    /chat                  → ChatScreen

STRUCTURE:
GoRouter with:
- Route guards for auth
- Nested routes for tabs/navigation
- Deep linking support
- Query parameter handling
```

## 6. State Management Provider Hierarchy (TO BE IMPLEMENTED)

```
Root Providers:
├── authNotifierProvider          ← User auth state
├── driverRepositoryProvider      ← Data access
├── loadRepositoryProvider
├── documentRepositoryProvider
├── invoiceRepositoryProvider
└── ...

Computed/Async Providers:
├── currentUserProvider           ← Depends on auth
├── filteredDriversProvider       ← Depends on driverRepo + filters
├── documentStatsProvider         ← Computed from documents
├── invoiceStatsProvider          ← Computed from invoices
├── driverLocationProvider        ← Realtime location stream
└── unreadNotificationsProvider   ← From notifications service

UI State Providers (local):
├── driverFilterProvider          ← UI filter state
├── sortOrderProvider             ← UI sort state
├── selectedDriverProvider        ← Current selection
└── tabIndexProvider              ← Navigation state
```

## 7. Authentication Flow

```
Zitadel OIDC Integration:

┌─────────────────────────────────────────────┐
│ 1. Login Screen                             │
│    user@example.com | password              │
└──────────────┬──────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────┐
│ 2. flutter_appauth.authorizeAndExchangeCode │
│    → Zitadel OIDC endpoint                  │
└──────────────┬──────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────┐
│ 3. flutter_secure_storage                   │
│    Save: access_token, refresh_token,       │
│    id_token                                 │
└──────────────┬──────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────┐
│ 4. Dio Auth Interceptor                     │
│    Attach access_token to all requests      │
└──────────────┬──────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────┐
│ 5. Navigate to /dashboard                   │
│    (auth_service.dart handles token mgmt)  │
└─────────────────────────────────────────────┘
```

## 8. Component Dependencies

```
Auth Service (implemented):
├── flutter_appauth
├── flutter_secure_storage  
├── logger service
└── env config

HTTP Client (partially):
├── Dio 5.4.0
├── Auth interceptor (empty)
└── Logging interceptor (empty)

Local Storage:
├── Hive (for models)
├── SharedPreferences (for simple KV)
└── flutter_secure_storage (for tokens)

UI Layer:
├── GoRouter
├── flutter_riverpod
├── Custom AppTheme (empty)
├── Material widgets
├── table_calendar
├── flutter_form_builder
└── [shared widgets - empty]
```

## 9. Build & Code Generation

```
pubspec.yaml defines:
├── dependencies (50+ packages)
└── dev_dependencies:
    ├── build_runner      ← Needed for code generation
    ├── freezed           ← Dart immutable classes
    ├── json_serializable ← JSON serialization
    └── hive_generator    ← Hive type adapters

Generation commands:
$ dart run build_runner build    # One-time build
$ dart run build_runner watch    # Watch mode during development
```

## 10. What Connections Are Missing

```
CRITICAL GAPS:
✗ Riverpod providers not wired to repositories
✗ Repositories not implemented (except auth)
✗ API layer empty (needs Dio integration)
✗ app_router.dart incomplete
✗ Shared widgets not built
✗ Theme.dart not implemented
✗ Error handling incomplete

SEMI-COMPLETE:
◐ Auth service implemented
◐ Models created (need .g.dart generation)
◐ Screen UI exists (no state wiring)
◐ Data structures defined

READY TO USE:
✓ Auth screens UI
✓ Onboarding screens UI
✓ Company model with Hive
✓ Authentication service (Zitadel OIDC)
✓ Dependencies in pubspec
✓ Feature module structure
```

