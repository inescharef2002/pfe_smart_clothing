import tensorflow as tf
import tf2onnx
import sys

print("Chargement clothing_model_v2.h5...")
model = tf.keras.models.load_model("clothing_model_v2.h5")
print("Modèle chargé ✅")

print("Export ONNX...")
spec = (tf.TensorSpec((None, 96, 96, 3), tf.float32, name="input"),)

model_proto, _ = tf2onnx.convert.from_keras(
    model,
    input_signature=spec,
    opset=13,
    output_path="clothing_model_v2.onnx"
)
print("✅ clothing_model_v2.onnx créé avec succès !")
input("Appuie sur Entrée pour fermer...")