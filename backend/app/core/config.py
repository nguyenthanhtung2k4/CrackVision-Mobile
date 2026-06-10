from pydantic_settings import BaseSettings
from pydantic import field_validator
from functools import lru_cache
from typing import Any


class Settings(BaseSettings):
    # App
    app_env: str = "development"
    app_host: str = "0.0.0.0"
    app_port: int = 8000
    debug: bool = True

    # Database
    database_url: str = "sqlite:///./crackvision_dev.db"

    # JWT
    jwt_secret_key: str = "change-this-secret-in-production"
    jwt_algorithm: str = "HS256"
    jwt_access_token_expire_minutes: int = 15
    jwt_refresh_token_expire_days: int = 7

    # AI Model
    model_path: str = "../AI_model/mobilenetv2_crack_final.keras"
    model_threshold: float = 0.5

    # File Upload
    upload_dir: str = "uploads"
    max_upload_size_mb: int = 10

    # CORS
    allowed_origins: str = "http://localhost:3000"

    @field_validator("debug", mode="before")
    @classmethod
    def parse_debug(cls, value: Any) -> Any:
        if isinstance(value, bool):
            return value
        if isinstance(value, str):
            normalized = value.strip().lower()
            if normalized in {"true", "1", "yes", "y", "on", "debug", "development", "dev"}:
                return True
            if normalized in {"false", "0", "no", "n", "off", "release", "production", "prod"}:
                return False
        return value

    @property
    def allowed_origins_list(self) -> list[str]:
        origins = [origin.strip() for origin in self.allowed_origins.split(",")]
        # Dev mode: cho phép tất cả localhost (Flutter Web dùng port ngẫu nhiên)
        if self.debug:
            origins.append("http://localhost")
        return origins

    @property
    def allow_origin_regex(self) -> str | None:
        if self.debug:
            return r"http://localhost(:\d+)?"
        return None

    @property
    def is_sqlite(self) -> bool:
        return self.database_url.startswith("sqlite")

    model_config = {
        "env_file": ".env",
        "env_file_encoding": "utf-8",
        "case_sensitive": False,
        "protected_namespaces": ("settings_",),
    }


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
