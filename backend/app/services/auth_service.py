from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.repositories.auth_repository import AuthRepository
from app.core.security import (
    hash_password,
    verify_password,
    create_access_token,
    generate_refresh_token,
    refresh_token_expire_at,
)
from app.schemas.auth import TokenResponse, UserResponse


class AuthService:
    def __init__(self, db: Session):
        self.repo = AuthRepository(db)

    def register(self, email: str, password: str, full_name: str) -> UserResponse:
        if self.repo.get_user_by_email(email):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Email đã được sử dụng",
            )
        user = self.repo.create_user(
            email=email,
            password_hash=hash_password(password),
            full_name=full_name,
        )
        return UserResponse.model_validate(user)

    def login(self, email: str, password: str) -> TokenResponse:
        user = self.repo.get_user_by_email(email)
        if not user or not verify_password(password, user.password_hash):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Email hoặc mật khẩu không đúng",
            )
        if not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Tài khoản đã bị vô hiệu hóa",
            )
        return self._issue_tokens(user.id)

    def refresh(self, raw_token: str) -> TokenResponse:
        token_record = self.repo.get_refresh_token(raw_token)
        if not token_record or not self.repo.is_token_valid(token_record):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Refresh token không hợp lệ hoặc đã hết hạn",
            )
        # Rotate: revoke old, issue new
        self.repo.revoke_token(token_record)
        return self._issue_tokens(token_record.user_id)

    def logout(self, raw_token: str) -> None:
        token_record = self.repo.get_refresh_token(raw_token)
        if token_record:
            self.repo.revoke_token(token_record)

    def _issue_tokens(self, user_id: str) -> TokenResponse:
        access_token = create_access_token(user_id)
        raw_refresh = generate_refresh_token()
        self.repo.create_refresh_token(
            user_id=user_id,
            raw_token=raw_refresh,
            expires_at=refresh_token_expire_at(),
        )
        return TokenResponse(access_token=access_token, refresh_token=raw_refresh)
