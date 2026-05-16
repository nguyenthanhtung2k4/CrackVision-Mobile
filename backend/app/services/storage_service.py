import uuid
from pathlib import Path
from fastapi import UploadFile, HTTPException, status
from app.core.config import settings

ALLOWED_CONTENT_TYPES = {"image/jpeg", "image/png", "image/jpg"}
MAX_BYTES = settings.max_upload_size_mb * 1024 * 1024


async def validate_and_read_image(file: UploadFile) -> bytes:
    """Validate content-type + size, trả về raw bytes."""
    if file.content_type not in ALLOWED_CONTENT_TYPES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Chỉ chấp nhận ảnh JPEG hoặc PNG. Nhận được: {file.content_type}",
        )
    img_bytes = await file.read()
    if len(img_bytes) > MAX_BYTES:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail=f"Ảnh quá lớn. Tối đa {settings.max_upload_size_mb}MB.",
        )
    return img_bytes


def save_image(img_bytes: bytes, user_id: str, original_filename: str) -> tuple[str, str]:
    """
    Lưu ảnh vào uploads/{user_id}/{uuid}.jpg
    Trả về (image_path, image_filename)
    """
    ext = Path(original_filename).suffix.lower() or ".jpg"
    filename = f"{uuid.uuid4()}{ext}"
    user_dir = Path(settings.upload_dir) / user_id
    user_dir.mkdir(parents=True, exist_ok=True)
    file_path = user_dir / filename
    file_path.write_bytes(img_bytes)
    # Path tương đối để lưu DB và build URL
    relative_path = f"{settings.upload_dir}/{user_id}/{filename}"
    return relative_path, original_filename


def delete_image(image_path: str) -> None:
    """Xóa file ảnh nếu tồn tại."""
    path = Path(image_path)
    if path.exists():
        path.unlink()
