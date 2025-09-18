# ⚡ Quickstart: MediBridge AI

Minimal setup guide to reproduce the MediBridge AI pipeline inside BigQuery.

> **Semantic Search + AI Care Cards inside BigQuery**

```
[ TCGA Clinical Data ]
          │
          ▼
 [ Embeddings (384D) ]
          │
          ▼
 [ Vector Index (IVF, COSINE) ]
          │
   ┌──────┴───────┐
   │              │
Semantic      AI Care Cards
 Search      (Gemini Flash)
   │              │
   └─────► Clinician Support
```

---

## 1. Prerequisites

* Google Cloud Project with billing enabled
* BigQuery + Vertex AI APIs enabled
* Service account with:

  * `BigQuery Admin`
  * `Vertex AI User`
  * `BigQuery Connection User`

---

## 2. Copy Processed Table

```sql
CREATE SCHEMA IF NOT EXISTS `YOUR_PROJECT.clinical_analysis` OPTIONS(location="US");

CREATE OR REPLACE TABLE `YOUR_PROJECT.clinical_analysis.tcga_clinical_processed` AS
SELECT * 
FROM `medi-bridge-2025.kaggle_share.tcga_clinical_processed`;
```

---

## 3. Create Embeddings Table

```sql
CREATE OR REPLACE TABLE `YOUR_PROJECT.clinical_analysis.clinical_case_embeddings` AS
SELECT
  case_id, clinical_note, disease_category, age_group, gender,
  CAST([] AS ARRAY<FLOAT64>) AS note_embedding
FROM `YOUR_PROJECT.clinical_analysis.tcga_clinical_processed`
WHERE clinical_note IS NOT NULL;
```

Populate embeddings with the Kaggle notebook (MiniLM-L6-v2, 384-D).

---

## 4. Build Vector Index

```sql
CREATE OR REPLACE VECTOR INDEX `YOUR_PROJECT.clinical_analysis.case_vi`
ON `YOUR_PROJECT.clinical_analysis.clinical_case_embeddings` (note_embedding)
OPTIONS(index_type="IVF", distance_type="COSINE", ivf_options='{"num_lists":128}');
```

---

## 5. Run Semantic Search

```sql
WITH q AS (
  SELECT ARRAY<FLOAT64>[ /* paste 384 floats here */ ] AS emb
)
SELECT
  v.base.case_id, v.distance, v.base.diag__primary_diagnosis,
  v.base.diag__ajcc_pathologic_stage, v.base.treatment_types
FROM VECTOR_SEARCH(
  TABLE `YOUR_PROJECT.clinical_analysis.clinical_case_embeddings`,
  'note_embedding',
  TABLE q,
  top_k => 5,
  distance_type => 'COSINE',
  query_column_to_search => 'emb'
) AS v;
```

---

## 6. Generate AI Care Card

```sql
CREATE OR REPLACE TABLE `YOUR_PROJECT.clinical_analysis.clinical_ai_guidance` AS
WITH src AS (
  SELECT case_id, SAFE.SUBSTR(clinical_note, 1, 20000) AS clinical_note
  FROM `YOUR_PROJECT.clinical_analysis.clinical_case_embeddings`
  LIMIT 1
)
SELECT
  case_id,
  AI.GENERATE(
    ('You are an oncology assistant. Return ONLY JSON with fields: '
     || 'summary_bullets ARRAY<STRING>, provisional_category STRING, staging_summary STRING, '
     || 'suggested_modalities ARRAY<STRING>, followup_plan STRING, escalation_flag BOOL, confidence_score FLOAT64',
     clinical_note),
    connection_id => "us.llm_connection",
    endpoint      => "gemini-2.0-flash",
    output_schema => "summary_bullets ARRAY<STRING>, provisional_category STRING, staging_summary STRING, suggested_modalities ARRAY<STRING>, followup_plan STRING, escalation_flag BOOL, confidence_score FLOAT64"
  ) AS guidance,
  CURRENT_TIMESTAMP() AS generated_at
FROM src;
```

☑️ You now have semantic search + AI-generated Care Cards running directly in BigQuery.
