# 🔄 Reproducibility Guide — MediBridge AI Pipeline

This guide provides step-by-step instructions to reproduce the MediBridge AI pipeline in your own Google Cloud Platform (GCP) project.

---

## ⚡ Prerequisites

- **Google Cloud Platform account** with billing enabled
- **BigQuery API** enabled in your project
- **Vertex AI API** enabled in your project  
- **Basic familiarity** with BigQuery, service accounts, and IAM roles

**Estimated costs:** $10-50 depending on query complexity and model usage (embeddings + AI.GENERATE/FORECAST calls).

---

## 🪜 Step-by-Step Setup

### Step 1: Create GCP Project & Enable APIs

```bash
# Create new project (optional)
gcloud projects create medibridge-demo-project --name="MediBridge Demo"

# Set project
gcloud config set project YOUR_PROJECT_ID

# Enable required APIs
gcloud services enable bigquery.googleapis.com
gcloud services enable aiplatform.googleapis.com
```

**Or via Console:**
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create new project or select existing one
3. Go to **APIs & Services > Library**
4. Enable **BigQuery API** and **Vertex AI API**

### Step 2: Create Service Account

```bash
# Create service account
gcloud iam service-accounts create medibridge-runner \
    --description="Service account for MediBridge AI pipeline" \
    --display-name="MediBridge Runner"

# Get the service account email
export SA_EMAIL="medibridge-runner@YOUR_PROJECT_ID.iam.gserviceaccount.com"

# Create and download key file
gcloud iam service-accounts keys
