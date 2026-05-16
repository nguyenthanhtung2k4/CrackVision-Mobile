# Entity Relationship Diagram — CrackVision Mobile

## Sơ Đồ ERD (Text)

```
┌─────────────────────────────────────┐
│               users                 │
├─────────────────────────────────────┤
│ PK  id              UUID            │
│     email           VARCHAR(255) UQ │
│     password_hash   VARCHAR(255)    │
│     full_name       VARCHAR(100)    │
│     is_active       BOOLEAN         │
│     created_at      TIMESTAMPTZ     │
│     updated_at      TIMESTAMPTZ     │
└──────────────┬──────────────────────┘
               │ 1
               │
               ├──────────────────────────────────┐
               │                                  │
               │ N                                │ N
┌──────────────▼──────────────────────┐ ┌─────────▼───────────────────────────┐
│          refresh_tokens             │ │           scan_results               │
├─────────────────────────────────────┤ ├─────────────────────────────────────┤
│ PK  id              UUID            │ │ PK  id                UUID           │
│ FK  user_id         UUID ──► users  │ │ FK  user_id           UUID ──► users │
│     token_hash      VARCHAR(255) UQ │ │                                      │
│     expires_at      TIMESTAMPTZ     │ │     pred_label        VARCHAR(20)    │
│     is_revoked      BOOLEAN         │ │     meaning           VARCHAR(50)    │
│     created_at      TIMESTAMPTZ     │ │     prob_positive     DECIMAL(6,4)   │
└─────────────────────────────────────┘ │     confidence        DECIMAL(6,4)   │
                                        │     threshold         DECIMAL(4,2)   │
                                        │     inference_time_s  DECIMAL(8,4)   │
                                        │     image_path        VARCHAR(500)   │
                                        │     image_filename    VARCHAR(255)   │
                                        │     source            VARCHAR(20)    │
                                        │     note              TEXT           │
                                        │     is_synced         BOOLEAN        │
                                        │     created_at        TIMESTAMPTZ    │
                                        │     updated_at        TIMESTAMPTZ    │
                                        └─────────────────────────────────────┘
```

## Mô Tả Quan Hệ

### users → refresh_tokens (1:N)
- Một user có thể có nhiều refresh token (đăng nhập nhiều thiết bị)
- Khi user bị xóa → tất cả refresh token tự động bị xóa (CASCADE)
- Khi logout → token bị đánh dấu `is_revoked = TRUE`

### users → scan_results (1:N)
- Một user có nhiều lần scan
- Khi user bị xóa → tất cả scan result tự động bị xóa (CASCADE)
- Mỗi scan result thuộc về đúng 1 user → đảm bảo privacy

## Indexes

| Bảng | Index | Mục đích |
|------|-------|---------|
| users | `email` | Tìm user khi login |
| refresh_tokens | `user_id` | Lấy tokens của user |
| refresh_tokens | `token_hash` | Verify token khi refresh |
| scan_results | `user_id` | Lấy history của user |
| scan_results | `created_at DESC` | Sort mới nhất trước |
| scan_results | `pred_label` | Filter theo label |

## SQLAlchemy Models (Python)

### Tương đương trong code

```python
# models/user.py
class User(Base):
    __tablename__ = "users"
    id = Column(UUID, primary_key=True, default=uuid4)
    email = Column(String(255), unique=True, nullable=False)
    password_hash = Column(String(255), nullable=False)
    full_name = Column(String(100), nullable=False)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), default=func.now())
    updated_at = Column(DateTime(timezone=True), default=func.now(), onupdate=func.now())
    scan_results = relationship("ScanResult", back_populates="user")
    refresh_tokens = relationship("RefreshToken", back_populates="user")

# models/scan_result.py
class ScanResult(Base):
    __tablename__ = "scan_results"
    id = Column(UUID, primary_key=True, default=uuid4)
    user_id = Column(UUID, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    pred_label = Column(String(20), nullable=False)
    meaning = Column(String(50), nullable=False)
    prob_positive = Column(Numeric(6, 4), nullable=False)
    confidence = Column(Numeric(6, 4), nullable=False)
    threshold = Column(Numeric(4, 2), default=0.50)
    inference_time_seconds = Column(Numeric(8, 4))
    image_path = Column(String(500))
    image_filename = Column(String(255))
    source = Column(String(20), default="server")
    note = Column(Text)
    is_synced = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), default=func.now())
    updated_at = Column(DateTime(timezone=True), default=func.now(), onupdate=func.now())
    user = relationship("User", back_populates="scan_results")
```

## Hive Schema (Flutter Local Storage)

```dart
// Lưu offline scan chưa sync lên server
@HiveType(typeId: 0)
class LocalScanResult extends HiveObject {
  @HiveField(0) late String localId;        // UUID local
  @HiveField(1) late String predLabel;
  @HiveField(2) late String meaning;
  @HiveField(3) late double probPositive;
  @HiveField(4) late double confidence;
  @HiveField(5) late String? imagePath;     // Đường dẫn local trên thiết bị
  @HiveField(6) late String source;         // 'tflite' hoặc 'server'
  @HiveField(7) late bool isSynced;
  @HiveField(8) late DateTime createdAt;
  @HiveField(9) String? serverId;           // UUID từ server sau khi sync
}
```
