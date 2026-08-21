from fastapi import APIRouter, HTTPException
from app.models.schemas import WeatherSuggestRequest, OutfitSuggestion
from app.services.outfit_service import generate_weather_outfit
from typing import List

router = APIRouter()

@router.post("/weather-outfit", response_model=List[OutfitSuggestion])
async def weather_outfit(request: WeatherSuggestRequest):
    """
    Reçoit la garde-robe + météo, retourne des tenues adaptées.
    Flutter envoie : { "wardrobe": [...], "temperature": 15, "description_meteo": "nuageux" }
    """
    try:
        suggestions = generate_weather_outfit(
            request.wardrobe,
            request.temperature,
            request.description_meteo,
        )
        return suggestions
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur météo outfit: {str(e)}")
