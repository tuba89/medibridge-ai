
-- Generate a structured Care Card for one case using Gemini Flash

CREATE OR REPLACE TABLE `YOUR_PROJECT.clinical_analysis.clinical_ai_guidance` AS
WITH src AS (
  SELECT case_id, SAFE.SUBSTR(clinical_note, 1, 5000) AS clinical_note
  FROM `YOUR_PROJECT.clinical_analysis.clinical_case_embeddings`
  LIMIT 1
)
SELECT
  case_id,
  AI.GENERATE(
    (
      'You are an oncology assistant. Return ONLY valid JSON with fields: '
      || 'summary_bullets ARRAY<STRING>, provisional_category STRING, staging_summary STRING, '
      || 'suggested_modalities ARRAY<STRING>, followup_plan STRING, escalation_flag BOOL, confidence_score FLOAT64. '
      || 'Clinical note: ' || clinical_note
    ),
    connection_id => 'us.llm_connection',
    endpoint      => 'gemini-2.0-flash',
    output_schema => 'summary_bullets ARRAY<STRING>, provisional_category STRING, staging_summary STRING, '
                     || 'suggested_modalities ARRAY<STRING>, followup_plan STRING, '
                     || 'escalation_flag BOOL, confidence_score FLOAT64'
  ) AS guidance,
  CURRENT_TIMESTAMP() AS generated_at
FROM src;
