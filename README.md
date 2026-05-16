# CrackVision Mobile

Ứng dụng Android phát hiện vết nứt bề mặt công trình bằng AI (MobileNetV2).  
Đồ án tốt nghiệp — Flutter + FastAPI + TensorFlow.

---

## Tính Năng

- **Scan ảnh**: Chụp ảnh hoặc chọn từ thư viện → AI phân tích ngay
- **Online mode**: Gửi ảnh lên server, model `.keras` cho kết quả chính xác
- **Offline mode**: TFLite on-device, hoạt động không cần internet
- **Lịch sử scan**: Xem lại toàn bộ kết quả đã scan, có thể ghi chú
- **Xác thực**: Đăng ký / đăng nhập bằng JWT, mỗi user có dữ liệu riêng

## Tech Stack

| Phần | Công nghệ |
|------|-----------|
| Mobile | Flutter (Android-first) |
| Backend | FastAPI (Python) |
| AI Model | MobileNetV2 — `.keras` (server) + `.tflite` (on-device) |
| Database | PostgreSQL (production) / SQLite (dev) |
| Auth | JWT (access 15min + refresh 7 ngày) |
| State | Riverpod |
| Storage local | Hive + flutter_secure_storage |

## Cấu Trúc Thư Mục

```
CrackVision-Mobile/
├── backend/          # FastAPI server
├── mobile/           # Flutter app
├── AI_model/         # Model + inference + convert script
├── database/         # Schema SQL + ERD
└── docs/             # Roadmap, API spec, wiki cho AI agents
```

## Trạng Thái Dự Án

> Đang phát triển — xem chi tiết tại [docs/wiki/PROJECT_STATE.md](docs/wiki/PROJECT_STATE.md)

- [x] Thiết kế hệ thống & database schema
- [x] Tài liệu API, architecture, roadmap
- [ ] Backend FastAPI (auth + scan API)
- [ ] Flutter app (UI + tích hợp API)
- [ ] TFLite offline mode
- [ ] Build APK release

## Tài Liệu

- [Roadmap ](docs/ROADMAP.md)
- [API Spec](docs/API_SPEC.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Database ERD](database/ERD.md)

---

*Đồ án tốt nghiệp — 2026*
