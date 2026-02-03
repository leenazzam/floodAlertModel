import pandas as pd
import joblib
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.metrics import classification_report, confusion_matrix, ConfusionMatrixDisplay
import os

def generate_evaluation_reports():
    print("--- Generating Evaluation Reports ---")
    
    # 1. Load Data and Model
    data_path = "data/processed/FloodGuard_Training_Data.csv"
    model_path = "models/flood_model.pkl"
    features_path = "models/feature_names.pkl"
    
    if not os.path.exists(data_path) or not os.path.exists(model_path):
        print("Required files missing. Please run pipeline first.")
        return

    df = pd.read_csv(data_path)
    model = joblib.load(model_path)
    features = joblib.load(features_path)

    # 2. Prepare Test Set (mimicking the split in training)
    from sklearn.model_selection import train_test_split
    X = df[features]
    y = df['Flood_Label']
    _, X_test, _, y_test = train_test_split(X, y, test_size=0.3, random_state=42, stratify=y)

    # 3. Predictions
    y_pred = model.predict(X_test)

    # 4. Confusion Matrix Plot
    plt.figure(figsize=(10, 8))
    cm = confusion_matrix(y_test, y_pred)
    disp = ConfusionMatrixDisplay(confusion_matrix=cm, display_labels=['No Flood', 'Flood'])
    disp.plot(cmap='Blues', values_format='d')
    plt.title("Confusion Matrix - FloodGuard Nablus")
    plt.savefig("reports/plots/confusion_matrix.png")
    print("Saved: reports/plots/confusion_matrix.png")

    # 5. Feature Importance Plot
    plt.figure(figsize=(12, 6))
    importances = pd.Series(model.feature_importances_, index=features).sort_values(ascending=False).head(10)
    importances.plot(kind='barh', color='#3498db')
    plt.title("Top 10 Features Driving Flood Prediction")
    plt.gca().invert_yaxis()
    plt.tight_layout()
    plt.savefig("reports/plots/feature_importance.png")
    print("Saved: reports/plots/feature_importance.png")

    # 6. Save Classification Report as Text
    report = classification_report(y_test, y_pred)
    with open("reports/model_performance_report.txt", "w") as f:
        f.write("--- FloodGuard Nablus Model Performance ---\n")
        f.write(report)
    print("Saved: reports/model_performance_report.txt")

    # 7. Create a Sample for Verification (First 10 test cases)
    verification_sample = X_test.copy()
    verification_sample['Actual_Label'] = y_test
    verification_sample['Predicted_Label'] = y_pred
    verification_sample.head(20).to_csv("reports/verification_sample.csv", index=False)
    print("Saved: reports/verification_sample.csv")

if __name__ == "__main__":
    generate_evaluation_reports()
