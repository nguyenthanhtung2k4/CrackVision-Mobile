from datetime import datetime, timezone
from typing import Optional
from sqlalchemy.orm import Session
from app.models.user import User
from app.models.refresh_token import RefreshToken
from app.core.security import hash_token


class AuthRepository:
    def __init__(self, db: Session):
        self.db = db

    # --- User ---

    def get_user_by_email(self, email: str) -> Optional[User]:
        return self.db.query(User).filter(User.email == email).first()

    def get_user_by_id(self, user_id: str) -> Optional[User]:
        return self.db.query(User).filter(User.id == user_id).first()

    def create_user(self, email: str, password_hash: str, full_name: str) -> User:
        user = User(email=email, password_hash=password_hash, full_name=full_name)
        self.db.add(user)
        self.db.commit()
        self.db.refresh(user)
        return user

    # --- Refresh Token ---

    def create_refresh_token(self, user_id: str, raw_token: str, expires_at: datetime) -> RefreshToken:
        token = RefreshToken(
            user_id=user_id,
            token_hash=hash_token(raw_token),
            expires_at=expires_at,
        )
        self.db.add(token)
        self.db.commit()
        return token

    def get_refresh_token(self, raw_token: str) -> Optional[RefreshToken]:
        return (
            self.db.query(RefreshToken)
            .filter(RefreshToken.token_hash == hash_token(raw_token))
            .first()
        )

    def revoke_token(self, token: RefreshToken) -> None:
        token.is_revoked = True
        self.db.commit()

    def revoke_all_user_tokens(self, user_id: str) -> None:
        self.db.query(RefreshToken).filter(
            RefreshToken.user_id == user_id,
            RefreshToken.is_revoked == False,  # noqa: E712
        ).update({"is_revoked": True})
        self.db.commit()

    def is_token_valid(self, token: RefreshToken) -> bool:
        now = datetime.now(timezone.utc)
        expires = token.expires_at
        # SQLite trả naive datetime — normalize về UTC để so sánh
        if expires.tzinfo is None:
            expires = expires.replace(tzinfo=timezone.utc)
        return not token.is_revoked and expires > now
