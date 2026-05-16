import uuid
from datetime import datetime, timezone
from sqlalchemy import Boolean, DateTime, ForeignKey, Numeric, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.core.database import Base


class ScanResult(Base):
    __tablename__ = "scan_results"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)

    # AI result
    pred_label: Mapped[str] = mapped_column(String(20), nullable=False)
    meaning: Mapped[str] = mapped_column(String(50), nullable=False)
    prob_positive: Mapped[float] = mapped_column(Numeric(6, 4), nullable=False)
    confidence: Mapped[float] = mapped_column(Numeric(6, 4), nullable=False)
    threshold: Mapped[float] = mapped_column(Numeric(4, 2), default=0.50, nullable=False)
    inference_time_seconds: Mapped[float | None] = mapped_column(Numeric(8, 4), nullable=True)

    # Image
    image_path: Mapped[str | None] = mapped_column(String(500), nullable=True)
    image_filename: Mapped[str | None] = mapped_column(String(255), nullable=True)

    # Metadata
    source: Mapped[str] = mapped_column(String(20), default="server", nullable=False)
    note: Mapped[str | None] = mapped_column(Text, nullable=True)
    is_synced: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False, index=True
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    user: Mapped["User"] = relationship("User", back_populates="scan_results")  # noqa: F821
