-- 06_vector_search_example.sql
-- Find top-k similar cases using your precomputed embeddings (384-D, MiniLM-L6-v2)
-- Replace the three ALL-CAPS placeholders before running.

DECLARE top_k INT64 DEFAULT 5;

-- Paste the 384 comma-separated floats from the notebook where indicated
--  paste the entire single line from assets/sample_query_embedding_minilm.txt here 
WITH q AS (
  SELECT ARRAY<FLOAT64>[
    /* <PASTE_384_FLOATS_HERE> */
  ] AS emb
)

SELECT
  v.base.case_id,
  v.distance,
  v.base.diag__primary_diagnosis,
  v.base.diag__ajcc_pathologic_stage,
  v.base.treatment_types,
  v.base.treatment_outcomes,
  v.base.age_group,
  v.base.gender,
  v.base.vital_status,
  SUBSTR(v.base.clinical_note, 1, 220) AS clinical_snippet
FROM VECTOR_SEARCH(
  TABLE `YOUR_PROJECT.clinical_analysis.clinical_case_embeddings`,  -- <== replace
  'note_embedding',
  TABLE q,
  top_k => top_k,
  distance_type => 'COSINE',
  query_column_to_search => 'emb'
) AS v
ORDER BY v.distance ASC;
