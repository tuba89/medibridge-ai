# 📊 Data Appendix - TCGA Clinical (Processed & Analysis-Ready)

## Overview

**Table:** `medi-bridge-2025.kaggle_share.tcga_clinical_processed`  
**Access:** Public, read-only BigQuery table  
**Rows:** ~11,428 consolidated clinical cases (one row per case_id)  
**Source:** TCGA clinical data from ISB-CGC public BigQuery datasets

[**Open in BigQuery Console**](https://console.cloud.google.com/bigquery?ws=!1m5!1m4!4m3!1smedi-bridge-2025!2skaggle_share!3stcga_clinical_processed)

---

## Table Schema

### Core Identifiers
- **`case_id`** (STRING) — Unique case identifier, primary key
- **`submitter_id`** (STRING) — TCGA submitter case ID  

### Demographics & Clinical Context
- **`disease_category`** (STRING) : Canonical cancer group (e.g., Breast, Lung, Colorectal)
- **`primary_site`** (STRING) : Primary tumor anatomical site
- **`age_group`** (STRING):— Derived age bucket (e.g., "50-59", "60-69")
- **`gender`** (STRING) : Reported gender
- **`race`** (STRING) : Reported race/ethnicity
- **`vital_status`** (STRING) : Vital status at last follow-up (Alive/Dead)

### Diagnosis Information
- **`diag__primary_diagnosis`** (STRING) : Primary diagnosis text
- **`diag__ajcc_pathologic_stage`** (STRING) : AJCC pathologic stage (if available)
- **`diag__tumor_grade`** (STRING) : Tumor grade classification
- **`diag__morphology`** (STRING) : Histological morphology code

### Treatment Data
- **`treatment_types`** (STRING) : Aggregated treatment modalities received
- **`treatment_outcomes`** (STRING) : Aggregated treatment outcomes/responses
- **`treatment_count`** (INTEGER) : Number of distinct treatments
- **`followup_count`** (INTEGER) : Number of follow-up records

### Analysis-Ready Features
- **`clinical_note`** (STRING) : **Key field** - Cleaned clinical summary text suitable for embeddings/LLMs
- **`has_stage_info`** (BOOLEAN) : Whether staging information is available
- **`has_treatment_outcome`** (BOOLEAN) : Whether treatment outcome data exists
- **`years_since_diagnosis`** (FLOAT64) : Time elapsed since initial diagnosis

---

## Sample Queries

### Basic Exploration
```sql
-- Row count and basic stats
SELECT 
  COUNT(*) AS total_cases,
  COUNT(DISTINCT disease_category) AS disease_types,
  COUNT(DISTINCT primary_site) AS primary_sites
FROM `medi-bridge-2025.kaggle_share.tcga_clinical_processed`;
```

### Disease Distribution
```sql
-- Top cancer types by case count
SELECT 
  disease_category, 
  COUNT(*) AS case_count,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS percentage
FROM `medi-bridge-2025.kaggle_share.tcga_clinical_processed`
GROUP BY disease_category
ORDER BY case_count DESC;
```

### Clinical Notes Sample
```sql
-- Peek at clinical notes for different cancer types
SELECT 
  case_id,
  disease_category,
  diag__primary_diagnosis,
  diag__ajcc_pathologic_stage,
  SUBSTR(clinical_note, 1, 200) AS note_snippet
FROM `medi-bridge-2025.kaggle_share.tcga_clinical_processed`
WHERE clinical_note IS NOT NULL
ORDER BY disease_category, case_id
LIMIT 10;
```

### Treatment Analysis
```sql
-- Cases with complete treatment outcome data
SELECT 
  disease_category,
  COUNT(*) AS total_cases,
  SUM(CASE WHEN has_treatment_outcome THEN 1 ELSE 0 END) AS with_outcomes,
  ROUND(AVG(treatment_count), 1) AS avg_treatments_per_case
FROM `medi-bridge-2025.kaggle_share.tcga_clinical_processed`
GROUP BY disease_category
ORDER BY total_cases DESC;
```

---

## Data Lineage & ETL Process

### 1. Source Data (ISB-CGC TCGA)
- **`isb-cgc-bq.TCGA_hg38_data_v0.clinical_diagnoses`**
- **`isb-cgc-bq.TCGA_hg38_data_v0.clinical_treatments`**  
- **`isb-cgc-bq.TCGA_hg38_data_v0.clinical_follow_up`**
- **`isb-cgc-bq.TCGA_hg38_data_v0.clinical_cases`**

### 2. Consolidation Process
```sql
-- Pseudo-code for case-level consolidation
WITH case_base AS (
  SELECT case_gdc_id, submitter_id, disease_type, primary_site
  FROM clinical_cases
),
diagnosis_ranked AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY case_gdc_id ORDER BY diagnosis_date DESC) as rn
  FROM clinical_diagnoses  
),
treatment_agg AS (
  SELECT 
    case_gdc_id,
    STRING_AGG(DISTINCT treatment_type) AS treatment_types,
    STRING_AGG(DISTINCT treatment_outcome) AS treatment_outcomes,
    COUNT(*) AS treatment_count
  FROM clinical_treatments
  GROUP BY case_gdc_id
)
SELECT 
  case_base.*,
  diagnosis_ranked.primary_diagnosis,
  diagnosis_ranked.ajcc_pathologic_stage,
  treatment_agg.treatment_types,
  -- ... additional fields
  CONCAT(
    'Patient: ', age_at_diagnosis, ' year old ', gender, ' ',
    'Diagnosis: ', primary_diagnosis, ' ',
    'Stage: ', COALESCE(ajcc_pathologic_stage, 'Unknown'), ' ',
    'Treatments: ', COALESCE(treatment_types, 'None documented')
  ) AS clinical_note
FROM case_base
LEFT JOIN diagnosis_ranked ON case_base.case_gdc_id = diagnosis_ranked.case_gdc_id AND diagnosis_ranked.rn = 1
LEFT JOIN treatment_agg ON case_base.case_gdc_id = treatment_agg.case_gdc_id
```

### 3. Data Quality & Normalization
- **Diagnosis ranking:** Most recent primary diagnosis per case
- **Stage standardization:** AJCC stages normalized to consistent format
- **Treatment aggregation:** Multiple treatments rolled up into summary strings
- **Clinical note generation:** Structured narrative suitable for LLM processing
- **Derived features:** Age groups, disease categories, boolean flags

### 4. Export & Sharing
- **Extraction date:** June 2025
- **Export format:** BigQuery table optimized for analytics workloads
- **Access:** Public read-only for research/educational use

---

## Usage Guidelines

### ✔️ Appropriate Uses
- Academic research on cancer epidemiology
- Machine learning model development (non-clinical)
- Educational demonstrations of healthcare analytics
- Semantic search and NLP technique validation

### 🚩 Inappropriate Uses  
- Clinical decision making for actual patients
- Diagnostic or treatment recommendations
- Commercial medical products without proper validation
- Any use that could impact patient care

### 🔒 Privacy & Ethics
- **De-identification:** All data is publicly available and de-identified per TCGA guidelines
- **No PHI/PII:** No protected health information or personally identifiable information
- **Research purpose:** Intended for research and educational use only
- **Attribution required:** Please cite TCGA and ISB-CGC in any publications

---

## Performance Notes

### Query Optimization Tips
- **Use `case_id` for point lookups** (indexed)
- **Filter on `disease_category`** for disease-specific analysis (good cardinality)  
- **`clinical_note` is TEXT** — use `SUBSTR()` for previews, full text for embeddings
- **Avoid `SELECT *`** on large result sets (>1000 rows)

### Table Statistics
- **Compressed size:** ~45 MB
- **Uncompressed size:** ~180 MB  
- **Partitioning:** None (single partition, case-level data)
- **Clustering:** Clustered by `disease_category` for optimal filtering

---

## Related Tables (Created by Pipeline)

When you run the full MediBridge pipeline, these additional tables are created:

- **`clinical_case_embeddings`** — Vector embeddings of clinical notes
- **`case_vi`** — Vector index for similarity search (IVF, COSINE distance)
- **`clinical_ai_guidance`** — AI-generated care cards and recommendations  
- **`case_daily` / `case_monthly`** — Time series aggregations for forecasting
- **`tumor_board_summaries`** — Structured summaries for clinical review

---

## Support & Issues

For questions about the data processing pipeline or to report data quality issues:
1. Check the main [README](../README.md) for pipeline documentation
2. Review the [reproducibility guide](REPRODUCIBILITY.md) for setup instructions  
3. Open an issue in this repository for specific problems

**Note:** This is a research dataset. For questions about the underlying TCGA data, refer to the official [TCGA documentation](https://docs.gdc.cancer.gov/) and [ISB-CGC resources](https://isb-cancer-genomics-cloud.readthedocs.io/).
