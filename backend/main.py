# ============================================================================
# VETERİNER DOĞUM TAHMİN SİSTEMİ - FASTAPI BACKEND
# ============================================================================
# Kullanım:
#   pip install fastapi uvicorn pydantic scikit-learn xgboost
#   uvicorn main:app --reload --host 0.0.0.0 --port 8000
# ============================================================================

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field, validator
from typing import Optional, Dict, Any
import pickle
import numpy as np
import os
import logging
from datetime import datetime

# ============================================================================
# LOGGING AYARI
# ============================================================================
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# ============================================================================
# FASTAPI UYGULAMASI
# ============================================================================
app = FastAPI(
    title="Veteriner Doğum Tahmin API",
    description="Makine öğrenmesi ile hayvan doğum zamanı tahmini",
    version="1.0.0",
)

# CORS — Flutter uygulaması her yerden bağlanabilsin
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ============================================================================
# MODEL YÜKLEME
# ============================================================================
MODELS_DIR = "saved_models"

models = {}
scaler = None

def load_models():
    """Kaydedilen modelleri ve scaler'ı yükle."""
    global scaler, models

    # Scaler
    scaler_path = os.path.join(MODELS_DIR, "scaler.pkl")
    if os.path.exists(scaler_path):
        with open(scaler_path, "rb") as f:
            scaler = pickle.load(f)
        logger.info("✅ Scaler yüklendi")
    else:
        logger.warning(f"⚠️  Scaler bulunamadı: {scaler_path}")

    # Random Forest
    rf_path = os.path.join(MODELS_DIR, "rf_model.pkl")
    if os.path.exists(rf_path):
        with open(rf_path, "rb") as f:
            models["random_forest"] = pickle.load(f)
        logger.info("✅ Random Forest yüklendi")

    # XGBoost
    xgb_path = os.path.join(MODELS_DIR, "xgb_model.pkl")
    if os.path.exists(xgb_path):
        with open(xgb_path, "rb") as f:
            models["xgboost"] = pickle.load(f)
        logger.info("✅ XGBoost yüklendi")

    # MLP Neural Network
    mlp_path = os.path.join(MODELS_DIR, "mlp_model.pkl")
    if os.path.exists(mlp_path):
        with open(mlp_path, "rb") as f:
            models["neural_network"] = pickle.load(f)
        logger.info("✅ Neural Network yüklendi")

    if not models:
        logger.error("❌ Hiçbir model yüklenemedi! saved_models/ klasörünü kontrol edin.")

# Uygulama başlarken modelleri yükle
@app.on_event("startup")
async def startup_event():
    load_models()

# ============================================================================
# TÜR KODLAMA HARİTASI
# Colab'daki LabelEncoder sıralamasıyla aynı olmalı (alfabetik)
# ============================================================================
SPECIES_MAP = {
    "Cat":    0,
    "Cattle": 1,
    "Dog":    2,
    "Goat":   3,
    "Horse":  4,
    "Pig":    5,
    "Sheep":  6,
}

