Open in Console:  
https://console.cloud.google.com/bigquery?ws=!1m5!1m4!4m3!1smedi-bridge-2025!2skaggle_share!3stcga_clinical_processed

---

## 🚀 What this repo contains

- `docs/DATA_APPENDIX.md` — Full dataset details, schema, lineage, and example queries  
- `docs/REPRODUCIBILITY.md` — End-to-end steps to run the pipeline in your own GCP project  
- `sql/` — Example SQL for building processed tables, searching, and forecasting  
- `assets/` — Figures for the writeup (semantic results, care card, forecasts)

---

## 🏗️ Pipeline (BigQuery-native)

```mermaid
graph TD
  A[TCGA Clinical (ISB-CGC)] --> C[Processed Case Table<br/>kaggle_share.tcga_clinical_processed]
  C --> E[Embeddings Table<br/>clinical_case_embeddings]
  E --> I[Vector Index (IVF)<br/>case_vi]
  Q[Clinician Query] --> QE[Embed Query Locally]
  QE --> I
  I --> K[Top-k Similar Cases]
  K --> G[AI.GENERATE → Care Card]
  C --> S[Build Daily/Monthly Series]
  S --> F[AI.FORECAST → Incidence]
  G --> D[Doctor UI / Notebook Demo]
  F --> D
  K --> D
