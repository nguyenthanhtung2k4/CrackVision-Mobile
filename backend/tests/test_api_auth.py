"""
Integration tests cho Auth flow: register, login, refresh, logout, JWT expiry.
"""
import pytest
from datetime import datetime, timedelta, timezone
from unittest.mock import patch

from app.core.security import create_access_token, hash_password

AUTH = "/api/v1/auth"


# ── Register ──────────────────────────────────────────────────────

class TestRegister:
    def test_register_success(self, client):
        r = client.post(f"{AUTH}/register", json={
            "email": "new_user@test.com",
            "password": "strongpass123",
            "full_name": "New User",
        })
        assert r.status_code == 201
        body = r.json()
        assert body["email"] == "new_user@test.com"
        assert "id" in body
        assert "password" not in body
        assert "password_hash" not in body

    def test_duplicate_email_returns_409(self, client):
        payload = {"email": "dup@test.com", "password": "password123", "full_name": "Dup"}
        client.post(f"{AUTH}/register", json=payload)
        r = client.post(f"{AUTH}/register", json=payload)
        assert r.status_code == 409

    def test_missing_fields_returns_422(self, client):
        r = client.post(f"{AUTH}/register", json={"email": "x@test.com"})
        assert r.status_code == 422

    def test_short_password_returns_422(self, client):
        """Password < 8 ký tự phải bị từ chối."""
        r = client.post(f"{AUTH}/register", json={
            "email": "short@test.com", "password": "abc", "full_name": "S"})
        assert r.status_code == 422


# ── Login ─────────────────────────────────────────────────────────

class TestLogin:
    @pytest.fixture(autouse=True)
    def _register(self, client):
        client.post(f"{AUTH}/register", json={
            "email": "login_user@test.com",
            "password": "mypassword123",
            "full_name": "Login User",
        })

    def test_login_success_returns_tokens(self, client):
        r = client.post(f"{AUTH}/login", json={
            "email": "login_user@test.com",
            "password": "mypassword123",
        })
        assert r.status_code == 200
        body = r.json()
        assert "access_token" in body
        assert "refresh_token" in body
        assert len(body["access_token"]) > 10
        assert len(body["refresh_token"]) > 10

    def test_wrong_password_returns_401(self, client):
        r = client.post(f"{AUTH}/login", json={
            "email": "login_user@test.com",
            "password": "wrongpassword",
        })
        assert r.status_code == 401

    def test_unknown_email_returns_401(self, client):
        r = client.post(f"{AUTH}/login", json={
            "email": "nobody@test.com",
            "password": "anypassword",
        })
        assert r.status_code == 401

    def test_error_message_not_reveal_which_field_wrong(self, client):
        """Không được tiết lộ email đúng hay sai để tránh user enumeration."""
        r_bad_pass = client.post(f"{AUTH}/login", json={
            "email": "login_user@test.com", "password": "wrongpassword"})
        r_bad_email = client.post(f"{AUTH}/login", json={
            "email": "no@no.com", "password": "wrongpassword"})
        assert r_bad_pass.json()["detail"] == r_bad_email.json()["detail"]


# ── /me (protected endpoint) ─────────────────────────────────────

class TestGetMe:
    def test_get_me_success(self, client, auth_headers):
        r = client.get(f"{AUTH}/me", headers=auth_headers)
        assert r.status_code == 200
        assert "email" in r.json()
        assert "password_hash" not in r.json()

    def test_get_me_no_token_returns_4xx(self, client):
        """Không có token → FastAPI trả 401 hoặc 403 tuỳ security scheme."""
        r = client.get(f"{AUTH}/me")
        assert r.status_code in (401, 403)

    def test_get_me_expired_token_401(self, client):
        """Token đã hết hạn phải bị từ chối."""
        with patch("app.core.security.settings") as mock_cfg:
            mock_cfg.jwt_secret_key = "change-this-secret-in-production"
            mock_cfg.jwt_algorithm = "HS256"
            mock_cfg.jwt_access_token_expire_minutes = -1   # đã hết hạn
            expired_token = create_access_token("fake-user-id")
        r = client.get(f"{AUTH}/me", headers={"Authorization": f"Bearer {expired_token}"})
        assert r.status_code == 401

    def test_get_me_malformed_token_401(self, client):
        r = client.get(f"{AUTH}/me", headers={"Authorization": "Bearer not.a.jwt"})
        assert r.status_code == 401


