import random
from app.models.schemas import WardrobeItem, OutfitSuggestion
from typing import List, Optional

# ── Compatibilité couleurs ────────────────────────────────────────────────────
COMPATIBLE_COLORS: dict[str, List[str]] = {
    "Noir":         ["Blanc", "Gris", "Gris clair", "Rouge", "Bordeaux", "Beige", "Camel", "Jaune", "Rose", "Bleu", "Violet"],
    "Blanc":        ["Noir", "Bleu", "Bleu marine", "Gris", "Gris clair", "Beige", "Camel", "Rouge", "Vert", "Rose", "Kaki"],
    "Gris":         ["Noir", "Blanc", "Bleu", "Bleu marine", "Rose", "Bordeaux", "Violet"],
    "Gris clair":   ["Noir", "Blanc", "Bleu", "Rose", "Bordeaux", "Violet"],
    "Bleu":         ["Blanc", "Gris", "Gris clair", "Beige", "Camel", "Marron", "Orange"],
    "Bleu marine":  ["Blanc", "Beige", "Camel", "Gris", "Gris clair", "Rouge"],
    "Rouge":        ["Noir", "Blanc", "Gris", "Beige"],
    "Bordeaux":     ["Noir", "Blanc", "Gris", "Gris clair", "Beige", "Camel"],
    "Beige":        ["Marron", "Marron foncé", "Noir", "Blanc", "Bleu", "Bleu marine", "Vert", "Kaki"],
    "Camel":        ["Noir", "Blanc", "Bleu", "Bleu marine", "Bordeaux", "Beige"],
    "Marron":       ["Beige", "Camel", "Blanc", "Crème", "Vert", "Kaki", "Bleu"],
    "Marron foncé": ["Beige", "Camel", "Blanc", "Crème"],
    "Crème":        ["Marron", "Marron foncé", "Camel", "Bleu marine", "Bordeaux"],
    "Vert":         ["Blanc", "Beige", "Marron", "Kaki", "Gris"],
    "Kaki":         ["Blanc", "Beige", "Marron", "Vert", "Noir", "Camel"],
    "Rose":         ["Blanc", "Gris", "Gris clair", "Noir", "Beige"],
    "Violet":       ["Blanc", "Gris", "Gris clair", "Noir", "Beige"],
    "Jaune":        ["Blanc", "Gris", "Noir", "Bleu marine"],
    "Orange":       ["Blanc", "Bleu", "Bleu marine", "Noir", "Marron"],
}

# ── Combinaisons valides PAR OCCASION ─────────────────────────────────────────
TENUE_PAR_OCCASION: dict[str, List[List]] = {
    "Sport": [
        ["T-shirts", "Pantalons"],
        ["T-shirts", "Jupes"],
        ["Pulls", "Pantalons"],
    ],
    "Travail": [
        ["Chemises", "Pantalons"],
        ["Vestes", "Pantalons"],
        ["Vestes", "Jupes"],
        ["Robes", None],
        ["Chemises", "Jupes"],
    ],
    "Soirée": [
        ["Robes", None],
        ["Vestes", "Jupes"],
        ["Chemises", "Pantalons"],
        ["Vestes", "Pantalons"],
    ],
    "Rendez-vous": [
        ["Robes", None],
        ["Chemises", "Jupes"],
        ["Vestes", "Jupes"],
        ["Chemises", "Pantalons"],
    ],
    "Mariage": [
        ["Robes", None],
        ["Vestes", "Jupes"],
        ["Vestes", "Pantalons"],
    ],
    "Weekend": [
        ["T-shirts", "Pantalons"],
        ["Chemises", "Pantalons"],
        ["Pulls", "Pantalons"],
        ["T-shirts", "Jupes"],
        ["Robes", None],
    ],
    "Quotidienne": [
        ["Chemises", "Pantalons"],
        ["T-shirts", "Pantalons"],
        ["Pulls", "Pantalons"],
        ["Chemises", "Jupes"],
        ["T-shirts", "Jupes"],
        ["Robes", None],
        ["Vestes", "Pantalons"],
    ],
    "météo": [
        ["Chemises", "Pantalons"],
        ["T-shirts", "Pantalons"],
        ["Pulls", "Pantalons"],
        ["Vestes", "Pantalons"],
        ["Robes", None],
        ["T-shirts", "Jupes"],
        ["Chemises", "Jupes"],
    ],
    "casual": [
        ["T-shirts", "Pantalons"],
        ["Chemises", "Pantalons"],
        ["Pulls", "Pantalons"],
        ["T-shirts", "Jupes"],
        ["Robes", None],
    ],
}

