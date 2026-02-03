import pandas as pd
import joblib
import os
from sklearn.model_selection import train_test_split

def final_stress_test():
    print("--- Final Model Stress Test & Probability Verification ---")
    
    # 1. Load Data and Model
    data_path = "data/processed/FloodGuard_Training_Data.csv"
    model_path = "models/flood_model.pkl"
    features_path = "models/feature_names.pkl"
    
    df = pd.read_csv(data_path)
    model = joblib.load(model_path)
    features = joblib.load(features_path)

    # 2. Extract Real Flood Events from the test set
    X = df[features]
    y = df['Flood_Label']
    _, X_test, _, y_test = train_test_split(X, y, test_size=0.3, random_state=42, stratify=y)

    # Calculate probabilities for all test cases
    probs = model.predict_proba(X_test)[:, 1]
    
    test_results = X_test.copy()
    test_results['Actual_Flood'] = y_test
    test_results['Flood_Probability'] = probs
    
    # 3. Find successful predictions (Where probability is high on actual floods)
    real_floods = test_results[test_results['Actual_Flood'] == 1].sort_values(by='Flood_Probability', ascending=False)
    
    print(f"\nTotal Real Floods in Test Set: {len(real_floods)}")
    print("--- Sample of Real Floods and Model's Confidence ---")
    print(real_floods[['rain_rolling_6h_sum', 'Flood_Probability']].head(10))

    # 4. EXTREME SCENARIO TEST (Fake Storm)
    print("\n--- Simulation: Extreme Storm Scenario (50mm in 6h) ---")
    # Take a random record and inject extreme numbers
    fake_storm = X_test.iloc[0:1].copy()
    for col in fake_storm.columns:
        if 'rain' in col:
            fake_storm[col] = 40.0 # Force heavy rain in all lags
    fake_storm['rain_rolling_6h_sum'] = 60.0 # Extreme accumulation
    
    extreme_prob = model.predict_proba(fake_storm)[:, 1][0]
    print(f"Result: For an extreme storm simulation, Model Probability is: {extreme_prob:.2%}")

    # Save these findings for your front-end team
    real_floods.to_csv("reports/real_floods_verification.csv", index=False)
    print("\nSaved detailed proof to: reports/real_floods_verification.csv")

if __name__ == "__main__":
    final_stress_test()
