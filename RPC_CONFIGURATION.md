# RPC Configuration Strategy

## Overview

The indexer uses a load-balanced RPC configuration with multiple fallback endpoints to ensure reliable data fetching from Base mainnet. The configuration prioritizes free public RPCs and uses paid endpoints as last resort fallbacks.

## Current Configuration

### Load Balancing Order (Priority)

1. **Base Official RPC** - `https://mainnet.base.org`
   - Rate Limit: 10 requests/second
   - Status: Free, no authentication
   - Reliability: High (official endpoint)

2. **PublicNode** - `https://base-rpc.publicnode.com`
   - Rate Limit: 10 requests/second
   - Status: Free, no authentication
   - Reliability: High (community favorite)

3. **Ankr** - `https://rpc.ankr.com/base`
   - Rate Limit: 10 requests/second
   - Status: Free, no authentication
   - Reliability: High (enterprise-grade infrastructure)

4. **Nodies (Pokt Network)** - `https://base-pokt.nodies.app`
   - Rate Limit: 8 requests/second
   - Status: Free, no authentication
   - Reliability: Medium-High

5. **Alchemy (Optional)** - Configured via `PONDER_RPC_URL_8453`
   - Rate Limit: 5 requests/second (conservative)
   - Status: Paid, requires API key
   - Reliability: High when not rate-limited
   - **Note:** Only used if environment variable is set

## Rate Limiting Strategy

### Why Conservative Rate Limits?

- Prevents overwhelming public endpoints
- Ensures fair usage and good standing with providers
- Allows load balancing to distribute requests evenly
- Reduces chance of temporary bans or throttling

### Current Limits Breakdown

| Endpoint | Rate Limit | Reasoning |
|----------|------------|-----------|
| Base Official | 10 req/s | Official endpoint, moderate limit |
| PublicNode | 10 req/s | Reliable free service |
| Ankr | 10 req/s | Enterprise infrastructure |
| Nodies | 8 req/s | Slightly lower for safety |
| Alchemy | 5 req/s | Has monthly cap, use sparingly |

## How Load Balancing Works

Ponder's `loadBalance()` function:
1. Distributes requests across all available endpoints
2. Automatically retries on failure
3. Respects individual rate limits per endpoint
4. Falls back to next endpoint if one is unavailable

## Monitoring & Troubleshooting

### Check for Rate Limiting Issues

```bash
# Check deployment logs for HTTP 429 errors
railway logs --filter "@level:error OR 429"
```

### Common Error Patterns

- **HTTP 429**: Rate limit exceeded
- **HTTP 503**: Service temporarily unavailable
- **Connection timeouts**: Network or endpoint issues

### If Indexing Stalls

1. Check logs for which endpoint is failing
2. Temporarily remove problematic endpoint from config
3. Consider adding more fallback RPCs
4. Verify rate limits aren't too aggressive

## Alternative RPC Providers

If you need additional endpoints:

### Free Options
- **Blast API**: `https://base-mainnet.public.blastapi.io`
- **1RPC**: `https://1rpc.io/base`
- **LlamaNodes**: `https://base.llamarpc.com`

### Paid Options (Higher Limits)
- **Alchemy**: Up to 300M compute units/month
- **Infura**: Up to 100k requests/day (free tier)
- **QuickNode**: Pay-as-you-go, very reliable
- **Ankr Premium**: Higher rate limits

## Environment Variables

### Required
- `DATABASE_URL`: PostgreSQL connection string

### Optional
- `PONDER_RPC_URL_8453`: Custom RPC for Base (used as last fallback)

### Setting on Railway

```bash
# Remove rate-limited Alchemy endpoint (recommended)
railway variables --delete PONDER_RPC_URL_8453

# Or set to a new provider
railway variables --set PONDER_RPC_URL_8453="https://your-rpc-url"
```

## Performance Optimization

### Current Setup Benefits

✅ **No single point of failure** - Multiple redundant endpoints
✅ **No authentication required** - All primary endpoints are public
✅ **Cost-effective** - Free tier is sufficient for most indexing
✅ **Auto-recovery** - Failed requests automatically retry on other endpoints
✅ **Rate limit compliant** - Conservative limits prevent throttling

### Expected Indexing Performance

With proper RPC configuration:
- **No skipped events** - All events processed successfully
- **Steady progress** - Consistent indexing without stalls
- **Historical sync** - ~24-72 hours for full sync (depends on event volume)
- **Real-time sync** - Near-instant once caught up

## Recent Changes

### December 22, 2024
- **Reconfigured RPC priority** - Free public RPCs now primary
- **Alchemy demoted to fallback** - Resolves monthly cap issues
- **Added Ankr and Nodies** - More redundancy
- **Adjusted rate limits** - Conservative to prevent throttling

## Next Steps

1. ✅ Update `ponder.config.ts` with new RPC configuration
2. ⚠️  Remove `PONDER_RPC_URL_8453` from Railway (or keep as emergency fallback)
3. 🔄 Restart deployment to apply changes
4. 📊 Monitor logs to verify successful RPC failover
5. ✅ Confirm indexing progresses without 429 errors

