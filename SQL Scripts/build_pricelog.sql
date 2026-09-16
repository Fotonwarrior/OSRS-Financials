-- Active: 1784840732944@@192.168.178.156@5432@osrs_financials
CREATE EXTENSION IF NOT EXISTS timescaledb;

DROP TABLE IF EXISTS pricelog;
CREATE TABLE IF NOT EXISTS pricelog (
    id           INTEGER     NOT NULL,
    high         INTEGER     NULL,
    hightime     TIMESTAMP   NULL,
    low          INTEGER     NULL,
    lowtime      TIMESTAMP   NULL,
    ingested_at  TIMESTAMP   NOT NULL,
    PRIMARY KEY (id, ingested_at)
);

-- Partition pricelog into a hypertable, chunked by ingestion time
SELECT create_hypertable('pricelog', by_range('ingested_at'), if_not_exists => TRUE);

CREATE INDEX IF NOT EXISTS idx_pricelog_id_time ON pricelog (id, ingested_at DESC);

-- Compress chunks older than 7 days to keep the table size in check
ALTER TABLE pricelog SET (
    timescaledb.compress,
    timescaledb.compress_segmentby = 'id'
);
SELECT add_compression_policy('pricelog', INTERVAL '7 days');
