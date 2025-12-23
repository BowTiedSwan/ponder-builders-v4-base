# Schema Comparison: Goldsky Endpoint vs Current Configuration

## Overview
This document compares the schema from the Goldsky endpoint (`https://api.goldsky.com/api/public/project_cmgzm6igw009l5np264iw7obk/subgraphs/morpheus-mainnet-base-compatible/v0.0.1/gn`) with the current local schema configuration.

## Key Differences

### 1. BuildersProject Type

#### Goldsky Schema:
```graphql
type BuildersProject {
  id: Bytes!                    # Different: Bytes vs String
  name: String!
  admin: Bytes!                 # Different: Bytes vs String
  claimAdmin: Bytes!            # NEW FIELD - Missing in current schema
  startsAt: BigInt!
  minimalDeposit: BigInt!
  withdrawLockPeriodAfterDeposit: BigInt!
  claimLockEnd: BigInt!
  slug: String!                 # Different: Non-nullable vs nullable
  description: String!          # Different: Non-nullable vs nullable
  website: String!              # Different: Non-nullable vs nullable
  image: String!                # Different: Non-nullable vs nullable
  totalStaked: BigInt!
  totalClaimed: BigInt!
  totalUsers: BigInt!           # Different: BigInt vs Int
  builderUsers: [BuildersUser!]! # Different: Relation name "builderUsers" vs "users"
}
```

#### Current Schema:
```graphql
type buildersProject {
  id: String!                   # Different: String vs Bytes
  name: String!
  admin: String!                # Different: String vs Bytes
  # claimAdmin: MISSING
  startsAt: BigInt!
  minimalDeposit: BigInt!
  withdrawLockPeriodAfterDeposit: BigInt!
  claimLockEnd: BigInt!
  slug: String                  # Different: Nullable vs non-nullable
  description: String           # Different: Nullable vs non-nullable
  website: String               # Different: Nullable vs non-nullable
  image: String                 # Different: Nullable vs non-nullable
  totalStaked: BigInt!
  totalUsers: Int!              # Different: Int vs BigInt
  totalClaimed: BigInt!
  chainId: Int!                 # MISSING in Goldsky
  contractAddress: String!      # MISSING in Goldsky
  createdAt: Int!               # MISSING in Goldsky
  createdAtBlock: BigInt!       # MISSING in Goldsky
  users: buildersUserPage       # Different: Relation name "users" vs "builderUsers"
  events: stakingEventPage      # MISSING in Goldsky
}
```

**Differences Summary:**
- ✅ **Missing in Current**: `claimAdmin: Bytes!` field
- ✅ **Type Differences**: 
  - `id`: String vs Bytes
  - `admin`: String vs Bytes
  - `totalUsers`: Int vs BigInt
- ✅ **Nullability Differences**: `slug`, `description`, `website`, `image` are nullable in current but non-nullable in Goldsky
- ✅ **Missing in Goldsky**: `chainId`, `contractAddress`, `createdAt`, `createdAtBlock`, `events` relation
- ✅ **Relation Name**: `users` vs `builderUsers`

---

### 2. BuildersUser Type

#### Goldsky Schema:
```graphql
type BuildersUser {
  id: Bytes!                    # Different: Bytes vs String
  address: Bytes!                # Different: Bytes vs String
  buildersProject: BuildersProject!  # Relation (different structure)
  staked: BigInt!
  lastStake: BigInt!
  # Missing: claimed, claimLockEnd, lastDeposit, virtualDeposited, chainId, buildersProjectId
}
```

#### Current Schema:
```graphql
type buildersUser {
  id: String!                   # Different: String vs Bytes
  buildersProjectId: String!     # MISSING in Goldsky (replaced by relation)
  address: String!              # Different: String vs Bytes
  staked: BigInt!
  claimed: BigInt!              # MISSING in Goldsky
  lastStake: BigInt!
  claimLockEnd: BigInt!         # MISSING in Goldsky
  lastDeposit: BigInt!           # MISSING in Goldsky
  virtualDeposited: BigInt!     # MISSING in Goldsky
  chainId: Int!                 # MISSING in Goldsky
  project: buildersProject       # Relation (different name/structure)
}
```

**Differences Summary:**
- ✅ **Missing in Goldsky**: `claimed`, `claimLockEnd`, `lastDeposit`, `virtualDeposited`, `chainId`, `buildersProjectId`
- ✅ **Type Differences**: 
  - `id`: String vs Bytes
  - `address`: String vs Bytes
- ✅ **Relation Structure**: Current uses `buildersProjectId` + `project` relation, Goldsky uses direct `buildersProject` relation

---

### 3. Counter Type

#### Goldsky Schema:
```graphql
type Counter {
  id: Bytes!                    # Different: Bytes vs String
  totalSubnets: BigInt!         # Different: BigInt vs Int
  totalBuildersProjects: BigInt! # Different: BigInt vs Int
  # Missing: totalStaked, totalUsers, lastUpdated
}
```

#### Current Schema:
```graphql
type counters {
  id: String!                   # Different: String vs Bytes
  totalBuildersProjects: Int!    # Different: Int vs BigInt
  totalSubnets: Int!            # Different: Int vs BigInt
  totalStaked: BigInt!          # MISSING in Goldsky
  totalUsers: Int!              # MISSING in Goldsky
  lastUpdated: Int!             # MISSING in Goldsky
}
```

**Differences Summary:**
- ✅ **Missing in Goldsky**: `totalStaked`, `totalUsers`, `lastUpdated`
- ✅ **Type Differences**: 
  - `id`: String vs Bytes
  - `totalSubnets`: Int vs BigInt
  - `totalBuildersProjects`: Int vs BigInt

---

### 4. Types Present Only in Goldsky Schema

The Goldsky schema includes additional types not present in the current schema:

1. **Subnet** - Subnet-related information
2. **SubnetUser** - User information for subnets
3. **Provider** - Provider information
4. **Upgraded** - Upgrade event tracking

---

### 5. Types Present Only in Current Schema

The current schema includes types not present in Goldsky:

1. **stakingEvent** - Detailed staking event history
2. **morTransfer** - MOR token transfer tracking
3. **dynamicSubnet** - Dynamic subnet creation tracking
4. **rewardDistribution** - Reward distribution events

---

## Summary of Critical Differences

### High Priority (Breaking Changes)
1. **claimAdmin field missing** in `buildersProject` - This is a required field in Goldsky
2. **Type mismatches** (Bytes vs String) for `id` and `admin` fields
3. **totalUsers type** mismatch (Int vs BigInt) in `buildersProject`
4. **Nullability differences** for metadata fields (`slug`, `description`, `website`, `image`)

### Medium Priority (Data Structure Differences)
1. **BuildersUser** missing several fields (`claimed`, `claimLockEnd`, `lastDeposit`, `virtualDeposited`, `chainId`)
2. **Counter** missing fields (`totalStaked`, `totalUsers`, `lastUpdated`)
3. **Relation naming** differences (`users` vs `builderUsers`)

### Low Priority (Additional Types)
1. Goldsky has subnet/provider types not in current schema
2. Current schema has event/transfer types not in Goldsky

---

## Recommendations

1. **Add `claimAdmin` field** to `buildersProject` table and schema
2. **Review type choices** - Consider if Bytes vs String makes sense for your use case
3. **Align nullability** - Decide if metadata fields should be nullable or not
4. **Consider field additions** - Evaluate if missing fields in Goldsky schema are needed
5. **Standardize relation names** - Align relation naming conventions