# ============================================================================
# GİRDİ MODELİ (Pydantic)
# ============================================================================
class AnimalInput(BaseModel):
    # Temel bilgiler
    species: str = Field(..., description="Hayvan türü", example="Cattle")
    age_years: int = Field(..., ge=1, le=20, description="Hayvanın yaşı (yıl)", example=4)
    parity: int = Field(..., ge=1, le=10, description="Kaçıncı doğum", example=2)
    gestation_days: int = Field(..., ge=50, le=400, description="Toplam gebelik süresi (gün)", example=280)
    days_before_birth: int = Field(..., ge=0, le=30, description="Doğuma tahmini kalan gün", example=2)

    # Fizyolojik
    body_temp_celsius: float = Field(..., ge=35.0, le=42.0, example=38.2)
    temp_change_celsius: float = Field(..., ge=-3.0, le=1.0, example=-0.5)

    # Meme
    udder_development_score: int = Field(..., ge=0, le=5, example=4)
    udder_edema_present: int = Field(..., ge=0, le=1, example=1)
    teat_enlargement_score: int = Field(..., ge=0, le=5, example=3)
    milk_secretion_present: int = Field(..., ge=0, le=1, example=1)

    # Vulva / Pelvis
    vulva_swelling_score: int = Field(..., ge=0, le=5, example=3)
    vulva_discharge_present: int = Field(..., ge=0, le=1, example=0)
    pelvic_relaxation_score: int = Field(..., ge=0, le=5, example=4)

    # Beslenme
    appetite_change_percent: float = Field(..., ge=-100, le=50, example=-20.0)
    feed_intake_kg: float = Field(..., ge=0, le=100, example=12.0)
    water_intake_liters: float = Field(..., ge=0, le=200, example=60.0)

    # Davranış
    activity_level_score: int = Field(..., ge=1, le=5, example=2)
    restlessness_score: int = Field(..., ge=0, le=5, example=3)
    nesting_behavior_present: int = Field(..., ge=0, le=1, example=1)
    isolation_behavior_present: int = Field(..., ge=0, le=1, example=1)
    aggression_score: int = Field(..., ge=0, le=3, example=1)
    lying_frequency_per_hour: int = Field(..., ge=0, le=20, example=7)
    standing_frequency_per_hour: int = Field(..., ge=0, le=20, example=8)

    # Vital
    respiration_rate_per_min: int = Field(..., ge=10, le=100, example=35)
    heart_rate_bpm: int = Field(..., ge=30, le=200, example=80)

    # Kan değerleri
    calcium_level_mmol_l: float = Field(..., ge=0, le=20, example=9.2)
    progesterone_ng_ml: float = Field(..., ge=0, le=10, example=1.2)

    # Doğum evresi & risk
    labor_stage: int = Field(..., ge=0, le=2, example=1)
    risk_factors: int = Field(..., ge=0, le=10, example=1)

    @validator("species")
    def validate_species(cls, v):
        if v not in SPECIES_MAP:
            raise ValueError(f"Geçersiz tür. Kabul edilenler: {list(SPECIES_MAP.keys())}")
        return v

    class Config:
        schema_extra = {
            "example": {
                "species": "Cattle",
                "age_years": 4,
                "parity": 2,
                "gestation_days": 280,
                "days_before_birth": 2,
                "body_temp_celsius": 38.2,
                "temp_change_celsius": -0.5,
                "udder_development_score": 4,
                "udder_edema_present": 1,
                "teat_enlargement_score": 3,
                "milk_secretion_present": 1,
                "vulva_swelling_score": 3,
                "vulva_discharge_present": 0,
                "pelvic_relaxation_score": 4,
                "appetite_change_percent": -20.0,
                "feed_intake_kg": 12.0,
                "water_intake_liters": 60.0,
                "activity_level_score": 2,
                "restlessness_score": 3,
                "nesting_behavior_present": 1,
                "isolation_behavior_present": 1,
                "aggression_score": 1,
                "lying_frequency_per_hour": 7,
                "standing_frequency_per_hour": 8,
                "respiration_rate_per_min": 35,
                "heart_rate_bpm": 80,
                "calcium_level_mmol_l": 9.2,
                "progesterone_ng_ml": 1.2,
                "labor_stage": 1,
                "risk_factors": 1,
            }
        }

def engineer_features(data: AnimalInput) -> np.ndarray:
    species_encoded = SPECIES_MAP[data.species]

    features = [
        species_encoded,
        data.age_years,
        data.parity,
        data.gestation_days,
        data.days_before_birth,
        data.body_temp_celsius,
        data.temp_change_celsius,
        data.udder_development_score,
        data.udder_edema_present,
        data.teat_enlargement_score,
        data.milk_secretion_present,
        data.vulva_swelling_score,
        data.vulva_discharge_present,
        data.pelvic_relaxation_score,
        data.appetite_change_percent,
        data.feed_intake_kg,
        data.water_intake_liters,
        data.activity_level_score,
        data.restlessness_score,
        data.nesting_behavior_present,
        data.isolation_behavior_present,
        data.aggression_score,
        data.lying_frequency_per_hour,
        data.standing_frequency_per_hour,
        data.respiration_rate_per_min,
        data.heart_rate_bpm,
        data.calcium_level_mmol_l,
        data.progesterone_ng_ml,
        data.labor_stage,
        data.risk_factors,
    ]

    return np.array(features, dtype=float).reshape(1, -1)
