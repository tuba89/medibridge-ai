SELECT
  disease_category,
  forecast_timestamp,
  forecast_value,
  prediction_interval_lower_bound,
  prediction_interval_upper_bound,
  ai_forecast_status
FROM AI.FORECAST(
  TABLE `YOUR_PROJECT.clinical_analysis.case_daily`,
  data_col      => 'n',
  timestamp_col => 'd',
  id_cols       => ['disease_category'],
  horizon       => 14
)
ORDER BY disease_category, forecast_timestamp;
