-- CrackVision Mobile — Database Schema
-- Database: PostgreSQL 15+ (hoặc SQLite cho dev)
-- Encoding: UTF-8
-- Created: 2026-05-16

-- Extension UUID (PostgreSQL only)
-- SQLite dùng TEXT cho UUID, bỏ dòng này
-- CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- TABLE: users
-- Lưu thông tin tài khoản người dùng
-- ============================================================
CREATE TABLE IF NOT EXISTS users (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email           VARCHAR(255) NOT NULL UNIQUE,
    password_hash   VARCHAR(255) NOT NULL,
    full_name       VARCHAR(100) NOT NULL,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users(email);

-- ============================================================
-- TABLE: refresh_tokens
-- Lưu refresh token để support logout và token rotation
-- ============================================================
CREATE TABLE IF NOT EXISTS refresh_tokens (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash      VARCHAR(255) NOT NULL UNIQUE,
    expires_at      TIMESTAMP WITH TIME ZONE NOT NULL,
    is_revoked      BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_refresh_tokens_user_id ON refresh_tokens(user_id);
CREATE INDEX idx_refresh_tokens_token_hash ON refresh_tokens(token_hash);

-- ============================================================
-- TABLE: scan_results
-- Lưu kết quả mỗi lần scan ảnh
-- ============================================================
CREATE TABLE IF NOT EXISTS scan_results (
    id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id                 UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Kết quả AI
    pred_label              VARCHAR(20) NOT NULL,       -- "Positive" hoặc "Negative"
    meaning                 VARCHAR(50) NOT NULL,        -- "Có vết nứt" / "Không có vết nứt"
    prob_positive           DECIMAL(6, 4) NOT NULL,     -- 0.0000 → 1.0000
    confidence              DECIMAL(6, 4) NOT NULL,     -- 0.0000 → 1.0000
    threshold               DECIMAL(4, 2) NOT NULL DEFAULT 0.50,
    inference_time_seconds  DECIMAL(8, 4),              -- Thời gian inference (giây)

    -- File ảnh
    image_path              VARCHAR(500),               -- Đường dẫn lưu ảnh trên server
    image_filename          VARCHAR(255),               -- Tên file gốc (hiển thị)

    -- Metadata
    source                  VARCHAR(20) NOT NULL DEFAULT 'server', -- 'server' hoặc 'tflite'
    note                    TEXT,                       -- Ghi chú của user (optional)
    is_synced               BOOLEAN NOT NULL DEFAULT TRUE, -- False nếu scan offline chưa sync

    created_at              TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_scan_results_user_id ON scan_results(user_id);
CREATE INDEX idx_scan_results_created_at ON scan_results(created_at DESC);
CREATE INDEX idx_scan_results_pred_label ON scan_results(pred_label);

-- ============================================================
-- TRIGGER: auto-update updated_at
-- ============================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_scan_results_updated_at
    BEFORE UPDATE ON scan_results
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- SAMPLE DATA (cho testing — chỉ dùng trong dev)
-- ============================================================
-- INSERT INTO users (email, password_hash, full_name) VALUES
-- ('test@example.com', '$2b$12$...bcrypt_hash...', 'Test User');
