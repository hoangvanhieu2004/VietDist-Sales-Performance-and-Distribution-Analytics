import sys; sys.path.append('..')
from sqlalchemy import text
from load_base import run_loader
from utils.db_utils import get_engine

FILE_NAME = 'SRC02_sales_target_plan.xlsx'
TABLE_NAME = 'sales_targets_raw'

# Mỗi phiên bản nằm ở một sheet riêng
VERSIONS = [
    ('v1', 'Plan_v1_Original'),
    ('v2', 'Plan_v2_Adjustment_H2'),
]


def record_sheet(batch_id, sheet_name, version_label, rows):
    """Ghi một dòng vào sổ theo dõi raw.sales_target_files."""
    with get_engine().begin() as conn:
        conn.execute(text(
            'INSERT INTO raw.sales_target_files'
            ' (batch_id, source_file, sheet_name, version_label, rows_loaded)'
            ' VALUES (:bid, :sf, :sn, :vl, :rl)'
        ), dict(bid=batch_id, sf=FILE_NAME, sn=sheet_name,
                vl=version_label, rl=rows))


if __name__ == '__main__':
    for version_label, sheet_name in VERSIONS:
        batch_id, rows = run_loader(FILE_NAME, TABLE_NAME, sheet_name=sheet_name)
        # Chỉ ghi sổ khi sheet được nạp thành công
        if rows > 0:
            record_sheet(batch_id, sheet_name, version_label, rows)
