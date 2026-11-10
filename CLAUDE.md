# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project status

No code exists yet. The only source of truth is `02_VietDist_Project_Description_v2.0_Đề bài.docx` (in Vietnamese). Everything below describes the system that brief specifies, not something already built. The folder is a local git repository; the brief also expects one on GitHub, which does not exist yet. Replace this section as code lands.

Tool versions: the project accepts the latest versions rather than the exact ones in the brief. This machine has Python 3.13 and PostgreSQL 18.

Working agreement: work through the brief one step at a time, and get the user's approval for each step before doing it. For anything Claude does not have permission to do itself (entering passwords, Google credentials, GUI tools), give the user instructions so they can do it.

Teaching mode: the user is a beginner. Build in small pieces following the order of the brief, explain each piece, and test it before moving on. Do not finish a whole phase in one go. Write basic, easy-to-read code with Vietnamese comments, and avoid advanced constructs.

Secrets: never open, print, or search the contents of files in `credentials/`. Programs may load the service account file at runtime to authenticate, but must not print it.

Reading the brief: `pandoc` is not installed here, and the accented filename breaks when passed inline through the shell. Locate it with `glob` from Python and read `word/document.xml` out of the zip. Many subtasks are a heading only, so their design is left to the implementer.

## What is being built

VietDist Sales Performance & Distribution Analytics: a localhost pipeline from Excel/CSV files on Google Drive into PostgreSQL 18 (database `vietdist_dw1`), using Medallion layers, served to Power BI Desktop. The brief calls the database `vietdist_dw`; the user chose `vietdist_dw1`, so use that name.

| Layer | Schema | Content | Tool |
|---|---|---|---|
| Bronze | `raw` | Source files as-is, plus metadata | Python + SQLAlchemy |
| Silver | `staging` | Cleaned, typed, deduplicated, validated | Python / SQL |
| Gold | `dwh` | Star schema, marts, business metrics | SQL |
| Serving | views | Power BI reads from `dwh` | Power BI Desktop |

Planned layout: `00_setup/` (`requirements.txt`, `.env.example`, `init_db.sql`), `01_ingestion/{connectors,loaders,utils}/`, `02_sql_analytics/`, `03_power_bi/`, `docs/`. The brief's tree has no folder for Silver/Gold SQL, so one must be chosen when Phase 2 starts.

## Commands

Setup, per the brief (Python 3.11+):

```powershell
python -m venv venv
venv\Scripts\activate
pip install pandas openpyxl sqlalchemy psycopg2-binary pyxlsb
pip install gspread google-auth msal requests python-dotenv
psql -U postgres -c '\l'    # confirm vietdist_dw1 exists
```

`pyxlsb` is not in the brief's install line but its parser note requires it for `.xlsb` files.

Run a loader from its own directory. The brief's sample uses `sys.path.append('..')`, and the digit-prefixed folders cannot be imported as Python packages:

```powershell
cd 01_ingestion\loaders
python load_sales_transactions.py
```

There is no build, lint, or test framework defined. Data quality tests are SQL scripts (`not_null` + `unique` on each primary key), with a target of 0 failures.

`.env` holds `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`, and `GOOGLE_SERVICE_ACCOUNT_JSON` (default `./credentials/gdrive_service_account.json`). Both `.env` and `credentials/` must be in `.gitignore`.

## Data flow rules

**Bronze**
- All source columns are `TEXT`. No cleaning happens here.
- Each table gets `_source_file`, `_source_platform` (`google_drive` or `onedrive`), `_ingested_at`, `_batch_id` (UUID per pipeline run).
- Loads are append-only. Running a loader twice on the same file doubles the rows, and that is correct. Do not add dedup or upsert here; dedup belongs in Silver.
- Every file load writes a row to `raw.ingest_log` (`batch_id, source_name, source_file, source_platform, rows_loaded, status, duration_sec, error_message`), with status `SUCCESS` or `FAILED`. A failure on one file does not stop the others.
- There are 10 sources (SRC-01 to SRC-10), each ending in a `raw.*` table. `file_parser.py` must handle CSV, XLSX, XLSM, XLSB and Vietnamese encoding in CSVs.

