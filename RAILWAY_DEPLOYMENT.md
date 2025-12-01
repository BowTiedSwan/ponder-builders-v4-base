# Railway Deployment Guide

This guide covers deploying the Builders V4 indexer to Railway with proper database persistence, health checks, and monitoring.

## Prerequisites

- Railway account
- PostgreSQL database (can be Railway PostgreSQL or external)
- RPC endpoint URL for the chain you're indexing

## Quick Setup

### Step 1: Create PostgreSQL Database

1. In your Railway project, click **"New"** → **"Database"** → **"Add PostgreSQL"**
2. Wait for the database to provision
3. Copy the `DATABASE_URL` from the database service variables

**Important**: Railway PostgreSQL provides automatic backups and persistence. This is critical for preventing data loss.

### Step 2: Deploy Indexer Service

1. Create a new service from your GitHub repository
2. Railway will automatically detect the project and start building

### Step 3: Configure Environment Variables

In your Railway service, go to **"Variables"** tab and set:

#### Required Variables

```bash
# Database Configuration (CRITICAL)
DATABASE_URL=${{Postgres.DATABASE_URL}}  # Link to PostgreSQL service, or set manually
DATABASE_SCHEMA=builders_v4_base_sepolia  # Unique schema name per deployment

# RPC Configuration
PONDER_RPC_URL_84532=https://your-rpc-endpoint.com  # Base Sepolia RPC URL
```

#### Optional Variables

```bash
# Logging
PONDER_LOG_LEVEL=info  # Options: trace, debug, info, warn, error

# Contract Overrides (if needed)
BUILDERS_V4_CONTRACT_ADDRESS=0x...
BUILDERS_V4_START_BLOCK=29016947
```

### Step 4: Verify Configuration

After deployment, check the logs for:

```
✅ Using PostgreSQL database (persistent storage)
```

**If you see this warning instead:**
```
⚠️  Using PGlite database (ephemeral file-based storage)
```

**STOP** - Your `DATABASE_URL` is not set correctly. The application will fail in production.

## Health Checks

Railway is configured with health checks via `railway.toml`:

```toml
[deploy]
healthcheckPath = "/health"
healthcheckTimeout = 300
```

- **`/health`**: Returns 200 immediately after process starts
- **`/ready`**: Returns 200 when indexing is caught up, 503 during backfill

Railway will automatically restart the service if health checks fail.

## Preventing Data Loss

### Critical: Database Persistence

The indexer includes validation to prevent accidental use of ephemeral storage:

1. **Production Detection**: Automatically detects Railway, Vercel, Fly.io environments
2. **PostgreSQL Validation**: Requires `DATABASE_URL` in production
3. **Startup Failure**: Application will **fail to start** if `DATABASE_URL` is missing in production

### What Happens on Restart

- **With PostgreSQL**: Indexer resumes from last indexed block (no data loss)
- **With PGlite**: Full reindex required (data loss on restart)

### Verifying Database Persistence

Check logs on startup:

```bash
# ✅ Good - Using PostgreSQL
✅ Using PostgreSQL database (persistent storage)
   Connection: postgresql://user:****@host:port/db

# ❌ Bad - Using PGlite (will fail in production)
⚠️  Using PGlite database (ephemeral file-based storage)
```

## Monitoring and Alerts

### Railway Built-in Monitoring

Railway provides:
- **Service logs**: Real-time logs in Railway dashboard
- **Metrics**: CPU, memory, network usage
- **Deployment history**: Track all deployments

### Recommended Alerts

Set up alerts in Railway for:

1. **Service Crashes**
   - Monitor for repeated restarts
   - Check logs for error patterns

2. **Database Connection Failures**
   - Look for "connection refused" or "timeout" errors
   - Verify PostgreSQL service is running

3. **Reindexing Events**
   - If you see "Started historical sync with 0% cached" frequently
   - This indicates data loss or schema issues

4. **Indexing Lag**
   - Monitor `/ready` endpoint status
   - Should return 200 after initial sync completes

### Health Check Monitoring

Monitor the health check endpoint:

```bash
# Check health status
curl https://your-app.railway.app/health

# Check readiness (indexing status)
curl https://your-app.railway.app/ready
```

## Verifying Tables Are Created

### Important: Railway UI Shows Default Schema

Railway's database UI shows tables in the `public` schema by default. **Ponder creates tables in a custom schema** (specified by `--schema` flag or `DATABASE_SCHEMA` env var).

### Check Tables in the Correct Schema

1. **Connect to your database** via Railway's "Connect" button or using `psql`:

```bash
psql $DATABASE_URL
```

2. **List all schemas** to see which schemas exist:

```sql
\dn
```

You should see schemas like:
- `public` (default, usually empty)
- `builders_v4_prod` (or your `DATABASE_SCHEMA` value)
- `builders_v4` (views schema)

3. **Check tables in your schema**:

```sql
-- Replace 'builders_v4_prod' with your actual schema name
\dt builders_v4_prod.*

-- Or list all tables in all schemas
SELECT schemaname, tablename 
FROM pg_tables 
WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
ORDER BY schemaname, tablename;
```

4. **Check if Ponder has created tables**:

