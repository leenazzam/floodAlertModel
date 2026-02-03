from fastapi import FastAPI
import pandas as pd
import geopandas as gpd
import joblib
import json
from src.model_utils import predict_flood_prob

app = FastAPI()

# Load pre-processed data and models on startup
try:
    model = joblib.load("models/flood_model.pkl")
    features = joblib.load("models/feature_names.pkl")
    # Load streets/schools if pre-processed
    # streets = gpd.read_file("data/processed/rafidia_streets.geojson")
except:
    model = None
    features = None

@app.get("/")
def read_root():
    return {"message": "FloodGuard Nablus Backend API"}

@app.get("/status")
def get_flood_status():
    """
    Returns the current flood risk and critical infrastructure status.
    This would ideally take real-time weather input.
    """
    # Mocking real-time evaluation
    risk_level = "High" if model else "Unknown"
    
    return {
        "risk_level": risk_level,
        "probability": 0.85, # Mock value
        "alert_message": "High flood risk detected in Rafidia area. Avoid low-lying streets.",
        "timestamp": "2026-02-02T15:35:00"
    }

@app.get("/infrastructure/streets")
def get_streets():
    """
    Returns GeoJSON-ready data for Flutter to display street risk on a map.
    """
    try:
        with open("data/processed/rafidia_streets.geojson", "r") as f:
            streets_data = json.load(f)
        return streets_data
    except Exception as e:
        return {"error": f"Streets data not found: {str(e)}"}

@app.get("/infrastructure/schools")
def get_schools_data():
    """
    Returns school locations and their related risk status.
    """
    try:
        schools_df = pd.read_csv("data/processed/rafidia_schools.csv")
        return schools_df.to_dict(orient="records")
    except Exception as e:
        return {"error": f"Schools data not found: {str(e)}"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
