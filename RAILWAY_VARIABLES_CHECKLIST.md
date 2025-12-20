# Railway Variables Checklist - Complete Guide

## Problem Summary

Your deployment was failing because `DATABASE_URL` was set but **empty** in the web service. This document explains all places to check and common issues.

## ✅ FIXED: DATABASE_URL Now Set

I've set `DATABASE_URL` to the PostgreSQL public URL:
```
postgresql://postgres:****@switchback.proxy.rlwy.net:47850/railway
```

The deployment should now work. Railway will automatically redeploy.

---

## All Places to Check Environment Variables

Based on Railway's documentation, here are **ALL** the places where variables can be set:

### 1. **Service Variables** (Most Common) ✅ CHECKED
**Location**: Service → Variables tab

**What I Found**:
- ✅ `DATABASE_URL` exists but was **EMPTY** (now fixed)
- ✅ Railway-provided variables are present (`RAILWAY_ENVIRONMENT`, etc.)

**How to Check**:
1. Go to your Railway project
2. Click on the service (`web`)
3. Click "Variables" tab
4. Look for `DATABASE_URL` - ensure it has a value

**Common Issues**:
- Variable exists but is empty (this was your issue!)
- Variable name has typos (case-sensitive: `DATABASE_URL` not `database_url`)
- Variable has extra spaces or newlines

---

### 2. **Shared Variables** (Project-Level) ⚠️ CHECK THIS
**Location**: Project Settings → Shared Variables

**What to Check**:
- Is `DATABASE_URL` defined here?
- If yes, is it being referenced correctly in the service?

**Important**: Shared variables are **NOT automatically injected** into services! You must reference them using:
```
DATABASE_URL=${{shared.DATABASE_URL}}
```

**How to Check**:
1. Go to Project Settings (gear icon)
2. Click "Shared Variables"
3. Check if `DATABASE_URL` exists
4. If it exists, go to your service Variables tab and ensure it's referenced

**Common Issues**:
- Shared variable exists but service doesn't reference it
- Reference syntax is wrong (must use `${{shared.VARIABLE_NAME}}`)

---

### 3. **Reference Variables** (Cross-Service) ⚠️ CHECK THIS
**Location**: Service → Variables tab → Reference another service

**What to Check**:
- Are services in the **same project**? (Reference variables only work within same project)
- Is the PostgreSQL service linked/connected?

**Your Situation**:
- ❌ **Services are in DIFFERENT projects**:
  - `ponder-buildersv4-base-sepolia` (web service)
  - `victorious-communication` (Postgres service)
- ✅ **Solution**: Use the public URL directly (already done)

**If services were in same project**, you could use:
```
DATABASE_URL=${{Postgres.DATABASE_URL}}
```