```sql
-- See all tables Ponder should create
SELECT tablename 
FROM pg_tables 
WHERE schemaname = 'builders_v4_prod';  -- Replace with your schema name

-- Expected tables:
-- - builders_project
-- - builders_user
-- - staking_event
-- - mor_transfer
-- - dynamic_subnet
-- - reward_distribution
-- - counters
```

### If Tables Don't Exist

If no tables exist in your schema:

1. **Check Railway deployment logs** - Look for:
   - "Created tables [...]" message
   - Any database connection errors
   - Schema creation messages

2. **Verify schema name** - Check what schema Ponder is using:
   - Check `RAILWAY_DEPLOYMENT_ID` environment variable
   - Check `DATABASE_SCHEMA` environment variable (if set)
   - Check `railway.toml` startCommand schema parameter

3. **Check if indexer started successfully**:
   - Look for "✅ Using PostgreSQL database" in logs
   - Verify no startup errors
   - Check that indexing has begun

## Troubleshooting

### Issue: "DATABASE_URL is required in production" Error

**Symptoms**: Application fails to start with error about DATABASE_URL

**Solution**:
1. Verify `DATABASE_URL` is set in Railway Variables
2. Check variable name is exactly `DATABASE_URL` (case-sensitive)
3. If using Railway PostgreSQL, link the service or use `${{Postgres.DATABASE_URL}}`
4. Verify PostgreSQL service is running

### Issue: Full Reindex on Every Restart

**Symptoms**: Logs show "Started historical sync with 0% cached" on every restart

**Causes**:
1. Using PGlite instead of PostgreSQL
2. Database schema was reset or corrupted
3. `DATABASE_SCHEMA` changed between deployments

**Solution**:
1. Verify PostgreSQL is being used (check startup logs)
2. Ensure `DATABASE_SCHEMA` is consistent across deployments
3. Check database connection is stable
4. Verify database hasn't been reset

### Issue: Health Checks Failing

**Symptoms**: Service keeps restarting, health checks timeout

**Solution**:
1. Check application logs for errors
2. Verify port is correct (Railway sets `PORT` automatically)
3. Check database connectivity
4. Increase `healthcheckTimeout` in `railway.toml` if needed

### Issue: Database Connection Errors

**Symptoms**: "connection refused", "timeout", or "too many connections"

**Solution**:
1. Verify PostgreSQL service is running
2. Check `DATABASE_URL` is correct
3. Verify network connectivity (Railway services can access linked databases)
4. Check connection pool limits (default: 30 per app)

## High Availability (Future Enhancement)

Currently using single instance with persistent PostgreSQL. For higher availability:

### Option 1: Railway HA PostgreSQL Template

Railway offers "PostgreSQL HA with Repmgr" template:
- Automatic failover
- Database replication
- Zero-downtime database updates

**To upgrade**:
1. Create new HA PostgreSQL service from template
2. Migrate data from current PostgreSQL
3. Update `DATABASE_URL` to point to HA instance

### Option 2: Multiple Indexer Instances (Not Recommended)

**Warning**: Indexers are stateful. Multiple instances will cause:
- Duplicate indexing
- Race conditions
- Data inconsistencies

**Better approach**: Keep single indexer instance, use HA database for persistence.

### Option 3: Separate API Service (For Scaling)

If you need horizontal scaling for GraphQL API:

1. **Indexer Service**: Single instance, handles indexing only
2. **API Service**: Multiple instances, stateless GraphQL API
3. **Shared Database**: Both connect to same PostgreSQL

This allows scaling the API layer independently while keeping indexing safe.

## Backup and Recovery

### Railway Automatic Backups

Railway PostgreSQL includes automatic backups:
- **Frequency**: Daily backups
- **Retention**: Configurable (check Railway dashboard)
- **Restore**: Available via Railway dashboard

### Manual Backup

```bash
# Connect to database
psql $DATABASE_URL

# Backup specific schema
pg_dump $DATABASE_URL -n builders_v4_base_sepolia > backup.sql

# Restore schema
psql $DATABASE_URL < backup.sql
```

### Recovery Procedures

1. **From Railway Backup**:
   - Go to PostgreSQL service in Railway
   - Select backup point
   - Restore via Railway dashboard

2. **From Manual Backup**:
   - Restore SQL dump to database
   - Update `DATABASE_SCHEMA` if needed
   - Redeploy indexer service

## Best Practices

1. **Always Use PostgreSQL in Production**
   - Never rely on PGlite for production
   - Validation prevents this automatically

2. **Monitor Health Checks**
   - Set up alerts for health check failures
   - Monitor `/ready` endpoint for indexing status

3. **Consistent Schema Names**
   - Use same `DATABASE_SCHEMA` across deployments
   - Prevents unnecessary reindexing

4. **Database Backups**
   - Enable Railway automatic backups
   - Test restore procedures regularly

5. **Log Monitoring**
   - Watch for database connection errors
   - Monitor indexing progress
   - Alert on unexpected reindexing

## Summary

✅ **PostgreSQL Required**: Application validates database configuration  
✅ **Health Checks**: Configured via `railway.toml`  
✅ **Auto-Restart**: Railway restarts service on failure  
✅ **Data Persistence**: PostgreSQL ensures data survives restarts  
✅ **Monitoring**: Railway provides logs and metrics  

This setup ensures your indexer is resilient and data is safe!

