from fastapi import APIRouter, HTTPException
from app.models.schemas import AnalyzeRequest, ClothingAnalysis
from app.services.vision_service import analyze_clothing_image
from app.services.stats_service import log_analysis, log_error

router = APIRouter()


@router.post("/analyze-clothing", response_model=ClothingAnalysis)
async def analyze_clothing(request: AnalyzeRequest):
    """
    Reçoit une image en base64 et retourne l'analyse du vêtement.
    Flutter envoie : { "image_base64": "..." }
    """
    try:
        result = analyze_clothing_image(request.image_base64)

        # Logger les métriques 
        log_analysis(
            categorie=result["categorie"],
            couleur=result["couleur"],
            confidence=result["confidence"],
            used_cnn=result.pop("_used_cnn", False),
            person_detected=result.pop("_person_detected", False),
            success=True,
        )

        return ClothingAnalysis(**result)
    except Exception as e:
        log_error()
        raise HTTPException(status_code=500, detail=f"Erreur analyse: {str(e)}")
