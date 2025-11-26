# CODING RULES - OPENHWY MONOREPO (FINAL STRUCTURE)

## The Structure
```
openhwy/
├── core/                          → Product-specific code
│   ├── apps/                     → Product frontends (Next.js)
│   │   ├── elda-course/
│   │   ├── fed-tms/
│   │   └── hwy-gig/
│   ├── docs/                     → Documentation
│   └── srvs/                     → Go microservices
│
├── src/                           → Shared code
│   ├── api/                      → Unified Next.js API backend
│   └── shared/                   → Shared frontend packages
│       ├── design-system/
│       ├── feature-flags/
│       └── typescript-config/
│
└── [configs]                      → Monorepo tooling
```

## Core Principles

1. **/core** = Product-specific (apps, docs, Go services)
2. **/src** = Shared code (API + frontend packages)
3. **Apps are pure frontends** (call `/src/api`)
4. **API proxies to Go services** (in `/core/srvs`)
5. **One symlink per app** (`src -> ../../../src`)

## Directory Rules

### `/src/api/` - Unified API Backend

**Purpose**: Single Next.js API that serves ALL product frontends

**Structure**:
```
src/api/
├── app/api/v1/
│   ├── auth/        → /api/v1/auth/*
│   ├── drivers/     → /api/v1/drivers/*
│   ├── loads/       → /api/v1/loads/*
│   └── users/       → /api/v1/users/*
├── lib/             → API utilities
└── package.json
```

**Rules**:
- This is the ONLY API in the monorepo
- All apps call these same endpoints
- Proxies requests to Go services in `/core/srvs`
- Contains route handlers, error handling, validation

**DO NOT** modify without understanding impact on all apps

### `/src/shared/` - Shared Frontend Code

**Purpose**: UI components, utilities, configs used across ALL apps

**Contains**:
- `design-system/` → UI components, hooks, layouts
- `feature-flags/` → Feature flag system
- `typescript-config/` → Shared TS configurations

**Rules**:
- Changes affect ALL apps
- Import with `@/src/shared/design-system`, etc.
- Components, hooks, and utilities only

### `/core/apps/<product>/` - Product Frontends

**Purpose**: Next.js frontends for each product

**Structure**:
```
core/apps/fed-tms/
├── app/             → Next.js routes (pages)
├── env.ts           → Environment variables
├── middleware.ts    → Frontend middleware
├── src -> ../../../src  → Symlink to /src
└── package.json
```

**Rules**:
- ONLY frontend code (routes, product-specific logic)
- Calls `/src/api` for ALL backend operations
- Imports from `@/src/shared/` for UI components
- Each app is completely independent

### `/core/docs/` - Documentation

**Purpose**: All documentation, AI context, examples

**Rules**:
- Read before coding
- Update after changes
- Product-specific docs in subdirectories

### `/core/srvs/` - Go Microservices

**Purpose**: Backend services in Go

**Contains**:
- `auth-service/` → Authentication
- `email-service/` → Email sending
- `payment-service/` → Payments
- `user-service/` → User management

**Rules**:
- DO NOT modify without explicit permission
- Production services
- `/src/api` proxies to these

## Working in a Product Frontend

### Example: Adding feature to fed-tms

1. **Navigate**:
```bash
   cd core/apps/fed-tms
```

2. **Read context**:
```bash
   cat ../../docs/fed-tms/UPDATE.md
```

3. **Build feature**:
```typescript
   // core/apps/fed-tms/app/(dashboard)/loads/page.tsx
   import { Button } from '@/src/shared/design-system';
   
   export default async function LoadsPage() {
     // Call unified API
     const res = await fetch('http://localhost:3000/api/v1/loads');
     const loads = await res.json();
     
     return (
       <div>
         <Button>Create Load</Button>
         {/* render loads */}
       </div>
     );
   }
```

4. **Update docs**:
```bash
   echo "## 2024-11-26 - Added Loads Page" >> ../../docs/fed-tms/UPDATE.md
```

## Working in the Unified API

### Example: Adding endpoint
```typescript
// src/api/app/api/v1/loads/route.ts
export async function GET(request: Request) {
  // Call Go service
  const response = await fetch('http://localhost:8001/api/loads');
  const data = await response.json();
  
  return Response.json(data);
}
```

**Rules**:
- Keep thin - just proxy to Go services
- Handle errors gracefully
- Use lib utilities for common patterns

## NEVER DO THIS

1. ❌ Create APIs in product apps
2. ❌ Modify `/src/api` without understanding impact
3. ❌ Modify `/core/srvs` without permission
4. ❌ Break the symlink in apps
5. ❌ Put product-specific code in `/src`

## ALWAYS DO THIS

1. ✅ Work in `/core/apps/<product>/app/` for features
2. ✅ Work in `/src/api/app/api/v1/` for API endpoints
3. ✅ Import from `@/src/shared/` for UI
4. ✅ Call `/src/api` from frontends
5. ✅ Keep apps as pure frontends

## Quick Reference

**Adding frontend page?**
→ `/core/apps/<product>/app/(dashboard)/<feature>/page.tsx`

**Adding API endpoint?**
→ `/src/api/app/api/v1/<resource>/route.ts`

**Need shared component?**
→ Import from `@/src/shared/design-system`

**Where are Go services?**
→ `/core/srvs/<service>/`

**Where's documentation?**
→ `/core/docs/<product>/`

## The Flow
```
Frontend App (core/apps/fed-tms)
       ↓
   Calls API
       ↓
Unified API (src/api)
       ↓
   Proxies to
       ↓
Go Services (core/srvs)
```