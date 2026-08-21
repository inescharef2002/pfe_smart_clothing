import cv2
import numpy as np
from PIL import Image
import base64
import io
from pathlib import Path
from sklearn.cluster import KMeans
from google import genai
from google.genai import types

# ── Google Gemini API ─────────────────────────────────────────────────────────
GEMINI_API_KEY  = "AIzaSyDqmuzZOLEzRU_F_JBxl-DFl6iG_LW58jQ"
_gemini_client  = genai.Client(api_key=GEMINI_API_KEY)

# ── Catégories acceptées ──────────────────────────────────────────────────────
CATEGORIES_VALIDES = [
    "Robes", "Jupes", "Pantalons", "Chemises",
    "T-shirts", "Pulls", "Vestes", "Chaussures", "Accessoires"
]

# ── Catégories modèle local (fallback) ───────────────────────────────────────
CATEGORIES_V2 = [
    "T-shirts", "Pantalons", "Pulls", "Robes", "Vestes",
    "Chaussures", "Chemises", "Accessoires", "Jupes",
]
CATEGORIES_V1 = [
    "T-shirts", "Pantalons", "Pulls", "Robes", "Vestes",
    "Chaussures", "Chemises", "Chaussures", "Accessoires", "Chaussures",
]

IMG_SIZE_V2          = 96
IMG_SIZE_V1          = 64
CONFIDENCE_THRESHOLD = 0.50

# ── Couleurs ──────────────────────────────────────────────────────────────────
COULEURS = {
    "Noir":         [20, 20, 20],
    "Blanc":        [245, 245, 245],
    "Gris":         [128, 128, 128],
    "Gris clair":   [190, 190, 190],
    "Rouge":        [200, 40, 40],
    "Bordeaux":     [130, 20, 40],
    "Bleu":         [50, 100, 200],
    "Bleu marine":  [20, 40, 100],
    "Vert":         [50, 160, 80],
    "Kaki":         [100, 110, 60],
    "Jaune":        [230, 200, 50],
    "Orange":       [230, 120, 40],
    "Rose":         [230, 120, 160],
    "Violet":       [120, 60, 160],
    "Marron":       [101, 55, 20],
    "Marron foncé": [60, 30, 10],
    "Camel":        [180, 130, 70],
    "Beige":        [210, 180, 140],
    "Crème":        [240, 230, 200],
}

_model_local = None
_is_v2       = False


def _get_local_model():
    global _model_local, _is_v2
    if _model_local is not None:
        return _model_local, _is_v2
    model_v2 = Path(__file__).parent.parent.parent / "clothing_model_v2.onnx"
    model_v1 = Path(__file__).parent.parent.parent / "clothing_model.onnx"
    try:
        import onnxruntime as ort
        if model_v2.exists():
            _model_local = ort.InferenceSession(
                str(model_v2), providers=["CPUExecutionProvider"])
            _is_v2 = True
            print("✅ Modèle MobileNetV2 chargé")
            return _model_local, True
        elif model_v1.exists():
            _model_local = ort.InferenceSession(
                str(model_v1), providers=["CPUExecutionProvider"])
            _is_v2 = False
            return _model_local, False
    except Exception as e:
        print(f"Erreur modèle local : {e}")
    return None, False


def decode_image(image_base64: str) -> np.ndarray:
    if "," in image_base64:
        image_base64 = image_base64.split(",")[1]
    image_bytes = base64.b64decode(image_base64)
    image_pil   = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    try:
        import PIL.ExifTags
        exif = image_pil._getexif()
        if exif:
            for tag, value in exif.items():
                if PIL.ExifTags.TAGS.get(tag) == "Orientation":
                    if value == 3:   image_pil = image_pil.rotate(180, expand=True)
                    elif value == 6: image_pil = image_pil.rotate(270, expand=True)
                    elif value == 8: image_pil = image_pil.rotate(90,  expand=True)
    except Exception:
        pass
    image_pil.thumbnail((800, 800))
    return cv2.cvtColor(np.array(image_pil), cv2.COLOR_RGB2BGR)


