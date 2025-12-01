# Shared PostgreSQL Database Setup Guide

This guide explains how to share a single PostgreSQL database instance (e.g., from Railway) across multiple indexer apps using PostgreSQL schemas for data isolation.

## Overview

✅ **Yes, you can share the same PostgreSQL database across multiple apps!**

PostgreSQL supports **schemas** (also called namespaces), which allow you to organize database objects (tables, views, functions) into logical groups within the same database. Each indexer app will use its own schema, keeping their data completely isolated.

## Benefits of Shared Database

- **Cost Savings**: One database instance instead of multiple
- **Simplified Management**: Single database to monitor and backup
- **Resource Efficiency**: Better utilization of database resources
- **Easy Cross-Chain Queries**: Can query across schemas if needed (advanced use case)

## How It Works

Each indexer app uses:
- **Same `DATABASE_URL`**: Points to the shared PostgreSQL instance
- **Different `DATABASE_SCHEMA`**: Unique schema name per app for data isolation

Ponder automatically creates and manages tables within the specified schema.

## Setup Instructions

### Step 1: Create a PostgreSQL Database on Railway

1. Go to your Railway project
2. Click "New" → "Database" → "Add PostgreSQL"
3. Wait for the database to provision
4. Copy the `DATABASE_URL` from the database service variables

### Step 2: Configure Each Indexer App

For each indexer app (Base Sepolia, Arbitrum Mainnet, Base Mainnet), set these environment variables:

#### Base Sepolia Indexer
```bash
DATABASE_URL=<your_railway_postgresql_url>
DATABASE_SCHEMA=builders_v4_base_sepolia
PONDER_RPC_URL_84532=<your_base_sepolia_rpc_url>
```

#### Arbitrum Mainnet Indexer
```bash
DATABASE_URL=<your_railway_postgresql_url>  # SAME as above
DATABASE_SCHEMA=builders_v4_arbitrum_mainnet  # DIFFERENT schema
PONDER_RPC_URL_42161=<your_arbitrum_rpc_url>
```

#### Base Mainnet Indexer
```bash
DATABASE_URL=<your_railway_postgresql_url>  # SAME as above
DATABASE_SCHEMA=builders_v4_base_mainnet  # DIFFERENT schema
PONDER_RPC_URL_8453=<your_base_mainnet_rpc_url>
```

### Step 3: Deploy Each App

Deploy each indexer app with its respective environment variables. Ponder will:
1. Connect to the shared database
2. Create the schema if it doesn't exist
3. Create tables within that schema
4. Start indexing

## Schema Isolation

Each schema is completely isolated:
- **Tables**: Each app's tables exist only in its schema
- **Data**: No data mixing between apps
- **Queries**: By default, queries only see tables in their own schema
- **Performance**: No performance impact - schemas are just logical organization

### Example Schema Structure

```
postgresql://.../builders_db
├── builders_v4_base_sepolia (schema)
│   ├── builders_v4 (table)
│   ├── reward_pool_v4 (table)
│   └── mor_token (table)
├── builders_v4_arbitrum_mainnet (schema)
│   ├── builders (table)
│   ├── mor_token (table)
│   ├── l2_factory (table)
│   └── subnet_factory (table)
└── builders_v4_base_mainnet (schema)
    ├── builders (table)
    └── mor_token (table)
```

## Railway-Specific Setup

### Option 1: Using Railway Environment Variables

1. In each Railway service, go to "Variables" tab
2. Add `DATABASE_URL` (can reference Railway's `${{Postgres.DATABASE_URL}}` if linked)
3. Add `DATABASE_SCHEMA` with unique name per service
4. Add chain-specific RPC URL

### Option 2: Using Railway Service Linking

1. Create PostgreSQL service in Railway
2. Link it to each indexer service
3. Railway automatically provides `${{Postgres.DATABASE_URL}}`
4. Set unique `DATABASE_SCHEMA` per service

## Verification

After deployment, verify schemas are created:

```sql
-- Connect to your database
psql $DATABASE_URL

-- List all schemas
\dn

-- You should see:
-- builders_v4_base_sepolia
-- builders_v4_arbitrum_mainnet
-- builders_v4_base_mainnet

-- Check tables in a specific schema
\dt builders_v4_arbitrum_mainnet.*
```

## Important Notes

### ⚠️ Schema Naming

- Use **descriptive, unique names** for each schema
- Recommended format: `builders_v4_<chain>_<network>`
- Avoid special characters or spaces
- Keep names consistent across deployments

### ⚠️ Database Permissions

Ensure your database user has:
- `CREATE SCHEMA` permission (usually granted by default)
- `CREATE TABLE` permission within schemas
- `USAGE` permission on schemas

### ⚠️ Connection Limits

Railway PostgreSQL typically has connection limits. With 3 apps sharing one database:
- Each app uses connection pooling (max 30 connections per app in config)
- Total: ~90 connections max (well within Railway's limits)
- Monitor connection usage if you add more apps

### ⚠️ Backup Considerations

- Railway backups include **all schemas** in the database
- Restore operations restore the entire database (all schemas)
- Consider schema-specific backup strategies if needed

## Troubleshooting

### Schema Already Exists Error

If you see "schema already exists" errors:
- This is normal on first deployment
- Ponder handles this gracefully
- Check logs to confirm schema creation

### Tables Not Found

If queries return "table does not exist":
- Verify `DATABASE_SCHEMA` is set correctly
- Check that the indexer has started and created tables
- Ensure you're querying the correct schema

### Connection Errors

If you see connection errors:
- Verify `DATABASE_URL` is correct
- Check Railway database is running
- Verify network connectivity
- Check connection limits haven't been exceeded

## Advanced: Cross-Schema Queries

If you need to query across schemas (e.g., aggregate data from all chains):

```sql
-- Query across schemas
SELECT 
  'base_sepolia' as chain,
  COUNT(*) as builders_count
FROM builders_v4_base_sepolia.builders_v4
UNION ALL
SELECT 
  'arbitrum_mainnet' as chain,
  COUNT(*) as builders_count
FROM builders_v4_arbitrum_mainnet.builders;
```

Note: Ponder's GraphQL API queries are schema-scoped by default. Cross-schema queries would need to be done via direct SQL.

## Summary

✅ **Same `DATABASE_URL`** → Points to shared Railway PostgreSQL  
✅ **Different `DATABASE_SCHEMA`** → Unique schema per app for isolation  
✅ **Complete Isolation** → No data mixing between apps  
✅ **Cost Efficient** → One database instance for all apps  

This setup is production-ready and recommended for managing multiple indexer deployments efficiently!


