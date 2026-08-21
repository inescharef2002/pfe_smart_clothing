# Smart Clothing Advisor — PFE

Application mobile Flutter (avec back-end IA et interface d'administration) permettant d'analyser des vêtements par image, de suggérer des tenues adaptées à la météo, et d'échanger des articles entre utilisateurs (marketplace).

Projet réalisé dans le cadre d'un Projet de Fin d'Études (PFE).

## Architecture

Le dépôt regroupe trois sous-projets :

```
pfe_smart_clothing/
├── lib/            # Application mobile Flutter (Clean Architecture)
├── backend/        # API IA en Python / FastAPI
├── smart-clothing-admin/  # Tableau de bord d'administration en Next.js
├── android/ ios/ web/ windows/ linux/ macos/   # Cibles Flutter
└── firestore.rules # Règles de sécurité Firebase
```

### 📱 Application mobile (`lib/`)

Flutter, organisé en Clean Architecture (`data` / `domain` / `presentation`) avec `flutter_bloc` pour la gestion d'état et `get_it` pour l'injection de dépendances.

Fonctionnalités (`lib/features/`) :
- **auth** — inscription / connexion (email, Google Sign-In)
- **home** — écran d'accueil
- **wardrobe** — garde-robe personnelle et historique d'analyses
- **outfit_analysis** — analyse IA d'une tenue et suggestions selon la météo
- **marketplace** — vente/échange d'articles entre utilisateurs, panier
- **profile** — gestion du profil utilisateur

Stockage et authentification via **Firebase** (Auth, Firestore, Storage).

### 🧠 Backend IA (`backend/`)

API **FastAPI** (Python) qui expose les endpoints suivants :

| Endpoint | Description |
|---|---|
| `POST /api/analyze-clothing` | Analyse d'une image de vêtement (modèle de classification) |
| `POST /api/suggest-outfits` | Suggestions de tenues |
| `POST /api/weather-outfit` | Suggestions de tenues selon la météo |
| `GET /api/admin/stats` | Statistiques d'usage |
| `DELETE /api/admin/stats/reset` | Réinitialisation des statistiques |

Le modèle de classification de vêtements est entraîné avec TensorFlow/Keras (`train_model.py`) puis exporté en ONNX (`export_onnx.py`) pour l'inférence.

### 🖥️ Interface d'administration (`smart-clothing-admin/`)

Dashboard **Next.js** (React) connecté à Firebase, pour la gestion des utilisateurs, des articles de la marketplace et le suivi des performances du modèle IA.

## Installation

### Application Flutter

```bash
flutter pub get
flutter run
```

Nécessite un fichier `.env` à la racine (non versionné) avec les clés d'API utilisées par l'app (météo, backend, etc.), ainsi qu'un projet Firebase configuré (`firebase_options.dart` généré via `flutterfire configure`).

### Backend

```bash
cd backend
pip install -r requirements.txt
uvicorn app.main:app --reload
```

Nécessite un fichier `backend/.env` (non versionné) avec les variables de configuration du service.

### Interface d'administration

```bash
cd smart-clothing-admin
npm install
npm run dev
```

Nécessite un fichier `smart-clothing-admin/.env.local` (non versionné) avec la configuration Firebase du projet.

## Sécurité

Les règles Firestore (`firestore.rules`) restreignent l'accès aux données : chaque utilisateur ne peut lire/écrire que ses propres données (garde-robe, panier, favoris), et les opérations d'administration sont réservées aux comptes avec le rôle `admin`.

## Auteure

**Ines Charef** — [@inescharef2002](https://github.com/inescharef2002)
