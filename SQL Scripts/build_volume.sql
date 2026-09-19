CREATE EXTENSION IF NOT EXISTS timescaledb;

DROP TABLE IF EXISTS volume;
CREATE TABLE IF NOT EXISTS volume (
    id                  INTEGER     NOT NULL,
    avg_high_price      INTEGER     NULL,
    high_price_volume   BIGINT      NULL,
    avg_low_price       INTEGER     NULL,
    low_price_volume    BIGINT      NULL,
    snapshot_time       TIMESTAMP   NOT NULL,
    ingested_at         TIMESTAMP   NOT NULL,
    PRIMARY KEY (id, ingested_at)
);

-- Partition volume into a hypertable, chunked by ingestion time
SELECT create_hypertable('volume', by_range('ingested_at'), if_not_exists => TRUE);

CREATE INDEX IF NOT EXISTS idx_volume_id_time ON volume (id, ingested_at DESC);

-- Compress chunks older than 7 days to keep the table size in check
ALTER TABLE volume SET (
    timescaledb.compress,
    timescaledb.compress_segmentby = 'id'
);
SELECT add_compression_policy('volume', INTERVAL '7 days');
