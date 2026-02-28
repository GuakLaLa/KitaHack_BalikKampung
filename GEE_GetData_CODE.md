import ee

# 1. Initialization
ee.Initialize(project='malaysia-flood-2026')

locations = [
    {'name': 'Serian_Sarawak', 'coords': [110.5689, 1.1693]},
    {'name': 'Segamat_Johor', 'coords': [102.8158, 2.5065]},
    {'name': 'Kota_Tinggi_Johor', 'coords': [103.8999, 1.7381]},
    {'name': 'Shah_Alam_Selangor', 'coords': [101.5037, 3.0697]},   # Representative of urban flooding (Major 2021 flood zone)
    {'name': 'Pekan_Nanas_Johor', 'coords': [103.5097, 1.5086]},
    {'name': 'Kuantan_Pahang', 'coords': [103.3260, 3.8077]},      # Flood-prone area in the lower Pahang River
    {'name': 'Rantau_Panjang_Kelantan', 'coords': [102.0837, 6.0210]}, # River overflow zone at the Thai-Malaysia border
    {'name': 'Kota_Bharu_Kelantan', 'coords': [102.2386, 6.1254]},    # Gateway for East Coast Monsoons
    {'name': 'Penang_Island', 'coords': [100.2525, 5.3496]}       # Representative of West Coast flash floods/mountain floods
]

# --- Configuration: Key Dates (Includes Flood Peaks and Dry Comparison Periods) ---
target_dates = [
    # === Flood Peak Periods ===
    '2026-01-10', '2026-01-17',                  # Current 2026 Monsoon
    '2025-12-20', '2025-11-25', '2025-01-05',    # Late 2025 Monsoon
    '2024-12-24', '2024-12-28', '2024-03-02',    # Major 2024 flood events
    '2024-01-15', '2024-02-10',                  # Early 2024 Monsoon

    # === Dry Season / Normal Baselines ===
    # This section is critical; the AI must learn the logic that "no rain equals no flood."
    '2025-07-01', '2025-07-15', '2025-08-10',    # 2025 Dry Season
    '2024-06-20', '2024-07-05', '2024-08-25',    # 2024 Dry Season
    '2025-05-15', '2024-05-10',                  # Inter-monsoon dry periods
    '2025-09-05', '2024-09-12'                   # Relatively dry periods in September
]

def run_deep_denoised_analysis(loc_name, lon, lat, date_str):
    try:
        roi = ee.Geometry.Point([lon, lat]).buffer(10000)
        start_date = ee.Date(date_str)

        # --- A. Permanent Water Denoising (JRC Global Surface Water) ---
        # Areas with an occurrence frequency > 80% are defined as "permanent water."
        jrc = ee.Image("JRC/GSW1_4/GlobalSurfaceWater").select('occurrence')
        permanent_water_mask = jrc.gt(80).clip(roi)

        # --- B. Terrain and Precipitation (Expanded to 7-day lookback) ---
        dem = ee.Image("USGS/SRTMGL1_003").clip(roi)
        gpm = ee.ImageCollection("NASA/GPM_L3/IMERG_V07").select('precipitation')

        # 7-day accumulated rainfall (Capturing the lag effect)
        rain_7day = gpm.filterDate(start_date.advance(-6, 'day'), start_date.advance(1, 'day')) \
                        .mean().multiply(168).reduceRegion(ee.Reducer.mean(), roi, 10000).get('precipitation')

        # --- C. Sentinel-1 Flood Calculation (Optimized Thresholds) ---
        s1 = ee.ImageCollection('COPERNICUS/S1_GRD').filterBounds(roi) \
                .filter(ee.Filter.eq('instrumentMode', 'IW')) \
                .filter(ee.Filter.listContains('transmitterReceiverPolarisation', 'VH'))

        before = s1.filterDate('2025-06-01', '2025-08-31').median().clip(roi)
        after_col = s1.filterDate(start_date, start_date.advance(5, 'day'))

        if after_col.size().getInfo() > 0:
            after = after_col.min().clip(roi)
            diff = before.select('VH').subtract(after.select('VH'))

            # Core Improvement: Increased difference threshold to 5.0 and excluded permanent water.
            flood_mask = diff.gt(5.0) \
                              .And(after.select('VH').lt(-22)) \
                              .And(permanent_water_mask.Not()) \
                              .updateMask(ee.Terrain.slope(dem).lt(5))

            stats = flood_mask.multiply(ee.Image.pixelArea()).reduceRegion(
                reducer=ee.Reducer.sum(), geometry=roi, scale=30, maxPixels=1e9
            )
            area_km2 = ee.Number(stats.get('VH', 0)).divide(1e6)

            # --- D. Export to BigQuery ---
            task = ee.batch.Export.table.toBigQuery(
                collection = ee.FeatureCollection([ee.Feature(None, {
                    'timestamp': date_str,
                    'district_name': loc_name,
                    'rain_7day_accum': rain_7day,
                    'flood_area_km2': area_km2,
                    'elevation': dem.reduceRegion(ee.Reducer.mean(), roi, 30).get('elevation')
                })]),
                description = f'DeepDenoiser_{loc_name}_{date_str.replace("-", "_")}',
                table = 'malaysia-flood-2026.flood_dataset.impact_table_v2', # Saving to a new table version
                append = True
            )
            task.start()
            print(f"✅ Deep denoising task submitted: {loc_name}")
    except Exception as e:
        print(f"❌ Error occurred: {str(e)}")

print("🚀 Launching GEE Data Scraping Pipeline...")
for loc in locations:
    for d in target_dates:
        run_deep_denoised_analysis(loc['name'], loc['coords'][0], loc['coords'][1], d)
print("🏁 All data scraping tasks have been queued. Please check GEE Tasks for progress.")