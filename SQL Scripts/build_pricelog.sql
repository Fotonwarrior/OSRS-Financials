DROP TABLE IF EXISTS pricelog;
CREATE TABLE IF NOT EXISTS pricelog (
    id INT UNSIGNED NOT NULL,
    high  INT  NULL,
    hightime  DATETIME  NULL,
    low INT  NULL,
    lowtime DATETIME  NULL,
    ingested_at DATETIME NOT NULL,
    PRIMARY KEY (id, ingested_at)
) ENGINE=InnoDB;