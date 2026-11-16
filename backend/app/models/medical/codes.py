"""The codes of conditions, allergies and contact relations, and the
checks built from them."""


# Ordered as the app shows them: the most common first.
CONDITION_CODES = (
    "diabetes",
    "hypertension",
    "cholesterol",
    "heart",
    "stroke",
    "asthma",
    "kidney",
    "thyroid",
    "arthritis",
    "osteoporosis",
    "dementia",
    "depression_anxiety",
    "cancer",
    "other",
)
MEDICATION_ALLERGY_CODES = (
    "penicillin",
    "sulfa",
    "cephalosporins",
    "quinolones",
    "aspirin",
    "nsaids",
    "opioids",
    "contrast_media",
    "anesthesia",
    "other",
)
FOOD_ALLERGY_CODES = (
    "milk",
    "eggs",
    "fish",
    "shellfish",
    "tree_nuts",
    "peanuts",
    "wheat",
    "soy",
    "sesame",
    "other",
)
CONTACT_RELATIONS = ("son", "daughter", "husband", "wife", "other")

CONDITIONS_SQL = ", ".join(f"'{c}'" for c in CONDITION_CODES)
MEDICATION_SQL = ", ".join(f"'{c}'" for c in MEDICATION_ALLERGY_CODES)
FOOD_SQL = ", ".join(f"'{c}'" for c in FOOD_ALLERGY_CODES)
RELATIONS_SQL = ", ".join(f"'{c}'" for c in CONTACT_RELATIONS)

# "other" always carries the text the user typed; every other code has none.
OTHER_TEXT = (
    "(code = 'other' AND other_text IS NOT NULL "
    "AND length(btrim(other_text)) BETWEEN 1 AND 100) OR "
    "(code <> 'other' AND other_text IS NULL)"
)
