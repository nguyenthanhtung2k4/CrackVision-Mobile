"""
Integration tests cho /scan/upload API.
Dùng TestClient + in-memory SQLite (từ conftest).
AI model được mock để không cần file .keras thật.
"""
import io
import pytest
from unittest.mock import patch, MagicMock
import numpy as np
from PIL import Image

from tests.conftest import make_jpeg_bytes, make_png_bytes

SCAN_URL = "/api/v1/scan/upload"

# ── Mock AI inference ─────────────────────────────────────────────

@pytest.fixture(autouse=True)
def mock_ai(monkeypatch):
    """Patch AIService.predict + is_ready để không cần model thật."""
    mock_result = {
        "pred_label": "Positive",
        "meaning": "Có vết nứt",
        "prob_positive": 0.87,
        "confidence": 0.87,
        "threshold": 0.5,
        "inference_time_s": 0.042,
        "source": "server",
    }
    with patch("app.routers.scan.ai_service") as mock_svc:
        mock_svc.is_ready = True
        mock_svc.predict.return_value = mock_result
        yield mock_svc


# ── Upload thành công ─────────────────────────────────────────────

class TestScanUploadSuccess:
    def test_jpeg_returns_201(self, client, auth_headers):
        r = client.post(
            SCAN_URL,
            files={"file": ("crack.jpg", make_jpeg_bytes(), "image/jpeg")},
            headers=auth_headers,
        )
        assert r.status_code == 201

    def test_png_returns_201(self, client, auth_headers):
        r = client.post(
            SCAN_URL,
            files={"file": ("wall.png", make_png_bytes(), "image/png")},
            headers=auth_headers,
        )
        assert r.status_code == 201

    def test_response_has_required_fields(self, client, auth_headers):
        r = client.post(
            SCAN_URL,
            files={"file": ("x.jpg", make_jpeg_bytes(), "image/jpeg")},
            headers=auth_headers,
        )
        body = r.json()
        for field in ("id", "pred_label", "meaning", "prob_positive",
                      "confidence", "threshold", "source", "created_at"):
            assert field in body, f"Thiếu field: {field}"

    def test_pred_label_matches_mock(self, client, auth_headers):
        r = client.post(
            SCAN_URL,
            files={"file": ("x.jpg", make_jpeg_bytes(), "image/jpeg")},
            headers=auth_headers,
        )
        assert r.json()["pred_label"] == "Positive"
        assert r.json()["meaning"] == "Có vết nứt"

    def test_confidence_in_range(self, client, auth_headers):
        r = client.post(
            SCAN_URL,
            files={"file": ("x.jpg", make_jpeg_bytes(), "image/jpeg")},
            headers=auth_headers,
        )
        conf = r.json()["confidence"]
        assert 0.0 <= conf <= 1.0


# ── Auth guard ────────────────────────────────────────────────────

class TestScanAuthGuard:
    def test_no_token_returns_4xx(self, client):
        """Không có token → HTTPBearer trả 403, invalid token → 401."""
        r = client.post(
            SCAN_URL,
            files={"file": ("x.jpg", make_jpeg_bytes(), "image/jpeg")},
        )
        assert r.status_code in (401, 403)

    def test_invalid_token_returns_401(self, client):
        r = client.post(
            SCAN_URL,
            files={"file": ("x.jpg", make_jpeg_bytes(), "image/jpeg")},
            headers={"Authorization": "Bearer invalid.token.here"},
        )
        assert r.status_code == 401


# ── Validation: file type ─────────────────────────────────────────

class TestScanValidation:
    def test_gif_returns_400(self, client, auth_headers):
        gif_bytes = b"GIF89a\x01\x00\x01\x00\x00\xff\x00,\x00\x00\x00\x00\x01\x00\x01\x00\x00\x02\x00;"
        r = client.post(
            SCAN_URL,
            files={"file": ("anim.gif", gif_bytes, "image/gif")},
            headers=auth_headers,
        )
        assert r.status_code == 400

    def test_text_file_returns_400(self, client, auth_headers):
        r = client.post(
            SCAN_URL,
            files={"file": ("note.txt", b"hello world", "text/plain")},
            headers=auth_headers,
        )
        assert r.status_code == 400

    def test_pdf_returns_400(self, client, auth_headers):
        r = client.post(
            SCAN_URL,
            files={"file": ("doc.pdf", b"%PDF-1.4", "application/pdf")},
            headers=auth_headers,
        )
        assert r.status_code == 400

    def test_oversized_file_returns_413(self, client, auth_headers):
        """Ảnh > 10MB phải trả 413."""
        big_bytes = b"\xff\xd8\xff\xe0" + b"\x00" * (11 * 1024 * 1024)
        r = client.post(
            SCAN_URL,
            files={"file": ("huge.jpg", big_bytes, "image/jpeg")},
            headers=auth_headers,
        )
        assert r.status_code == 413

    def test_error_message_in_vietnamese(self, client, auth_headers):
        """Error message phải dùng tiếng Việt."""
        r = client.post(
            SCAN_URL,
            files={"file": ("bad.gif", b"GIF89a", "image/gif")},
            headers=auth_headers,
        )
        detail = r.json().get("detail", "")
        assert any(word in detail for word in ["Chỉ", "JPEG", "PNG", "hợp lệ"])


# ── AI model chưa sẵn sàng ────────────────────────────────────────

class TestAINotReady:
    def test_returns_503_when_model_not_ready(self, client, auth_headers):
        with patch("app.routers.scan.ai_service") as mock_svc:
            mock_svc.is_ready = False
            r = client.post(
                SCAN_URL,
                files={"file": ("x.jpg", make_jpeg_bytes(), "image/jpeg")},
                headers=auth_headers,
            )
        assert r.status_code == 503


# ── CORS headers ──────────────────────────────────────────────────

class TestCORS:
    def test_cors_preflight_from_localhost(self, client):
        """OPTIONS preflight từ localhost phải được chấp nhận."""
        r = client.options(
            SCAN_URL,
            headers={
                "Origin": "http://localhost:3000",
                "Access-Control-Request-Method": "POST",
                "Access-Control-Request-Headers": "Authorization, Content-Type",
            },
        )
        assert r.status_code in (200, 204)

    def test_cors_header_present_on_post(self, client, auth_headers):
        """Response POST phải có Access-Control-Allow-Origin."""
        r = client.post(
            SCAN_URL,
            files={"file": ("x.jpg", make_jpeg_bytes(), "image/jpeg")},
            headers={**auth_headers, "Origin": "http://localhost:3000"},
        )
        assert "access-control-allow-origin" in {k.lower() for k in r.headers}
