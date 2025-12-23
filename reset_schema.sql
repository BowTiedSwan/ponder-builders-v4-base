-- Reset schema script
-- This will drop and recreate the schema for a fresh start

\set schema_name 'builders_v4_base_mainnet'

-- Drop schema if it exists (WARNING: This deletes all data!)
DROP SCHEMA IF EXISTS :schema_name CASCADE;

-- Create fresh schema
CREATE SCHEMA :schema_name;

-- Grant permissions
GRANT ALL ON SCHEMA :schema_name TO postgres;

-- Verify schema was created
SELECT 'Schema created successfully: ' || :'schema_name' as status;

