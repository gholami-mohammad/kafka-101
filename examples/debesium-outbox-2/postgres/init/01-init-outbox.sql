-- =============================================
-- 1. Create the orderdb database
-- =============================================
CREATE DATABASE orderdb;

-- =============================================
-- 2. Create tibobit user as owner of orderdb
-- =============================================
CREATE USER tibobit WITH PASSWORD 'tibobit';

-- Make tibobit the owner of the database
ALTER DATABASE orderdb OWNER TO tibobit;


-- Connect to the specific database for further grants
\c orderdb

-- Create schema if needed
CREATE SCHEMA IF NOT EXISTS outbox_schema;

-- Create outbox table (adjust columns as per your needs)
CREATE TABLE IF NOT EXISTS outbox_schema.outbox (
    id              SERIAL PRIMARY KEY,
    aggregatetype   VARCHAR(255) NOT NULL,
    aggregateid     VARCHAR(255) NOT NULL,
    type            VARCHAR(255) NOT NULL,
    payload         JSONB NOT NULL,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    processed       BOOLEAN DEFAULT FALSE
);

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_outbox_unprocessed 
    ON outbox_schema.outbox (processed, created_at);

ALTER TABLE outbox_schema.outbox REPLICA IDENTITY FULL;

-- Create publication for the outbox table so Debezium does not need superuser
-- rights to create a FOR ALL TABLES publication.
CREATE PUBLICATION outbox_publication FOR TABLE outbox_schema.outbox;

-- =============================================
-- 3. Create Debezium user with proper permissions
-- =============================================
-- Create Debezium role with explicit encrypted password and login
CREATE ROLE debezium WITH REPLICATION LOGIN ENCRYPTED PASSWORD 'debezium';

-- Basic database access
GRANT CONNECT ON DATABASE orderdb TO debezium;

-- Grant access only to the outbox schema and table
GRANT USAGE ON SCHEMA outbox_schema TO debezium;
GRANT SELECT ON TABLE outbox_schema.outbox TO debezium;

-- For future tables created in this schema (good if you add more later)
ALTER DEFAULT PRIVILEGES IN SCHEMA outbox_schema
    GRANT SELECT ON TABLES TO debezium;

-- Allow Debezium to create the publication (recommended with pgoutput)
GRANT CREATE ON DATABASE orderdb TO debezium;

-- Optional but useful: let it manage its own publication
ALTER ROLE debezium CREATEDB;   -- gives flexibility for publication creation