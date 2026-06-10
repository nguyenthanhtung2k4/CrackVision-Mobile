from datetime import datetime, timezone
from uuid import uuid4

from fastapi import APIRouter, Depends, File, HTTPException, Query, UploadFile, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.user import User
from app.repositories.scan_repository import ScanRepository
from app.schemas.scan import ScanResultResponse
from app.services.ai_service import ai_service
from app.services.storage_service import save_image, validate_and_read_image

router = APIRouter(prefix="/scan", tags=["scan"])


@router.post(
    "/upload",
    response_model=ScanResultResponse,
    status_code=status.HTTP_201_CREATED,
)
async def upload_and_scan(
    file: UploadFile = File(..., description="Anh JPEG hoac PNG, toi da 10MB"),
    save: bool = Query(default=True, description="Luu ket qua vao lich su"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    img_bytes = await validate_and_read_image(file)

    if not ai_service.is_ready:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="AI model chua san sang. Thu lai sau.",
        )
    try:
        ai_result = ai_service.predict(img_bytes)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Loi inference: {e}",
        )

    if not save:
        return ScanResultResponse(
            id=f"preview_{uuid4()}",
            pred_label=ai_result["pred_label"],
            meaning=ai_result["meaning"],
            prob_positive=ai_result["prob_positive"],
            confidence=ai_result["confidence"],
            threshold=ai_result["threshold"],
            inference_time_seconds=ai_result.get("inference_time_s"),
            image_filename=file.filename,
            image_path=None,
            source=ai_result["source"],
            note=None,
            is_synced=False,
            created_at=datetime.now(timezone.utc),
            texture_warning=ai_result.get("texture_warning"),
        )

    image_path, image_filename = save_image(
        img_bytes=img_bytes,
        user_id=current_user.id,
        original_filename=file.filename or "image.jpg",
    )

    repo = ScanRepository(db)
    scan = repo.create(
        user_id=current_user.id,
        ai_result=ai_result,
        image_path=image_path,
        image_filename=image_filename,
    )

    response = ScanResultResponse.model_validate(scan)
    response.texture_warning = ai_result.get("texture_warning")
    return response
