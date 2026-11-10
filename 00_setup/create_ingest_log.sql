CREATE TABLE IF NOT EXISTS raw.ingest_log (
    log_id          SERIAL PRIMARY KEY,
    batch_id        UUID NOT NULL,
    source_name     TEXT NOT NULL,
    source_file     TEXT,
    source_platform TEXT,
    rows_loaded     INTEGER,
    status          TEXT NOT NULL,
    duration_sec    NUMERIC(10, 2),
    error_message   TEXT,
    logged_at       TIMESTAMP DEFAULT NOW()
);
