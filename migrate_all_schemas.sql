-- Migration script for all schemas with builders_project tables
-- This script will migrate all UUID-based schemas that contain builders_project

DO $$
DECLARE
  schema_record RECORD;
  row_count INTEGER;
  null_counts RECORD;
  has_claim_admin BOOLEAN;
BEGIN
  -- Loop through all UUID-based schemas
  FOR schema_record IN 
    SELECT schema_name 
    FROM information_schema.schemata 
    WHERE schema_name ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
      AND EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = schema_name 
          AND table_name = 'builders_project'
      )
  LOOP
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Processing schema: %', schema_record.schema_name;
    RAISE NOTICE '========================================';
    
    -- Set search path
    EXECUTE format('SET search_path TO %I', schema_record.schema_name);
    
    -- Check row count
    EXECUTE format('SELECT COUNT(*) FROM %I.builders_project', schema_record.schema_name) INTO row_count;
    RAISE NOTICE 'Found % rows in builders_project', row_count;
    
    IF row_count = 0 THEN
      RAISE NOTICE 'Skipping empty schema';
      CONTINUE;
    END IF;
    
    -- Check if claim_admin column exists
    DECLARE
      has_claim_admin BOOLEAN;
    BEGIN
      SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = schema_record.schema_name 
          AND table_name = 'builders_project' 
          AND column_name = 'claim_admin'
      ) INTO has_claim_admin;
      
      -- Query NULL counts
      IF has_claim_admin THEN
        EXECUTE format('
          SELECT 
            COUNT(*) FILTER (WHERE slug IS NULL) as null_slug,
            COUNT(*) FILTER (WHERE description IS NULL) as null_description,
            COUNT(*) FILTER (WHERE website IS NULL) as null_website,
            COUNT(*) FILTER (WHERE image IS NULL) as null_image,
            COUNT(*) FILTER (WHERE claim_admin IS NULL) as null_claim_admin
          FROM %I.builders_project
        ', schema_record.schema_name) INTO null_counts;
      ELSE
        EXECUTE format('
          SELECT 
            COUNT(*) FILTER (WHERE slug IS NULL) as null_slug,
            COUNT(*) FILTER (WHERE description IS NULL) as null_description,
            COUNT(*) FILTER (WHERE website IS NULL) as null_website,
            COUNT(*) FILTER (WHERE image IS NULL) as null_image,
            0 as null_claim_admin
          FROM %I.builders_project
        ', schema_record.schema_name) INTO null_counts;
      END IF;
    END;
    
    RAISE NOTICE 'NULL counts - slug: %, description: %, website: %, image: %, claim_admin: %',
      null_counts.null_slug, null_counts.null_description, 
      null_counts.null_website, null_counts.null_image, null_counts.null_claim_admin;
    
    -- Migration 1: Convert NULL metadata to empty strings
    IF null_counts.null_slug > 0 OR null_counts.null_description > 0 OR 
       null_counts.null_website > 0 OR null_counts.null_image > 0 THEN
      EXECUTE format('
        UPDATE %I.builders_project 
        SET 
          slug = COALESCE(slug, ''''),
          description = COALESCE(description, ''''),
          website = COALESCE(website, ''''),
          image = COALESCE(image, '''')
        WHERE slug IS NULL OR description IS NULL OR website IS NULL OR image IS NULL
      ', schema_record.schema_name);
      RAISE NOTICE 'Migrated NULL metadata fields to empty strings';
    END IF;
    
    -- Migration 2: Convert total_users to bigint if needed
    IF EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_schema = schema_record.schema_name 
        AND table_name = 'builders_project' 
        AND column_name = 'total_users' 
        AND data_type != 'bigint'
    ) THEN
      EXECUTE format('ALTER TABLE %I.builders_project ALTER COLUMN total_users TYPE BIGINT USING total_users::BIGINT', schema_record.schema_name);
      RAISE NOTICE 'Migrated total_users to bigint';
    END IF;
    
    -- Migration 3: Add claim_admin column if it doesn't exist
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_schema = schema_record.schema_name 
        AND table_name = 'builders_project' 
        AND column_name = 'claim_admin'
    ) THEN
      EXECUTE format('ALTER TABLE %I.builders_project ADD COLUMN claim_admin BYTEA', schema_record.schema_name);
      RAISE NOTICE 'Added claim_admin column';
      RAISE NOTICE 'WARNING: claim_admin values need to be backfilled from contract';
    END IF;
    
    -- Migration 4: Set NOT NULL constraints on metadata fields
    IF EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_schema = schema_record.schema_name 
        AND table_name = 'builders_project' 
        AND column_name = 'slug' 
        AND is_nullable = 'YES'
    ) THEN
      EXECUTE format('ALTER TABLE %I.builders_project ALTER COLUMN slug SET NOT NULL', schema_record.schema_name);
      RAISE NOTICE 'Set slug to NOT NULL';
    END IF;
    
    IF EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_schema = schema_record.schema_name 
        AND table_name = 'builders_project' 
        AND column_name = 'description' 
        AND is_nullable = 'YES'
    ) THEN
      EXECUTE format('ALTER TABLE %I.builders_project ALTER COLUMN description SET NOT NULL', schema_record.schema_name);
      RAISE NOTICE 'Set description to NOT NULL';
    END IF;
    
    IF EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_schema = schema_record.schema_name 
        AND table_name = 'builders_project' 
        AND column_name = 'website' 
        AND is_nullable = 'YES'
    ) THEN
      EXECUTE format('ALTER TABLE %I.builders_project ALTER COLUMN website SET NOT NULL', schema_record.schema_name);
      RAISE NOTICE 'Set website to NOT NULL';
    END IF;
    
    IF EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_schema = schema_record.schema_name 
        AND table_name = 'builders_project' 
        AND column_name = 'image' 
        AND is_nullable = 'YES'
    ) THEN
      EXECUTE format('ALTER TABLE %I.builders_project ALTER COLUMN image SET NOT NULL', schema_record.schema_name);
      RAISE NOTICE 'Set image to NOT NULL';
    END IF;
    
    -- Migration 5: Set claim_admin to NOT NULL if no NULL values exist
    -- Note: claim_admin will have NULL values initially and needs to be backfilled from contract
    -- So we skip setting NOT NULL constraint for now
    -- IF EXISTS (
    --   SELECT 1 FROM information_schema.columns 
    --   WHERE table_schema = schema_record.schema_name 
    --     AND table_name = 'builders_project' 
    --     AND column_name = 'claim_admin'
    --     AND is_nullable = 'YES'
    -- ) AND null_counts.null_claim_admin = 0 THEN
    --   EXECUTE format('ALTER TABLE %I.builders_project ALTER COLUMN claim_admin SET NOT NULL', schema_record.schema_name);
    --   RAISE NOTICE 'Set claim_admin to NOT NULL';
    -- END IF;
    RAISE NOTICE 'Note: claim_admin column added but NOT NULL constraint skipped (needs backfill from contract)';
    
    RAISE NOTICE 'Migration completed for schema: %', schema_record.schema_name;
    RAISE NOTICE '';
  END LOOP;
  
  RAISE NOTICE '========================================';
  RAISE NOTICE 'All migrations completed!';
  RAISE NOTICE '========================================';
END $$;

