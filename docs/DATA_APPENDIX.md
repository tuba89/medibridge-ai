# 📊 Data Appendix: TCGA Clinical (Processed & Analysis-Ready)

## Overview

**Table:** `medi-bridge-2025.kaggle_share.tcga_clinical_processed`
**Access:** Public, read-only BigQuery table
**Rows:** \~11,428 consolidated clinical cases (one row per case\_id)
**Source:** TCGA clinical data from ISB-CGC public BigQuery datasets

[**Open in BigQuery Console**](https://console.cloud.google.com/bigquery?ws=!1m5!1m4!4m3!1smedi-bridge-2025!2skaggle_share!3stcga_clinical_processed)

---

## Table Schema

### Core Identifiers

* **`case_id`** (STRING) : Unique case identifier, primary key
* **`submitter_id`** (STRING) : TCGA submitter case ID

### Demographics & Clinical Context

* **`disease_category`** (STRING) : Canonical cancer group (e.g., Breast, Lung, Colorectal)
* **`primary_site`** (STRING) : Primary tumor anatomical site
* **`age_group`** (STRING) : Derived age bucket (e.g., "50-59", "60-69")
* **`gender`** (STRING) : Reported gender
* **`race`** (STRING) : Reported race/ethnicity
* **`vital_status`** (STRING) : Vital status at last follow-up (Alive/Dead)

### Diagnosis Information

* **`diag__primary_diagnosis`** (STRING) : Primary diagnosis text
* **`diag__ajcc_pathologic_stage`** (STRING) : AJCC pathologic stage (if available)
* **`diag__tumor_grade`** (STRING) : Tumor grade classification
* **`diag__morphology`** (STRING) : Histological morphology code

### Treatment Data

* **`treatment_types`** (STRING) : Aggregated treatment modalities received
* **`treatment_outcomes`** (STRING) : Aggregated treatment outcomes/responses
* **`treatment_count`** (INTEGER) : Number of distinct treatments
* **`followup_count`** (INTEGER) : Number of follow-up records

### Analysis-Ready Features

* **`clinical_note`** (STRING) : Cleaned clinical summary text used for embeddings/LLMs
* **`has_stage_info`** (BOOLEAN) : Whether staging information is available
* **`has_treatment_outcome`** (BOOLEAN) : Whether treatment outcome data exists

---

## Sample Queries

**Row count & basic stats**

```sql
SELECT 
  COUNT(*) AS total_cases,
  COUNT(DISTINCT disease_category) AS disease_types,
  COUNT(DISTINCT primary_site) AS primary_sites
FROM `medi-bridge-2025.kaggle_share.tcga_clinical_processed`;
```

**Top cancer types**

```sql
SELECT 
  disease_category, 
  COUNT(*) AS case_count,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS percentage
FROM `medi-bridge-2025.kaggle_share.tcga_clinical_processed`
GROUP BY disease_category
ORDER BY case_count DESC;
```

**Clinical note snippets**

```sql
SELECT 
  case_id,
  disease_category,
  diag__primary_diagnosis,
  diag__ajcc_pathologic_stage,
  SUBSTR(clinical_note, 1, 200) AS note_snippet
FROM `medi-bridge-2025.kaggle_share.tcga_clinical_processed`
WHERE clinical_note IS NOT NULL
LIMIT 10;
```

**Treatment outcomes**

```sql
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

1. **Source Data**: ISB-CGC TCGA clinical tables (`diagnoses`, `treatments`, `follow_up`, `cases`)
2. **Consolidation**: One row per case, with most recent diagnosis + rolled-up treatments
3. **Enrichment**: Derived fields (`age_group`, `has_stage_info`, `has_treatment_outcome`) + generated `clinical_note`
4. **Export**: Optimized BigQuery table for embeddings, semantic search, and AI generation

---

## Usage Guidelines

✔️ **Appropriate Uses**

* Academic cancer research
* ML/NLP demonstrations
* Educational purposes

🚩 **Not Allowed**

* Clinical decision-making
* Real patient diagnosis or treatment
* Commercial medical products without validation

🔒 **Privacy & Ethics**

* Public, de-identified TCGA data
* No PHI/PII
* Cite TCGA and ISB-CGC in any publications

---

## Performance Notes

* Use `case_id` for direct lookups
* Filter by `disease_category` for efficient disease-specific queries
* Use `SUBSTR()` for previewing `clinical_note` instead of selecting full text

**Table Size**

* Compressed: \~45 MB
* Uncompressed: \~180 MB
* No partitioning; clustered by `disease_category`

---

## Related Tables (Pipeline Outputs)

* **`clinical_case_embeddings`** : vector embeddings of notes
* **`case_vi`** : vector index for similarity search
* **`clinical_ai_guidance`** : AI-generated Care Cards

---

## Support & Issues

For help with the pipeline or to report issues:

* Check the [README](../README.md)
* Review the reproducibility guide
* Open a GitHub issue

**Note:** This is a research dataset. For original TCGA data, see [TCGA docs](https://docs.gdc.cancer.gov/) and [ISB-CGC resources](https://isb-cancer-genomics-cloud.readthedocs.io/).


