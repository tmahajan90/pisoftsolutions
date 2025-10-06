-- Database initialization script
-- This script runs when the PostgreSQL container starts for the first time

-- Create the database if it doesn't exist (PostgreSQL creates it automatically via environment variables)
-- But we can add any additional setup here

-- Grant additional privileges if needed
GRANT ALL PRIVILEGES ON DATABASE pisoftsolutions_production TO pisoftsolutions_user;

-- Create extensions if needed
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Log the initialization
DO $$
BEGIN
    RAISE NOTICE 'Database initialization completed successfully';
END $$;
