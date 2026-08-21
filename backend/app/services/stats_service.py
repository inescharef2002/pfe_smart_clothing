import json
import os
from datetime import datetime, date
from threading import Lock

_STATS_FILE = os.path.join(os.path.dirname(__file__), '..', 'data', 'stats.json')
_lock = Lock()

_DEFAULT: dict = {
    "total_analyses": 0,
    "analyses_today": 0,
    "last_analysis_date": "",
    "avg_confidence": 0.0,
    "min_confidence": 1.0,
    "max_confidence": 0.0,
    "confidence_sum": 0.0,
    "confidence_high": 0,    # >= 0.80
    "confidence_medium": 0,  # 0.60 – 0.79
    "confidence_low": 0,     # < 0.60  (OpenCV fallback)
    "cnn_used": 0,
    "opencv_used": 0,
    "person_detected": 0,
    "errors_count": 0,
    "categories_distribution": {},
    "total_suggestions": 0,
    "suggestions_today": 0,
    "weather_suggestions_today": 0,
    "last_suggestion_date": "",
    "occasions_distribution": {},
    "recent_analyses": [],   # dernières 10 analyses
}


def _ensure_dir():
    os.makedirs(os.path.dirname(_STATS_FILE), exist_ok=True)


def _load() -> dict:
    _ensure_dir()
    if not os.path.exists(_STATS_FILE):
        return dict(_DEFAULT)
    try:
        with open(_STATS_FILE, 'r', encoding='utf-8') as f:
            data = json.load(f)
        # Compléter les clés manquantes (migration)
        for k, v in _DEFAULT.items():
            data.setdefault(k, v)
        return data
    except Exception:
        return dict(_DEFAULT)


def _save(data: dict):
    _ensure_dir()
    with open(_STATS_FILE, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)


def _reset_daily_if_needed(data: dict, today: str):
    if data.get("last_analysis_date") != today:
        data["analyses_today"] = 0
        data["last_analysis_date"] = today
    if data.get("last_suggestion_date") != today:
        data["suggestions_today"] = 0
        data["weather_suggestions_today"] = 0
        data["last_suggestion_date"] = today


# ── API publique ──────────────────────────────────────────────────────────────

def log_analysis(
    *,
    categorie: str,
    couleur: str,
    confidence: float,
    used_cnn: bool,
    person_detected: bool,
    success: bool = True,
):
    today = date.today().isoformat()
    now = datetime.now().strftime("%H:%M:%S")

    with _lock:
        data = _load()
        _reset_daily_if_needed(data, today)

        if not success:
            data["errors_count"] += 1
            _save(data)
            return

        data["total_analyses"] += 1
        data["analyses_today"] += 1

        # Confiance
        data["confidence_sum"] += confidence
        data["avg_confidence"] = round(
            data["confidence_sum"] / data["total_analyses"], 3
        )
        data["min_confidence"] = round(min(data["min_confidence"], confidence), 3)
        data["max_confidence"] = round(max(data["max_confidence"], confidence), 3)

        if confidence >= 0.80:
            data["confidence_high"] += 1
        elif confidence >= 0.60:
            data["confidence_medium"] += 1
        else:
            data["confidence_low"] += 1

        # Moteur utilisé
        if used_cnn:
            data["cnn_used"] += 1
        else:
            data["opencv_used"] += 1

        if person_detected:
            data["person_detected"] += 1

        # Distribution catégories
        dist = data["categories_distribution"]
        dist[categorie] = dist.get(categorie, 0) + 1

        # Historique récent (max 10)
        data["recent_analyses"] = ([{
            "time": now,
            "categorie": categorie,
            "couleur": couleur,
            "confidence": round(confidence, 2),
            "moteur": "CNN" if used_cnn else "OpenCV",
        }] + data["recent_analyses"])[:10]

        _save(data)


def log_suggestion(*, occasion: str, is_weather: bool = False):
    today = date.today().isoformat()
    with _lock:
        data = _load()
        _reset_daily_if_needed(data, today)

        data["total_suggestions"] += 1
        data["suggestions_today"] += 1
        if is_weather:
            data["weather_suggestions_today"] += 1

        dist = data["occasions_distribution"]
        dist[occasion] = dist.get(occasion, 0) + 1

        _save(data)


def log_error():
    with _lock:
        data = _load()
        data["errors_count"] += 1
        _save(data)


def get_stats() -> dict:
    with _lock:
        data = _load()
    # Ne pas exposer confidence_sum (interne)
    result = {k: v for k, v in data.items() if k != "confidence_sum"}
    result["last_updated"] = datetime.now().isoformat(timespec="seconds")
    return result


def reset_stats():
    with _lock:
        _save(dict(_DEFAULT))
