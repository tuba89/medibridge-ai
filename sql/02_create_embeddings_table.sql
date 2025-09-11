CREATE OR REPLACE TABLE `YOUR_PROJECT.clinical_analysis.clinical_case_embeddings` AS
SELECT
  case_id, submitter_id, clinical_note, disease_category, primary_site,
  diag__primary_diagnosis, diag__ajcc_pathologic_stage, treatment_types,
  treatment_outcomes, age_group, gender, vital_status,
  CAST([] AS ARRAY<FLOAT64>) AS note_embedding
FROM `YOUR_PROJECT.clinical_analysis.tcga_clinical_processed`
WHERE clinical_note IS NOT NULL;
