-- One-off migration: widen price columns from INTEGER to BIGINT without losing data.
-- Some items trade above the INTEGER max (2,147,483,647), which made inserts fail.
--
-- TimescaleDB refuses to change column types while compression is enabled, and Postgres
-- refuses to change columns a view reads. So this script decompresses existing chunks,
-- drops potionflips, changes the types, then recreates the view and re-enables compression.
-- Everything runs in one transaction: if any step fails, nothing changes.

BEGIN;

-- potionflips reads pricelog.high/low; drop it now, recreated at the end
DROP VIEW IF EXISTS potionflips;

-- pricelog
SELECT remove_compression_policy('pricelog', if_exists => TRUE);
SELECT decompress_chunk(c, if_compressed => TRUE) FROM show_chunks('pricelog') c;
ALTER TABLE pricelog SET (timescaledb.compress = false);
ALTER TABLE pricelog
    ALTER COLUMN high TYPE BIGINT,
    ALTER COLUMN low  TYPE BIGINT;
ALTER TABLE pricelog SET (
    timescaledb.compress,
    timescaledb.compress_segmentby = 'id'
);
SELECT add_compression_policy('pricelog', INTERVAL '7 days');

-- volume
SELECT remove_compression_policy('volume', if_exists => TRUE);
SELECT decompress_chunk(c, if_compressed => TRUE) FROM show_chunks('volume') c;
ALTER TABLE volume SET (timescaledb.compress = false);
ALTER TABLE volume
    ALTER COLUMN avg_high_price TYPE BIGINT,
    ALTER COLUMN avg_low_price  TYPE BIGINT;
ALTER TABLE volume SET (
    timescaledb.compress,
    timescaledb.compress_segmentby = 'id'
);
SELECT add_compression_policy('volume', INTERVAL '7 days');

-- recreate potionflips (definition copied from the live database)
CREATE VIEW potionflips AS
WITH potions AS (
    SELECT mapping.id,
        mapping.name,
        TRIM(BOTH FROM split_part(mapping.name, '(', 1)) AS name_base,
        substring(mapping.name, '\((\d+)\)')::integer AS dose,
        pricelog.high,
        pricelog.low,
        pricelog.ingested_at
    FROM pricelog
        JOIN mapping ON pricelog.id = mapping.id
    WHERE pricelog.ingested_at = (SELECT max(pricelog_1.ingested_at) FROM pricelog pricelog_1)
        AND mapping.name LIKE '%potion%'
        AND mapping.name ~ '\(\d+\)'
), target_highs AS (
    SELECT potions.name_base,
        max(potions.high) FILTER (WHERE potions.dose = 1) AS high_1,
        max(potions.high) FILTER (WHERE potions.dose = 2) AS high_2,
        max(potions.high) FILTER (WHERE potions.dose = 3) AS high_3,
        max(potions.high) FILTER (WHERE potions.dose = 4) AS high_4
    FROM potions
    GROUP BY potions.name_base
), spreads AS (
    SELECT p.id,
        p.name,
        p.name_base,
        p.dose,
        p.low,
        p.high,
        CASE WHEN p.dose <> 1 THEN round((t.high_1 * p.dose)::numeric / 1.0 - p.low::numeric) END AS profit_to_1,
        CASE WHEN p.dose <> 2 THEN round((t.high_2 * p.dose)::numeric / 2.0 - p.low::numeric) END AS profit_to_2,
        CASE WHEN p.dose <> 3 THEN round((t.high_3 * p.dose)::numeric / 3.0 - p.low::numeric) END AS profit_to_3,
        CASE WHEN p.dose <> 4 THEN round((t.high_4 * p.dose)::numeric / 4.0 - p.low::numeric) END AS profit_to_4,
        p.ingested_at
    FROM potions p
        JOIN target_highs t ON p.name_base = t.name_base
)
SELECT id,
    name,
    name_base,
    dose,
    low,
    high,
    profit_to_1,
    profit_to_2,
    profit_to_3,
    profit_to_4,
    ingested_at,
    GREATEST(profit_to_1, profit_to_2, profit_to_3, profit_to_4) AS max_profit
FROM spreads
ORDER BY GREATEST(profit_to_1, profit_to_2, profit_to_3, profit_to_4) DESC NULLS LAST;

COMMIT;
