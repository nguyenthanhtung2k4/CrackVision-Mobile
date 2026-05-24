# StructScan AI — CrackVision Mobile

**Xây dựng Mobile App nhận diện vết nứt bề mặt vật liệu xây dựng sử dụng mô hình học sâu nhẹ MobileNet**

Đồ án tốt nghiệp — Ngành Công nghệ Thông tin  
Trường Đại học Đại Nam  
Sinh viên: **Dương Ngọc Minh** — MSV: 1457020408 — Khóa 14  
Giảng viên hướng dẫn: **TS. Trần Quý Nam**  
Năm: 2026

---

## Giới Thiệu Đề Tài

Trong quá trình xây dựng, khai thác và bảo trì công trình, việc kiểm tra chất lượng bề mặt vật liệu xây dựng luôn giữ vai trò quan trọng. Vết nứt trên bề mặt bê tông, tường, sàn hoặc các cấu kiện là dấu hiệu phổ biến của hư hỏng, nếu không phát hiện kịp thời có thể lan rộng và ảnh hưởng đến an toàn công trình.

Hiện tại, kiểm tra vết nứt vẫn chủ yếu thực hiện thủ công — dễ bị ảnh hưởng bởi điều kiện ánh sáng, kinh nghiệm người kiểm tra và tốn nhiều thời gian. Đề tài này xây dựng hệ thống **StructScan AI** gồm hai phần:

1. **Mô hình AI** — phân loại ảnh nhị phân (có vết nứt / không có vết nứt) sử dụng MobileNet
2. **Mobile App** — ứng dụng Flutter cho phép quét ảnh, xem kết quả và quản lý lịch sử kiểm tra

> Bài toán được xác định là **phân loại ảnh nhị phân** (Binary Image Classification), không phải object detection — mô hình không xác định tọa độ hay bounding box của vết nứt.

---

## Kết Quả Mô Hình AI

### Dataset
- **Concrete & Pavement Crack Dataset** (Kaggle) — 30.000 ảnh bề mặt bê tông và mặt đường
- Chia train / validation / test theo tỷ lệ **70% / 15% / 15%** (21.000 / 4.500 / 4.500 ảnh)
- Tập test cân bằng: 2.250 ảnh Positive (có vết nứt) + 2.250 ảnh Negative

### So sánh 3 mô hình MobileNet

| Mô hình | Accuracy | Đặc điểm |
|---|---|---|
| MobileNetV1 | >99% | Chỉ số tổng thể tốt nhất |
| **MobileNetV2** | >99% | **Recall tốt nhất** — ít bỏ sót vết nứt nhất |
| MobileNetV3Small | >99% | Kích thước nhỏ nhất — phù hợp on-device |

- Cả 3 mô hình đạt **accuracy > 99%**, thời gian suy luận < 2 giây/ảnh
- **MobileNetV2** được chọn cho server (độ chính xác cao)
- **MobileNetV3Small** → chuyển đổi sang TFLite cho on-device

### Kết quả TFLite Conversion

| Chỉ số | Giá trị |
|---|---|
| TFLite output | `crack_model.tflite` — **2.41 MB** |
| Avg diff (prob) | `0.0109` (~1.1%) |
| Max diff (prob) | `0.0126` (~1.3%) |
| Label mismatch | **0/10** — 100% khớp với model gốc |
| Phương pháp | Keras 3 → `tf.function` → TFLite |

---

## Tech Stack

| Thành phần | Công nghệ |
|---|---|
| Mobile app | Flutter 3.x (Android-first, hỗ trợ iOS & Web) |
| Backend API | FastAPI (Python 3.10+) |
| AI Server | MobileNetV2 `.keras` — TensorFlow 2.16 |
| AI On-device | MobileNetV3Small `.tflite` — tflite_flutter 0.12 |
| Texture pre-filter | MobileNetV2 binary classifier (bê tông / không phải bê tông) |
| Database | MySQL 8.0+ (production) / SQLite (dev) |
| Auth | JWT — access token 15 phút + refresh token 7 ngày |
| State management | Riverpod 2.x |
| Navigation | GoRouter 14.x |
| HTTP client | Dio 5.x |
| Local storage | Hive + flutter_secure_storage |

---

## Tính Năng Chính

- **Quét ảnh** bằng camera hoặc tải từ thư viện → AI phân tích ngay
- **Online mode**: gửi ảnh lên server, model `.keras` cho kết quả chính xác
- **Offline mode**: TFLite on-device, hoạt động không cần internet, tự động fallback khi mất mạng
- **Texture pre-filter**: tự động từ chối ảnh không phải bề mặt bê tông
- **Kết quả chi tiết**: xác suất, độ tin cậy, thời gian xử lý, nguồn AI
- **Lịch sử scan**: xem lại, tìm kiếm, lọc, ghi chú từng lần kiểm tra
- **Đa ngôn ngữ**: Tiếng Việt + Tiếng Anh
- **Dark mode**, xác thực JWT, mỗi user có dữ liệu riêng biệt

