from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
import os

from app.core.config import settings
from app.core.database import engine, Base
from app.models import User, RefreshToken, ScanResult  # noqa: F401 — register models
from app.routers import auth, scan, history
from app.services.ai_service import ai_service

# Tạo tables (dev mode — production dùng Alembic)
if settings.is_sqlite:
    Base.metadata.create_all(bind=engine)


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: load AI model một lần duy nhất
    ai_service.load_model()
    yield
    # Shutdown: không cần cleanup


app = FastAPI(
    title="CrackVision API",
    description="API phát hiện vết nứt bề mặt bằng AI",
    version="1.0.0",
    docs_url="/docs" if settings.debug else None,
    redoc_url="/redoc" if settings.debug else None,
    lifespan=lifespan,
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins_list,
    allow_origin_regex=settings.allow_origin_regex,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Static files (ảnh upload)
os.makedirs(settings.upload_dir, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=settings.upload_dir), name="uploads")

# Routers
app.include_router(auth.router, prefix="/api/v1")
app.include_router(scan.router, prefix="/api/v1")
app.include_router(history.router, prefix="/api/v1")


@app.get("/health")
def health_check():
    return {
        "status": "ok",
        "env": settings.app_env,
        "ai_model": "ready" if ai_service.is_ready else "not loaded",
    }
