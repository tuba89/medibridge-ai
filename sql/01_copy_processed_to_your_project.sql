-- Copy the shared processed table into your own project
CREATE SCHEMA IF NOT EXISTS `YOUR_PROJECT.clinical_analysis` OPTIONS(location='US');

CREATE OR REPLACE TABLE `YOUR_PROJECT.clinical_analysis.tcga_clinical_processed` AS
SELECT * FROM `medi-bridge-2025.kaggle_share.tcga_clinical_processed`;
