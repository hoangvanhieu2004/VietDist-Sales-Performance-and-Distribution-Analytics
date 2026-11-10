import os
from pathlib import Path

from dotenv import load_dotenv
from google.oauth2 import service_account
from google.auth.transport.requests import AuthorizedSession

# Tìm thư mục gốc dự án: file này nằm sâu 2 cấp bên trong
PROJECT_ROOT = Path(__file__).resolve().parents[2]

# Nạp các biến trong file .env
load_dotenv(PROJECT_ROOT / ".env")

# Chỉ xin quyền ĐỌC Google Drive
SCOPES = ["https://www.googleapis.com/auth/drive.readonly"]


def get_session():
    """Tạo phiên làm việc đã đăng nhập vào Google Drive."""
    # Đường dẫn tới file JSON của service account
    key_file = PROJECT_ROOT / os.getenv("GOOGLE_SERVICE_ACCOUNT_JSON")

    # Dùng file JSON để tạo thông tin đăng nhập
    credentials = service_account.Credentials.from_service_account_file(
        key_file, scopes=SCOPES
    )

    # Tạo phiên làm việc dùng thông tin đăng nhập đó
    session = AuthorizedSession(credentials)
    return session


def list_files_in_folder(folder_id):
    """Trả về danh sách file nằm trong một thư mục Drive."""
    session = get_session()
    url = "https://www.googleapis.com/drive/v3/files"

    # Nội dung câu hỏi gửi lên Google Drive
    params = {
        "q": f"'{folder_id}' in parents and trashed = false",
        "fields": "nextPageToken, files(id, name, mimeType)",
        "pageSize": 1000,
        "supportsAllDrives": True,
        "includeItemsFromAllDrives": True,
    }

    all_files = []
    while True:
        response = session.get(url, params=params)
        response.raise_for_status()  # Dừng và báo lỗi nếu Google từ chối
        data = response.json()
        all_files.extend(data["files"])

        # Hết trang thì dừng, còn trang thì lấy trang tiếp theo
        if "nextPageToken" not in data:
            break
        params["pageToken"] = data["nextPageToken"]

    return all_files


def download_file_as_bytes(file_id):
    """Tải nội dung một file trên Drive về dạng bytes."""
    session = get_session()
    url = f"https://www.googleapis.com/drive/v3/files/{file_id}"

    # alt=media nghĩa là: lấy nội dung file, không phải thông tin về file
    params = {"alt": "media", "supportsAllDrives": True}

    response = session.get(url, params=params)
    response.raise_for_status()  # Dừng và báo lỗi nếu Google từ chối
    return response.content
