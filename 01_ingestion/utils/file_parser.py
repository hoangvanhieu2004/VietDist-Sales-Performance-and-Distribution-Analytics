import io

import pandas as pd


def read_csv_file(raw_bytes):
    """Đọc CSV, thử lần lượt từng bảng mã."""
    for encoding in ["utf-8-sig", "cp1258"]:
        try:
            df = pd.read_csv(
                io.BytesIO(raw_bytes),
                encoding=encoding,
                dtype=str,
                keep_default_na=False,
            )
            print(f"Đọc CSV bằng bảng mã: {encoding}")
            return df
        except UnicodeDecodeError:
            print(f"Không đọc được bằng bảng mã: {encoding}")

    raise ValueError("Không đọc được file CSV bằng các bảng mã đã thử")


def read_excel_file(raw_bytes, engine, sheet_name=0):
    """Đọc một sheet của file Excel, mặc định là sheet đầu tiên."""
    df = pd.read_excel(
        io.BytesIO(raw_bytes),
        sheet_name=sheet_name,
        engine=engine,
        dtype=str,
        keep_default_na=False,
    )
    return df


def parse_file(raw_bytes, file_name, sheet_name=0):
    """Chọn cách đọc phù hợp theo đuôi file."""
    name = file_name.lower()

    if name.endswith(".csv"):
        return read_csv_file(raw_bytes)
    if name.endswith(".xlsx") or name.endswith(".xlsm"):
        return read_excel_file(raw_bytes, "openpyxl", sheet_name)
    if name.endswith(".xlsb"):
        return read_excel_file(raw_bytes, "pyxlsb", sheet_name)

    raise ValueError(f"Chưa hỗ trợ định dạng file: {file_name}")
