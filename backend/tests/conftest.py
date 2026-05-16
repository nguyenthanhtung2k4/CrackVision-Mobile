"""
Shared fixtures cho toàn bộ test suite.
Dùng SQLite in-memory (StaticPool) + TestClient không cần server thật.
"""
import io
import pytest
from PIL import Image
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

# Import models để register với Base TRƯỚC create_all
from app.core.database import Base, get_db
from app.models import User, RefreshToken, ScanResult  # noqa: F401

# ── In-memory SQLite với StaticPool (tất cả connections dùng cùng 1 DB) ──
_engine = create_engine(
    "sqlite:///:memory:",
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
_TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=_engine)

# Tạo schema — models đã được import ở trên nên Base đã có đủ tables
Base.metadata.create_all(bind=_engine)


def _override_get_db():
    db = _TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()


@pytest.fixture(scope="session", autouse=True)
def _apply_db_override():
    from app.main import app
    app.dependency_overrides[get_db] = _override_get_db
    yield
    app.dependency_overrides.clear()


@pytest.fixture(scope="session")
def client(_apply_db_override):
    from app.main import app
    with TestClient(app, raise_server_exceptions=False) as c:
        yield c


# ── Tạo user + lấy token ──────────────────────────────────────────
@pytest.fixture(scope="session")
def auth_tokens(client):
    client.post("/api/v1/auth/register", json={
        "email": "session_user@crackvision.com",
        "password": "password123",
        "full_name": "Session User",
    })
    r = client.post("/api/v1/auth/login", json={
        "email": "session_user@crackvision.com",
        "password": "password123",
    })
    assert r.status_code == 200, f"Login thất bại: {r.status_code} {r.text}"
    return r.json()


@pytest.fixture(scope="session")
def auth_headers(auth_tokens):
    return {"Authorization": f"Bearer {auth_tokens['access_token']}"}


# ── Helpers ───────────────────────────────────────────────────────
def make_jpeg_bytes(width: int = 64, height: int = 64) -> bytes:
    img = Image.new("RGB", (width, height), color=(100, 150, 200))
    buf = io.BytesIO()
    img.save(buf, format="JPEG")
    return buf.getvalue()


def make_png_bytes(width: int = 64, height: int = 64) -> bytes:
    img = Image.new("RGB", (width, height), color=(200, 100, 50))
    buf = io.BytesIO()
    img.save(buf, format="PNG")
    return buf.getvalue()