def segment_foreground(image: np.ndarray) -> np.ndarray:
    rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB).astype(np.int32)
    white_mask = (rgb[:,:,0]>200) & (rgb[:,:,1]>200) & (rgb[:,:,2]>200)
    gray_mask  = (
        (np.abs(rgb[:,:,0].astype(int)-rgb[:,:,1].astype(int)) < 15) &
        (np.abs(rgb[:,:,1].astype(int)-rgb[:,:,2].astype(int)) < 15) &
        (rgb[:,:,0] > 170)
    )
    bg_mask = (white_mask | gray_mask).astype(np.uint8)
    fg_mask = (1 - bg_mask).astype(np.uint8) * 255
    kernel  = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (15,15))
    fg_mask = cv2.morphologyEx(fg_mask, cv2.MORPH_CLOSE, kernel)
    fg_mask = cv2.morphologyEx(fg_mask, cv2.MORPH_OPEN,  kernel)
    contours, _ = cv2.findContours(
        fg_mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    if not contours:
        return image
    largest = max(contours, key=cv2.contourArea)
    if cv2.contourArea(largest) < 500:
        return image
    x, y, w, h = cv2.boundingRect(largest)
    pad = 15
    x1 = max(0, x-pad); y1 = max(0, y-pad)
    x2 = min(image.shape[1], x+w+pad)
    y2 = min(image.shape[0], y+h+pad)
    crop = image[y1:y2, x1:x2]
    return crop if crop.size > 0 else image


def classify_with_gemini(image: np.ndarray) -> tuple[str | None, float, str | None]:
    """
    Classifie via Google Gemini 2.0 Flash Vision.
    Retourne (categorie, confiance, couleur).
    """
    try:
        # Convertir image en bytes JPEG
        buf = io.BytesIO()
        Image.fromarray(
            cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
        ).save(buf, format="JPEG", quality=90)
        img_bytes = buf.getvalue()

        prompt = """Analyse cette image de vêtement et réponds UNIQUEMENT avec ce JSON :
{
  "categorie": "...",
  "couleur": "...",
  "confiance": 0.95
}

Catégories possibles (choisis une seule) :
Robes, Jupes, Pantalons, Chemises, T-shirts, Pulls, Vestes, Chaussures, Accessoires

Couleurs possibles (choisis une seule) :
Noir, Blanc, Gris, Gris clair, Rouge, Bordeaux, Bleu, Bleu marine, Vert, Kaki, Jaune, Orange, Rose, Violet, Marron, Marron foncé, Camel, Beige, Crème

Règles importantes :
- Robe longue ou courte sur mannequin = Robes
- Blazer avec revers = Vestes
- Pull tricoté ou sweatshirt = Pulls
- Jean ou pantalon = Pantalons
- Chemise boutonnée = Chemises
- T-shirt simple = T-shirts
- Si une personne porte un vêtement, analyser le vêtement principal (ignorer la personne)
- Pour la couleur : couleur dominante du vêtement uniquement (ignorer le fond)
- Marron foncé pour les teintes chocolat/café
- Camel pour les teintes chameau/beige foncé
- Bleu pour les rayures bleues dominantes

Réponds UNIQUEMENT avec le JSON, rien d'autre."""

        response = _gemini_client.models.generate_content(
             model="gemini-2.5-flash",
            contents=[
                types.Part.from_bytes(data=img_bytes, mime_type="image/jpeg"),
                prompt,
            ]
        )
        text = response.text.strip()
        print(f"Gemini réponse : {text}")

        import json
        import re

        json_match = re.search(r'\{[^}]+\}', text, re.DOTALL)
        if not json_match:
            print("Gemini : pas de JSON trouvé")
            return None, 0.0, None

        data      = json.loads(json_match.group())
        categorie = data.get("categorie", "").strip()
        couleur   = data.get("couleur",   "").strip()
        confiance = float(data.get("confiance", 0.8))

        # Valider catégorie
        if categorie not in CATEGORIES_VALIDES:
            for cat in CATEGORIES_VALIDES:
                if cat.lower() in categorie.lower() or \
                   categorie.lower() in cat.lower():
                    categorie = cat
                    break
            else:
                print(f"Gemini catégorie invalide : '{categorie}'")
                return None, 0.0, None

        # Valider couleur
        couleurs_valides = list(COULEURS.keys())
        if couleur not in couleurs_valides:
            couleur_trouvee = None
            for c in couleurs_valides:
                if c.lower() in couleur.lower() or \
                   couleur.lower() in c.lower():
                    couleur_trouvee = c
                    break
            couleur = couleur_trouvee

        print(f"✅ Gemini : {categorie} | {couleur} ({confiance:.1%})")
        return categorie, confiance, couleur

    except Exception as e:
        print(f"Gemini erreur : {e}")
        return None, 0.0, None


def _classify_with_local_model(image: np.ndarray) -> tuple[str | None, float]:
    """Fallback : MobileNetV2 local."""
    session, is_v2 = _get_local_model()
    if session is None:
        return None, 0.0

    if is_v2:
        gray       = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        resized    = cv2.resize(gray, (IMG_SIZE_V2, IMG_SIZE_V2))
        normalized = (resized.astype(np.float32)/255.0 - 0.5) / 0.5
        x          = np.stack([normalized]*3, axis=-1)[np.newaxis]
        categories = CATEGORIES_V2
    else:
        gray       = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        resized    = cv2.resize(gray, (IMG_SIZE_V1, IMG_SIZE_V1))
        normalized = resized.astype(np.float32) / 255.0
        x          = np.stack([normalized]*3, axis=-1)[np.newaxis]
        categories = CATEGORIES_V1

    input_name = session.get_inputs()[0].name
    preds      = session.run(None, {input_name: x})[0][0]
    idx        = int(np.argmax(preds))
    conf       = float(preds[idx])
    categorie  = categories[idx]

    if categorie == "Accessoires" and conf < 0.90:
        sorted_idx  = np.argsort(preds)[::-1]
        second_idx  = int(sorted_idx[1])
        second_conf = float(preds[second_idx])
        second_cat  = categories[second_idx]
        if second_conf >= 0.30 and second_cat != "Accessoires":
            return second_cat, second_conf
        return None, conf

    if conf < CONFIDENCE_THRESHOLD:
        return None, conf

    return categorie, conf


def detect_dominant_color(image: np.ndarray) -> tuple[str, str]:
    h, w    = image.shape[:2]
    mh, mw  = int(h*0.12), int(w*0.12)
    cropped = image[mh:h-mh, mw:w-mw]
    rgb     = cv2.cvtColor(cropped, cv2.COLOR_BGR2RGB)
    pixels  = rgb.reshape(-1, 3).astype(np.float32)

    is_white  = (pixels[:,0]>200)&(pixels[:,1]>200)&(pixels[:,2]>200)
    is_nwhite = (
        (np.abs(pixels[:,0].astype(int)-pixels[:,1].astype(int))<20)&
        (np.abs(pixels[:,1].astype(int)-pixels[:,2].astype(int))<20)&
        (pixels[:,0]>175)
    )
    is_dark  = (pixels[:,0]<10)&(pixels[:,1]<10)&(pixels[:,2]<10)
    mask     = ~(is_white|is_nwhite|is_dark)
    filtered = pixels[mask]

    if len(filtered) < 100: filtered = pixels[~(is_white|is_dark)]
    if len(filtered) < 10:  return "Indéterminé", "#808080"

    k      = min(3, len(filtered))
    kmeans = KMeans(n_clusters=k, n_init=5, random_state=42)
    kmeans.fit(filtered)
    counts   = np.bincount(kmeans.labels_)
    centers  = kmeans.cluster_centers_.astype(int)
    sorted_i = np.argsort(counts)[::-1]
    dom      = centers[sorted_i[0]]
    for i in sorted_i:
        c = centers[i]
        if int(c[0])+int(c[1])+int(c[2]) < 600:
            dom = c
            break

    min_d, nom = float("inf"), "Autre"
    for n, ref in COULEURS.items():
        d = float(np.linalg.norm(dom - np.array(ref)))
        if d < min_d: min_d, nom = d, n

    return nom, "#{:02X}{:02X}{:02X}".format(*dom)


def detect_pattern(image: np.ndarray) -> str:
    gray         = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    edges        = cv2.Canny(gray, 50, 150)
    edge_density = np.sum(edges>0) / edges.size
    if edge_density < 0.05: return "Uni"
    lines = cv2.HoughLinesP(edges, 1, np.pi/180, threshold=50,
                             minLineLength=50, maxLineGap=10)
    if lines is None:
        return "Uni" if edge_density < 0.10 else "Imprimé"
    horizontal = sum(1 for l in lines if abs(l[0][3]-l[0][1])<10)
    vertical   = sum(1 for l in lines if abs(l[0][2]-l[0][0])<10)
    total      = len(lines)
    if horizontal>total*0.4 and vertical>total*0.4: return "À carreaux"
    if horizontal>total*0.5 or vertical>total*0.5:  return "Rayé"
    return "Uni" if edge_density < 0.10 else "Imprimé"


def _content_width(roi: np.ndarray) -> float:
    if roi.size == 0: return 0.0
    edges  = cv2.Canny(roi, 30, 100)
    sums   = np.sum(edges, axis=0)
    active = np.where(sums > 0)[0]
    return float(active[-1]-active[0]) if len(active) >= 2 else float(roi.shape[1])


def _detect_two_legs(gray: np.ndarray) -> bool:
    h, w  = gray.shape
    lower = gray[int(h*0.5):]
    if lower.shape[0] == 0: return False
    score = 0
    bot   = gray[int(h*0.82):]
    if bot.shape[0] > 0:
        cm = np.mean(bot, axis=0).astype(float)
        if np.std(cm) > 5:
            thresh   = np.mean(cm)+0.4*np.std(cm)
            bright   = (cm>thresh).astype(np.int8)
            n_starts = int(np.sum(np.diff(bright)==1))
            if n_starts >= 2: score += 1
    lw    = max(1, int(w*0.15))
    l_std = float(np.std(lower[:,:lw]))
    r_std = float(np.std(lower[:,w-lw:]))
    c_std = float(np.std(lower[:,int(w*0.4):int(w*0.6)]))+1e-5
    if (l_std+r_std)/2 > c_std*1.15: score += 1
    top_w = _content_width(gray[int(h*0.25):int(h*0.45),:])
    mid_w = _content_width(gray[int(h*0.50):int(h*0.70),:])
    if top_w>0 and mid_w>0 and mid_w<top_w*0.90: score += 1
    return score >= 2


def _classify_opencv(image: np.ndarray) -> tuple[str, float]:
    """Fallback OpenCV avec règles métier."""
    h, w   = image.shape[:2]
    ratio  = h / max(w, 1)
    gray   = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    edges  = cv2.Canny(gray, 50, 150)
    dens   = float(np.sum(edges>0)) / max(1, edges.size)
    lapvar = float(cv2.Laplacian(gray, cv2.CV_64F).var())

    if ratio < 0.55: return "Chaussures", 0.80
    if ratio < 0.75:
        return ("Accessoires" if dens>0.06 else "Chaussures"), 0.70
    if ratio > 1.40:
        if _detect_two_legs(gray): return "Pantalons", 0.85
        top_w = _content_width(gray[:h//4,:])
        bot_w = _content_width(gray[3*h//4:,:])
        if bot_w/max(top_w,1) > 1.15: return "Robes", 0.80
        return "Pantalons", 0.72
    if ratio > 1.10:
        if _detect_two_legs(gray): return "Pantalons", 0.82
        top_w = _content_width(gray[:h//4,:])
        bot_w = _content_width(gray[3*h//4:,:])
        if bot_w/max(top_w,1) > 1.20: return "Jupes", 0.78
        return "Robes", 0.78
    cx1,cx2  = int(w*0.40), int(w*0.60)
    center_d = float(np.sum(edges[:,cx1:cx2]>0))/max(1,edges[:,cx1:cx2].size)
    top_d    = float(np.sum(edges[:h//3,:]>0))/max(1,edges[:h//3,:].size)
    if center_d>0.08 and top_d>0.07 and dens>0.10: return "Vestes", 0.78
    if center_d>0.06 and top_d>0.06: return "Chemises", 0.72
    if lapvar>300 or dens>0.09: return "Pulls", 0.70
    return "T-shirts", 0.68


def _has_person(image: np.ndarray) -> bool:
    h, w = image.shape[:2]
    top  = cv2.cvtColor(
        image[:int(h*0.25),:], cv2.COLOR_BGR2RGB).astype(np.float32)
    r,g,b = top[:,:,0], top[:,:,1], top[:,:,2]
    skin  = (r>60)&(g>30)&(b>15)&(r>b)&(r>g)&\
            (np.abs(r.astype(int)-g.astype(int))>8)&(r<240)
    skin_ratio = float(skin.sum())/max(1,skin.size)
    nw         = ~((r>215)&(g>215)&(b>215))
    nw_ratio   = float(nw.sum())/max(1,nw.size)
    aspect     = h/max(1,w)
    gray       = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    edges      = cv2.Canny(gray, 50, 150)
    le = float(np.sum(edges[:,:int(w*0.2)]>0))/max(1,edges[:,:int(w*0.2)].size)
    re = float(np.sum(edges[:,int(w*0.8):]>0))/max(1,edges[:,int(w*0.8):].size)
    has_sil = le>0.05 and re>0.05 and aspect>1.2
    return skin_ratio>0.03 or (nw_ratio>0.12 and aspect>1.3) or has_sil


def _crop_clothing(image: np.ndarray) -> np.ndarray:
    h = image.shape[0]
    return image[int(h*0.18):int(h*0.92),:]


def detect_season_by_category(categorie: str, couleur: str) -> str:
    if categorie in ["Vestes","Pulls","Manteaux"]: return "Hiver"
    if categorie in ["Robes","Jupes","T-shirts"]:
        return "Toutes saisons" if couleur in \
            ["Noir","Gris","Marron foncé","Bordeaux","Violet"] else "Été"
    if categorie in ["Chemises","Pantalons","Chaussures","Accessoires"]:
        if couleur in ["Blanc","Jaune","Rose","Orange","Beige","Crème"]: return "Été"
        if couleur in ["Noir","Gris","Marron foncé"]:                    return "Hiver"
        return "Toutes saisons"
    return "Toutes saisons"


def detect_style(categorie: str, pattern: str) -> str:
    if categorie in ["Chaussures","Accessoires"]: return "Accessoire"
    if categorie in ["Robes","Jupes"]:            return "Élégant"
    if categorie == "Vestes":                     return "Smart Casual"
    if categorie == "T-shirts":
        return "Sport" if pattern == "Uni" else "Casual"
    if pattern in ["Rayé","À carreaux"]:          return "Casual"
    return "Casual"


def analyze_clothing_image(image_base64: str) -> dict:
    """
    Pipeline complet :
    1. Google Gemini 2.0 Flash Vision (catégorie + couleur)
    2. Fallback MobileNetV2 local (92.6%)
    3. Fallback OpenCV géométrique
    """
    image   = decode_image(image_base64)
    couleur_kmeans, hex_couleur_kmeans = detect_dominant_color(image)
    pattern = detect_pattern(image)

    person_detected = _has_person(image)

    if person_detected:
        crop       = _crop_clothing(image)
        img_to_use = segment_foreground(crop)
    else:
        img_to_use = segment_foreground(image)

    used_cnn    = False
    confidence  = 0.0
    categorie   = None
    couleur     = couleur_kmeans
    hex_couleur = hex_couleur_kmeans

    # ── Étape 1 : Google Gemini 2.0 Flash ────────────────────────────────────
    gemini_cat, gemini_conf, gemini_couleur = classify_with_gemini(image)
    if gemini_cat is not None:
        categorie  = gemini_cat
        confidence = gemini_conf
        used_cnn   = True
        if gemini_couleur is not None:
            couleur     = gemini_couleur
            hex_couleur = "#{:02X}{:02X}{:02X}".format(*COULEURS[couleur])
        print(f"✅ Gemini final : {categorie} | {couleur} ({confidence:.1%})")

    # ── Étape 2 : Modèle local MobileNetV2 ───────────────────────────────────
    if categorie is None:
        local_cat, local_conf = _classify_with_local_model(img_to_use)
        if local_cat is not None:
            categorie  = local_cat
            confidence = local_conf
            used_cnn   = True
            print(f"✅ Local : {categorie} ({confidence:.1%})")

    # ── Étape 3 : OpenCV fallback ─────────────────────────────────────────────
    if categorie is None:
        opencv_cat, _ = _classify_opencv(img_to_use)
        categorie  = opencv_cat
        confidence = 0.0
        used_cnn   = False
        print(f"⚠️  OpenCV : {categorie}")

    # ── Garde-fous ────────────────────────────────────────────────────────────
    if categorie == "Accessoires":
        h, w = img_to_use.shape[:2]
        if h / max(w, 1) > 1.0:
            categorie  = "Robes"
            confidence = 0.0
            used_cnn   = False

    saison = detect_season_by_category(categorie, couleur)
    style  = detect_style(categorie, pattern)

    description = (
        f"Vêtement de type {categorie.lower()}, "
        f"couleur {couleur.lower()}, motif {pattern.lower()}. "
        f"Style {style.lower()}, recommandé pour {saison.lower()}."
    )

    return {
        "categorie":        categorie,
        "couleur":          couleur,
        "couleur_hex":      hex_couleur,
        "motif":            pattern,
        "saison":           saison,
        "style":            style,
        "description":      description,
        "confidence":       round(confidence, 3),
        "_used_cnn":        used_cnn,
        "_person_detected": person_detected,
    }