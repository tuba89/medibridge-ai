
-- Find top-k similar cases (using 384-D MiniLM embeddings)

DECLARE top_k INT64 DEFAULT 5;

WITH q AS (
  SELECT ARRAY<FLOAT64>[
    -- TODO: Paste the 384 floats here 
  ] AS emb
)

SELECT
  v.base.case_id,
  (1.0 - v.distance) AS similarity,  -- convert distance to similarity
  v.base.diag__primary_diagnosis,
  v.base.diag__ajcc_pathologic_stage,
  v.base.treatment_types,
  v.base.treatment_outcomes,
  v.base.age_group,
  v.base.gender,
  v.base.vital_status,
  SUBSTR(v.base.clinical_note, 1, 220) AS clinical_snippet
FROM VECTOR_SEARCH(
  TABLE `YOUR_PROJECT.clinical_analysis.clinical_case_embeddings`,
  'note_embedding',
  TABLE q,
  top_k => top_k,
  distance_type => 'COSINE',
  query_column_to_search => 'emb'
) AS v
ORDER BY similarity DESC;
