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
- [x] Backend FastAPI — Auth API (register / login / refresh / logout)
- [x] TFLite conversion — `crack_model.tflite` (2.41 MB, sai số < 1.3%, label 100% khớp)
- [x] Flutter project structure — pubspec.yaml, router, Dio client, secure storage
- [ ] Backend — AI Service + Scan API + History API
- [ ] Flutter app — UI screens + tích hợp API
- [ ] Build APK release

## Tài Liệu

- [Roadmap ](docs/ROADMAP.md)
- [API Spec](docs/API_SPEC.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Database ERD](database/ERD.md)

## Kết Quả TFLite Conversion

| Chỉ số | Giá trị |
|--------|---------|
| Model gốc | `mobilenetv2_crack_final.keras` |
| TFLite output | `crack_model.tflite` — **2.41 MB** |
| Avg diff (prob) | `0.0109` (~1.1%) |
| Max diff (prob) | `0.0126` (~1.3%) |
| Label mismatch | **0/10** — Positive/Negative 100% khớp |
| Phương pháp convert | Keras 3 → `tf.function` concrete function → TFLite |

---

*Đồ án tốt nghiệp — 2026*
