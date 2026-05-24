"""
Build texture_dataset/ từ 2 nguồn:
  1. Ảnh uploads/ của user (đã biết nhãn qua DB hoặc tên file)
  2. Ảnh trong TEST_IMG/ (non_concrete — ảnh không liên quan bê tông)
  3. Ảnh crack dataset có sẵn trong AI_model/ (concrete)

Sau khi chạy xong:
  texture_dataset/
      concrete/      (ảnh bê tông — có hoặc không crack)
      non_concrete/  (ảnh không liên quan)

Run: python AI_model/build_texture_dataset.py
"""
import os, shutil, sys, urllib.request
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'

from pathlib import Path
from PIL import Image
from io import BytesIO

SCRIPT_DIR    = Path(__file__).parent
REPO_ROOT     = SCRIPT_DIR.parent
DATASET_DIR   = SCRIPT_DIR / "texture_dataset"
CONCRETE_DIR  = DATASET_DIR / "concrete"
NON_CON_DIR   = DATASET_DIR / "non_concrete"
TEST_IMG_DIR  = REPO_ROOT / "TEST_IMG"
UPLOADS_DIR   = REPO_ROOT / "backend" / "uploads"

CONCRETE_DIR.mkdir(parents=True, exist_ok=True)
NON_CON_DIR.mkdir(parents=True, exist_ok=True)


def copy_img(src: Path, dst_dir: Path, stem_prefix: str = "") -> bool:
    """Copy image to dst_dir, skip if unreadable."""
    try:
        img = Image.open(src)
        if img.mode != "RGB":
            img = img.convert("RGB")
        dst = dst_dir / f"{stem_prefix}{src.stem}.jpg"
        # avoid overwrite
        i = 1
        while dst.exists():
            dst = dst_dir / f"{stem_prefix}{src.stem}_{i}.jpg"
            i += 1
        img.save(dst, "JPEG", quality=90)
        return True
    except Exception as e:
        print(f"  [skip] {src.name}: {e}")
        return False


def count(d: Path) -> int:
    return len(list(d.glob("*.jpg")) + list(d.glob("*.png")) + list(d.glob("*.jpeg")))


# ── SOURCE 1: TEST_IMG → non_concrete ────────────────────────
print("=== Source 1: TEST_IMG/ → non_concrete ===")
if TEST_IMG_DIR.exists():
    imgs = list(TEST_IMG_DIR.glob("*.jpg")) + list(TEST_IMG_DIR.glob("*.png")) + list(TEST_IMG_DIR.glob("*.jpeg"))
    added = 0
    for img in imgs:
        if copy_img(img, NON_CON_DIR, "testimg_"):
            added += 1
    print(f"  Added {added} images from TEST_IMG/")
else:
    print(f"  [skip] TEST_IMG/ not found")


# ── SOURCE 2: Uploads → non_concrete (ảnh ko phải bê tông) ───
# Các ảnh này user đã test với nội dung không phải bê tông
# Danh sách file name pattern nhận ra từ log:
NON_CONCRETE_FILENAMES = {
    "zenlish",      # TOEIC poster
    "thanh_trung", "thanh trung", "logo",  # logo
    "lephì", "lephi",                       # chân dung
    "choi",                                 # ảnh sinh hoạt
    "tgian",                                # screenshot
    "hanhtrinh",                            # non-concrete
}

print("\n=== Source 2: uploads/ → non_concrete (by filename pattern) ===")
added = 0
if UPLOADS_DIR.exists():
    for img in UPLOADS_DIR.rglob("*.jpg"):
        # uploads có tên UUID — dùng image_filename từ tên pattern nếu biết
        # Chỉ copy nếu file nhỏ (< 500KB) — ảnh bê tông thường lớn hơn
        # Đây là heuristic; người dùng có thể tự thêm vào sau
        pass
    print(f"  [info] uploads/ chứa UUIDs — khó detect tự động, bỏ qua")
    print(f"         Hãy tự copy ảnh non-concrete vào: {NON_CON_DIR}")
else:
    print(f"  [skip] uploads/ not found")


# ── SOURCE 3: Download concrete samples từ internet ──────────
CONCRETE_URLS = [
    # Ảnh bề mặt bê tông không nứt (public domain / CC0)
    "https://upload.wikimedia.org/wikipedia/commons/thumb/b/b9/Above_Gotham.jpg/640px-Above_Gotham.jpg",
    "https://upload.wikimedia.org/wikipedia/commons/thumb/3/3f/Bikeleg.jpg/640px-Bikeleg.jpg",
]

# Thay vì download từ internet (có thể bị block), hướng dẫn dùng ảnh local
print("\n=== Source 3: Concrete images ===")
print(f"  [info] Copy ảnh bê tông/tường vào: {CONCRETE_DIR}")
print(f"         Ví dụ: ảnh từ uploads/ của các scan bê tông thật")