**Sales target versioning (SRC-02), the hardest part**
- `sales_target_plan` has multiple versions per year (v1, v2, v3...), each either a separate file or a separate sheet.
- All versions must be kept. Never overwrite an earlier version.
- Bronze stores the data in long format with `month_col` holding `T1`..`T12`. The `TỔNG` total row and the total column are excluded.
- Silver (`stg_sales_targets_versioned`) adds version, effective date, and an `is_latest` flag. Effective version by month: T1–T6 use v1, T7–T12 use v2. v1 and v2 both carry targets for T7–T12.

**Silver**
- Profile first: record row counts, % null on key columns, and duplicates per table in `docs/data_issues.md`.
- One `stg_*` model per `raw.*` table: cast types, remove null/nan, dedup.

**Gold**
- Dimensions: `dim_date` (2022–2026), `dim_customers` and `dim_products` (SCD1), `dim_employees` and `dim_distributors` (SCD2).
- Facts: `fact_sales` (grain: one line item), `fact_targets` (employee/month/version), `fact_returns`.
- Marts: `mart_sales_vs_target` (monthly by employee, all versions), `mart_distributor_performance`.
- SCD2 joins must be temporal: `emp.employee_code = fact.employee_code AND fact.date BETWEEN emp.effective_from AND emp.effective_to`. A plain key join fans out rows. `is_current = TRUE` only on the latest record.
- The fiscal year is labeled by its starting calendar year and ends in August: both 2023-10-01 and 2024-01-01 are FY 2023.

Assumptions made during implementation go in `docs/assumptions_log.md`.

## Source files on Google Drive

All 10 sources sit in one Drive folder, named `SRC<nn>_<name>.<ext>`:

| Source | File | Sheets (Excel only) |
|---|---|---|
| SRC-01 | `sales_transactions.csv` | |
| SRC-02 | `sales_target_plan.xlsx` | `Plan_v1_Original`, `Plan_v2_Adjustment_H2`, `Summary` |
| SRC-03 | `customer_master.csv` | |
| SRC-04 | `product_master.xlsx` | `Products`, `Category_Summary` |
| SRC-05 | `distributor_orders.xlsx` | `Orders` |
| SRC-06 | `distributor_master.csv` | |
| SRC-07 | `employee_master.xlsx` | `Employee_v1_StartYear`, `Employee_v2_Adjustment`, `Change_Log` |
| SRC-08 | `territory_mapping.xlsx` | `Sheet1` |
| SRC-09 | `return_transactions.csv` | |
| SRC-10 | `promotion_program.xlsx` | `Sheet1` |

`parse_file` reads only the first sheet. The loaders for SRC-02 and SRC-07 must also read their other version sheets, since SCD2 history for employees depends on them. All four CSVs are UTF-8.

## Inconsistencies in the brief

Confirm these with the user rather than silently picking one:

- Metadata column is `e_source_file` in the table but `_source_file` in the checkpoint. `_source_file` looks correct.
- Subtask 1.4.1 names `raw.sales_target_versions`, while the checkpoint uses `raw.sales_target_files` and `raw.sales_targets_raw`.
- The folder tree lists 6 loaders, but there are 10 sources.
- The brief describes SRC-02 with `T1`..`T12` columns and a `TỔNG` row, but its first sheet is already long format with a `month` column. Check this before Task 1.4.
- The checkpoint expects `distributor_orders` as XLSB, but the real file is `.xlsx`, and the folder has no XLSB or XLSM files.
- The brief refers to `BRD_VietDist_Analytics_Project_v1_0.docx`, which is not in this folder.
- `onedrive` is a valid platform and `msal` is installed, but only a Google Drive connector is specified.
- The versioning table has a v3 (October) column, but SRC-02 currently contains only v1 and v2.
- Both `stg_sales_transactions` and `stg_sales_transaction` appear.
- The filename says v2.0, the cover says v1.0. Task numbering skips 1.2.
