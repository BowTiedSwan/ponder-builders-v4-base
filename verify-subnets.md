# Subnet Verification Guide

## How to Verify if Subnets Exist

When you see warnings like:
```
Skipping UserDeposited event: subnet 0x... does not exist in contract at block X
```

### Method 1: Check BaseScan for SubnetCreated Events

1. Go to the BuildersV4 contract on BaseScan: https://basescan.org/address/0x42bb446eae6dca7723a9ebdb81ea88afe77ef4b9#events
2. Filter for `SubnetCreated` events
3. Search for the subnet ID in the event logs

### Method 2: Query Database for Indexed Subnets

Connect to your database and run:

```sql
-- Replace 'YOUR_SCHEMA_NAME' with your actual schema (check Railway logs)
-- Find your schema name from logs: "Using database schema 'YOUR_SCHEMA_NAME'"

-- Check if subnet exists in database
SELECT id, name, admin, "createdAtBlock", "createdAt"
FROM YOUR_SCHEMA_NAME.builders_project
WHERE id = '0x0c8d5f4c48826aeecff5b2defb4314351a3ca7f93f7b41d8bb99c47e3aae1360';

-- Check all indexed subnets
SELECT id, name, admin, "createdAtBlock", "totalStaked", "totalUsers"
FROM YOUR_SCHEMA_NAME.builders_project
ORDER BY "createdAtBlock" DESC;

-- Check for SubnetCreated events in staking_events (if we track them)
-- Note: SubnetCreated events are handled separately, but you can check if projects exist
```

### Method 3: Check Contract State at Specific Block

**Note:** BaseScan's "Read Contract" interface reads at the **latest block** by default. To read at a specific historical block, you need to use the API or a tool like viem.

#### Option A: Using BaseScan API (for specific block)

Use BaseScan's API to read contract state at a specific block:

```bash
# Replace YOUR_API_KEY with your BaseScan API key
# Replace BLOCK_NUMBER with the block number (e.g., 29019882)

curl "https://api.basescan.org/api?module=proxy&action=eth_call&to=0x42bb446eae6dca7723a9ebdb81ea88afe77ef4b9&data=0x02e30f9a0c8d5f4c48826aeecff5b2defb4314351a3ca7f93f7b41d8bb99c47e3aae1360&tag=0x[BLOCK_NUMBER_HEX]&apikey=YOUR_API_KEY"
```

Where:
- `0x02e30f9a` is the function selector for `subnets(bytes32)`
- `0x0c8d5f4c...` is the subnet ID (padded to 32 bytes)
- `0x[BLOCK_NUMBER_HEX]` is the block number in hex (e.g., `0x1baa4ea` for block 29019882)

#### Option B: Using BaseScan Web Interface (latest block only)

1. Go to: https://basescan.org/address/0x42bb446eae6dca7723a9ebdb81ea88afe77ef4b9#readContract
2. Find the `subnets(bytes32)` function (it's function #19)
3. Enter the subnet ID: `0x0c8d5f4c48826aeecff5b2defb4314351a3ca7f93f7b41d8bb99c47e3aae1360`
4. Click "Query"
5. **Note:** This reads at the **latest block**, not historical blocks

#### Option C: Using viem/ethers.js (for programmatic checks)

```typescript
import { createPublicClient, http } from 'viem';
import { base } from 'viem/chains';

const client = createPublicClient({
  chain: base,
  transport: http('https://mainnet.base.org'),
});

// Read at specific block
const subnetData = await client.readContract({
  address: '0x42bb446eae6dca7723a9ebdb81ea88afe77ef4b9',
  abi: BuildersV4Abi,
  functionName: 'subnets',
  args: ['0x0c8d5f4c48826aeecff5b2defb4314351a3ca7f93f7b41d8bb99c47e3aae1360'],
  blockNumber: 29019882n, // Read at the event block
});
```

### Method 4: GraphQL Query

Query your indexer's GraphQL API:

```graphql
query CheckSubnet($subnetId: String!) {
  buildersProject(id: $subnetId) {
    id
    name
    admin
    createdAtBlock
    totalStaked
    totalUsers
  }
}

# Variables:
# {
#   "subnetId": "0x0c8d5f4c48826aeecff5b2defb4314351a3ca7f93f7b41d8bb99c47e3aae1360"
# }
```

## Understanding the Warnings

When you see these warnings, it means:

1. **A UserDeposited/UserWithdrawn event was emitted** for a subnet ID
2. **But reading the subnet from the contract reverts** (subnet doesn't exist)

### Possible Reasons:

1. **Subnet was deleted**: The subnet existed when the deposit happened, but was later deleted
2. **Subnet never existed**: The event is malformed or the subnet ID is invalid
3. **Reading at wrong block**: We now read at the event block, but there might still be edge cases
4. **Contract upgrade**: The contract might have been upgraded and the function signature changed

### What Happens:

- The event is **skipped** (not indexed)
- A **warning is logged** with details
- The indexer **continues processing** other events
- The indexer **does not crash**

## Verification Checklist

For each skipped subnet, verify:

- [ ] Does a `SubnetCreated` event exist for this subnet ID?
- [ ] Is the subnet indexed in the database?
- [ ] Can you read the subnet from the contract at the event block?
- [ ] Can you read the subnet from the contract at the current block?
- [ ] Are there other events (UserDeposited/UserWithdrawn) for this subnet that were indexed?

## Example: Checking Subnet 0x0c8d5f4c48826aeecff5b2defb4314351a3ca7f93f7b41d8bb99c47e3aae1360

1. **Check transaction**: https://basescan.org/tx/0x692e8e42da7138ca1b09283b8402d499aca897ed461051817d5977455e0631ed
   - Shows `UserDeposited` event was emitted
   - Deposit was successful
   - Block: 29019882

2. **Check if SubnetCreated exists**: Search BaseScan for `SubnetCreated` events with this subnet ID

3. **Check database**: Query your database schema for this subnet ID

4. **Check contract state**: Try reading `subnets(bytes32)` at block 29019882