---

## Cấu Trúc Thư Mục

```
CrackVision-Mobile/
├── backend/                        # FastAPI server
│   ├── app/
│   │   ├── core/                   # Config, database, auth, deps
│   │   ├── models/                 # SQLAlchemy ORM models
│   │   ├── routers/                # API endpoints (auth, scan, history)
│   │   ├── schemas/                # Pydantic request/response schemas
│   │   ├── services/               # AI service, storage service
│   │   └── repositories/           # Database query layer
│   ├── requirements.txt
│   └── .env                        # Biến môi trường (KHÔNG commit git)
├── mobile/                         # Flutter app (StructScan AI)
│   ├── lib/
│   │   ├── core/                   # Theme, router, l10n, network, storage
│   │   ├── features/               # auth, scanner, history, home, settings
│   │   └── services/               # TFLite service (native & stub)
│   ├── assets/
│   │   ├── models/crack_model.tflite
│   │   └── images/
│   └── pubspec.yaml
├── AI_model/                       # Scripts train & convert model
│   ├── V2_mobilenetv2_crack_final.keras    # MobileNetV2 — server
│   ├── texture_classifier.keras            # Texture pre-filter
│   ├── crack_model.tflite                  # MobileNetV3Small — on-device
│   ├── train_texture_classifier.py
│   └── convert_tflite.py
├── database/                       # Schema SQL & ERD
└── docs/                           # Báo cáo, API spec, architecture
```

---

## Yêu Cầu Hệ Thống

### Backend
| | Yêu cầu |
|---|---|
| Python | 3.10 – 3.12 |
| RAM | 4 GB+ (TensorFlow load model ~1.5 GB) |
| Database | MySQL 8.0+ **hoặc** SQLite (không cần cài, dùng cho dev) |
| OS | Windows 10/11 · macOS 12+ · Ubuntu 20.04+ |

### Flutter / Mobile
| | Yêu cầu |
|---|---|
| Flutter SDK | 3.19+ |
| Dart SDK | 3.3+ |
| Android SDK | API 21+ (Android 5.0+) |
| Xcode (iOS only) | 15+ — chỉ cần trên macOS |

---

## Cài Đặt & Chạy

### Bước 1 — Clone repo

```bash
git clone https://github.com/<your-username>/CrackVision-Mobile.git
cd CrackVision-Mobile
```

---

### Bước 2 — Cài Backend

#### Windows (PowerShell)

```powershell
cd backend

# Tạo virtual environment
python -m venv .venv
.venv\Scripts\activate

# Cài dependencies
pip install -r requirements.txt

# Tạo file .env
copy .env.example .env
```

#### macOS

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
```

#### Linux (Ubuntu / Debian)

```bash
cd backend
sudo apt install python3-venv python3-pip -y
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
```

---

#### Cấu hình `backend/.env`

```env
# Database — chọn 1 trong 2:
DATABASE_URL=sqlite:///./crackvision_dev.db
# DATABASE_URL=mysql+pymysql://root:password@localhost:3306/crackvision

# JWT
JWT_SECRET_KEY=your-super-secret-key-change-this-in-production
JWT_ALGORITHM=HS256
JWT_ACCESS_TOKEN_EXPIRE_MINUTES=15
JWT_REFRESH_TOKEN_EXPIRE_DAYS=7

# App
APP_ENV=development
APP_HOST=0.0.0.0
APP_PORT=8000
DEBUG=true

# AI Model (đường dẫn tương đối từ thư mục backend/)
MODEL_PATH=../AI_model/V2_mobilenetv2_crack_final.keras
MODEL_THRESHOLD=0.5

# File Upload
UPLOAD_DIR=uploads
MAX_UPLOAD_SIZE_MB=10

# CORS — thêm IP LAN nếu test trên thiết bị thật
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8000,http://10.0.2.2:8000
```

---

#### Khởi tạo DB & chạy server

```bash
# Đảm bảo đang ở thư mục backend/ và đã activate .venv

# Tạo bảng database
python -c "from app.core.database import Base, engine; Base.metadata.create_all(engine)"

# Chạy server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

| URL | Mô tả |
|---|---|
| `http://localhost:8000` | API base |
| `http://localhost:8000/docs` | Swagger UI |
| `http://localhost:8000/api/v1/health` | Health check |

> **Lưu ý:** Lần đầu chạy, TensorFlow cần ~7 giây để load và warmup model. Các request sau chỉ mất ~0.5s.

---

### Bước 3 — Cài Flutter App

#### Tất cả OS

```bash
cd mobile
flutter pub get
flutter devices    # Kiểm tra thiết bị / emulator
```

