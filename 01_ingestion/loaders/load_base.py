import uuid, time
from connectors.gdrive_connector import list_files_in_folder, download_file_as_bytes
from utils.file_parser import parse_file
from utils.db_utils import add_metadata, load_to_bronze, get_engine
from sqlalchemy import text

FOLDER_ID = '1DxPEHsw8n8_jv6KKSgEdAoEpbkqSWGaa'

def run_loader(file_name, table_name, sheet_name=0):
    batch_id = str(uuid.uuid4())
    start    = time.time()
    engine   = get_engine()
    files = list_files_in_folder(FOLDER_ID)
    print(f'Tìm thấy {len(files)} file(s) trong folder')
    total_loaded = 0
    for f in files:
        if f['name'] != file_name:
            continue
        try:
            raw_bytes = download_file_as_bytes(f['id'])
            df = parse_file(raw_bytes, f['name'], sheet_name)
            df = add_metadata(df, f['name'], 'google_drive', batch_id)
            rows = load_to_bronze(df, table_name, if_exists='append')
            total_loaded += rows
            print(f'  OK: {f["name"]} — {rows} dòng')
            # Ghi log thành công
            with engine.begin() as conn:
                conn.execute(text(
                    'INSERT INTO raw.ingest_log (batch_id, source_name, source_file,'
                    ' source_platform, rows_loaded, status, duration_sec)'
                    ' VALUES (:bid, :sn, :sf, :sp, :rl, :st, :dur)'
                ), dict(bid=batch_id, sn=table_name, sf=f['name'],
                        sp='google_drive', rl=rows, st='SUCCESS',
                        dur=round(time.time()-start,2)))
        except Exception as e:
            print(f'  LỖI: {f["name"]} — {e}')
            # Ghi log lỗi
            with engine.begin() as conn:
                conn.execute(text(
                    'INSERT INTO raw.ingest_log (batch_id, source_name, source_file,'
                    ' source_platform, rows_loaded, status, duration_sec, error_message)'
                    ' VALUES (:bid, :sn, :sf, :sp, :rl, :st, :dur, :err)'
                ), dict(bid=batch_id, sn=table_name, sf=f['name'],
                        sp='google_drive', rl=0, st='FAILED',
                        dur=round(time.time()-start,2), err=str(e)))
    print(f'Tổng cộng: {total_loaded} dòng đã load')
    return batch_id, total_loaded