# ── Emojis par occasion ───────────────────────────────────────────────────────
OCCASION_EMOJI = {
    "Quotidienne": "👗", "Travail": "💼", "Soirée": "✨",
    "Sport": "🏃", "Rendez-vous": "💕", "Weekend": "🌿",
    "Mariage": "💍", "météo": "🌤️", "casual": "👗",
}

# ── Conseils par occasion ─────────────────────────────────────────────────────
OCCASION_ADVICE = {
    "Travail":     "Tenue professionnelle : restez sobre et élégant(e). Choisissez des accessoires discrets.",
    "Soirée":      "Pour briller en soirée, ajoutez bijoux et chaussures habillées.",
    "Sport":       "Privilégiez des matières respirantes et des baskets confortables.",
    "Rendez-vous": "Tenue romantique : misez sur les détails soignés et un parfum léger.",
    "Mariage":     "Tenue de mariage : choisissez des couleurs sobres pour ne pas éclipser les mariés.",
    "Weekend":     "Look décontracté et confortable, parfait pour les sorties du week-end.",
    "Quotidienne": "Style casual-chic facile à porter au quotidien.",
}


def colors_compatible(c1: str, c2: str) -> bool:
    if not c1 or not c2:
        return True
    if c1 == c2:
        return True
    compat = COMPATIBLE_COLORS.get(c1, [])
    return c2 in compat or c1 in COMPATIBLE_COLORS.get(c2, [])


def score_outfit(items: List[WardrobeItem]) -> float:
    if len(items) < 2:
        return 0.5
    total, ok = 0, 0
    for i in range(len(items)):
        for j in range(i + 1, len(items)):
            total += 1
            if colors_compatible(items[i].couleur, items[j].couleur):
                ok += 1
    return ok / total if total > 0 else 0.5


def _get_combos_for_occasion(occasion: str) -> List[List]:
    """Retourne les combinaisons valides pour l'occasion donnée."""
    return TENUE_PAR_OCCASION.get(occasion, TENUE_PAR_OCCASION["casual"])


def generate_outfit_suggestions(
    wardrobe: List[WardrobeItem],
    occasion: Optional[str] = "casual",
    seed: Optional[int] = None,
) -> List[OutfitSuggestion]:
    """Génère des suggestions de tenues adaptées à l'occasion."""
    rng = random.Random(seed)
    occ = occasion or "casual"

    by_cat: dict[str, List[WardrobeItem]] = {}
    for item in wardrobe:
        by_cat.setdefault(item.categorie, []).append(item)

    for lst in by_cat.values():
        rng.shuffle(lst)

    suggestions: List[OutfitSuggestion] = []
    emoji = OCCASION_EMOJI.get(occ, "👗")
    advice = OCCASION_ADVICE.get(occ, "")

    # ✅ Utiliser les combinaisons spécifiques à l'occasion
    combos = _get_combos_for_occasion(occ)

    for combo in combos:
        cat1, cat2 = combo
        items1 = by_cat.get(cat1, [])

        if cat2 is None:
            # Robe seule
            for i1 in items1[:4]:
                outfit = [i1]
                # Accessoires optionnels
                acc = by_cat.get("Accessoires", [])
                if acc:
                    outfit.append(rng.choice(acc))
                # Chaussures optionnelles
                shoes = by_cat.get("Chaussures", [])
                if shoes:
                    outfit.append(rng.choice(shoes))
                score = score_outfit(outfit)
                if score >= 0.3:
                    suggestions.append(OutfitSuggestion(
                        items=outfit,
                        titre=f"Tenue {occ} — {i1.couleur}",
                        description=_build_description(outfit, occ, score, advice),
                        score_compatibilite=round(score, 2),
                    ))
        else:
            items2 = by_cat.get(cat2, [])
            for i1 in items1[:4]:
                for i2 in items2[:4]:
                    outfit = [i1, i2]
                    # Chaussures adaptées à l'occasion
                    shoes = by_cat.get("Chaussures", [])
                    if shoes:
                        outfit.append(rng.choice(shoes))
                    # Accessoires sauf pour Sport
                    if occ != "Sport":
                        acc = by_cat.get("Accessoires", [])
                        if acc:
                            outfit.append(rng.choice(acc))
                    score = score_outfit(outfit)
                    if score >= 0.3:
                        suggestions.append(OutfitSuggestion(
                            items=outfit,
                            titre=f"Tenue {occ} — {i1.couleur} & {i2.couleur}",
                            description=_build_description(outfit, occ, score, advice),
                            score_compatibilite=round(score, 2),
                        ))

    # Trier par score, mélanger légèrement pour la variété
    suggestions.sort(key=lambda x: x.score_compatibilite, reverse=True)
    top = suggestions[:10]
    rng.shuffle(top)
    return top[:5]


