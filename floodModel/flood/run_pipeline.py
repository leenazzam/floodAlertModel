import os
import pandas as pd
from src.weather_api import fetch_weather_data
from src.geo_processor import get_street_network, calculate_terrain_features, get_schools
from src.model_utils import prepare_training_data, train_flood_model

def main():
    # 1. Weather Data Collection
    print("--- Step 1: Weather Data Collection ---")
    raw_weather_path = "data/raw/floodguard_weather_raw.csv"
    if not os.path.exists(raw_weather_path):
        df_rafidia = fetch_weather_data(32.2211, 35.2333, "rafidia")
        df_shavei = fetch_weather_data(32.2750, 35.1700, "shavei")
        weather_df = pd.merge(df_rafidia, df_shavei, on="timestamp")
        weather_df.to_csv(raw_weather_path, index=False)
        print(f"Saved weather data to {raw_weather_path}")
    else:
        print("Weather data already exists. Skipping...")
        weather_df = pd.read_csv(raw_weather_path)

    # 2. Model Training
    print("\n--- Step 2: Model Training ---")
    processed_training_path = "data/processed/FloodGuard_Training_Data.csv"
    if not os.path.exists("models/flood_model.pkl"):
        training_df = prepare_training_data(weather_df)
        training_df.to_csv(processed_training_path, index=False)
        model = train_flood_model(training_df)
        print("Model trained and saved to models/flood_model.pkl")
    else:
        print("Model already exists. Skipping...")

    # 3. Geo-Spatial Processing
    print("\n--- Step 3: Geo-Spatial Processing ---")
    dem_path = "rafidia_dem.tif"
    if os.path.exists(dem_path):
        streets_path = "data/processed/rafidia_streets.geojson"
        if not os.path.exists(streets_path):
            streets = get_street_network(32.2211, 35.2333)
            print("Calculating terrain features (Slope/Elevation)...")
            streets = calculate_terrain_features(streets, dem_path)
            streets.to_file(streets_path, driver='GeoJSON')
            print(f"Saved processed streets to {streets_path}")
        else:
            print("Street network already processed. Skipping...")
        
        # Schools
        schools_path = "data/processed/rafidia_schools.csv"
        if not os.path.exists(schools_path):
            schools = get_schools(32.2211, 35.2333)
            if not schools.empty:
                schools[['name', 'geometry']].to_csv(schools_path, index=False)
                print(f"Saved schools data to {schools_path}")
    else:
        print(f"Warning: {dem_path} not found. Geo-spatial terrain analysis skipped.")

    print("\n--- Pipeline Completed Successfully! ---")

if __name__ == "__main__":
    main()
