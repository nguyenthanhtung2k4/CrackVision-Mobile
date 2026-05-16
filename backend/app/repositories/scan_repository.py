from typing import Optional
from sqlalchemy.orm import Session
from sqlalchemy import desc
from app.models.scan_result import ScanResult


class ScanRepository:
    def __init__(self, db: Session):
        self.db = db

    def create(self, user_id: str, ai_result: dict, image_path: str | None, image_filename: str | None) -> ScanResult:
        scan = ScanResult(
            user_id=user_id,
            pred_label=ai_result["pred_label"],
            meaning=ai_result["meaning"],
            prob_positive=ai_result["prob_positive"],
            confidence=ai_result["confidence"],
            threshold=ai_result["threshold"],
            inference_time_seconds=ai_result["inference_time_s"],
            image_path=image_path,
            image_filename=image_filename,
            source=ai_result["source"],
            is_synced=True,
        )
        self.db.add(scan)
        self.db.commit()
        self.db.refresh(scan)
        return scan

    def get_by_id(self, scan_id: str, user_id: str) -> Optional[ScanResult]:
        return (
            self.db.query(ScanResult)
            .filter(ScanResult.id == scan_id, ScanResult.user_id == user_id)
            .first()
        )

    def get_history(self, user_id: str, page: int, page_size: int) -> tuple[list[ScanResult], int]:
        query = (
            self.db.query(ScanResult)
            .filter(ScanResult.user_id == user_id)
            .order_by(desc(ScanResult.created_at))
        )
        total = query.count()
        items = query.offset((page - 1) * page_size).limit(page_size).all()
        return items, total

    def delete(self, scan: ScanResult) -> None:
        self.db.delete(scan)
        self.db.commit()

    def update_note(self, scan: ScanResult, note: str) -> ScanResult:
        scan.note = note
        self.db.commit()
        self.db.refresh(scan)
        return scan
