from datetime import datetime
from typing import Optional
from pydantic import BaseModel


class ScanResultResponse(BaseModel):
    id: str
    pred_label: str
    meaning: str
    prob_positive: float
    confidence: float
    threshold: float
    inference_time_seconds: Optional[float]
    image_filename: Optional[str]
    source: str
    note: Optional[str]
    is_synced: bool
    created_at: datetime

    model_config = {"from_attributes": True}


class ScanHistoryResponse(BaseModel):
    items: list[ScanResultResponse]
    total: int
    page: int
    page_size: int
    total_pages: int


class NoteUpdateRequest(BaseModel):
    note: str
