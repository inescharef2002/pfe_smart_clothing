from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routers import analyze, suggest, weather, admin

app = FastAPI(
    title="Smart Clothing Advisor API",
    description="Backend IA pour l'analyse de vêtements et suggestions de tenues",
    version="1.0.0",
)

# Autoriser Flutter (web + mobile) à appeler l'API
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(analyze.router, prefix="/api", tags=["Analyse"])
app.include_router(suggest.router, prefix="/api", tags=["Suggestions"])
app.include_router(weather.router, prefix="/api", tags=["Météo"])
app.include_router(admin.router,   prefix="/api", tags=["Admin"])

@app.get("/")
def root():
    return {"status": "Smart Clothing API en ligne ✅"}
