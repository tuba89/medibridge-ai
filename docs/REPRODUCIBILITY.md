# 🔄 Reproducibility Guide — MediBridge AI Pipeline

This guide provides step-by-step instructions to reproduce the **MediBridge AI pipeline** in your own Google Cloud Platform (GCP) project.

⚠️ **Note:** This is a research demo using de-identified TCGA data. It is **not intended for clinical use**.

---

## ⚡ Prerequisites

* Google Cloud Platform (GCP) account with billing enabled
* **BigQuery API** enabled
* **Vertex AI API** enabled
* Familiarity with BigQuery, IAM roles, and service accounts

💰 **Estimated cost:** \$10–30 depending on query size and AI generation calls.

---

## 🪜 Step-by-Step Setup

### Step 1: Create a GCP Project & Enable APIs

```bash
# Create a new project (optional)
gcloud projects create medibridge-demo --name="MediBridge Demo"

# Set project
gcloud config set project YOUR_PROJECT_ID

# Enable required APIs
gcloud services enable bigquery.googleapis.com
gcloud services enable aiplatform.googleapis.com
```

Or via Console:

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create or select a project
3. Enable **BigQuery API** and **Vertex AI API**

---

### Step 2: Create a Service Account

```bash
# Create service account
gcloud iam service-accounts create medibridge-runner \
    --description="Service account for MediBridge AI pipeline" \
    --display-name="MediBridge Runner"

# Get email
export SA_EMAIL="medibridge-runner@YOUR_PROJECT_ID.iam.gserviceaccount.com"

# Create and download JSON key
gcloud iam service-accounts keys create key.json \
    --iam-account=$SA_EMAIL
```

Assign roles:

```bash
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
    --member="serviceAccount:$SA_EMAIL" \
    --role="roles/bigquery.admin"

gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
    --member="serviceAccount:$SA_EMAIL" \
    --role="roles/aiplatform.user"

gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
    --member="serviceAccount:$SA_EMAIL" \
    --role="roles/bigquery.connectionUser"
```

---

### Step 3: Copy the Processed Clinical Table

Run:

```sql
-- 01_copy_processed_to_your_project.sql
CREATE SCHEMA IF NOT EXISTS `YOUR_PROJECT.clinical_analysis` OPTIONS(location="US");

CREATE OR REPLACE TABLE `YOUR_PROJECT.clinical_analysis.tcga_clinical_processed` AS
SELECT *
FROM `medi-bridge-2025.kaggle_share.tcga_clinical_processed`;
```

---

### Step 4: Create Embeddings Table

```sql
-- 02_create_embeddings_table.sql
CREATE OR REPLACE TABLE `YOUR_PROJECT.clinical_analysis.clinical_case_embeddings` AS
SELECT
  case_id, submitter_id, clinical_note, disease_category, primary_site,
  diag__primary_diagnosis, diag__ajcc_pathologic_stage, treatment_types,
  treatment_outcomes, age_group, gender, vital_status,
  CAST([] AS ARRAY<FLOAT64>) AS note_embedding
FROM `YOUR_PROJECT.clinical_analysis.tcga_clinical_processed`
WHERE clinical_note IS NOT NULL;
```

Populate embeddings using the provided **Kaggle notebook** (`SentenceTransformer all-MiniLM-L6-v2`).

---

### Step 5: Build Vector Index

```sql
-- 03_create_vector_index.sql
CREATE OR REPLACE VECTOR INDEX `YOUR_PROJECT.clinical_analysis.case_vi`
ON `YOUR_PROJECT.clinical_analysis.clinical_case_embeddings` (note_embedding)
OPTIONS(index_type="IVF", distance_type="COSINE", ivf_options='{"num_lists":128}');
```

---

### Step 6: Run Semantic Search

```sql
-- 06_vector_search_example.sql
WITH q AS (
  SELECT ARRAY<FLOAT64>[ /* paste 384 floats here */ ] AS emb
)
SELECT
  v.base.case_id,
  v.distance,
  v.base.diag__primary_diagnosis,
  v.base.diag__ajcc_pathologic_stage,
  v.base.treatment_types,
  v.base.treatment_outcomes,
  v.base.gender,
  v.base.age_group,
  SUBSTR(v.base.clinical_note, 1, 220) AS clinical_snippet
FROM VECTOR_SEARCH(
  TABLE `YOUR_PROJECT.clinical_analysis.clinical_case_embeddings`,
  'note_embedding',
  TABLE q,
  top_k => 5,
  distance_type => 'COSINE',
  query_column_to_search => 'emb'
) AS v
ORDER BY v.distance ASC;
```

---

### Step 7: Generate AI Care Cards

```sql
-- 07_ai_generate_care_card.sql
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

