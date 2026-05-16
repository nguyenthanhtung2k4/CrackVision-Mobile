import time
import logging
from io import BytesIO
from typing import Optional
from pathlib import Path

from PIL import Image
import numpy as np

from app.core.config import settings

logger = logging.getLogger(__name__)

# Kích thước input model MobileNetV2
IMG_SIZE = (224, 224)
ALLOWED_FORMATS = {"JPEG", "PNG", "JPG"}


class AIService:
    """Singleton — load model một lần khi khởi động server."""

    _instance: Optional["AIService"] = None
    _model = None

    def __new__(cls) -> "AIService":
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance

    def load_model(self) -> None:
        if self._model is not None:
            return
        model_path = Path(settings.model_path)
        if not model_path.exists():
            logger.warning(f"Model không tồn tại: {model_path} — AI service chạy ở mock mode")
            return
        try:
            import keras
            logger.info(f"Loading model: {model_path}")
            self._model = keras.models.load_model(str(model_path))
            logger.info("Model loaded OK")
        except Exception as e:
            logger.error(f"Load model thất bại: {e}")
            self._model = None

    @property
    def is_ready(self) -> bool:
        return self._model is not None

    def _preprocess(self, img_bytes: bytes) -> np.ndarray:
        """Load ảnh từ bytes → numpy array (1, 224, 224, 3) float32 normalized."""
        img = Image.open(BytesIO(img_bytes))

        if img.format not in ALLOWED_FORMATS and img.format is not None:
            raise ValueError(f"Định dạng ảnh không hợp lệ: {img.format}. Chỉ chấp nhận JPEG, PNG.")

        # Chuyển sang RGB (bỏ alpha channel nếu có)
        if img.mode != "RGB":
            img = img.convert("RGB")

        img = img.resize(IMG_SIZE, Image.LANCZOS)
        arr = np.array(img, dtype=np.float32) / 255.0   # normalize [0,1]
        return np.expand_dims(arr, axis=0)               # (1, 224, 224, 3)

    def predict(self, img_bytes: bytes) -> dict:
        """
        Trả về dict:
          pred_label        : "Positive" | "Negative"
          meaning           : "Có vết nứt" | "Không có vết nứt"
          prob_positive     : float 0.0–1.0
          confidence        : float 0.0–1.0
          threshold         : float
          inference_time_s  : float (giây)
          source            : "server"
        """
        if not self.is_ready:
            raise RuntimeError("AI model chưa được load. Kiểm tra MODEL_PATH trong .env.")

        x = self._preprocess(img_bytes)

        t0 = time.perf_counter()
        prob_positive = float(self._model.predict(x, verbose=0)[0][0])
        inference_time = round(time.perf_counter() - t0, 4)

        threshold = float(settings.model_threshold)
        is_positive = prob_positive >= threshold
        confidence = prob_positive if is_positive else (1.0 - prob_positive)

        return {
            "pred_label": "Positive" if is_positive else "Negative",
            "meaning": "Có vết nứt" if is_positive else "Không có vết nứt",
            "prob_positive": round(prob_positive, 4),
            "confidence": round(confidence, 4),
            "threshold": threshold,
            "inference_time_s": inference_time,
            "source": "server",
        }


# Singleton instance dùng chung toàn app
ai_service = AIService()
