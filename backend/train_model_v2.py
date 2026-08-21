import traceback
import sys

print("Python:", sys.version)
print("Démarrage du script...")

try:
    import cv2
    import numpy as np
    import tensorflow as tf
    from tensorflow import keras
    import tf2onnx
    import onnx
    import shutil
    print("Tous les imports OK ✅")
    print("="*50)

    CATEGORIES = [
        "T-shirts",    # 0
        "Pantalons",   # 1
        "Pulls",       # 2
        "Robes",       # 3
        "Vestes",      # 4
        "Chaussures",  # 5
        "Chemises",    # 6
        "Accessoires", # 7
        "Jupes",       # 8
    ]

    NUM_CLASSES  = len(CATEGORIES)
    IMG_SIZE     = 96
    BATCH_SIZE   = 32
    EPOCHS_P1    = 10
    EPOCHS_P2    = 15

    FMNIST_MAP = {0:0, 1:1, 2:2, 3:3, 4:4, 5:5, 6:6, 7:5, 8:7, 9:5}

    # ── 1. Chargement Fashion-MNIST ──────────────────────────────────────────
    print("\nChargement Fashion-MNIST...")
    (x_train_raw, y_train_raw), (x_test_raw, y_test_raw) = \
        keras.datasets.fashion_mnist.load_data()
    print(f"  Train: {len(x_train_raw)} | Test: {len(x_test_raw)}")

    y_train = np.array([FMNIST_MAP[y] for y in y_train_raw], dtype=np.int32)
    y_test  = np.array([FMNIST_MAP[y] for y in y_test_raw],  dtype=np.int32)

    # ── 2. Pipeline tf.data ──────────────────────────────────────────────────
    print("\nCréation du pipeline tf.data...")

    def preprocess_sample(image, label):
        image = tf.cast(image, tf.float32)
        image = tf.expand_dims(image, -1)
        image = tf.image.resize(image, [IMG_SIZE, IMG_SIZE])
        image = tf.repeat(image, 3, axis=-1)
        image = (image / 127.5) - 1.0
        return image, label

    def make_dataset(x, y, shuffle=False):
        ds = tf.data.Dataset.from_tensor_slices((x, y))
        if shuffle:
            ds = ds.shuffle(10000, seed=42)
        ds = ds.map(preprocess_sample, num_parallel_calls=tf.data.AUTOTUNE)
        ds = ds.batch(BATCH_SIZE)
        ds = ds.prefetch(tf.data.AUTOTUNE)
        return ds

    val_size   = int(len(x_train_raw) * 0.1)
    x_val_raw  = x_train_raw[:val_size]
    y_val      = y_train[:val_size]
    x_tr_raw   = x_train_raw[val_size:]
    y_tr       = y_train[val_size:]

    train_ds = make_dataset(x_tr_raw,   y_tr,   shuffle=True)
    val_ds   = make_dataset(x_val_raw,  y_val,  shuffle=False)
    test_ds  = make_dataset(x_test_raw, y_test, shuffle=False)

    print(f"  Train: {len(x_tr_raw)} | Val: {val_size} | Test: {len(x_test_raw)}")

    # ── 3. Architecture MobileNetV2 ──────────────────────────────────────────
    print("\nConstruction du modèle MobileNetV2...")
    base_model = keras.applications.MobileNetV2(
        input_shape=(IMG_SIZE, IMG_SIZE, 3),
        include_top=False,
        weights="imagenet",
    )
    base_model.trainable = False

    inputs  = keras.Input(shape=(IMG_SIZE, IMG_SIZE, 3))
    x       = base_model(inputs, training=False)
    x       = keras.layers.GlobalAveragePooling2D()(x)
    x       = keras.layers.BatchNormalization()(x)
    x       = keras.layers.Dense(256, activation="relu")(x)
    x       = keras.layers.Dropout(0.4)(x)
    x       = keras.layers.Dense(128, activation="relu")(x)
    x       = keras.layers.Dropout(0.3)(x)
    outputs = keras.layers.Dense(NUM_CLASSES, activation="softmax")(x)
    model   = keras.Model(inputs, outputs, name="clothing_mobilenetv2")

    model.summary()

    # ── 4. Phase 1 : Entraînement classifier ─────────────────────────────────
    print("\nPhase 1 : Entraînement du classifier (backbone gelé)...")
    model.compile(
        optimizer=keras.optimizers.Adam(learning_rate=1e-3),
        loss="sparse_categorical_crossentropy",
        metrics=["accuracy"],
    )

    callbacks_p1 = [
        keras.callbacks.EarlyStopping(
            monitor="val_accuracy", patience=3,
            restore_best_weights=True, verbose=1),
        keras.callbacks.ReduceLROnPlateau(
            monitor="val_loss", patience=2, factor=0.5, verbose=1),
    ]

    model.fit(
        train_ds,
        epochs=EPOCHS_P1,
        validation_data=val_ds,
        callbacks=callbacks_p1,
        verbose=1,
    )

    # ── 5. Phase 2 : Fine-tuning ─────────────────────────────────────────────
    print("\nPhase 2 : Fine-tuning (dégeler les 30 dernières couches)...")
    base_model.trainable = True
    for layer in base_model.layers[:-30]:
        layer.trainable = False

    model.compile(
        optimizer=keras.optimizers.Adam(learning_rate=1e-5),
        loss="sparse_categorical_crossentropy",
        metrics=["accuracy"],
    )

    callbacks_p2 = [
        keras.callbacks.EarlyStopping(
            monitor="val_accuracy", patience=4,
            restore_best_weights=True, verbose=1),
        keras.callbacks.ReduceLROnPlateau(
            monitor="val_loss", patience=2, factor=0.3, verbose=1),
    ]

    model.fit(
        train_ds,
        epochs=EPOCHS_P2,
        validation_data=val_ds,
        callbacks=callbacks_p2,
        verbose=1,
    )

    # ── 6. Évaluation ────────────────────────────────────────────────────────
    print("\nÉvaluation...")
    loss, acc = model.evaluate(test_ds, verbose=0)
    print(f"\n✅ Précision finale : {acc:.1%}")

    preds_list, labels_list = [], []
    for batch_x, batch_y in test_ds:
        p = model.predict(batch_x, verbose=0)
        preds_list.extend(np.argmax(p, axis=1))
        labels_list.extend(batch_y.numpy())

    preds  = np.array(preds_list)
    labels = np.array(labels_list)

    print("\nPrécision par catégorie :")
    for idx, label in enumerate(CATEGORIES):
        mask = labels == idx
        if mask.sum() == 0:
            continue
        cat_acc = (preds[mask] == labels[mask]).mean()
        print(f"  {label:14s} : {cat_acc:.1%}  ({mask.sum()} images)")

    # ── 7. Sauvegarde H5 ─────────────────────────────────────────────────────
    model.save("clothing_model_v2.h5")
    print("\n📦 Modèle H5 → clothing_model_v2.h5")

    # ── 8. Export ONNX ────────────────────────────────────────────────────────
    print("\nExport ONNX...")
    try:
        # Méthode 1 : via CLI tf2onnx (plus compatible)
        import subprocess
        saved_dir = "_tmp_savedmodel_v2"
        tf.saved_model.save(model, saved_dir)
        result = subprocess.run(
            [sys.executable, "-m", "tf2onnx.convert",
             "--saved-model", saved_dir,
             "--output", "clothing_model_v2.onnx",
             "--opset", "13"],
            capture_output=True, text=True
        )
        print(result.stdout)
        if result.returncode != 0:
            print("Erreur CLI:", result.stderr)
            raise Exception("CLI échouée")
        if os.path.exists(saved_dir):
            shutil.rmtree(saved_dir)
        print("📦 Modèle ONNX → clothing_model_v2.onnx ✅")

    except Exception as e1:
        print(f"Méthode CLI échouée : {e1}")
        try:
            # Méthode 2 : tf2onnx.convert.from_keras
            spec = (tf.TensorSpec(
                (None, IMG_SIZE, IMG_SIZE, 3),
                tf.float32, name="input"),)
            model_proto, _ = tf2onnx.convert.from_keras(
                model,
                input_signature=spec,
                opset=13,
                output_path="clothing_model_v2.onnx"
            )
            print("📦 Modèle ONNX → clothing_model_v2.onnx ✅")

        except Exception as e2:
            print(f"Méthode from_keras échouée : {e2}")
            try:
                # Méthode 3 : sauvegarder en .keras
                model.save("clothing_model_v2.keras")
                print("📦 Modèle Keras → clothing_model_v2.keras")
                print("Lance manuellement dans le terminal :")
                print("python -m tf2onnx.convert --keras clothing_model_v2.keras "
                      "--output clothing_model_v2.onnx --opset 13")
            except Exception as e3:
                print(f"Toutes les méthodes ont échoué : {e3}")

    print("\n🎉 Entraînement terminé !")
    print(f"   Précision : {acc:.1%}")
    print("   Relance le serveur FastAPI.")

except Exception as e:
    print("\n❌ ERREUR :", e)
    traceback.print_exc()

input("\nAppuie sur Entrée pour fermer...")