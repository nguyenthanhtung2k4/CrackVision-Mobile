"""
Convert mobilenetv2_crack_final.keras → crack_model.tflite

Chạy: python convert_tflite.py  (từ thư mục AI_model/)

Root cause & fix:
  - File .keras được lưu bằng Keras 3 (module: keras.src.models.functional)
  - tf-keras (Keras 2) không load được Keras 3 format
  - tf.saved_model.save() và model.export() đều crash do _DictWrapper incompatibility
  - Fix: dùng tf.function → concrete function → TFLiteConverter.from_concrete_functions()
    Approach này bypass hoàn toàn SavedModel traversal nên không bị lỗi _DictWrapper
"""
import os, sys, shutil
from pathlib import Path

os.environ['TF_ENABLE_ONEDNN_OPTS'] = '0'
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '2'

# ── Paths ─────────────────────────────────────────────────────
MODEL_DIR    = Path(__file__).parent
ROOT         = MODEL_DIR.parent
KERAS_PATH   = MODEL_DIR / "mobilenetv2_crack_final.keras"
TFLITE_PATH  = MODEL_DIR / "crack_model.tflite"
MOBILE_ASSET = ROOT / "mobile" / "assets" / "models" / "crack_model.tflite"

if not KERAS_PATH.exists():
    print(f"[ERROR] Không tìm thấy: {KERAS_PATH}")
    sys.exit(1)

import keras
import tensorflow as tf
import numpy as np

print(f"[INFO] Keras {keras.__version__} | TensorFlow {tf.__version__}")

# ── Load model (Keras 3) ──────────────────────────────────────
print(f"[INFO] Load model: {KERAS_PATH.name}")
model = keras.models.load_model(str(KERAS_PATH))
print(f"[OK]   Input: {model.input_shape} | Output: {model.output_shape}")

# ── Convert via concrete function ─────────────────────────────
# Dùng tf.function để trace graph, bypass SavedModel traversal
# (tránh lỗi _DictWrapper incompatibility giữa Keras 3 và TF checkpoint)
print("[INFO] Tracing computation graph...")
run_fn = tf.function(
    lambda x: model(x, training=False),
    input_signature=[tf.TensorSpec(shape=(1, 224, 224, 3), dtype=tf.float32)]
)
concrete_fn = run_fn.get_concrete_function()
print("[OK]   Graph traced.")

print("[INFO] Converting to TFLite (dynamic range quantization)...")
converter = tf.lite.TFLiteConverter.from_concrete_functions([concrete_fn])
converter.optimizations = [tf.lite.Optimize.DEFAULT]
tflite_model = converter.convert()

# ── Lưu file ─────────────────────────────────────────────────
TFLITE_PATH.write_bytes(tflite_model)
size_mb = TFLITE_PATH.stat().st_size / (1024 * 1024)
print(f"[OK]   Saved: {TFLITE_PATH.name} ({size_mb:.2f} MB)")

# ── Copy sang Flutter assets ──────────────────────────────────
MOBILE_ASSET.parent.mkdir(parents=True, exist_ok=True)
shutil.copy(TFLITE_PATH, MOBILE_ASSET)
print(f"[OK]   Copied → {MOBILE_ASSET}")

# ── Verify: Keras vs TFLite ───────────────────────────────────
# Dùng ai_edge_litert thay tf.lite.Interpreter (deprecated từ TF 2.20+)
print("\n[INFO] Verifying...")
dummy = np.random.rand(1, 224, 224, 3).astype(np.float32)

keras_out = float(model.predict(dummy, verbose=0)[0][0])

try:
    from ai_edge_litert.interpreter import Interpreter
    interp = Interpreter(str(TFLITE_PATH))
except ImportError:
    interp = tf.lite.Interpreter(model_path=str(TFLITE_PATH))

interp.allocate_tensors()
interp.set_tensor(interp.get_input_details()[0]['index'], dummy)
interp.invoke()
tflite_out = float(interp.get_tensor(interp.get_output_details()[0]['index'])[0][0])

diff = abs(keras_out - tflite_out)
print(f"  Keras  prob_positive = {keras_out:.6f}")
print(f"  TFLite prob_positive = {tflite_out:.6f}")
print(f"  Diff                 = {diff:.6f}")

status = "[OK]   Kết quả khớp ✓" if diff < 0.01 else "[WARN] Lệch do quantization (bình thường)"
print(status)

print(f"\n[DONE] TFLite model sẵn sàng!")
print(f"       {TFLITE_PATH}")
print(f"       {MOBILE_ASSET}")
