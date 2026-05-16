"""
Script test nhanh auth flow — chạy khi server đang chạy.
Usage: python test_auth.py
"""
import httpx
import sys

BASE = "http://localhost:8000/api/v1"
HEADERS = {"Content-Type": "application/json"}

def ok(msg): print(f"  [OK]  {msg}")
def fail(msg): print(f"  [FAIL] {msg}"); sys.exit(1)
def step(msg): print(f"\n>>> {msg}")


def main():
    print("\n========= CrackVision Auth Flow Test =========")

    # 1. Register
    step("1. Register")
    r = httpx.post(f"{BASE}/auth/register", json={
        "email": "test@crackvision.com",
        "password": "password123",
        "full_name": "Test User"
    })
    if r.status_code == 201:
        ok(f"Đăng ký thành công: {r.json()['email']}")
    elif r.status_code == 400 and "đã được sử dụng" in r.json().get("detail", ""):
        ok("Email đã tồn tại (chạy lại test) — bỏ qua")
    else:
        fail(f"Register thất bại: {r.status_code} — {r.text}")

    # 2. Login
    step("2. Login")
    r = httpx.post(f"{BASE}/auth/login", json={
        "email": "test@crackvision.com",
        "password": "password123"
    })
    if r.status_code != 200:
        fail(f"Login thất bại: {r.status_code} — {r.text}")
    tokens = r.json()
    access_token = tokens["access_token"]
    refresh_token = tokens["refresh_token"]
    ok(f"Login OK — access_token: {access_token[:30]}...")

    # 3. Get /me
    step("3. GET /auth/me")
    r = httpx.get(f"{BASE}/auth/me", headers={"Authorization": f"Bearer {access_token}"})
    if r.status_code != 200:
        fail(f"/me thất bại: {r.status_code} — {r.text}")
    ok(f"User: {r.json()}")

    # 4. Refresh token
    step("4. Refresh token")
    r = httpx.post(f"{BASE}/auth/refresh", json={"refresh_token": refresh_token})
    if r.status_code != 200:
        fail(f"Refresh thất bại: {r.status_code} — {r.text}")
    new_tokens = r.json()
    ok(f"Refresh OK — new access_token: {new_tokens['access_token'][:30]}...")

    # 5. Logout
    step("5. Logout")
    r = httpx.post(f"{BASE}/auth/logout", json={"refresh_token": new_tokens["refresh_token"]})
    if r.status_code != 204:
        fail(f"Logout thất bại: {r.status_code} — {r.text}")
    ok("Logout OK")

    # 6. Dùng refresh token cũ sau logout → phải thất bại
    step("6. Dùng refresh token cũ sau logout (phải bị từ chối)")
    r = httpx.post(f"{BASE}/auth/refresh", json={"refresh_token": new_tokens["refresh_token"]})
    if r.status_code == 401:
        ok("Bị từ chối đúng chuẩn (401) ✓")
    else:
        fail(f"Lỗ hổng bảo mật: token cũ vẫn dùng được! {r.status_code}")

    print("\n========= TẤT CẢ TEST PASSED ✓ =========\n")


if __name__ == "__main__":
    main()
