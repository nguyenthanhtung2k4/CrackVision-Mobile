# Database — CrackVision Mobile

## Files

| File | Mô tả |
|------|-------|
| `schema.sql` | DDL đầy đủ: tạo tables, indexes, triggers |
| `ERD.md` | Sơ đồ quan hệ (text) + mô tả + SQLAlchemy models |

## Bảng Tóm Tắt

| Bảng | Mục đích | Số cột |
|------|---------|--------|
| `users` | Tài khoản người dùng | 7 |
| `refresh_tokens` | JWT refresh token, hỗ trợ logout | 6 |
| `scan_results` | Kết quả mỗi lần scan AI | 15 |

## Chạy Schema

### PostgreSQL (Production)
```bash
psql -U postgres -d crackvision -f database/schema.sql
```

### SQLite (Development - qua Alembic)
```bash
cd backend
alembic upgrade head
```

## Migration Workflow

```bash
# Tạo migration mới sau khi thay đổi model
alembic revision --autogenerate -m "add note column to scan_results"

# Apply migration
alembic upgrade head

# Rollback
alembic downgrade -1
```

## Xem thêm
- `ERD.md` — chi tiết quan hệ và SQLAlchemy code
- `schema.sql` — SQL đầy đủ để setup tay
