CREATE TABLE IF NOT EXISTS raw.sales_target_files (
    file_id       SERIAL PRIMARY KEY,
    batch_id      UUID NOT NULL,
    source_file   TEXT NOT NULL,
    sheet_name    TEXT NOT NULL,
    version_label TEXT NOT NULL,
    rows_loaded   INTEGER,
    loaded_at     TIMESTAMP DEFAULT NOW()
);
