import pg from 'pg';
const { Client } = pg;

const DATABASE_URL = process.env.DATABASE_URL || 'postgresql://postgres:AjkMWGtVwKZbqIJGtOilofFOUcZHpLNo@postgres.railway.internal:5432/railway';
const DATABASE_SCHEMA = process.env.DATABASE_SCHEMA || 'builders_v4_prod';

async function checkAndMigrate() {
  const client = new Client({
    connectionString: DATABASE_URL,
  });

  try {
    await client.connect();
    console.log('✅ Connected to database');

    // Check if schema exists
    const schemaCheck = await client.query(`
      SELECT schema_name 
      FROM information_schema.schemata 
      WHERE schema_name = $1
    `, [DATABASE_SCHEMA]);

    if (schemaCheck.rows.length === 0) {
      console.log(`⚠️  Schema '${DATABASE_SCHEMA}' does not exist. Creating it...`);
      await client.query(`CREATE SCHEMA IF NOT EXISTS ${DATABASE_SCHEMA}`);
      console.log(`✅ Schema '${DATABASE_SCHEMA}' created`);
      await client.end();
      return;
    }

    console.log(`✅ Schema '${DATABASE_SCHEMA}' exists`);

    // Set search path to the schema
    await client.query(`SET search_path TO ${DATABASE_SCHEMA}`);

    // Check if builders_project table exists
    const tableCheck = await client.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = $1 AND table_name = 'builders_project'
    `, [DATABASE_SCHEMA]);

    if (tableCheck.rows.length === 0) {
      console.log('⚠️  Table builders_project does not exist. No migration needed.');
      await client.end();
      return;
    }

    console.log('✅ Table builders_project exists');

    // Check for existing data
    const countResult = await client.query(`
      SELECT COUNT(*) as count FROM builders_project
    `);
    const rowCount = parseInt(countResult.rows[0].count);
    console.log(`📊 Found ${rowCount} existing records in builders_project`);

    if (rowCount === 0) {
      console.log('✅ No existing data. No migration needed.');
      await client.end();
      return;
    }

    // Check current column types and nullability
    const columnInfo = await client.query(`
      SELECT 
        column_name,
        data_type,
        is_nullable,
        column_default
      FROM information_schema.columns
      WHERE table_schema = $1 
        AND table_name = 'builders_project'
        AND column_name IN ('total_users', 'slug', 'description', 'website', 'image', 'claim_admin')
      ORDER BY column_name
    `, [DATABASE_SCHEMA]);

    console.log('\n📋 Current column information:');
    columnInfo.rows.forEach(col => {
      console.log(`  - ${col.column_name}: ${col.data_type} (nullable: ${col.is_nullable})`);
    });

    // Check for NULL values in metadata fields
    const nullCheck = await client.query(`
      SELECT 
        COUNT(*) FILTER (WHERE slug IS NULL) as null_slug,
        COUNT(*) FILTER (WHERE description IS NULL) as null_description,
        COUNT(*) FILTER (WHERE website IS NULL) as null_website,
        COUNT(*) FILTER (WHERE image IS NULL) as null_image,
        COUNT(*) FILTER (WHERE claim_admin IS NULL) as null_claim_admin
      FROM builders_project
    `);

    const nulls = nullCheck.rows[0];
    console.log('\n📊 NULL value counts:');
    console.log(`  - slug: ${nulls.null_slug}`);
    console.log(`  - description: ${nulls.null_description}`);
    console.log(`  - website: ${nulls.null_website}`);
    console.log(`  - image: ${nulls.null_image}`);
    console.log(`  - claim_admin: ${nulls.null_claim_admin}`);

    // Check total_users type
    const totalUsersCol = columnInfo.rows.find(col => col.column_name === 'total_users');
    const needsBigIntMigration = totalUsersCol && totalUsersCol.data_type !== 'bigint';

    const needsMigration = 
      nulls.null_slug > 0 ||
      nulls.null_description > 0 ||
      nulls.null_website > 0 ||
      nulls.null_image > 0 ||
      nulls.null_claim_admin > 0 ||
      needsBigIntMigration;

    if (!needsMigration) {
      console.log('\n✅ No migration needed. All data is already compatible.');
      await client.end();
      return;
    }

    console.log('\n⚠️  Migration needed. Starting migration...');

    // Migration 1: Convert NULL metadata to empty strings
    if (nulls.null_slug > 0 || nulls.null_description > 0 || nulls.null_website > 0 || nulls.null_image > 0) {
      console.log('\n🔄 Migrating NULL metadata fields to empty strings...');
      await client.query(`
        UPDATE builders_project 
        SET 
          slug = COALESCE(slug, ''),
          description = COALESCE(description, ''),
          website = COALESCE(website, ''),
          image = COALESCE(image, '')
        WHERE slug IS NULL OR description IS NULL OR website IS NULL OR image IS NULL
      `);
      console.log('✅ Metadata fields migrated');
    }

    // Migration 2: Convert total_users to bigint if needed
    if (needsBigIntMigration) {
      console.log('\n🔄 Migrating total_users from integer to bigint...');
      await client.query(`
        ALTER TABLE builders_project 
        ALTER COLUMN total_users TYPE BIGINT USING total_users::BIGINT
      `);
      console.log('✅ total_users type migrated to bigint');
    }

    // Migration 3: Add claim_admin column if it doesn't exist
    const claimAdminCol = columnInfo.rows.find(col => col.column_name === 'claim_admin');
    if (!claimAdminCol) {
      console.log('\n🔄 Adding claim_admin column...');
      await client.query(`
        ALTER TABLE builders_project 
        ADD COLUMN claim_admin BYTEA
      `);
      console.log('✅ claim_admin column added');
      console.log('⚠️  Note: You will need to backfill claim_admin values from the contract');
    }

    // Migration 4: Set NOT NULL constraints if column exists but allows NULL
    if (claimAdminCol && claimAdminCol.is_nullable === 'YES' && nulls.null_claim_admin === 0) {
      console.log('\n🔄 Setting claim_admin to NOT NULL...');
      await client.query(`
        ALTER TABLE builders_project 
        ALTER COLUMN claim_admin SET NOT NULL
      `);
      console.log('✅ claim_admin set to NOT NULL');
    }

    // Migration 5: Set NOT NULL constraints on metadata fields if they allow NULL
    const metadataFields = ['slug', 'description', 'website', 'image'];
    for (const field of metadataFields) {
      const col = columnInfo.rows.find(c => c.column_name === field);
      if (col && col.is_nullable === 'YES') {
        console.log(`\n🔄 Setting ${field} to NOT NULL...`);
        await client.query(`
          ALTER TABLE builders_project 
          ALTER COLUMN ${field} SET NOT NULL
        `);
        console.log(`✅ ${field} set to NOT NULL`);
      }
    }

    console.log('\n✅ Migration completed successfully!');
    
    // Verify migration
    const verifyResult = await client.query(`
      SELECT 
        COUNT(*) FILTER (WHERE slug IS NULL) as null_slug,
        COUNT(*) FILTER (WHERE description IS NULL) as null_description,
        COUNT(*) FILTER (WHERE website IS NULL) as null_website,
        COUNT(*) FILTER (WHERE image IS NULL) as null_image,
        COUNT(*) FILTER (WHERE claim_admin IS NULL) as null_claim_admin
      FROM builders_project
    `);
    
    const verifyNulls = verifyResult.rows[0];
    console.log('\n📊 Post-migration NULL value counts:');
    console.log(`  - slug: ${verifyNulls.null_slug}`);
    console.log(`  - description: ${verifyNulls.null_description}`);
    console.log(`  - website: ${verifyNulls.null_website}`);
    console.log(`  - image: ${verifyNulls.null_image}`);
    console.log(`  - claim_admin: ${verifyNulls.null_claim_admin}`);

    await client.end();
  } catch (error) {
    console.error('❌ Error:', error.message);
    await client.end();
    process.exit(1);
  }
}

checkAndMigrate();
