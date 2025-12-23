# GraphQL Test Query for Builders Projects

## Endpoint
**GraphQL Playground**: https://ponder-builders-v4-base.up.railway.app

## Quick Test Query

Copy and paste this query into the GraphQL playground:

```graphql
query GetAllBuildersProjects {
  buildersProjects(
    limit: 100
    orderBy: "createdAt"
    orderDirection: "desc"
  ) {
    items {
      id
      name
      admin
      claimAdmin
      totalStaked
      totalUsers
      totalClaimed
      minimalDeposit
      slug
      description
      website
      image
      createdAt
      chainId
    }
    totalCount
    pageInfo {
      hasNextPage
      hasPreviousPage
    }
  }
}
```

## Expected Response

You should see a response like:

```json
{
  "data": {
    "buildersProjects": {
      "items": [
        {
          "id": "0x...",
          "name": "Subnet Name",
          "admin": "0x...",
          "claimAdmin": "0x...",
          "totalStaked": "1000000000000000000",
          "totalUsers": "5",
          "totalClaimed": "500000000000000000",
          "minimalDeposit": "100000000000000000",
          "slug": "subnet-slug",
          "description": "Subnet description",
          "website": "https://example.com",
          "image": "https://example.com/image.png",
          "createdAt": 1234567890,
          "chainId": 8453
        }
      ],
      "totalCount": 1,
      "pageInfo": {
        "hasNextPage": false,
        "hasPreviousPage": false
      }
    }
  }
}
```

## About the Logs

The warnings you're seeing are **normal and expected**:

1. **Contract Revert Warnings**: These occur during historical sync when Ponder tries to read subnet data for events where:
   - The subnet was deleted after the event
   - The subnet never existed (invalid event)
   - The event is from before the subnet was created

2. **Error Handling**: Your code at `src/index.ts:173` correctly handles these cases by:
   - Catching the error
   - Logging a warning
   - Skipping the event (return statement)
   - Continuing with other events

3. **This is Working Correctly**: The fact that you see:
   - ✅ Tables created successfully
   - ✅ Server started on port 8080
   - ✅ Historical sync started (98.5% cached)
   - ⚠️ Some warnings for non-existent subnets (expected)

   Means everything is working as designed!

## Additional Test Queries

### Get Projects with Minimum Stake Filter

```graphql
query GetHighStakeProjects {
  buildersProjects(
    where: {
      totalStaked_gte: "1000000000000000000"  # 1 MOR (18 decimals)
    }
    orderBy: "totalStaked"
    orderDirection: "desc"
    limit: 20
  ) {
    items {
      id
      name
      slug
      totalStaked
      totalUsers
      admin
      claimAdmin
    }
    totalCount
  }
}
```

### Get Projects with Users

```graphql
query GetProjectsWithUsers {
  buildersProjects(limit: 10) {
    items {
      id
      name
      slug
      totalUsers
      builderUsers(limit: 5) {
        items {
          address
          staked
          claimed
        }
        totalCount
      }
    }
  }
}
```

### Get Single Project by ID

```graphql
query GetProject($projectId: String!) {
  buildersProject(id: $projectId) {
    id
    name
    admin
    claimAdmin
    totalStaked
    totalUsers
    slug
    description
    website
    image
    builderUsers {
      totalCount
    }
  }
}
```

**Variables**:
```json
{
  "projectId": "0x1234567890abcdef1234567890abcdef12345678"
}
```

## Troubleshooting

If you get errors:

1. **"Cannot query field 'claimAdmin'"**: The schema hasn't been regenerated yet. Wait for Ponder to restart or manually trigger a schema regeneration.

2. **"Cannot query field 'builderUsers'"**: Make sure you're using the new relation name `builderUsers` instead of `users`.

3. **Empty results**: Check if there's actual data in the database. The migration was successful, but if no events have been processed yet, there won't be any projects.

4. **Connection errors**: Verify the Railway service is running and accessible at the public URL.

