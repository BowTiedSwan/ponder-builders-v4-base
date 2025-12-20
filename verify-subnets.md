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

Use a tool like BaseScan's "Read Contract" feature:
1. Go to: https://basescan.org/address/0x42bb446eae6dca7723a9ebdb81ea88afe77ef4b9#readContract
2. Find the `subnets(bytes32)` function
3. Enter the subnet ID: `0x0c8d5f4c48826aeecff5b2defb4314351a3ca7f93f7b41d8bb99c47e3aae1360`
4. Try reading at different block numbers:
   - At the block where UserDeposited occurred (29019882)
   - At the current block
   - At blocks before/after

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

