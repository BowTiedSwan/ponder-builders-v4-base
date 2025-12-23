-- Check existing schema and data
\set schema_name 'builders_v4_prod'

-- Check if schema exists
SELECT 
  CASE 
    WHEN EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = :'schema_name')
    THEN 'Schema exists'
    ELSE 'Schema does not exist'
  END as schema_status;

-- Set search path
SET search_path TO :schema_name;

-- Check if table exists and get row count
SELECT 
  CASE 
    WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = :'schema_name' AND table_name = 'builders_project')
    THEN (SELECT COUNT(*)::text || ' rows' FROM builders_project)
    ELSE 'Table does not exist'
  END as table_status;

-- Check column information
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = :'schema_name' 
  AND table_name = 'builders_project'
  AND column_name IN ('total_users', 'slug', 'description', 'website', 'image', 'claim_admin')
ORDER BY column_name;

-- Check for NULL values
SELECT 
  COUNT(*) FILTER (WHERE slug IS NULL) as null_slug,
  COUNT(*) FILTER (WHERE description IS NULL) as null_description,
  COUNT(*) FILTER (WHERE website IS NULL) as null_website,
  COUNT(*) FILTER (WHERE image IS NULL) as null_image,
  COUNT(*) FILTER (WHERE claim_admin IS NULL) as null_claim_admin,
  COUNT(*) as total_rows
FROM builders_project;

