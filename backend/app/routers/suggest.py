from fastapi import APIRouter, HTTPException
from app.models.schemas import SuggestRequest, OutfitSuggestion, WeatherSuggestRequest
from app.services.outfit_service import generate_outfit_suggestions, generate_weather_outfit
from app.services.stats_service import log_suggestion, log_error
from typing import List

router = APIRouter()


@router.post("/suggest-outfits", response_model=List[OutfitSuggestion])
async def suggest_outfits(request: SuggestRequest):
    """
    Reçoit la garde-robe et l'occasion, retourne des suggestions de tenues.
    Flutter envoie : { "wardrobe": [...], "occasion": "casual" }
    """
    try:
        suggestions = generate_outfit_suggestions(request.wardrobe, request.occasion)
        log_suggestion(occasion=request.occasion or "casual", is_weather=False)
        return suggestions
    except Exception as e:
        log_error()
        raise HTTPException(status_code=500, detail=f"Erreur suggestion: {str(e)}")


@router.post("/weather-outfit", response_model=List[OutfitSuggestion])
async def weather_outfit(request: WeatherSuggestRequest):
    """
    Reçoit la garde-robe + météo, retourne des tenues adaptées.
    Flutter envoie : { "wardrobe": [...], "temperature": 20, "description_meteo": "...", "ville": "Tunis" }
    """
    try:
        suggestions = generate_weather_outfit(
            wardrobe=request.wardrobe,
            temperature=request.temperature,
            description_meteo=request.description_meteo,
        )
        log_suggestion(occasion="météo", is_weather=True)
        return suggestions
    except Exception as e:
        log_error()
        raise HTTPException(status_code=500, detail=f"Erreur météo outfit: {str(e)}")
