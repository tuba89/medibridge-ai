-- Simple daily series: one synthetic date per case (year -> Jan 1)
CREATE OR REPLACE TABLE `YOUR_PROJECT.clinical_analysis.case_daily` AS
SELECT
  DATE(
    CONCAT(
      CAST(
        COALESCE(
          diag__year_of_diagnosis,
          2015 + MOD(ABS(FARM_FINGERPRINT(CAST(case_id AS STRING))), 8)
        ) AS STRING
      ),
      '-01-01'
    )
  ) AS d,
  COALESCE(disease_category, 'Unknown') AS disease_category,
  COUNT(*) AS n
FROM `YOUR_PROJECT.clinical_analysis.tcga_clinical_processed`
GROUP BY 1,2
HAVING d IS NOT NULL;
