# Quick Database Check Guide

## Why Railway Shows "No Tables"

Railway's database UI shows tables in the **`public` schema** by default. Ponder creates tables in a **custom schema** (e.g., `builders_v4_prod` or your `DATABASE_SCHEMA` value).

## Quick Check Commands

### 1. Connect to Database

In Railway, click **"Connect"** button on your PostgreSQL service, or use:

```bash
psql $DATABASE_URL
```

### 2. List All Schemas

```sql
\dn
```

You should see schemas like:
- `public` (default, usually empty - this is what Railway UI shows)
- `builders_v4_prod` (or your deployment ID)
- `builders_v4` (views schema)

### 3. Check Tables in Your Schema

```sql
-- Replace 'builders_v4_prod' with your actual schema name
-- Check what schema name Ponder is using from Railway logs or env vars
\dt builders_v4_prod.*

-- Or see all tables across all schemas
SELECT schemaname, tablename 
FROM pg_tables 
WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
ORDER BY schemaname, tablename;
```

### 4. Find Your Schema Name

The schema name comes from:
- `RAILWAY_DEPLOYMENT_ID` environment variable (Railway sets this automatically)
- Or `DATABASE_SCHEMA` environment variable (if you set it manually)
- Or defaults to `builders_v4_prod` (from `railway.toml`)

Check your Railway service logs for:
```
Using database schema 'YOUR_SCHEMA_NAME' and views schema 'builders_v4'
```

### 5. Expected Tables

Ponder should create these tables in your schema:
- `builders_project`
- `builders_user`
- `staking_event`
- `mor_transfer`
- `dynamic_subnet`
- `reward_distribution`
- `counters`

### 6. If Tables Still Don't Exist

1. **Check Railway deployment logs** for:
   ```
   Created tables [builders_project, builders_user, ...]
   ```

2. **Verify DATABASE_URL is set** - Check logs for:
   ```
   ✅ Using PostgreSQL database (persistent storage)
   ```

3. **Check for errors** - Look for:
   - Database connection errors
   - Permission errors
   - Schema creation errors

4. **Verify indexer started** - Check logs show indexing has begun

## Common Issues

### Issue: Tables in `public` schema but not in custom schema

**Cause**: Ponder is using a different schema than expected.

**Solution**: 
- Check what schema name Ponder is using from logs
- Verify `RAILWAY_DEPLOYMENT_ID` or `DATABASE_SCHEMA` is set correctly

### Issue: No tables in any schema

**Cause**: Indexer hasn't started successfully or database connection failed.

**Solution**:
- Check Railway deployment logs for errors
- Verify `DATABASE_URL` is correct
- Ensure PostgreSQL service is running
- Check database permissions

### Issue: Schema exists but no tables

**Cause**: Indexer started but table creation failed.

**Solution**:
- Check logs for table creation errors
- Verify database user has `CREATE TABLE` permission
- Check for schema-level permission issues

## SQL Queries for Verification

```sql
-- List all schemas
SELECT schema_name 
FROM information_schema.schemata 
WHERE schema_name NOT IN ('pg_catalog', 'information_schema', 'pg_toast');

-- Count tables per schema
SELECT schemaname, COUNT(*) as table_count
FROM pg_tables
WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
GROUP BY schemaname;

-- List all tables with their schemas
SELECT schemaname, tablename 
FROM pg_tables 
WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
ORDER BY schemaname, tablename;

-- Check if specific table exists in a schema
SELECT EXISTS (
  SELECT FROM information_schema.tables 
  WHERE table_schema = 'builders_v4_prod'  -- Replace with your schema
  AND table_name = 'builders_project'
);
```

