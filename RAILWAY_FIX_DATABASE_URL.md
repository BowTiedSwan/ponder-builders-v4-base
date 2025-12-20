# Quick Fix: DATABASE_URL Not Found Error

## ✅ RESOLVED

**Current Status**: PostgreSQL has been created in the same project and `DATABASE_URL` is configured using reference variables.

**Setup**:
- PostgreSQL service: `Postgres` (in same project)
- DATABASE_URL: `${{Postgres.DATABASE_URL}}` (reference variable)
- Both services in: `ponder-buildersv4-base-sepolia` project

See [POSTGRES_SETUP_COMPLETE.md](./POSTGRES_SETUP_COMPLETE.md) for details.

---

## The Problem (Historical)

You were seeing this error:
```
Error: DATABASE_URL is required in production. PGlite is ephemeral and will cause data loss.
```

This happened because:
- `DATABASE_URL` existed but was **empty** in the web service
- PostgreSQL was in a different project, so reference variables didn't work

## Why This Happens

Railway has different types of variables:
- **Shared Variables** (Project-level): Available but must be **explicitly referenced**
- **Service Variables** (Service-level): Directly available to that service
- **Reference Variables**: Can reference other services' variables (only works within same project)

**Shared variables are NOT automatically injected into services!** You need to reference them.

## Quick Fix (Choose One)

### Option 1: Link PostgreSQL Service (✅ CURRENT SETUP - Recommended)

**Prerequisites**: PostgreSQL service must be in the **same project** as your app.

1. Go to your **indexer service** (the one that's failing)
2. Click **"Variables"** tab
3. Click **"New Variable"**
4. Set:
   - **Name**: `DATABASE_URL`
   - **Value**: `${{Postgres.DATABASE_URL}}` ← Reference variable syntax
5. Click **"Add"**
6. Railway will automatically redeploy

**Note**: If PostgreSQL is in a different project, use Option 3 instead.

### Option 2: Reference Shared Variable

If `DATABASE_URL` is already in Shared Variables:

1. Go to your **indexer service** → **"Variables"** tab
2. Click **"New Variable"**
3. Set:
   - **Name**: `DATABASE_URL`
   - **Value**: `${{DATABASE_URL}}` ← This references the shared variable
4. Click **"Add"**
5. Railway will automatically redeploy

### Option 3: Copy Value Directly

1. Go to **Project Settings** → **"Shared Variables"**
2. Find `DATABASE_URL` and click the **eye icon** to reveal the value
3. Copy the full connection string
4. Go to your **indexer service** → **"Variables"** tab
5. Click **"New Variable"**
6. Set:
   - **Name**: `DATABASE_URL`
   - **Value**: `postgresql://...` (paste the copied value)
7. Click **"Add"**
8. Railway will automatically redeploy

## Verify It Works

After redeploying, check the logs. You should see:

```
✅ Using PostgreSQL database (persistent storage)
   Connection: postgresql://user:****@host:port/db
```

**NOT** this warning:
```
⚠️  Using PGlite database (ephemeral file-based storage)
```

## Why This Matters

- **Shared Variables**: Available to all services but must be referenced with `${{VariableName}}`
- **Service Variables**: Directly available, no reference needed
- **Linked Services**: Automatically provide variables like `${{Postgres.DATABASE_URL}}`

The application needs `DATABASE_URL` to be available as an environment variable at runtime. Setting it as a shared variable alone doesn't make it available unless you reference it.

## Still Having Issues?

1. **Check variable name**: Must be exactly `DATABASE_URL` (case-sensitive)
2. **Check PostgreSQL is running**: Go to PostgreSQL service and verify it's active
3. **Check connection string format**: Should start with `postgresql://`
4. **Check logs**: Look for any database connection errors after the fix

