from fastapi import APIRouter, HTTPException
from app.services.stats_service import get_stats, reset_stats

router = APIRouter()


@router.get("/admin/stats")
async def admin_stats():
    """
    Retourne les métriques de performance du système IA.
    Accessible uniquement depuis l'application admin Flutter.
    """
    try:
        return get_stats()
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur stats: {str(e)}")


@router.delete("/admin/stats/reset")
async def admin_reset_stats():
    """Remet toutes les métriques IA à zéro."""
    try:
        reset_stats()
        return {"message": "Statistiques réinitialisées ✅"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
