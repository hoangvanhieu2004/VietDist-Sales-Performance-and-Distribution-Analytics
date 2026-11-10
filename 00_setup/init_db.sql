-- Chay bang psql (lenh \connect khong chay duoc trong pgAdmin):
--   psql -U postgres -f 00_setup\init_db.sql
CREATE DATABASE vietdist_dw1;
\connect vietdist_dw1
CREATE SCHEMA IF NOT EXISTS raw;      -- Bronze layer
CREATE SCHEMA IF NOT EXISTS staging;  -- Silver layer
CREATE SCHEMA IF NOT EXISTS dwh;      -- Gold layer

-- Kiem tra: ket qua mong doi la 3 dong
SELECT schema_name FROM information_schema.schemata
WHERE schema_name IN ('raw', 'staging', 'dwh');
