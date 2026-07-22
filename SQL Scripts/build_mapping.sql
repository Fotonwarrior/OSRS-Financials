CREATE TABLE IF NOT EXISTS mapping (
    id           INT UNSIGNED    NOT NULL,
    name         VARCHAR(255)    NOT NULL,
    examine      VARCHAR(255)    NULL,
    members      BOOLEAN         NOT NULL,
    `limit`      INT UNSIGNED    NULL,
    value        INT UNSIGNED    NULL,
    lowalch      INT UNSIGNED    NULL,
    highalch     INT UNSIGNED    NULL,
    icon         VARCHAR(255)    NULL,
    ingested_at  DATETIME        NOT NULL,
    PRIMARY KEY (id)
) ENGINE=InnoDB;