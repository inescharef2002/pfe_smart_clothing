from pydantic import BaseModel
from typing import List, Optional

# Ce que Flutter envoie pour analyser un vêtement
class AnalyzeRequest(BaseModel):
    image_base64: str  # image encodée en base64

# Ce que l'API retourne après analyse
class ClothingAnalysis(BaseModel):
    categorie: str        # ex: "Pantalons"
    couleur: str          # ex: "Noir"
    couleur_hex: str      # ex: "#1A1A1A"
    motif: str            # ex: "Uni", "Rayé", "À carreaux"
    saison: str           # ex: "Hiver", "Été", "Toutes saisons"
    style: str            # ex: "Casual", "Formel", "Sport"
    description: str      # description complète générée
    confidence: float = 0.0  # confiance du CNN (0.0 si OpenCV utilisé)

# Un vêtement dans la garde-robe
class WardrobeItem(BaseModel):
    id: str
    nom: str
    categorie: str
    couleur: str
    couleur_hex: Optional[str] = "#000000"
    taille: Optional[str] = ""
    marque: Optional[str] = ""
    imageUrl: Optional[str] = ""

# Ce que Flutter envoie pour suggestions de tenues
class SuggestRequest(BaseModel):
    wardrobe: List[WardrobeItem]
    occasion: Optional[str] = "casual"  # casual, formel, sport, soirée

# Une tenue suggérée
class OutfitSuggestion(BaseModel):
    items: List[WardrobeItem]
    titre: str
    description: str
    score_compatibilite: float  # 0.0 à 1.0

# Ce que Flutter envoie pour suggestion météo
class WeatherSuggestRequest(BaseModel):
    wardrobe: List[WardrobeItem]
    temperature: int          # ex: 15
    description_meteo: str    # ex: "nuageux", "ensoleillé"
    ville: Optional[str] = "Tunis"
