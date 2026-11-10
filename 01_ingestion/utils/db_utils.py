import os
from datetime import datetime
from pathlib import Path

from dotenv import load_dotenv
from sqlalchemy import URL, create_engine
from sqlalchemy.dialects.postgresql import UUID

# Tìm thư mục gốc dự án rồi nạp file .env
PROJECT_ROOT = Path(__file__).resolve().parents[2]
load_dotenv(PROJECT_ROOT / ".env")


def get_engine():
    """Tạo đầu mối kết nối tới PostgreSQL."""
    url = URL.create(
        "postgresql+psycopg2",
        username=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD"),
        host=os.getenv("DB_HOST"),
        port=int(os.getenv("DB_PORT")),
        database=os.getenv("DB_NAME"),
    )
    return create_engine(url)


def add_metadata(df, source_file, source_platform, batch_id):
    """Thêm 4 cột metadata vào bảng dữ liệu."""
    df = df.copy()  # Tạo bản sao để không làm thay đổi bảng gốc
    df["_source_file"] = source_file
    df["_source_platform"] = source_platform
    df["_ingested_at"] = datetime.now()
    df["_batch_id"] = batch_id
    return df


def load_to_bronze(df, table_name, if_exists="append"):
    """Ghi dữ liệu vào schema raw và trả về số dòng đã ghi."""
    engine = get_engine()
    df.to_sql(
        table_name,
        engine,
        schema="raw",
        if_exists=if_exists,
        index=False,
        chunksize=5000,
        dtype={"_batch_id": UUID(as_uuid=False)},
    )
    return len(df)
