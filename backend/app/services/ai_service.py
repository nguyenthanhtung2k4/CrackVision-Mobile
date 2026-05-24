import time
import logging
from io import BytesIO
from typing import Optional
from pathlib import Path

from PIL import Image, ImageFilter
import numpy as np

from app.core.config import settings

# Suppress TF startup noise on Windows CPU-only builds
import os
os.environ.setdefault("TF_CPP_MIN_LOG_LEVEL", "2")
os.environ.setdefault("TF_ENABLE_ONEDNN_OPTS", "0")

logger = logging.getLogger(__name__)

# Absolute path to repo root, regardless of CWD when uvicorn is launched.
# __file__ = backend/app/services/ai_service.py → .parent x3 = repo root
_REPO_ROOT = Path(__file__).resolve().parent.parent.parent

# Kích thước input model MobileNetV2
IMG_SIZE = (224, 224)
ALLOWED_FORMATS = {"JPEG", "PNG", "JPG"}
VISION_MAX_SIDE = 640
VISION_LINE_THRESHOLDS = (6, 8, 10, 12)

# Texture classifier — optional, loaded if file exists
# _REPO_ROOT is the CrackVision-Mobile repo root (parent of backend/)
_TEXTURE_MODEL_PATH = (_REPO_ROOT.parent / "AI_model" / "texture_classifier.keras").resolve()
# prob_non_concrete >= this → reject image as non-concrete before crack analysis
_TEXTURE_REJECT_THRESHOLD = 0.80


