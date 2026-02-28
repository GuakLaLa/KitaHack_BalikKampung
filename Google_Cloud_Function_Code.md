import functions_framework
from google.cloud import bigquery
import json
import requests

client = bigquery.Client()
WEATHER_API_KEY = "Your api key"

DISTRICT_COORDS = {
    'Shah_Alam_Selangor': {'lat': 3.0697, 'lon': 101.5037},
    'Kota_Bharu_Kelantan': {'lat': 6.1254, 'lon': 102.2386},
    'Segamat_Johor': {'lat': 2.5065, 'lon': 102.8158},
    'Kuantan_Pahang': {'lat': 3.8077, 'lon': 103.3260},
    'Pekan_Nanas_Johor': {'lat': 1.5086, 'lon': 103.5097},
    'Penang_Island': {'lat': 5.3496, 'lon': 100.2525},
    'Rantau_Panjang_Kelantan': {'lat': 6.0210, 'lon': 102.0837},
    'Serian_Sarawak': {'lat': 1.1693, 'lon': 110.5689},
    'Kota_Tinggi_Johor': {'lat': 1.7381, 'lon': 103.8999}
}

# --- NEW: Dry season flooding baselines for each district ---
# Based on historical logs, Kota Bharu shows approximately 0.90 km2 even without rain
DISTRICT_BASELINES = {
    'Kota_Bharu_Kelantan': 0.90,
    'Rantau_Panjang_Kelantan': 0.45,
    'Shah_Alam_Selangor': 0.05,
    # Default baseline for other districts is 0.05
}

def get_forecast_rain_list(district):
    coords = DISTRICT_COORDS.get(district)
    if not coords: return [0.0, 0.0, 0.0], "Clear"

    url = f"https://api.openweathermap.org/data/2.5/forecast?lat={coords['lat']}&lon={coords['lon']}&appid={WEATHER_API_KEY}&units=metric"
    resp = requests.get(url).json()

    rain_scales = [0.0, 0.0, 0.0]
    current_weather = "Clear"

    if "list" in resp:
        current_weather = resp["list"][0]["weather"][0]["main"]
        for i, entry in enumerate(resp["list"][:24]):
            rain_3h = entry.get("rain", {}).get("3h", 0)
            if i < 8 : rain_scales[0] += rain_3h
            if i < 16 : rain_scales[1] += rain_3h
            if i < 24 : rain_scales[2] += rain_3h

    return [r for r in rain_scales], current_weather

def query_model_area(district, rain_val):
    # Querying the BigQuery ML model for predicted flood area
    query = f"""
    SELECT predicted_flood_area_km2 as area
    FROM ML.PREDICT(MODEL `malaysia-flood-2026.flood_dataset.flood_model_v1`, (
      SELECT district_name, AVG(elevation) as elevation, {rain_val} as rain_7day_accum
      FROM `malaysia-flood-2026.flood_dataset.impact_table_v2_training`
      WHERE district_name = '{district}'
      GROUP BY district_name
    ))
    """
    query_job = client.query(query)
    results = query_job.result()
    for row in results:
        return row.area
    return 0

@functions_framework.http
def predict_flood(request):
    # Handle CORS preflight request
    if request.method == 'OPTIONS':
        headers = {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'POST',
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Max-Age': '3600'
        }
        return ('', 204, headers)

    headers = {'Access-Control-Allow-Origin': '*'}

    try:
        request_json = request.get_json(silent=True)
        district = request_json.get('district', 'Kota_Bharu_Kelantan')
        rain_list, current_weather = get_forecast_rain_list(district)

        found_day = None
        today_area = 0
        final_risk = "LOW"
        forecast_list = []
        day_names = ["Today", "Tomorrow", "Day 3"]

        # Retrieve the specific baseline for the selected district to handle false positives
        baseline = DISTRICT_BASELINES.get(district, 0.05)

        for i, rain_val in enumerate(rain_list):
            area = query_model_area(district, rain_val)
            
            # --- Core Improvement: Calculating Excess Area ---
            # We subtract the baseline to differentiate between geographical status quo and actual flood anomalies
            excess_area = max(0, area - baseline)
            print(f"DEBUG: Day {i}, {district}, Area: {area}, Excess: {excess_area}")

            # Use excess_area to determine the risk level for the early warning system
            current_day_risk = "LOW"
            if excess_area >= 0.50: current_day_risk = "HIGH"
            elif excess_area >= 0.15: current_day_risk = "MEDIUM"

            forecast_list.append({
                "day": day_names[i],
                "riskLevel": current_day_risk
            })

            if i == 0:
                today_area = area
                final_risk = current_day_risk

            if current_day_risk != "LOW" and found_day is None:
                found_day = i

        reminder = None
        if found_day == 0:
            reminder = "Flood risk detected TODAY! Take action."
        elif found_day is not None:
            reminder = f"Heavy rain forecast! Flood predicted in {found_day} days."

        response_data = {
            "location": district.replace("_", " "),
            "riskLevel": final_risk,
            "predictedArea": f"{today_area:.4f} km2", # Total area displayed on UI
            "currentWeather": current_weather,
            "floodReminder": reminder, 
            "daysUntilFlood": found_day,
            "forecast": forecast_list
        }

        return (json.dumps(response_data), 200, {**headers, 'Content-Type': 'application/json'})
        
    except Exception as e:
        return (json.dumps({"error": str(e)}), 500, headers)