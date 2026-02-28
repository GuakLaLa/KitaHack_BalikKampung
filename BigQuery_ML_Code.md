-- Create or update the machine learning model in BigQuery
CREATE OR REPLACE MODEL `malaysia-flood-2026.flood_dataset.flood_model_v1`
OPTIONS(
  -- Utilizing a Boosted Tree Regressor (XGBoost), which is highly effective 
  -- for capturing non-linear patterns in geospatial and weather data
  model_type='boosted_tree_regressor', 
  
  -- Defining the flood extent (in square kilometers) as the target label for prediction
  input_label_cols=['flood_area_km2']  
) AS
-- Selecting high-quality features derived from our denoised GEE pipeline
SELECT 
  flood_area_km2,   -- Target Variable: The actual flood area detected via Sentinel-1
  rain_7day_accum,  -- Feature: 7-day cumulative rainfall from NASA GPM (captures soil saturation)
  elevation,        -- Feature: Mean elevation from USGS SRTM (topographical risk factor)
  district_name     -- Feature: Categorical data to account for unique regional geography
FROM `malaysia-flood-2026.flood_dataset.impact_table_v2_training`
