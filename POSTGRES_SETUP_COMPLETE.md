# PostgreSQL Setup Complete ✅

## What Was Done

1. ✅ **Created PostgreSQL service** in the same project (`ponder-buildersv4-base-sepolia`)
2. ✅ **Updated DATABASE_URL** to use reference variable: `${{Postgres.DATABASE_URL}}`
3. ✅ **Verified configuration** - DATABASE_URL is now properly set

## Current Setup

### Services in Project
- **Postgres**: PostgreSQL database service (newly created)
- **web**: Your indexer application

### Database Configuration
- **DATABASE_URL**: `${{Postgres.DATABASE_URL}}` (reference variable)
- **Resolved Value**: `postgresql://postgres:****@postgres.railway.internal:5432/railway`
- **Database Name**: `railway`
- **Connection**: Internal Railway network (faster and more secure)

## Benefits of This Setup

### ✅ Reference Variables Work
Since both services are in the same project, you can use Railway's reference variable syntax:
```
DATABASE_URL=${{Postgres.DATABASE_URL}}
```

**Advantages**:
- Automatically updates if PostgreSQL URL changes
- More secure (no hardcoded passwords)
- Uses internal Railway network (faster)
- Easier to manage

### ✅ Better Organization
- All related services in one project
- Easier to manage and monitor
- Clear service relationships

### ✅ Automatic Updates
If Railway changes the PostgreSQL connection details, your app automatically gets the new URL without manual updates.

## Verification

After Railway redeploys, check the logs for:
```
✅ Using PostgreSQL database (persistent storage)
   Connection: postgresql://postgres:****@postgres.railway.internal:5432/railway
```

**NOT** this error:
```
⚠️  CRITICAL WARNING: Running in production without DATABASE_URL!
```

## Next Steps

1. **Wait for Railway to redeploy** (automatic after variable change)
2. **Monitor deployment logs** for successful startup
3. **Verify health check** passes (`/health` endpoint)
4. **Check database connection** in logs

## Database Schema

Remember to set `DATABASE_SCHEMA` if you need a specific schema:
```
DATABASE_SCHEMA=builders_v4_base_sepolia
```

This is optional - Ponder will use the default schema if not set.

## Migration from Old Database

If you were using the database from `victorious-communication` project:

1. **Data Migration** (if needed):
   - Export data from old database
   - Import to new database
   - Or start fresh (if acceptable)

2. **Old Database**:
   - You can keep it running for backup
   - Or delete it to save costs
   - The old project (`victorious-communication`) is no longer needed

## Troubleshooting

### If DATABASE_URL Still Not Working

1. **Check variable value**:
   ```bash
   railway variables
   ```
   Should show `DATABASE_URL` with value starting with `postgresql://`

2. **Verify PostgreSQL is running**:
   - Go to Railway dashboard
   - Check Postgres service status
   - Should show "Active" or "Running"

3. **Check service linking**:
   - Both services should be in same project
   - Reference variable syntax: `${{Postgres.DATABASE_URL}}`
   - Service name must match exactly: `Postgres` (case-sensitive)

4. **Check logs**:
   - Look for database connection errors
   - Verify PostgreSQL is accessible
   - Check for authentication errors

### Common Issues

**Issue**: Reference variable not resolving
- **Solution**: Ensure services are in same project
- **Solution**: Check service name matches exactly (`Postgres`)

**Issue**: Connection timeout
- **Solution**: Verify PostgreSQL service is running
- **Solution**: Check internal network connectivity

**Issue**: Authentication failed
- **Solution**: Railway handles this automatically with reference variables
- **Solution**: Don't manually set password - use reference variable

## Reference

- [Railway Variables Guide](https://docs.railway.com/guides/variables)
- [Railway Reference Variables](https://docs.railway.com/guides/variables#reference-variables)
- [RAILWAY_VARIABLES_CHECKLIST.md](./RAILWAY_VARIABLES_CHECKLIST.md)