# ── Refresh token ─────────────────────────────────────────────────

class TestRefreshToken:
    def test_refresh_returns_new_tokens(self, client):
        """Refresh token hợp lệ → nhận được token mới."""
        client.post(f"{AUTH}/register", json={
            "email": "refresh_test@test.com", "password": "password123", "full_name": "RT"})
        r = client.post(f"{AUTH}/login", json={
            "email": "refresh_test@test.com", "password": "password123"})
        refresh_tok = r.json()["refresh_token"]

        r2 = client.post(f"{AUTH}/refresh", json={"refresh_token": refresh_tok})
        assert r2.status_code == 200
        body = r2.json()
        assert "access_token" in body
        assert "refresh_token" in body

    def test_refresh_with_garbage_returns_401(self, client):
        r = client.post(f"{AUTH}/refresh", json={"refresh_token": "garbage-token"})
        assert r.status_code == 401

    def test_token_rotation(self, client):
        """Dùng refresh token rồi dùng lại lần 2 phải bị từ chối (rotation)."""
        # Tạo user riêng để tránh ảnh hưởng session khác
        client.post(f"{AUTH}/register", json={
            "email": "rotate@test.com", "password": "password123", "full_name": "R"})
        r = client.post(f"{AUTH}/login", json={
            "email": "rotate@test.com", "password": "password123"})
        first_refresh = r.json()["refresh_token"]

        # Dùng lần 1 → OK
        r2 = client.post(f"{AUTH}/refresh", json={"refresh_token": first_refresh})
        assert r2.status_code == 200

        # Dùng lại lần 2 → 401 (token đã bị revoke khi rotate)
        r3 = client.post(f"{AUTH}/refresh", json={"refresh_token": first_refresh})
        assert r3.status_code == 401


# ── Logout ────────────────────────────────────────────────────────

class TestLogout:
    def test_logout_invalidates_refresh_token(self, client):
        """Sau logout, dùng refresh token cũ phải bị từ chối."""
        client.post(f"{AUTH}/register", json={
            "email": "logout_flow@test.com", "password": "password123", "full_name": "L"})
        r = client.post(f"{AUTH}/login", json={
            "email": "logout_flow@test.com", "password": "password123"})
        assert r.status_code == 200
        tokens = r.json()

        # Logout
        r_logout = client.post(f"{AUTH}/logout", json={"refresh_token": tokens["refresh_token"]})
        assert r_logout.status_code == 204

        # Thử dùng lại → 401
        r2 = client.post(f"{AUTH}/refresh", json={"refresh_token": tokens["refresh_token"]})
        assert r2.status_code == 401

    def test_logout_with_unknown_token_no_crash(self, client):
        """Logout với token không tồn tại không crash (idempotent)."""
        r = client.post(f"{AUTH}/logout", json={"refresh_token": "unknown-token-abc-xyz"})
        assert r.status_code == 204


# ── JWT expiry flow ───────────────────────────────────────────────

class TestJWTExpiry:
    def test_access_token_format_is_jwt(self, client, auth_tokens):
        token = auth_tokens["access_token"]
        parts = token.split(".")
        assert len(parts) == 3, "Access token phải có đúng 3 phần (header.payload.sig)"

    def test_refresh_token_is_opaque_string(self, client, auth_tokens):
        """Refresh token không phải JWT — là opaque random string."""
        token = auth_tokens["refresh_token"]
        assert len(token) > 20
        assert token.count(".") != 2, "Refresh token không được là JWT"

    def test_expired_access_token_rejected(self, client):
        """Token hết hạn bị từ chối ở /auth/me."""
        with patch("app.core.security.settings") as mock_cfg:
            mock_cfg.jwt_secret_key = "change-this-secret-in-production"
            mock_cfg.jwt_algorithm = "HS256"
            mock_cfg.jwt_access_token_expire_minutes = -5
            expired = create_access_token("some-user-id")
        r = client.get(f"{AUTH}/me", headers={"Authorization": f"Bearer {expired}"})
        assert r.status_code == 401