def _build_description(
    outfit: List[WardrobeItem],
    occasion: str,
    score: float,
    advice: str,
) -> str:
    if len(outfit) >= 2:
        n1 = outfit[0].nom
        c1 = outfit[0].couleur.lower()
        n2 = outfit[1].nom
        c2 = outfit[1].couleur.lower()
        desc = (
            f"Associez votre {n1} {c1} avec votre {n2} {c2}. "
            f"Compatibilité couleurs : {int(score * 100)}%."
        )
    else:
        n1 = outfit[0].nom
        c1 = outfit[0].couleur.lower()
        desc = f"Portez votre {n1} {c1}. Compatibilité : {int(score * 100)}%."

    if advice:
        desc += f" {advice}"

    return desc


def generate_weather_outfit(
    wardrobe: List[WardrobeItem],
    temperature: int,
    description_meteo: str,
) -> List[OutfitSuggestion]:
    """Génère des tenues adaptées à la météo."""
    categories_ok = _get_temp_categories(temperature)
    filtered = [item for item in wardrobe if item.categorie in categories_ok]
    if not filtered:
        filtered = wardrobe

    suggestions = generate_outfit_suggestions(filtered, occasion="météo")

    weather_advice = _weather_advice(temperature, description_meteo)
    for s in suggestions:
        s.description = f"{weather_advice} {s.description}".strip()

    return suggestions


def _get_temp_categories(temperature: int) -> List[str]:
    """Catégories adaptées à la température."""
    if temperature < 10:
        return ["Vestes", "Pulls", "Manteaux", "Pantalons", "Accessoires", "Chaussures"]
    elif temperature < 18:
        return ["Vestes", "Pulls", "Chemises", "Pantalons", "Jupes", "Accessoires", "Chaussures"]
    elif temperature < 25:
        return ["Chemises", "T-shirts", "Pantalons", "Jupes", "Robes", "Vestes", "Chaussures", "Accessoires"]
    else:
        return ["T-shirts", "Robes", "Chemises", "Jupes", "Pantalons", "Chaussures", "Accessoires"]


def _weather_advice(temperature: int, description: str) -> str:
    desc = description.lower()
    if temperature < 5:
        return "Il fait très froid, portez un manteau chaud et des accessoires."
    if temperature < 15:
        if "pluie" in desc or "pluvieux" in desc:
            return "Temps froid et pluvieux : imperméable conseillé."
        return "Temps frais, pensez à une veste ou un pull."
    if temperature < 25:
        if "nuage" in desc or "couvert" in desc:
            return "Temps nuageux, prévoyez un léger gilet."
        return "Température agréable, une tenue légère avec une veste suffira."
    if "soleil" in desc or "ensoleillé" in desc or "dégagé" in desc:
        return "Beau temps chaud, optez pour des matières légères et respirantes."
    return "Temps chaud, privilégiez les vêtements légers et clairs."