"""
Script d'entraînement du classifieur de vêtements.
Dataset  : Fashion-MNIST (70 000 images, 10 catégories de vêtements)
Modèle   : CNN personnalisé (compatible CPU, ~85% précision)
Sortie   : backend/clothing_model.onnx  (+ clothing_model.h5 de sauvegarde)

Exécution (une seule fois, sur la machine de développement) :
    cd backend
    pip install tensorflow tf2onnx onnx
    python train_model.py
"""

import cv2
import numpy as np
import tensorflow as tf
from tensorflow import keras

print(f"TensorFlow {tf.__version__}")

#  Mappage Fashion-MNIST 
# 0 T-shirt/top | 1 Trouser | 2 Pullover | 3 Dress | 4 Coat
# 5 Sandal      | 6 Shirt   | 7 Sneaker  | 8 Bag   | 9 Ankle boot
LABELS = ["T-shirts", "Pantalons", "Pulls", "Robes", "Vestes",
          "Chaussures", "Chemises", "Chaussures", "Accessoires", "Chaussures"]

IMG_SIZE = 64   
# résolution d'entrée du CNN

#  1. Chargement des données 
print("Chargement Fashion-MNIST...")
(x_train, y_train), (x_test, y_test) = keras.datasets.fashion_mnist.load_data()
print(f"  Train : {len(x_train)} images | Test : {len(x_test)} images")


def preprocess(images: np.ndarray) -> np.ndarray:
    """28×28 grayscale → 64×64 RGB normalisé."""
    result = np.empty((len(images), IMG_SIZE, IMG_SIZE, 3), dtype=np.float32)
    for i, img in enumerate(images):
        resized = cv2.resize(img, (IMG_SIZE, IMG_SIZE))
        normalized = resized.astype(np.float32) / 255.0
        result[i] = np.stack([normalized] * 3, axis=-1)
    return result


print("Prétraitement des images...")
x_train_p = preprocess(x_train)
x_test_p  = preprocess(x_test)

# 2. Architecture CNN 
print("Construction du modèle CNN...")
model = keras.Sequential([
    keras.layers.Input(shape=(IMG_SIZE, IMG_SIZE, 3)),

    # Bloc 1
    keras.layers.Conv2D(32, (3, 3), activation="relu", padding="same"),
    keras.layers.BatchNormalization(),
    keras.layers.MaxPooling2D(2, 2),

    # Bloc 2
    keras.layers.Conv2D(64, (3, 3), activation="relu", padding="same"),
    keras.layers.BatchNormalization(),
    keras.layers.MaxPooling2D(2, 2),

    # Bloc 3
    keras.layers.Conv2D(128, (3, 3), activation="relu", padding="same"),
    keras.layers.BatchNormalization(),
    keras.layers.MaxPooling2D(2, 2),

    # Classificateur
    keras.layers.GlobalAveragePooling2D(),
    keras.layers.Dense(256, activation="relu"),
    keras.layers.Dropout(0.4),
    keras.layers.Dense(10, activation="softmax"),
], name="clothing_cnn")

model.summary()

# 3. Entraînement 
model.compile(
    optimizer=keras.optimizers.Adam(learning_rate=1e-3),
    loss="sparse_categorical_crossentropy",
    metrics=["accuracy"],
)

callbacks = [
    keras.callbacks.EarlyStopping(monitor="val_accuracy", patience=3,
                                  restore_best_weights=True, verbose=1),
    keras.callbacks.ReduceLROnPlateau(monitor="val_loss", patience=2,
                                      factor=0.5, verbose=1),
]

print("\nEntraînement en cours...")
history = model.fit(
    x_train_p, y_train,
    epochs=20,
    batch_size=64,
    validation_split=0.1,
    callbacks=callbacks,
    verbose=1,
)

#  4. Évaluation 
loss, acc = model.evaluate(x_test_p, y_test, verbose=0)
print(f"\n✅ Précision sur le jeu de test : {acc:.1%}")

preds = np.argmax(model.predict(x_test_p, verbose=0), axis=1)
print("\nPrécision par catégorie :")
for idx, label in enumerate(LABELS):
    mask = y_test == idx
    if mask.sum() == 0:
        continue
    cat_acc = (preds[mask] == y_test[mask]).mean()
    print(f"  {label:12s} (classe {idx}) : {cat_acc:.1%}")

#  5. Sauvegarde H5  
model.save("clothing_model.h5")
print("\n📦 Modèle H5 sauvegardé → backend/clothing_model.h5")

#  6. Export ONNX 
print("\nExport ONNX en cours...")
try:
    import tf2onnx
    import onnx

    # from_keras incompatible Keras 3.x → passer par SavedModel
    import shutil
    saved_dir = "_tmp_savedmodel"
    tf.saved_model.save(model, saved_dir)
    model_proto, _ = tf2onnx.convert.from_saved_model(saved_dir, opset=13)
    onnx.save(model_proto, "clothing_model.onnx")
    shutil.rmtree(saved_dir)
    print("📦 Modèle ONNX sauvegardé → backend/clothing_model.onnx")
    print("   Le serveur FastAPI utilisera ce fichier (onnxruntime, ~15 MB).")
except ImportError:
    print("⚠️  tf2onnx / onnx non installés — export ONNX ignoré.")
    print("   Installe avec : pip install tf2onnx onnx")
    print("   Le serveur utilisera clothing_model.h5 en dernier recours.")