**Common Issues**:
- Trying to reference service from different project (doesn't work)
- Service name mismatch (must match exactly: `Postgres` not `postgres`)
- PostgreSQL service not linked/connected

---

### 4. **Environment-Specific Variables** ⚠️ CHECK THIS
**Location**: Variables tab → Environment dropdown

**What to Check**:
- Are you setting variables for the correct environment?
- Railway has environments: `production`, `staging`, etc.
- Variables can be set per environment

**How to Check**:
1. Go to Service → Variables tab
2. Check the environment dropdown (top right)
3. Ensure you're viewing/editing `production` environment
4. Variables set in wrong environment won't be available

**Common Issues**:
- Variables set in `staging` but deploying to `production`
- Environment dropdown shows wrong environment

---

### 5. **Railway-Provided Variables** ✅ AUTOMATIC
**Location**: Automatically provided by Railway

**What Railway Provides**:
- `RAILWAY_ENVIRONMENT` - Current environment name
- `RAILWAY_ENVIRONMENT_NAME` - Same as above
- `RAILWAY_PUBLIC_DOMAIN` - Public URL
- `RAILWAY_PRIVATE_DOMAIN` - Internal domain
- Database services provide: `DATABASE_URL`, `DATABASE_PUBLIC_URL`, etc.

**These are automatic** - no action needed.

---

### 6. **Build-Time vs Runtime Variables** ⚠️ CHECK THIS
**Location**: Variables are available at both build and runtime

**What to Check**:
- Variables are available during `npm install` and build
- Variables are available when the app runs
- Your `ponder.config.ts` reads `process.env.DATABASE_URL` at startup

**Your Code** (from `ponder.config.ts`):
```typescript
const databaseUrl = process.env.DATABASE_URL;
```

This reads the variable at **runtime** (when the app starts).

**Common Issues**:
- Variable set after build completes (won't help)
- Variable only available at build time but needed at runtime
- Need to redeploy after setting variables

---

### 7. **Staged Changes** ⚠️ CHECK THIS
**Location**: Railway Dashboard → Staged Changes

**What to Check**:
- Railway requires you to **review and deploy** variable changes
- Changes don't take effect until deployed

**How to Check**:
1. After setting variables, check "Staged Changes" in Railway dashboard
2. Review the changes
3. Click "Deploy" or "Apply Changes"
4. Railway will redeploy automatically

**Common Issues**:
- Variables set but changes not deployed
- Forgot to review staged changes

---

### 8. **Variable Visibility** ⚠️ CHECK THIS
**Location**: Variables tab → Eye icon

**What to Check**:
- Sealed variables cannot be viewed (security feature)
- Regular variables can be viewed by clicking eye icon
- Ensure you can see the actual value (not just that it exists)

**Common Issues**:
- Variable appears to exist but value is actually empty
- Variable is sealed and can't verify value
- Copy-paste errors when setting value

---

## What Was Wrong in Your Case

### Root Cause
1. ✅ `DATABASE_URL` variable existed in the web service
2. ❌ **But it was EMPTY** (no value)
3. ❌ Services are in different projects, so reference variables don't work

### Why It Was Empty
- Possibly set manually but value wasn't saved
- Possibly copied from shared variables but reference wasn't created
- Possibly cleared during a previous update

### The Fix
- Set `DATABASE_URL` directly to the PostgreSQL public URL
- Used `DATABASE_PUBLIC_URL` from the PostgreSQL service
- This works across projects (public URL is accessible from anywhere)

---

## Complete Checklist for Future Deployments

### Before Deploying:
- [ ] PostgreSQL service is running and healthy
- [ ] `DATABASE_URL` is set in the **service** (not just shared)
- [ ] `DATABASE_URL` has a **non-empty value**
- [ ] Variable name is exactly `DATABASE_URL` (case-sensitive)
- [ ] If using reference variables, services are in **same project**
- [ ] If services are in different projects, use **public URL**
- [ ] Environment is set to `production` (or correct environment)
- [ ] Staged changes are reviewed and deployed

### After Deploying:
- [ ] Check logs for: `✅ Using PostgreSQL database`
- [ ] Verify NO warning: `⚠️ Using PGlite database`
- [ ] Health check endpoint `/health` returns 200
- [ ] Database connection is successful (no connection errors)

---

## Railway Variable Types Summary

| Type | Scope | Auto-Injected? | Reference Syntax |
|------|-------|----------------|------------------|
| **Service Variables** | Single service | ✅ Yes | Direct access |
| **Shared Variables** | All services in project | ❌ No | `${{shared.VAR}}` |
| **Reference Variables** | Cross-service (same project) | ❌ No | `${{Service.VAR}}` |
| **Railway Variables** | Automatic | ✅ Yes | Direct access |

---

## Troubleshooting Steps

If `DATABASE_URL` is still not working:

1. **Verify Variable Exists**:
   ```bash
   railway variables
   ```
   Should show `DATABASE_URL` with a value

2. **Check Variable Value**:
   - Go to Railway dashboard
   - Service → Variables tab
   - Click eye icon to view value
   - Ensure it's not empty

3. **Check PostgreSQL Service**:
   - Verify PostgreSQL service is running
   - Check PostgreSQL logs for errors
   - Verify `DATABASE_URL` exists in PostgreSQL service

4. **Check Environment**:
   - Ensure you're viewing `production` environment
   - Variables are environment-specific

5. **Check Staged Changes**:
   - Go to Railway dashboard
   - Check "Staged Changes"
   - Deploy if changes are pending

6. **Check Logs**:
   - Look for database connection errors
   - Check if `DATABASE_URL` is being read correctly
   - Verify PostgreSQL is accessible

7. **Test Connection**:
   - Use Railway CLI to test:
   ```bash
   railway run psql $DATABASE_URL
   ```

---

## Best Practices

1. **Use Reference Variables** (when possible):
   - If PostgreSQL and app are in same project
   - Use: `DATABASE_URL=${{Postgres.DATABASE_URL}}`
   - Automatically updates if PostgreSQL URL changes

2. **Use Public URL** (for cross-project):
   - If services are in different projects
   - Use `DATABASE_PUBLIC_URL` from PostgreSQL service
   - More secure than copying password

3. **Set Variables Before First Deploy**:
   - Set all required variables before deploying
   - Prevents failed deployments

4. **Verify After Setting**:
   - Always check variable value after setting
   - Use Railway CLI or dashboard to verify

5. **Use Shared Variables** (for common config):
   - Set once, reference everywhere
   - Easier to manage across multiple services

---

## Your Current Setup

✅ **Fixed**: `DATABASE_URL` is now set correctly
✅ **PostgreSQL**: Running in `victorious-communication` project
✅ **Web Service**: Running in `ponder-buildersv4-base-sepolia` project
✅ **Connection**: Using public URL (works across projects)

**Next Steps**:
1. Wait for Railway to redeploy automatically
2. Check deployment logs for success
3. Verify health check passes
4. Monitor for database connection errors

---

## References

- [Railway Variables Guide](https://docs.railway.com/guides/variables)
- [Railway Reference Variables](https://docs.railway.com/guides/variables#reference-variables)
- [Railway Shared Variables](https://docs.railway.com/guides/variables#shared-variables)