# ============================================================================
# YARDIMCI: TAHMİN YORUMLAMA
# ============================================================================
def interpret_prediction(prob: float, days_before: int) -> Dict[str, Any]:
    """Olasılık ve kalan güne göre açıklama ve öneri üret."""
    if days_before == 0:
        urgency = "KRİTİK"
        message = "Doğum başlamış olabilir. Anında veteriner müdahalesi gerekli."
    elif days_before <= 1:
        urgency = "ACİL"
        message = "Doğum 24 saat içinde bekleniyor. Yakın takip ve hazırlık şart."
    elif days_before <= 3:
        urgency = "YÜKSEK"
        message = "Doğum 1-3 gün içinde bekleniyor. Sık kontrol edin."
    else:
        urgency = "NORMAL"
        message = "Doğum henüz yakın değil. Rutin takibe devam edin."

    if prob >= 0.90:
        risk_level = "Düşük Risk"
    elif prob >= 0.75:
        risk_level = "Orta Risk"
    elif prob >= 0.60:
        risk_level = "Yüksek Risk"
    else:
        risk_level = "Çok Yüksek Risk"

    return {
        "urgency": urgency,
        "message": message,
        "risk_level": risk_level,
    }


# ============================================================================
# ENDPOINT: SAĞLIK KONTROLÜ
# ============================================================================
@app.get("/", tags=["Genel"])
async def root():
    return {
        "api": "Veteriner Doğum Tahmin API",
        "version": "1.0.0",
        "status": "çalışıyor",
        "modeller": list(models.keys()),
        "timestamp": datetime.now().isoformat(),
    }

@app.get("/health", tags=["Genel"])
async def health_check():
    return {
        "status": "ok",
        "scaler_loaded": scaler is not None,
        "models_loaded": list(models.keys()),
    }

@app.get("/species", tags=["Genel"])
async def get_species():
    """Desteklenen hayvan türlerini döndür."""
    return {"species": list(SPECIES_MAP.keys())}


# ============================================================================
# ENDPOINT: TAHMİN (ANA ENDPOINT)
# ============================================================================
@app.post("/predict", tags=["Tahmin"])
async def predict(animal: AnimalInput):
    """
    Hayvan verilerini alır, tüm modellerin ensemble tahmini ile
    başarılı doğum olasılığını döndürür.
    """
    if not models:
        raise HTTPException(
            status_code=503,
            detail="Modeller yüklenemedi. saved_models/ klasörünü kontrol edin."
        )
    if scaler is None:
        raise HTTPException(
            status_code=503,
            detail="Scaler yüklenemedi."
        )

    try:
        # Özellik vektörü oluştur ve standardize et
        X = engineer_features(animal)
        X_scaled = scaler.transform(X)

        # Her modelden tahmin al
        model_predictions = {}
        weights = []
        weighted_sum = 0.0

        for name, model in models.items():
            prob = float(model.predict_proba(X_scaled)[0, 1])
            model_predictions[name] = round(prob, 4)

            # Ensemble ağırlığı — hepsini eşit al (F1 bilinmediği için)
            weight = 1.0
            weights.append(weight)
            weighted_sum += prob * weight

        # Ensemble olasılık
        ensemble_prob = weighted_sum / sum(weights)
        predicted_success = int(ensemble_prob >= 0.5)

        # Yorum
        interpretation = interpret_prediction(ensemble_prob, animal.days_before_birth)

        return {
            "animal_id": f"{animal.species[:3].upper()}_{datetime.now().strftime('%H%M%S')}",
            "species": animal.species,
            "days_before_birth": animal.days_before_birth,
            "successful_birth_probability": round(ensemble_prob, 4),
            "successful_birth_percent": round(ensemble_prob * 100, 1),
            "prediction": "Başarılı" if predicted_success else "Riskli",
            "model_probabilities": model_predictions,
            "interpretation": interpretation,
            "timestamp": datetime.now().isoformat(),
        }

    except Exception as e:
        logger.error(f"Tahmin hatası: {e}")
        raise HTTPException(status_code=500, detail=f"Tahmin sırasında hata: {str(e)}")


# ============================================================================
# ENDPOINT: TOPLU TAHMİN
# ============================================================================
@app.post("/predict/batch", tags=["Tahmin"])
async def predict_batch(animals: list[AnimalInput]):
    """Birden fazla hayvan için aynı anda tahmin yap."""
    if len(animals) > 50:
        raise HTTPException(status_code=400, detail="Tek seferde en fazla 50 hayvan gönderilebilir.")

    results = []
    for animal in animals:
        result = await predict(animal)
        results.append(result)

    return {
        "count": len(results),
        "results": results,
    }