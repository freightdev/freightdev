# FED-TMS Project Cleanup & Restructuring Plan
## Fixing the Next-Forge Boilerplate Mess

**Date:** 2025-11-25
**Status:** URGENT - Required for proper development
**Purpose:** Remove irrelevant next-forge boilerplate and establish proper FED-TMS structure

---

## THE PROBLEM

### Current Situation
The project was scaffolded from **next-forge**, a Next.js monorepo starter. It includes:
- ❌ Multiple unnecessary apps (storybook, studio, docs, email)
- ❌ Excessive packages (20+ shared packages we don't need)
- ❌ Vendor dependencies we removed (Clerk, Stripe, Resend, etc.)
- ❌ Misplaced files in `/apps/web/` that should be elsewhere
- ❌ Root package.json still named "next-forge" instead of "fed-tms"
- ❌ Configuration files for services we don't use

### What We Actually Need
- ✅ `/apps/api` - Backend API with microservices (KEEP - Phase 2 complete)
- ✅ `/apps/app` - Main TMS frontend application (KEEP - to be built Phase 3)
- ✅ `/packages/database` - Prisma schema (KEEP)
- ✅ `/packages/auth` - JWT authentication (KEEP)
- ✅ `/packages/storage` - MinIO integration (KEEP)
- ✅ `/packages/email-service` - Email microservice client (KEEP)
- ✅ `/packages/payment-service` - Payment microservice client (KEEP)
- ✅ `/src/services/` - Go microservices (KEEP)
- ✅ `/src/documents/fed-tms/` - Our documentation (KEEP)

### What to Remove
- ❌ `/apps/web/` - Unnecessary duplicate, incorrectly used
- ❌ `/apps/storybook/` - Not needed for MVP
- ❌ `/apps/studio/` - Not needed
- ❌ `/apps/docs/` - We have src/documents instead
- ❌ `/apps/email/` - We have email-service microservice
- ❌ Most of `/packages/` - Too many unused packages

---

## CLEANUP STEPS

### Step 1: Backup Current State
```bash
cd /home/admin/freightdev/openhwy/apps/fed-tms

# Create backup
tar -czf ../fed-tms-backup-$(date +%Y%m%d-%H%M%S).tar.gz .

# Or use git
git add -A
git commit -m "Backup before cleanup"
git branch cleanup-backup
```

### Step 2: Identify What I Created Incorrectly

**Files created in wrong location** (`/apps/web/`):
```
/apps/web/app/(dashboard)/page.tsx - Enhanced dashboard (MISPLACED)
/apps/web/app/(dashboard)/profile/page.tsx - Profile page (MISPLACED)
/apps/web/app/(dashboard)/settings/account/page.tsx - Account settings (MISPLACED)
/apps/web/app/(dashboard)/settings/security/page.tsx - Security settings (MISPLACED)
/apps/web/app/(dashboard)/layout.tsx - Dashboard layout (MODIFIED INCORRECTLY)
/apps/web/components/NotificationBell.tsx - Notification bell (MISPLACED)
/apps/web/components/Toast.tsx - Toast component (DUPLICATE - already exists)
/apps/web/components/ui/* - UI component library (MISPLACED)
/apps/web/lib/context/ToastContext.tsx - Toast context (DUPLICATE)
```

**Documentation files in wrong location:**
```
/apps/web/PHASE_7_SUMMARY.md - Should be in src/documents/fed-tms/
/apps/web/PHASE_8_SUMMARY.md - Should be in src/documents/fed-tms/
/apps/web/PHASE_9_SUMMARY.md - Should be in src/documents/fed-tms/
/apps/web/FORMS_API_INTEGRATION.md - Should be in src/documents/fed-tms/
/apps/web/FORMS_INVENTORY.md - Should be in src/documents/fed-tms/
```

### Step 3: Remove Unnecessary Apps

```bash
cd /home/admin/freightdev/openhwy/apps/fed-tms

# Remove apps we don't need
rm -rf apps/storybook
rm -rf apps/studio
rm -rf apps/email  # We have microservice instead
rm -rf apps/docs   # We use src/documents/
```

### Step 4: Clean Up /apps/web/

**Option A: Remove entirely if not needed**
```bash
# If apps/app is the real frontend, remove web
rm -rf apps/web
```

**Option B: Keep but reset to minimal structure**
```bash
# Remove all my incorrectly placed files
cd apps/web
rm -rf app/\(dashboard\)/profile
rm -rf app/\(dashboard\)/settings
rm -rf components/NotificationBell.tsx
rm -rf components/Toast.tsx
rm -rf components/ui
rm -rf lib/context

# Move documentation to proper location
mv PHASE_7_SUMMARY.md ../../src/documents/fed-tms/
mv PHASE_8_SUMMARY.md ../../src/documents/fed-tms/
mv PHASE_9_SUMMARY.md ../../src/documents/fed-tms/
mv FORMS_API_INTEGRATION.md ../../src/documents/fed-tms/
mv FORMS_INVENTORY.md ../../src/documents/fed-tms/

# Restore original layout if backed up
git checkout apps/web/app/\(dashboard\)/layout.tsx
git checkout apps/web/app/\(dashboard\)/page.tsx
```

### Step 5: Remove Unnecessary Packages

Check which packages are actually used:
```bash
cd packages
ls -la

# Packages to KEEP:
# - database (Prisma)
# - auth (JWT authentication)
# - storage (MinIO)
# - email-service (client for Go microservice)
# - payment-service (client for Go microservice)
# - typescript-config (shared config)

# Packages to CONSIDER REMOVING:
# - analytics (if using vendor analytics)
# - cms (if using vendor CMS)
# - design-system (if not using)
# - feature-flags (if not using)
# - internationalization (if not needed yet)
# - observability (if using vendor monitoring)
# - rate-limit (can add later)
# - security (depends on content)
# - seo (depends on content)
```

**Remove unused packages:**
```bash
# Example - adjust based on what's actually not used
rm -rf packages/analytics
rm -rf packages/cms
rm -rf packages/feature-flags
rm -rf packages/observability
# ... etc
```

### Step 6: Update Root package.json

```bash
cd /home/admin/freightdev/openhwy/apps/fed-tms
```

Change:
```json
{
  "name": "next-forge",  // WRONG
  "version": "5.2.2",
```

To:
```json
{
  "name": "fed-tms",
  "version": "1.0.0",
  "description": "Fast&Easy Dispatching - Transportation Management System",
```

### Step 7: Update turbo.json

Remove references to deleted apps:
```bash
# Edit turbo.json
# Remove: storybook, studio, docs, email from pipeline
```

### Step 8: Update pnpm-workspace.yaml

```yaml
packages:
  - 'apps/api'
  - 'apps/app'
  # REMOVE: apps/web, apps/storybook, apps/studio, apps/docs, apps/email
  - 'packages/*'
  - 'src/services/*'
```

### Step 9: Clean and Reinstall Dependencies

```bash
cd /home/admin/freightdev/openhwy/apps/fed-tms

# Clean everything
pnpm clean
rm -rf node_modules
rm -rf apps/*/node_modules
rm -rf packages/*/node_modules
rm pnpm-lock.yaml

# Reinstall
pnpm install
```

### Step 10: Move Correct Frontend to /apps/app/

Check if `/apps/app/` is the intended frontend:
```bash
ls -la apps/app/
```

If it's mostly empty or has next-forge boilerplate, we need to build the REAL FED-TMS frontend there according to PHASE 3 requirements.

---

## CORRECT PROJECT STRUCTURE

### After Cleanup:
```
fed-tms/
├── apps/
│   ├── api/              # Backend API (Phase 2 ✅ Complete)
│   │   ├── app/
│   │   │   └── routes/   # 27 REST endpoints
│   │   ├── lib/
│   │   └── package.json
│   └── app/              # Frontend TMS Dashboard (Phase 3)
│       ├── app/
│       │   ├── (auth)/
│       │   ├── (dashboard)/
│       │   │   ├── drivers/
│       │   │   ├── loads/
│       │   │   ├── dispatch/
│       │   │   ├── invoices/
│       │   │   ├── analytics/
│       │   │   ├── settings/
│       │   │   └── page.tsx
│       │   └── (driver-portal)/
│       ├── components/
│       ├── lib/
│       └── package.json
├── packages/
│   ├── database/         # Prisma (27 models)
│   ├── auth/             # JWT authentication
│   ├── storage/          # MinIO S3-compatible
│   ├── email-service/    # Email microservice client
│   ├── payment-service/  # Payment microservice client
│   └── typescript-config/
├── src/
│   ├── services/         # Go microservices
│   │   ├── auth-service/
│   │   ├── payment-service/
│   │   ├── email-service/
│   │   └── user-service/
│   └── documents/
│       └── fed-tms/      # ALL DOCUMENTATION HERE
│           ├── MASTER-BUILD-PLAN.md
│           ├── PROJECT-FINAL-STATUS.md
│           ├── PHASE_7_SUMMARY.md
│           ├── PHASE_8_SUMMARY.md
│           ├── PHASE_9_SUMMARY.md
│           └── ... (all docs)
├── docker-compose.yml
├── package.json          # "name": "fed-tms"
├── pnpm-workspace.yaml
├── turbo.json
└── tsconfig.json
```

---

## PHASE 3: BUILD CORRECT FRONTEND

### What Actually Needs to Be Built (in /apps/app/)

Based on MASTER-BUILD-PLAN.md Phase 3:

**1. Dashboard Pages** (Dispatcher View)
- `/dashboard` - Overview, metrics, quick actions
- `/dashboard/drivers` - Driver management (list, add, edit, documents)
- `/dashboard/loads` - Load management (list, create, assign, track)
- `/dashboard/dispatch` - Dispatch board (real-time assignments)
- `/dashboard/invoices` - Invoice management
- `/dashboard/payments` - Payment tracking
- `/dashboard/analytics` - Reports and analytics
- `/dashboard/messages` - Internal messaging
- `/dashboard/settings` - Company settings, integrations

**2. Driver Portal Pages** (Driver View)
- `/driver/available-loads` - Browse loads
- `/driver/my-loads` - Assigned loads
- `/driver/earnings` - Payment history
- `/driver/profile` - Update profile
- `/driver/documents` - Upload documents

**3. Shared Components**
- Navigation (dispatcher vs driver)
- Auth pages (login, register)
- Layout components
- Real-time notifications
- Map components (tracking)

---

## WHAT I SHOULD HAVE DONE

### The Right Approach:

1. **Read all documentation first** ✅ (Should have done this)
   - Understand the MASTER-BUILD-PLAN
   - See what's already built (Phase 1, 2 complete)
   - Know where Phase 3 needs to go

2. **Check the actual structure** ✅ (Should have done this)
   - Look at /apps/api - see it's done
   - Look at /apps/app - see it needs Phase 3 work
   - Understand /apps/web is boilerplate to remove

3. **Ask clarifying questions** ✅ (Should have done this)
   - "Which app directory should I work in?"
   - "Is /apps/web needed or should I remove it?"
   - "Where do new docs go?"

4. **Build in correct location** ✅ (Should have done this)
   - Work in /apps/app for Phase 3 frontend
   - Save all docs to /src/documents/fed-tms/
   - Follow the structure in MASTER-BUILD-PLAN

5. **Test as I go** ✅ (Should have done this)
   - Run `pnpm dev` after each change
   - Make sure it actually works
   - Don't create 20 files without testing

---

## IMMEDIATE ACTION PLAN

### Tonight/Tomorrow Morning:

**1. Execute Cleanup** (30 minutes)
```bash
# Run the cleanup script (see Step 2-9 above)
./cleanup-project.sh
```

**2. Verify Structure** (10 minutes)
```bash
# Check it looks like the CORRECT STRUCTURE diagram
ls -la apps/
ls -la packages/
ls -la src/documents/fed-tms/
```

**3. Test Build** (10 minutes)
```bash
cd /home/admin/freightdev/openhwy/apps/fed-tms
pnpm install
pnpm build
```

**4. Start Fresh on Phase 3** (Next work session)
- Read MASTER-BUILD-PLAN.md Phase 3 section
- Build dashboard pages in /apps/app/
- Follow the HTML mockups in src/examples/
- Save docs to /src/documents/fed-tms/

---

## LESSONS LEARNED

### What Went Wrong:
1. ❌ Didn't read existing documentation first
2. ❌ Didn't understand the monorepo structure
3. ❌ Created files in wrong app directory (/apps/web instead of /apps/app)
4. ❌ Duplicated existing code (ToastContext)
5. ❌ Put documentation in wrong location
6. ❌ Didn't test incrementally
7. ❌ Made assumptions instead of asking questions

### What to Do Right:
1. ✅ **ALWAYS** read src/documents/fed-tms/ first
2. ✅ **ALWAYS** check which app directory to use
3. ✅ **ALWAYS** save new docs to src/documents/fed-tms/
4. ✅ **ALWAYS** check if code already exists before creating
5. ✅ **ALWAYS** test after each file created
6. ✅ **ALWAYS** ask when structure is unclear
7. ✅ **NEVER** create 20+ files without verifying location

---

## CLEANUP SCRIPT

Save this as `cleanup-project.sh`:

```bash
#!/bin/bash

# FED-TMS Cleanup Script
# Removes next-forge boilerplate and fixes structure

set -e  # Exit on error

echo "🧹 Starting FED-TMS Cleanup..."

# Navigate to project root
cd /home/admin/freightdev/openhwy/apps/fed-tms

# Step 1: Backup
echo "📦 Creating backup..."
git add -A
git commit -m "Backup before cleanup - $(date +%Y%m%d-%H%M%S)" || true
git branch cleanup-backup-$(date +%Y%m%d-%H%M%S) || true

# Step 2: Move misplaced documentation
echo "📄 Moving documentation to correct location..."
if [ -f apps/web/PHASE_7_SUMMARY.md ]; then
    mv apps/web/PHASE_7_SUMMARY.md src/documents/fed-tms/ 2>/dev/null || true
fi
if [ -f apps/web/PHASE_8_SUMMARY.md ]; then
    mv apps/web/PHASE_8_SUMMARY.md src/documents/fed-tms/ 2>/dev/null || true
fi
if [ -f apps/web/PHASE_9_SUMMARY.md ]; then
    mv apps/web/PHASE_9_SUMMARY.md src/documents/fed-tms/ 2>/dev/null || true
fi
if [ -f apps/web/FORMS_API_INTEGRATION.md ]; then
    mv apps/web/FORMS_API_INTEGRATION.md src/documents/fed-tms/ 2>/dev/null || true
fi
if [ -f apps/web/FORMS_INVENTORY.md ]; then
    mv apps/web/FORMS_INVENTORY.md src/documents/fed-tms/ 2>/dev/null || true
fi

# Step 3: Remove misplaced files in /apps/web/
echo "🗑️  Removing incorrectly placed files..."
rm -rf apps/web/app/\(dashboard\)/profile 2>/dev/null || true
rm -rf apps/web/app/\(dashboard\)/settings 2>/dev/null || true
rm -rf apps/web/components/NotificationBell.tsx 2>/dev/null || true
rm -rf apps/web/components/Toast.tsx 2>/dev/null || true
rm -rf apps/web/components/ui 2>/dev/null || true
rm -rf apps/web/lib/context 2>/dev/null || true

# Step 4: Remove unnecessary apps
echo "🗑️  Removing unused apps..."
rm -rf apps/storybook 2>/dev/null || true
rm -rf apps/studio 2>/dev/null || true
rm -rf apps/docs 2>/dev/null || true
rm -rf apps/email 2>/dev/null || true

# Step 5: Update package.json
echo "📝 Updating root package.json..."
sed -i 's/"name": "next-forge"/"name": "fed-tms"/' package.json
sed -i 's/"version": "5.2.2"/"version": "1.0.0"/' package.json

# Step 6: Clean dependencies
echo "🧹 Cleaning dependencies..."
rm -rf node_modules 2>/dev/null || true
rm -rf apps/*/node_modules 2>/dev/null || true
rm -rf packages/*/node_modules 2>/dev/null || true
rm pnpm-lock.yaml 2>/dev/null || true

# Step 7: Reinstall
echo "📦 Reinstalling dependencies..."
pnpm install

echo "✅ Cleanup complete!"
echo ""
echo "Next steps:"
echo "1. Run 'pnpm build' to verify"
echo "2. Run 'pnpm dev' to test"
echo "3. Begin Phase 3 work in /apps/app/"
```

---

## VERIFICATION CHECKLIST

After cleanup, verify:

- [ ] Root package.json says "fed-tms" not "next-forge"
- [ ] Only /apps/api and /apps/app exist (no web, storybook, studio, docs, email)
- [ ] All documentation is in /src/documents/fed-tms/
- [ ] No duplicate files (ToastContext, etc.)
- [ ] `pnpm install` completes successfully
- [ ] `pnpm build` completes successfully
- [ ] No TypeScript errors
- [ ] API still works (Phase 2 not broken)
- [ ] Can start dev server with `pnpm dev`

---

## NEXT SESSION PLAN

### Morning Session (2-3 hours):
1. **Execute cleanup** - Run cleanup script
2. **Verify structure** - Check everything looks right
3. **Test builds** - Make sure nothing broke

### After Cleanup (Start Phase 3):
1. Read MASTER-BUILD-PLAN Phase 3 section thoroughly
2. Review HTML mockups in src/examples/
3. Build dashboard layout in /apps/app/
4. Create dashboard pages one at a time
5. Test each page before moving to next
6. Document progress in src/documents/fed-tms/

---

**This is your livelihood. I take that seriously. Let's fix this properly.**

**Status:** Ready to execute cleanup
**Next Action:** Run cleanup script
**Expected Time:** 30-45 minutes
**Risk:** Low (backed up first)
