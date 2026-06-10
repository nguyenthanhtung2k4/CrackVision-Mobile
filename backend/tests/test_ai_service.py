"""
Unit tests cho AIService — chạy hoàn toàn offline, không cần model thật.
Mock model.predict() để kiểm tra logic xử lý kết quả.
"""
import io
import pytest
import numpy as np
from unittest.mock import MagicMock, patch, PropertyMock
from PIL import Image

from app.services.ai_service import AIService


# ── Fixtures ──────────────────────────────────────────────────────

def _make_image_bytes(fmt: str = "JPEG", mode: str = "RGB", size=(64, 64)) -> bytes:
    img = Image.new(mode, size, color=(120, 80, 40))
    buf = io.BytesIO()
    img.save(buf, format=fmt)
    return buf.getvalue()


def _make_thin_crack_image_bytes() -> bytes:
    img = Image.new("RGB", (280, 180), color=(194, 190, 182))
    for y in range(20, 160):
        x = 138 + int(np.sin(y / 11) * 3)
        img.putpixel((x, y), (95, 92, 88))
        if y % 9 == 0:
            img.putpixel((x + 1, y), (120, 116, 110))
    buf = io.BytesIO()
    img.save(buf, format="JPEG", quality=92)
    return buf.getvalue()


@pytest.fixture
def service():
    """Trả về instance AIService mới, reset _model về None."""
    svc = AIService()
    svc._model = None
    return svc


@pytest.fixture
def service_with_mock_model(service):
    """AIService với model giả — predict trả về prob_positive = 0.85."""
    mock_model = MagicMock()
    mock_model.predict.return_value = np.array([[0.85]])
    service._model = mock_model
    return service


# ── load_model ────────────────────────────────────────────────────

class TestLoadModel:
    def test_skip_if_already_loaded(self, service):
        """Không load lại nếu model đã có."""
        sentinel = object()
        service._model = sentinel
        service.load_model()
        assert service._model is sentinel

    def test_mock_mode_when_file_missing(self, service, tmp_path):
        """Ghi warning + giữ _model = None khi file không tồn tại."""
        with patch("app.services.ai_service._REPO_ROOT", tmp_path), \
             patch("app.services.ai_service.settings") as mock_cfg:
            mock_cfg.model_path = "nonexistent.keras"
            service.load_model()
        assert service._model is None

    def test_is_ready_false_when_no_model(self, service):
        assert service.is_ready is False

    def test_is_ready_true_when_model_set(self, service):
        service._model = MagicMock()
        assert service.is_ready is True


# ── _preprocess ────────────────────────────────────────────────────

class TestPreprocess:
    def test_output_shape(self, service):
        arr = service._preprocess(_make_image_bytes("JPEG"))
        assert arr.shape == (1, 224, 224, 3)

    def test_output_dtype_float32(self, service):
        arr = service._preprocess(_make_image_bytes("JPEG"))
        assert arr.dtype == np.float32

    def test_raw_pixel_range_for_model_rescaling_layer(self, service):
        arr = service._preprocess(_make_image_bytes("JPEG"))
        assert arr.min() >= 0.0
        assert arr.max() <= 255.0
        assert arr.max() > 1.0

    def test_accepts_png(self, service):
        arr = service._preprocess(_make_image_bytes("PNG"))
        assert arr.shape == (1, 224, 224, 3)

    def test_converts_rgba_to_rgb(self, service):
        """Ảnh có alpha channel phải được convert về RGB."""
        img = Image.new("RGBA", (64, 64), (100, 150, 200, 128))
        buf = io.BytesIO()
        img.save(buf, format="PNG")
        arr = service._preprocess(buf.getvalue())
        assert arr.shape == (1, 224, 224, 3)

    def test_converts_grayscale_to_rgb(self, service):
        img = Image.new("L", (64, 64), 128)
        buf = io.BytesIO()
        img.save(buf, format="JPEG")
        arr = service._preprocess(buf.getvalue())
        assert arr.shape == (1, 224, 224, 3)

    def test_resizes_large_image(self, service):
        arr = service._preprocess(_make_image_bytes("JPEG", size=(1920, 1080)))
        assert arr.shape == (1, 224, 224, 3)


# ── predict ────────────────────────────────────────────────────────

class TestPredict:
    def test_raises_when_model_not_ready(self, service):
        with pytest.raises(RuntimeError, match="AI model chưa được load"):
            service.predict(_make_image_bytes())

    def test_positive_result(self, service_with_mock_model):
        """prob_positive=0.85 >= threshold 0.5 → CRACK."""
        result = service_with_mock_model.predict(_make_image_bytes())
        assert result["pred_label"] == "CRACK"
        assert result["meaning"] == "Có vết nứt"
        assert result["prob_positive"] == pytest.approx(0.85, abs=1e-4)
        assert result["confidence"] == pytest.approx(0.85, abs=1e-4)
        assert result["source"] == "server"
        assert "inference_time_s" in result
        assert result["inference_time_s"] >= 0.0

    def test_negative_result(self, service):
        """prob_positive=0.2 < threshold 0.5 → NO_CRACK, confidence = 1 - 0.2."""
        mock_model = MagicMock()
        mock_model.predict.return_value = np.array([[0.2]])
        service._model = mock_model

        result = service.predict(_make_image_bytes())
        assert result["pred_label"] == "NO_CRACK"
        assert result["meaning"] == "Không có vết nứt"
        assert result["confidence"] == pytest.approx(0.8, abs=1e-4)

    def test_vision_fallback_catches_thin_crack(self, service):
        mock_model = MagicMock()
        mock_model.predict.return_value = np.array([[0.002]])
        service._model = mock_model

        result = service.predict(_make_thin_crack_image_bytes())

        assert result["pred_label"] == "CRACK"
        assert result["prob_positive"] >= 0.5
        assert result["source"] == "server+vision"

    def test_boundary_exactly_at_threshold(self, service):
        """prob = 0.5 đúng bằng threshold → Positive."""
        mock_model = MagicMock()
        mock_model.predict.return_value = np.array([[0.5]])
        service._model = mock_model
        with patch("app.services.ai_service.settings") as mock_cfg:
            mock_cfg.model_threshold = 0.5
            result = service.predict(_make_image_bytes())
        assert result["pred_label"] == "CRACK"

    def test_result_has_all_required_keys(self, service_with_mock_model):
        result = service_with_mock_model.predict(_make_image_bytes())
        for key in ("pred_label", "meaning", "prob_positive", "confidence",
                    "threshold", "inference_time_s", "source"):
            assert key in result, f"Thiếu key: {key}"

    def test_confidence_clamped_to_0_1(self, service):
        """Confidence luôn trong [0, 1]."""
        for prob in [0.0, 0.01, 0.5, 0.99, 1.0]:
            mock_model = MagicMock()
            mock_model.predict.return_value = np.array([[prob]])
            service._model = mock_model
            result = service.predict(_make_image_bytes())
            assert 0.0 <= result["confidence"] <= 1.0

    def test_inference_time_measured(self, service_with_mock_model):
        """inference_time_s phải là số thực >= 0."""
        result = service_with_mock_model.predict(_make_image_bytes())
        assert isinstance(result["inference_time_s"], float)
        assert result["inference_time_s"] >= 0.0