class AIService:
    """Singleton — load model một lần khi khởi động server."""

    _instance: Optional["AIService"] = None
    _model = None
    _texture_model = None   # optional pre-filter

    def __new__(cls) -> "AIService":
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance

    def load_model(self) -> None:
        if self._model is not None:
            return
        model_path = (_REPO_ROOT / settings.model_path).resolve()
        if not model_path.exists():
            logger.warning(f"Model không tồn tại: {model_path} — AI service chạy ở mock mode")
            return
        try:
            import keras
            from keras.applications.mobilenet_v2 import preprocess_input
            logger.info(f"Loading crack model: {model_path}")
            self._model = keras.models.load_model(
                str(model_path),
                custom_objects={"preprocess_input": preprocess_input},
            )
            # Warmup: compile computation graph so first real request is fast
            _dummy = np.zeros((1, 224, 224, 3), dtype=np.float32)
            self._model(_dummy, training=False)
            logger.info("Crack model loaded OK (warmup done)")
        except Exception as e:
            logger.error(f"Load crack model thất bại: {e}")
            self._model = None

        # Load texture classifier if available
        if _TEXTURE_MODEL_PATH.exists():
            try:
                import keras
                logger.info(f"Loading texture classifier: {_TEXTURE_MODEL_PATH}")
                self._texture_model = keras.models.load_model(str(_TEXTURE_MODEL_PATH))
                # Warmup texture model too
                _dummy = np.zeros((1, 224, 224, 3), dtype=np.float32)
                self._texture_model(_dummy, training=False)
                logger.info("Texture classifier loaded OK (warmup done)")
            except Exception as e:
                logger.warning(f"Load texture classifier thất bại (bỏ qua): {e}")
                self._texture_model = None
        else:
            logger.info("Texture classifier not found — running without pre-filter")

    @property
    def is_ready(self) -> bool:
        return self._model is not None

    @property
    def has_texture_filter(self) -> bool:
        return self._texture_model is not None

    def _preprocess(self, img_bytes: bytes) -> np.ndarray:
        """Load ảnh từ bytes → numpy array (1, 224, 224, 3) float32 raw pixels."""
        img = Image.open(BytesIO(img_bytes))

        if img.format not in ALLOWED_FORMATS and img.format is not None:
            raise ValueError(f"Định dạng ảnh không hợp lệ: {img.format}. Chỉ chấp nhận JPEG, PNG.")

        if img.mode != "RGB":
            img = img.convert("RGB")

        # Match keras.utils.load_img(target_size=...) in AI_model/inference.ipynb.
        img = img.resize(IMG_SIZE, Image.NEAREST)

        # The model already includes its own Rescaling layer. Keep raw 0..255
        # pixels here; normalizing again makes crack images look negative.
        arr = np.array(img, dtype=np.float32)
        return np.expand_dims(arr, axis=0)               # (1, 224, 224, 3)

    def _preprocess_texture(self, img_bytes: bytes) -> np.ndarray:
        """Preprocess for texture classifier — uses MobileNetV2 [-1, 1] range."""
        img = Image.open(BytesIO(img_bytes))
        if img.mode != "RGB":
            img = img.convert("RGB")
        img = img.resize(IMG_SIZE, Image.BILINEAR)
        arr = np.array(img, dtype=np.float32)
        # MobileNetV2 preprocess_input: scale to [-1, 1]
        arr = (arr / 127.5) - 1.0
        return np.expand_dims(arr, axis=0)               # (1, 224, 224, 3)

    def _is_concrete_surface(self, img_bytes: bytes) -> tuple[bool, float]:
        """
        Returns (is_concrete, prob_non_concrete).
        If texture classifier not loaded → always returns (True, 0.0).
        """
        if self._texture_model is None:
            return True, 0.0
        try:
            x = self._preprocess_texture(img_bytes)
            prob_non_concrete = float(self._texture_model(x, training=False)[0][0])
            is_concrete = prob_non_concrete < _TEXTURE_REJECT_THRESHOLD
            return is_concrete, prob_non_concrete
        except Exception as e:
            logger.warning(f"Texture check failed (skipping): {e}")
            return True, 0.0

    def _crack_line_score(self, img_bytes: bytes) -> float:
        """Detect long, thin dark crack lines that the classifier may miss."""
        img = Image.open(BytesIO(img_bytes)).convert("L")
        max_side = max(img.size)
        if max_side > VISION_MAX_SIDE:
            scale = VISION_MAX_SIDE / max_side
            img = img.resize(
                (max(1, round(img.width * scale)), max(1, round(img.height * scale))),
                Image.BILINEAR,
            )

        radius = max(3, round(min(img.size) * 0.02))
        bg = img.filter(ImageFilter.BoxBlur(radius))
        gray = np.asarray(img, dtype=np.int16)
        diff = np.asarray(bg, dtype=np.int16) - gray

        best = 0.0
        for threshold in VISION_LINE_THRESHOLDS:
            best = max(best, self._score_dark_line_mask(diff > threshold))
        return best

    def _score_dark_line_mask(self, mask: np.ndarray) -> float:
        h, w = mask.shape
        seen = np.zeros(mask.shape, dtype=bool)
        best = 0.0

        for y, x in np.argwhere(mask):
            if seen[y, x]:
                continue

            stack = [(int(y), int(x))]
            seen[y, x] = True
            count = 0
            min_y = max_y = int(y)
            min_x = max_x = int(x)

            while stack:
                cy, cx = stack.pop()
                count += 1
                min_y = min(min_y, cy)
                max_y = max(max_y, cy)
                min_x = min(min_x, cx)
                max_x = max(max_x, cx)

                for dy in (-1, 0, 1):
                    for dx in (-1, 0, 1):
                        if dx == 0 and dy == 0:
                            continue
                        ny, nx = cy + dy, cx + dx
                        if 0 <= ny < h and 0 <= nx < w and mask[ny, nx] and not seen[ny, nx]:
                            seen[ny, nx] = True
                            stack.append((ny, nx))

            comp_h = max_y - min_y + 1
            comp_w = max_x - min_x + 1
            slenderness = comp_h / max(comp_w, 1)

            is_crack_like = (
                comp_h >= min(h, w) * 0.22
                and comp_w <= max(14, w * 0.08)
                and slenderness >= 5.0
                and count >= 30
            )
            if not is_crack_like:
                continue

            length_score = min(1.0, comp_h / (h * 0.55))
            slender_score = min(1.0, max(0.0, (slenderness - 5.0) / 6.0))
            area_score = min(1.0, count / (h * w * 0.002))
            quality = length_score * slender_score * area_score
            best = max(best, 0.65 + 0.35 * quality)

        return best

    def predict(self, img_bytes: bytes) -> dict:
        """
        Returns dict:
          pred_label        : "CRACK" | "NO_CRACK"
          meaning           : "Có vết nứt" | "Không có vết nứt"
          prob_positive     : float 0.0–1.0
          confidence        : float 0.0–1.0
          threshold         : float
          inference_time_s  : float
          source            : "server" | "server+vision"
          texture_warning   : str | None  — set when image is not concrete surface
        """
        if not self.is_ready:
            raise RuntimeError("AI model chưa được load. Kiểm tra MODEL_PATH trong .env.")

        t0 = time.perf_counter()

        # ── Step 1: Texture pre-filter ────────────────────────────────
        is_concrete, prob_non_concrete = self._is_concrete_surface(img_bytes)
        texture_warning = None

        if not is_concrete:
            inference_time = round(time.perf_counter() - t0, 4)
            logger.info(
                f"Texture filter rejected image: prob_non_concrete={prob_non_concrete:.3f}"
            )
            return {
                "pred_label": "NO_CRACK",
                "meaning": "Không phải bề mặt bê tông",
                "prob_positive": 0.0,
                "confidence": round(prob_non_concrete, 4),
                "threshold": float(settings.model_threshold),
                "inference_time_s": inference_time,
                "source": "texture_filter",
                "texture_warning": (
                    f"Ảnh không được nhận dạng là bề mặt bê tông/tường "
                    f"(prob_non_concrete={prob_non_concrete:.0%}). "
                    "Vui lòng chụp trực tiếp bề mặt cần kiểm tra."
                ),
            }

        # ── Step 2: Crack detection ───────────────────────────────────
        x = self._preprocess(img_bytes)
        model_prob_positive = float(self._model(x, training=False)[0][0])
        vision_score = self._crack_line_score(img_bytes)
        inference_time = round(time.perf_counter() - t0, 4)

        threshold = float(settings.model_threshold)
        prob_positive = max(model_prob_positive, vision_score)
        is_positive = prob_positive >= threshold
        confidence = prob_positive if is_positive else (1.0 - prob_positive)
        source = "server+vision" if vision_score > model_prob_positive and is_positive else "server"

        # Mild texture warning (concrete but uncertain) when classifier loaded
        if self._texture_model is not None and prob_non_concrete > 0.40:
            texture_warning = (
                f"Ảnh có thể không phải bề mặt bê tông thuần túy "
                f"(prob_non_concrete={prob_non_concrete:.0%}). Kết quả có thể kém chính xác."
            )

        return {
            "pred_label": "CRACK" if is_positive else "NO_CRACK",
            "meaning": "Có vết nứt" if is_positive else "Không có vết nứt",
            "prob_positive": round(prob_positive, 4),
            "confidence": round(confidence, 4),
            "threshold": threshold,
            "inference_time_s": inference_time,
            "source": source,
            "texture_warning": texture_warning,
        }


# Singleton instance dùng chung toàn app
ai_service = AIService()
