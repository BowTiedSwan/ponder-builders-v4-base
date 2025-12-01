import { createConfig } from "ponder";
import { http, type Abi } from "viem";
import { loadBalance, rateLimit } from "ponder";

// Import v4 contract ABIs
import { BuildersV4Abi, RewardPoolV4Abi, FeeConfigAbi, BuildersTreasuryV2Abi, ERC20Abi } from "./abis/index.js";

// Detect production environment
const isProduction = 
  process.env.NODE_ENV === "production" ||
  process.env.RAILWAY_ENVIRONMENT !== undefined ||
  process.env.RAILWAY_ENVIRONMENT_NAME === "production" ||
  process.env.VERCEL_ENV === "production" ||
  process.env.FLY_APP_NAME !== undefined;

// Validate database configuration
const databaseUrl = process.env.DATABASE_URL;
const usingPostgres = !!databaseUrl;
const usingPGlite = !databaseUrl;

if (isProduction && usingPGlite) {
  console.error("⚠️  CRITICAL WARNING: Running in production without DATABASE_URL!");
  console.error("⚠️  PGlite (ephemeral file-based database) will be used, which will cause DATA LOSS on restart!");
  console.error("⚠️  Set DATABASE_URL environment variable to use PostgreSQL for persistent storage.");
  console.error("⚠️  This is a production deployment - data will NOT persist across restarts!");
  throw new Error(
    "DATABASE_URL is required in production. PGlite is ephemeral and will cause data loss. " +
    "Please set DATABASE_URL to a PostgreSQL connection string."
  );
}

if (usingPostgres) {
  console.log("✅ Using PostgreSQL database (persistent storage)");
  console.log(`   Connection: ${databaseUrl?.replace(/:[^:@]+@/, ":****@")}`); // Mask password
} else {
  console.warn("⚠️  Using PGlite database (ephemeral file-based storage)");
  console.warn("⚠️  This is suitable for local development only.");
  console.warn("⚠️  Data will be lost on restart. Use DATABASE_URL for production.");
}

export default createConfig({
  // Database configuration: Use Postgres if DATABASE_URL is provided, otherwise use PGlite for local dev
  ...(databaseUrl
    ? {
        database: {
          kind: "postgres",
          connectionString: databaseUrl,
          poolConfig: {
            max: 30,
          },
        },
      }
    : {}),
  chains: {
    baseSepolia: {
      id: 84532,
      rpc: loadBalance([
        http(process.env.PONDER_RPC_URL_84532 || "https://sepolia.base.org"),
        rateLimit(http("https://base-sepolia-rpc.publicnode.com"), { 
          requestsPerSecond: 10 
        }),
      ]),
    },
  },
  contracts: {
    // Builders v4 staking contract - deployed on Base Sepolia
    BuildersV4: {
      abi: BuildersV4Abi as Abi,
      chain: "baseSepolia",
      address: (process.env.BUILDERS_V4_CONTRACT_ADDRESS || "0x6C3401D71CEd4b4fEFD1033EA5F83e9B3E7e4381") as `0x${string}`,
      startBlock: Number(process.env.BUILDERS_V4_START_BLOCK || "29016947"),
      includeTransactionReceipts: true,
    },

    // Reward Pool v4 - handles reward distribution
    RewardPoolV4: {
      abi: RewardPoolV4Abi as Abi,
      chain: "baseSepolia",
      address: (process.env.REWARD_POOL_V4_CONTRACT_ADDRESS || "0x0000000000000000000000000000000000000000") as `0x${string}`,
      startBlock: Number(process.env.REWARD_POOL_V4_START_BLOCK || "0"),
    },

    // Builders Treasury V2 - handles reward distribution to users
    BuildersTreasuryV2: {
      abi: BuildersTreasuryV2Abi as Abi,
      chain: "baseSepolia",
      address: (process.env.BUILDERS_TREASURY_V2_CONTRACT_ADDRESS || "0x0000000000000000000000000000000000000000") as `0x${string}`,
      startBlock: Number(process.env.BUILDERS_TREASURY_V2_START_BLOCK || "0"),
    },

    // Fee Config - proxy contract for fee configuration
    FeeConfig: {
      abi: FeeConfigAbi as Abi,
      chain: "baseSepolia",
      address: (process.env.FEE_CONFIG_CONTRACT_ADDRESS || "0x0000000000000000000000000000000000000000") as `0x${string}`,
      startBlock: Number(process.env.FEE_CONFIG_START_BLOCK || "0"),
    },

    // MOR Token contract - for tracking transfers and approvals
    MorToken: {
      abi: ERC20Abi,
      chain: "baseSepolia",
      // TODO: Update with actual MOR token address on Base Sepolia
      address: (process.env.MOR_TOKEN_ADDRESS_BASE_SEPOLIA || "0x5C80Ddd187054E1E4aBBfFCD750498e81d34FfA3") as `0x${string}`,
      // TODO: Update with actual deployment block number
      startBlock: Number(process.env.MOR_TOKEN_START_BLOCK_BASE_SEPOLIA || "24869176"),
    },
  },
});