#### Android Emulator

```bash
flutter run
# Tự động dùng http://10.0.2.2:8000/api/v1
```

#### Android thật (physical device)

```bash
# Bật USB Debugging → cắm cáp → tìm IP LAN máy tính:
#   Windows: ipconfig  →  IPv4 Address
#   macOS/Linux: ifconfig  →  inet

flutter run --dart-define=BASE_URL=http://192.168.x.x:8000/api/v1
```

#### iOS (macOS only)

```bash
cd mobile/ios && pod install && cd ..
open -a Simulator
flutter run
```

#### Web (Chrome)

```bash
flutter run -d chrome
# Lưu ý: Offline AI (TFLite) không hoạt động trên Web
```

#### Build APK release

```bash
flutter build apk --release
# Output: mobile/build/app/outputs/flutter-apk/app-release.apk
```

---

## Kết Nối App ↔ Backend

| Môi trường | BASE_URL |
|---|---|
| Android Emulator | `http://10.0.2.2:8000/api/v1` *(tự động)* |
| Web (localhost) | `http://localhost:8000/api/v1` *(tự động)* |
| Android thật / iOS | `--dart-define=BASE_URL=http://<IP-LAN>:8000/api/v1` |
| Production | `--dart-define=BASE_URL=https://api.domain.com/api/v1` |

---

## API Endpoints

| Method | Endpoint | Mô tả |
|---|---|---|
| POST | `/api/v1/auth/register` | Đăng ký tài khoản |
| POST | `/api/v1/auth/login` | Đăng nhập, nhận JWT |
| POST | `/api/v1/auth/refresh` | Làm mới access token |
| POST | `/api/v1/auth/logout` | Đăng xuất |
| GET | `/api/v1/auth/me` | Thông tin user hiện tại |
| POST | `/api/v1/scan/upload` | Upload ảnh + phân tích AI |
| GET | `/api/v1/history` | Danh sách lịch sử scan |
| GET | `/api/v1/history/{id}` | Chi tiết 1 kết quả scan |
| GET | `/api/v1/health` | Trạng thái server + AI model |

Chi tiết đầy đủ: `http://localhost:8000/docs`

---

## Troubleshooting

**Backend không start:**
- Kiểm tra Python version: `python --version` (cần 3.10+)
- Đảm bảo đã activate venv — dấu `(.venv)` phải hiện ở đầu terminal
- Kiểm tra file `.env` đã tồn tại trong `backend/`

**App báo "Không thể kết nối server":**
- Đảm bảo `uvicorn` đang chạy và không có lỗi
- Android thật: bắt buộc dùng `--dart-define=BASE_URL=http://<IP-LAN>:8000/api/v1`
- Kiểm tra firewall không chặn port 8000

**TFLite không hoạt động:**
- TFLite chỉ chạy trên Android/iOS, không chạy trên Web
- Kiểm tra `mobile/assets/models/crack_model.tflite` tồn tại

**Flutter lỗi khi build:**
- Chạy `flutter doctor` để kiểm tra môi trường
- Windows: kiểm tra `ANDROID_HOME` được set đúng
- macOS/iOS: đảm bảo Xcode và CocoaPods đã cài đặt

**Model AI load lâu lần đầu:**
- Bình thường — TensorFlow JIT compile mất ~7s khi server mới khởi động
- Các request sau chỉ mất ~0.5s (warmup tự động khi load model)

---

## Trạng Thái Dự Án

- [x] Database schema & ERD
- [x] Backend — Auth API (register / login / refresh / logout / me)
- [x] Backend — AI Service (MobileNetV2 + texture pre-filter + vision scorer)
- [x] Backend — Scan API + History API
- [x] Huấn luyện & so sánh MobileNetV1, V2, V3Small (accuracy > 99%)
- [x] TFLite conversion (`crack_model.tflite` — 2.41 MB, sai số < 1.3%)
- [x] Flutter — Auth screens (login / register)
- [x] Flutter — Scanner (camera + gallery + online/offline AI + auto fallback)
- [x] Flutter — Result screen (kết quả chi tiết, cảnh báo texture)
- [x] Flutter — History screen (danh sách + chi tiết + ghi chú)
- [x] Flutter — Settings (offline mode, dark mode, ngôn ngữ)
- [x] Đa ngôn ngữ Tiếng Việt / Tiếng Anh
- [ ] Build APK release & test thiết bị thật
- [ ] Deploy backend lên server production

---

## Tài Liệu

- [API Spec](docs/API_SPEC.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Database ERD](database/ERD.md)
- [Roadmap](docs/ROADMAP.md)
- [Báo cáo đồ án](docs/Baocao_AI-Mobile.docx)

---

*Đồ án tốt nghiệp — Trường Đại học Đại Nam — 2026*
