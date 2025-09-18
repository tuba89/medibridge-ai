
-- 🚨 IMPORTANT: Replace `YOUR_PROJECT` with your own GCP project ID before running.
-- Example: my-ai-project or my-hackathon-demo
-- Dataset will be created in US region as `clinical_analysis`

CREATE SCHEMA IF NOT EXISTS `YOUR_PROJECT.clinical_analysis` OPTIONS(location='US');

CREATE OR REPLACE TABLE `YOUR_PROJECT.clinical_analysis.tcga_clinical_processed` AS
SELECT * 
FROM `medi-bridge-2025.kaggle_share.tcga_clinical_processed`;
