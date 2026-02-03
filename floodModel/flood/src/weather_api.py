import openmeteo_requests
import pandas as pd
from retry_requests import retry

def fetch_weather_data(lat, lon, name, start_date="2004-01-01", end_date="2024-12-31"):
    """
    Fetches historical weather data from Open-Meteo API.
    """
    retry_strategy = retry(retries=5, backoff_factor=0.2)
    openmeteo = openmeteo_requests.Client()
    
    url = "https://archive-api.open-meteo.com/v1/archive"
    params = {
        "latitude": lat,
        "longitude": lon,
        "start_date": start_date,
        "end_date": end_date,
        "hourly": ["precipitation", "pressure_msl", "relative_humidity_2m", "temperature_2m", "wind_speed_10m"],
        "timezone": "Africa/Cairo"
    }
    
    print(f"Fetching data for {name}...")
    responses = openmeteo.weather_api(url, params=params)
    res = responses[0]

    hourly = res.Hourly()
    data = {
        "timestamp": pd.date_range(
            start=pd.to_datetime(hourly.Time(), unit="s"),
            end=pd.to_datetime(hourly.TimeEnd(), unit="s"),
            freq=pd.Timedelta(seconds=hourly.Interval()),
            inclusive="left"
        ),
        f"rain_{name}": hourly.Variables(0).ValuesAsNumpy(),
        f"pressure_{name}": hourly.Variables(1).ValuesAsNumpy(),
        f"humidity_{name}": hourly.Variables(2).ValuesAsNumpy(),
        f"temp_{name}": hourly.Variables(3).ValuesAsNumpy(),
        f"wind_{name}": hourly.Variables(4).ValuesAsNumpy(),
    }
    return pd.DataFrame(data)

if __name__ == "__main__":
    # Example usage for Rafidia
    df_rafidia = fetch_weather_data(32.2211, 35.2333, "rafidia")
    df_shavei = fetch_weather_data(32.2750, 35.1700, "shavei")
    
    final_df = pd.merge(df_rafidia, df_shavei, on="timestamp")
    final_df.to_csv("data/raw/floodguard_weather_raw.csv", index=False)
    print("Weather data saved to data/raw/floodguard_weather_raw.csv")
