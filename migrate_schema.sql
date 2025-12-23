-- Migration script for schema changes
\set schema_name 'builders_v4_prod'

-- Set search path
SET search_path TO :schema_name;

-- Migration 1: Convert NULL metadata to empty strings
UPDATE builders_project 
SET 
  slug = COALESCE(slug, ''),
  description = COALESCE(description, ''),
  website = COALESCE(website, ''),
  image = COALESCE(image, '')
WHERE slug IS NULL OR description IS NULL OR website IS NULL OR image IS NULL;

-- Migration 2: Convert total_users to bigint if needed
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'builders_v4_prod' 
      AND table_name = 'builders_project' 
      AND column_name = 'total_users' 
      AND data_type != 'bigint'
  ) THEN
    ALTER TABLE builders_project 
    ALTER COLUMN total_users TYPE BIGINT USING total_users::BIGINT;
    RAISE NOTICE 'Migrated total_users to bigint';
  ELSE
    RAISE NOTICE 'total_users already bigint';
  END IF;
END $$;

-- Migration 3: Add claim_admin column if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'builders_v4_prod' 
      AND table_name = 'builders_project' 
      AND column_name = 'claim_admin'
  ) THEN
    ALTER TABLE builders_project ADD COLUMN claim_admin BYTEA;
    RAISE NOTICE 'Added claim_admin column';
  ELSE
    RAISE NOTICE 'claim_admin column already exists';
  END IF;
END $$;

-- Migration 4: Set NOT NULL constraints on metadata fields if they allow NULL
DO $$
DECLARE
  col_record RECORD;
BEGIN
  FOR col_record IN 
    SELECT column_name 
    FROM information_schema.columns
    WHERE table_schema = 'builders_v4_prod'
      AND table_name = 'builders_project'
      AND column_name IN ('slug', 'description', 'website', 'image')
      AND is_nullable = 'YES'
  LOOP
    EXECUTE format('ALTER TABLE builders_project ALTER COLUMN %I SET NOT NULL', col_record.column_name);
    RAISE NOTICE 'Set % to NOT NULL', col_record.column_name;
  END LOOP;
END $$;

-- Migration 5: Set claim_admin to NOT NULL if no NULL values exist
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'builders_v4_prod' 
      AND table_name = 'builders_project' 
      AND column_name = 'claim_admin'
      AND is_nullable = 'YES'
  ) AND NOT EXISTS (
    SELECT 1 FROM builders_project WHERE claim_admin IS NULL
  ) THEN
    ALTER TABLE builders_project ALTER COLUMN claim_admin SET NOT NULL;
    RAISE NOTICE 'Set claim_admin to NOT NULL';
  ELSE
    RAISE NOTICE 'claim_admin constraint check skipped (column missing or has NULL values)';
  END IF;
END $$;

-- Verify migration
SELECT 
  'Migration complete. Verification:' as status,
  COUNT(*) FILTER (WHERE slug IS NULL) as null_slug,
  COUNT(*) FILTER (WHERE description IS NULL) as null_description,
  COUNT(*) FILTER (WHERE website IS NULL) as null_website,
  COUNT(*) FILTER (WHERE image IS NULL) as null_image,
  COUNT(*) FILTER (WHERE claim_admin IS NULL) as null_claim_admin
FROM builders_project;

