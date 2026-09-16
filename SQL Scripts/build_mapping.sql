CREATE TABLE IF NOT EXISTS mapping (
    id           INTEGER         NOT NULL,
    name         VARCHAR(255)    NOT NULL,
    examine      VARCHAR(255)    NULL,
    members      BOOLEAN         NOT NULL,
    "limit"      INTEGER         NULL,
    value        INTEGER         NULL,
    lowalch      INTEGER         NULL,
    highalch     INTEGER         NULL,
    icon         VARCHAR(255)    NULL,
    ingested_at  TIMESTAMP       NOT NULL,
    PRIMARY KEY (id)
);
