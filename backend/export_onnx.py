"""
Convertit clothing_model.h5 → clothing_model.onnx (sans réentraîner).
Utilise la CLI tf2onnx (compatible toutes versions).

Exécuter depuis le dossier backend/ :
    python export_onnx.py
"""
import shutil
import subprocess
import sys
import tensorflow as tf

print("Chargement de clothing_model.h5...")
model = tf.keras.models.load_model("clothing_model.h5")
print(f"  Modèle chargé — {model.count_params():,} paramètres")

# Sauvegarder en format SavedModel
saved_dir = "_tmp_savedmodel"
print("Export SavedModel temporaire...")
tf.saved_model.save(model, saved_dir)

# Conversion via CLI tf2onnx 
print("Conversion ONNX (opset 13)...")
result = subprocess.run(
    [sys.executable, "-m", "tf2onnx.convert",
     "--saved-model", saved_dir,
     "--output", "clothing_model.onnx",
     "--opset", "13"],
    capture_output=True, text=True,
)
print(result.stdout)
if result.returncode != 0:
    print("ERREUR :", result.stderr)
    sys.exit(1)

shutil.rmtree(saved_dir)
print("\n✅ clothing_model.onnx généré avec succès !")
print("   Lance le serveur : python -m uvicorn app.main:app --reload")