# Copy các ảnh upload có model_prob cao (bê tông thật) vào concrete/
# Danh sách UUID từ phân tích trước — model_prob >= 0.8 (rất chắc là bê tông)
CONFIRMED_CONCRETE_UUIDS = [
    "09b45f85-4687-43e9-9ac5-0fa1c3257f82",  # model=1.0
    "12512e25-2bf3-4b7a-b72b-e9a982db699b",  # model=1.0
    "2996a179-72fc-4241-810f-91aadf8420eb",  # model=1.0
    "3142b406-6f79-43ec-86a1-88af2e717ab7",  # model=0.9999
    "4fb80222-4ecd-454c-b769-eb4fc139feb4",  # model=0.9999
    "506dd8f1-5c9d-4e3b-a2d1-de89ba94562a",  # model=1.0
    "9a78b270-0e49-47f2-b147-6101e9dbf106",  # model=1.0
    "a5fd3c94-4b65-4872-bf7f-3c66ac8c0185",  # model=0.9963
    "1b31d05e-0260-482d-bbbe-cd92e9d39525",  # model=0.9287
    "619fd631-09a0-4775-802d-9e4af12bbff0",  # model=0.9976
    "eeea16b7-a32b-409a-b954-5ec628c329a3",  # model=1.0
    "fd6a5644-afb1-43c9-90a4-cf70b79ba83e",  # model=1.0
    "29442ba9-b119-4c0d-ac0d-42d91a8aa515",  # model=0.9963
    "b0c19d1a-9302-4ff5-bc98-36668a30c55d",  # model=0.9942
    "09a23949-81ec-4a3d-a734-98c1da0391f5",  # model=0.8367
    "1a1d20e6-86e6-47a7-87ac-367a23263908",  # model=0.8367
    "fbbd567d-57c2-4f6d-912b-76b5600067e7",  # model=0.8367
    "b7a5714b-2c2b-4d40-b936-b1e07d9f246a",  # model=0.8367
    "1748fa39-df21-424f-b562-4218ded7e85c",  # model=0.9821
]

added_concrete = 0
if UPLOADS_DIR.exists():
    for uuid in CONFIRMED_CONCRETE_UUIDS:
        for ext in ("jpg", "png"):
            src = next(UPLOADS_DIR.rglob(f"{uuid}.{ext}"), None)
            if src and src.exists():
                if copy_img(src, CONCRETE_DIR, "crack_"):
                    added_concrete += 1
                break
    print(f"  Added {added_concrete} confirmed-concrete images from uploads/")

# ── SOURCE 4: Non-concrete từ uploads đã biết ─────────────────
CONFIRMED_NON_CONCRETE_UUIDS = [
    "b6cdb0be-0562-4ea5-8470-3bdfb4fcc065",  # ZENLISH poster
    "34edd2a4-6769-4ad0-97e1-2ff896b0ebff",  # Logo Thành Trung
]
print("\n=== Source 4: Known non-concrete from uploads ===")
added_non = 0
if UPLOADS_DIR.exists():
    for uuid in CONFIRMED_NON_CONCRETE_UUIDS:
        for ext in ("jpg", "png"):
            src = next(UPLOADS_DIR.rglob(f"{uuid}.{ext}"), None)
            if src and src.exists():
                if copy_img(src, NON_CON_DIR, "noncrete_"):
                    added_non += 1
                break
    print(f"  Added {added_non} known non-concrete images")

# ── Summary ───────────────────────────────────────────────────
n_concrete  = count(CONCRETE_DIR)
n_non       = count(NON_CON_DIR)
print(f"\n{'='*50}")
print(f"Dataset summary:")
print(f"  concrete/     : {n_concrete} images  →  {CONCRETE_DIR}")
print(f"  non_concrete/ : {n_non} images  →  {NON_CON_DIR}")
print()

MIN_PER_CLASS = 30
if n_concrete < MIN_PER_CLASS or n_non < MIN_PER_CLASS:
    print(f"[WARN] Cần ít nhất {MIN_PER_CLASS} ảnh mỗi class để train tốt.")
    print()
    if n_concrete < MIN_PER_CLASS:
        print(f"  → Thêm ảnh bê tông vào: {CONCRETE_DIR}")
        print(f"    (Gợi ý: Google 'concrete surface texture' → lưu ảnh vào đó)")
    if n_non < MIN_PER_CLASS:
        print(f"  → Thêm ảnh non-concrete vào: {NON_CON_DIR}")
        print(f"    (Ảnh logo, poster, người, phong cảnh, screenshot...)")
    print()
    print("Sau khi thêm ảnh, chạy lại: python AI_model/build_texture_dataset.py")
    print("Rồi train:                  python AI_model/train_texture_classifier.py")
else:
    print(f"[OK] Dataset đủ để train!")
    print(f"     Chạy: python AI_model/train_texture_classifier.py")
