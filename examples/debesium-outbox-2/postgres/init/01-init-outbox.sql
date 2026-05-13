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

-- Grant permissions to Debezium user (recommended)
-- CREATE USER debezium WITH PASSWORD 'debezium';
-- GRANT USAGE ON SCHEMA outbox_schema TO debezium;
-- GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA outbox_schema TO debezium;
-- GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA outbox_schema TO debezium;