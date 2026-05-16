from fastapi import APIRouter, Depends, UploadFile, File, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.user import User
from app.repositories.scan_repository import ScanRepository
from app.services.ai_service import ai_service
from app.services.storage_service import validate_and_read_image, save_image
from app.schemas.scan import ScanResultResponse

router = APIRouter(prefix="/scan", tags=["scan"])


@router.post("/upload", response_model=ScanResultResponse, status_code=status.HTTP_201_CREATED)
async def upload_and_scan(
    file: UploadFile = File(..., description="Ảnh JPEG hoặc PNG, tối đa 10MB"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    # 1. Validate + đọc bytes
    img_bytes = await validate_and_read_image(file)

    # 2. Chạy AI
    if not ai_service.is_ready:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="AI model chưa sẵn sàng. Thử lại sau.",
        )
    try:
        ai_result = ai_service.predict(img_bytes)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Lỗi inference: {e}")

    # 3. Lưu file ảnh
    image_path, image_filename = save_image(
        img_bytes=img_bytes,
        user_id=current_user.id,
        original_filename=file.filename or "image.jpg",
    )

    # 4. Lưu DB
    repo = ScanRepository(db)
    scan = repo.create(
        user_id=current_user.id,
        ai_result=ai_result,
        image_path=image_path,
        image_filename=image_filename,
    )

    return scan
