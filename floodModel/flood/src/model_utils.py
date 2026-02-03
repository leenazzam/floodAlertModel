import pandas as pd
from xgboost import XGBClassifier
from sklearn.model_selection import train_test_split
import joblib

def prepare_training_data(df, hourly_thresh=5, rolling_thresh=20):
    """
    Labels data and creates features (lags, rolling sums).
    """
    # Feature Engineering
    for lag in [1, 3, 6, 12, 24]:
        df[f'rain_lag_{lag}h'] = df['rain_rafidia'].shift(lag)
        df[f'pressure_lag_{lag}h'] = df['pressure_rafidia'].shift(lag)

    df['rain_rolling_6h_sum'] = df['rain_rafidia'].rolling(window=6).sum()

    # Labeling
    df['Flood_Label'] = 0
    df.loc[(df['rain_rafidia'] >= hourly_thresh) | 
           (df['rain_rolling_6h_sum'] >= rolling_thresh), 'Flood_Label'] = 1
    
    df.dropna(inplace=True)
    return df

def train_flood_model(df):
    features = [col for col in df.columns if 'lag' in col or 'rolling' in col]
    X = df[features]
    y = df['Flood_Label']

    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.3, random_state=42, stratify=y)
    
    scale_weight = (len(y_train) - sum(y_train)) / max(sum(y_train), 1)

    model = XGBClassifier(
        n_estimators=150,
        learning_rate=0.05,
        max_depth=6,
        scale_pos_weight=scale_weight,
        objective='binary:logistic',
        eval_metric='aucpr'
    )

    model.fit(X_train, y_train)
    
    # Save model
    joblib.dump(model, "models/flood_model.pkl")
    joblib.dump(features, "models/feature_names.pkl")
    
    return model

def predict_flood_prob(model, current_data, features):
    probs = model.predict_proba(current_data[features])[:, 1]
    return probs
