import math
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.user import User
from app.repositories.scan_repository import ScanRepository
from app.services.storage_service import delete_image
from app.schemas.scan import ScanResultResponse, ScanHistoryResponse, NoteUpdateRequest

router = APIRouter(prefix="/history", tags=["history"])


@router.get("", response_model=ScanHistoryResponse)
def get_history(
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=10, ge=1, le=50),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    repo = ScanRepository(db)
    items, total = repo.get_history(current_user.id, page, page_size)
    total_pages = math.ceil(total / page_size) if total > 0 else 1
    return ScanHistoryResponse(
        items=items,
        total=total,
        page=page,
        page_size=page_size,
        total_pages=total_pages,
    )


@router.get("/{scan_id}", response_model=ScanResultResponse)
def get_scan_detail(
    scan_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    repo = ScanRepository(db)
    scan = repo.get_by_id(scan_id, current_user.id)
    if not scan:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Không tìm thấy kết quả scan."
        )
    return scan


@router.patch("/{scan_id}/note", response_model=ScanResultResponse)
def update_note(
    scan_id: str,
    body: NoteUpdateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    repo = ScanRepository(db)
    scan = repo.get_by_id(scan_id, current_user.id)
    if not scan:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Không tìm thấy kết quả scan."
        )
    return repo.update_note(scan, body.note)


@router.delete("", status_code=status.HTTP_204_NO_CONTENT)
def clear_history(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    repo = ScanRepository(db)
    scans = repo.get_all_history(current_user.id)
    for scan in scans:
        if scan.image_path:
            delete_image(scan.image_path)
    repo.delete_many(scans)


@router.delete("/{scan_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_scan(
    scan_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    repo = ScanRepository(db)
    scan = repo.get_by_id(scan_id, current_user.id)
    if not scan:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Không tìm thấy kết quả scan."
        )
    if scan.image_path:
        delete_image(scan.image_path)
    repo.delete(scan)
