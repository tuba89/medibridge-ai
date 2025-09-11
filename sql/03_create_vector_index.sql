CREATE OR REPLACE VECTOR INDEX `YOUR_PROJECT.clinical_analysis.case_vi`
ON `YOUR_PROJECT.clinical_analysis.clinical_case_embeddings` (note_embedding)
OPTIONS(index_type='IVF', distance_type='COSINE', ivf_options='{"num_lists":128}');
