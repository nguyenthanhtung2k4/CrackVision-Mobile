"""
Train texture classifier: concrete vs non_concrete
Uses MobileNetV2 pretrained on ImageNet — fine-tune top layers only.

Dataset structure expected:
  AI_model/texture_dataset/
      concrete/       ← ảnh tường, bê tông, đá, vữa (có hoặc không có crack)
      non_concrete/   ← ảnh logo, poster, người, phong cảnh, text, screenshot

Output: AI_model/texture_classifier.keras

Run from repo root:
  python AI_model/train_texture_classifier.py
"""
import os, sys
os.environ['TF_ENABLE_ONEDNN_OPTS'] = '0'
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '2'

from pathlib import Path
import numpy as np

SCRIPT_DIR   = Path(__file__).parent
DATASET_DIR  = SCRIPT_DIR / "texture_dataset"
OUTPUT_PATH  = SCRIPT_DIR / "texture_classifier.keras"
IMG_SIZE     = (224, 224)
BATCH_SIZE   = 16
EPOCHS_HEAD  = 10   # train only top layers
EPOCHS_FINE  = 5    # unfreeze last 20 layers and fine-tune

# ── Validate dataset ──────────────────────────────────────────
for cls in ("concrete", "non_concrete"):
    d = DATASET_DIR / cls
    if not d.exists():
        print(f"[ERROR] Missing: {d}")
        print("        Run: python AI_model/build_texture_dataset.py  first")
        sys.exit(1)
    count = len(list(d.glob("*.jpg")) + list(d.glob("*.png")) + list(d.glob("*.jpeg")))
    print(f"[INFO] {cls}: {count} images")
    if count < 20:
        print(f"[WARN] Too few images in {cls} — need at least 20")

import keras
import tensorflow as tf

print(f"[INFO] Keras {keras.__version__} | TF {tf.__version__}")

# ── Data pipeline ─────────────────────────────────────────────
train_ds = keras.utils.image_dataset_from_directory(
    DATASET_DIR,
    validation_split=0.2,
    subset="training",
    seed=42,
    image_size=IMG_SIZE,
    batch_size=BATCH_SIZE,
    label_mode="binary",
    class_names=["concrete", "non_concrete"],
)
val_ds = keras.utils.image_dataset_from_directory(
    DATASET_DIR,
    validation_split=0.2,
    subset="validation",
    seed=42,
    image_size=IMG_SIZE,
    batch_size=BATCH_SIZE,
    label_mode="binary",
    class_names=["concrete", "non_concrete"],
)

print(f"[INFO] Classes: {train_ds.class_names}")
print(f"       concrete=0  non_concrete=1")

# Prefetch for performance
AUTOTUNE = tf.data.AUTOTUNE
train_ds = train_ds.prefetch(AUTOTUNE)
val_ds   = val_ds.prefetch(AUTOTUNE)

# ── Augmentation (only on training) ──────────────────────────
augment = keras.Sequential([
    keras.layers.RandomFlip("horizontal"),
    keras.layers.RandomRotation(0.1),
    keras.layers.RandomZoom(0.1),
    keras.layers.RandomBrightness(0.15),
], name="augmentation")

# ── Build model ───────────────────────────────────────────────
# MobileNetV2 pretrained — freeze all base layers first
base = keras.applications.MobileNetV2(
    input_shape=(*IMG_SIZE, 3),
    include_top=False,
    weights="imagenet",
    pooling="avg",
)
base.trainable = False

inputs  = keras.Input(shape=(*IMG_SIZE, 3))
x       = augment(inputs)
x       = keras.applications.mobilenet_v2.preprocess_input(x)
x       = base(x, training=False)
x       = keras.layers.Dropout(0.3)(x)
outputs = keras.layers.Dense(1, activation="sigmoid", name="texture_output")(x)
model   = keras.Model(inputs, outputs, name="texture_classifier")

model.summary(print_fn=lambda s: print(" ", s))

# ── Phase 1: Train head only ──────────────────────────────────
print(f"\n[PHASE 1] Training head ({EPOCHS_HEAD} epochs)...")
model.compile(
    optimizer=keras.optimizers.Adam(1e-3),
    loss="binary_crossentropy",
    metrics=["accuracy"],
)
history1 = model.fit(
    train_ds,
    validation_data=val_ds,
    epochs=EPOCHS_HEAD,
    callbacks=[
        keras.callbacks.EarlyStopping(patience=3, restore_best_weights=True, monitor="val_accuracy"),
    ],
    verbose=1,
)

# ── Phase 2: Fine-tune last 20 base layers ────────────────────
print(f"\n[PHASE 2] Fine-tuning last 20 layers ({EPOCHS_FINE} epochs)...")
base.trainable = True
for layer in base.layers[:-20]:
    layer.trainable = False

model.compile(
    optimizer=keras.optimizers.Adam(1e-5),   # much lower lr
    loss="binary_crossentropy",
    metrics=["accuracy"],
)
history2 = model.fit(
    train_ds,
    validation_data=val_ds,
    epochs=EPOCHS_FINE,
    callbacks=[
        keras.callbacks.EarlyStopping(patience=3, restore_best_weights=True, monitor="val_accuracy"),
    ],
    verbose=1,
)

# ── Save ──────────────────────────────────────────────────────
model.save(str(OUTPUT_PATH))
print(f"\n[DONE] Saved: {OUTPUT_PATH}")
size_mb = OUTPUT_PATH.stat().st_size / 1024 / 1024
print(f"       Size: {size_mb:.1f} MB")

# ── Quick eval ────────────────────────────────────────────────
loss, acc = model.evaluate(val_ds, verbose=0)
print(f"       Val accuracy: {acc*100:.1f}%  |  Val loss: {loss:.4f}")
print()
print("Next step: restart backend — texture_classifier.keras will be loaded automatically.")
