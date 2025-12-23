# Database Reset Instructions

## What Was Done

1. ✅ **Set `DATABASE_SCHEMA` environment variable** in Railway to `builders_v4_base_mainnet`
2. ✅ **Created fresh schema** `builders_v4_base_mainnet` in the database
3. ✅ **Schema is ready** for Ponder to create tables and start indexing

## Next Steps

### 1. Restart Railway Service

Ponder needs to restart to pick up the new `DATABASE_SCHEMA` environment variable:

1. Go to Railway dashboard
2. Navigate to your `ponder-builders-v4-base` project
3. Click on the `web` service
4. Click "Restart" or "Redeploy"

### 2. Verify After Restart

After restart, check the logs for:
- ✅ `Created tables [builders_project, builders_user, ...]` - Tables created in new schema
- ✅ `Started 'base' historical sync` - Indexing started
- ⚠️ Some contract revert warnings are normal (for non-existent subnets)

### 3. Check GraphQL After Indexing

Once indexing starts, wait a few minutes then query:

```graphql
query CheckData {
  buildersProjects(limit: 10) {
    totalCount
    items {
      id
      name
      totalStaked
    }
  }
}
```

## Why This Was Needed

**Problem**: 
- `DATABASE_SCHEMA` was not set, so Ponder was using UUID-based schemas
- Data existed in old schemas but GraphQL was querying a different schema
- Multiple schemas from previous deployments caused confusion

**Solution**:
- Set a fixed `DATABASE_SCHEMA` value
- Created a fresh schema for clean indexing
- Ponder will now use the specified schema consistently

## About the Contract Revert Warnings

The warnings you see are **normal**:
- They occur when processing historical events for subnets that:
  - Were deleted after the event
  - Never existed (invalid events)
  - Events from before subnet creation
- Your code correctly handles these by skipping the events
- This doesn't prevent indexing of valid events

## If Still No Data After Restart

If after restart you still see no data:

1. **Check start block**: Verify `BUILDERS_V4_START_BLOCK` is correct (currently `24381796`)
2. **Check contract address**: Verify `0x42BB446eAE6dca7723a9eBdb81EA88aFe77eF4B9` is correct
3. **Check RPC**: Ensure RPC endpoint is working (you have Alchemy set up ✅)
4. **Check logs**: Look for actual event processing (not just warnings)

## Environment Variables Set

- ✅ `DATABASE_SCHEMA=builders_v4_base_mainnet`
- ✅ `DATABASE_URL` (already set)
- ✅ `PONDER_RPC_URL_8453` (already set)

## Migration Files Created

- `migrate_all_schemas.sql` - For migrating existing schemas (if needed)
- `reset_schema.sql` - For creating fresh schema
- `check_schema.sql` - For checking schema state

