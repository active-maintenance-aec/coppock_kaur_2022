# coppock_kaur_2022/run_all.R
# Runs the whole reproduction in order: fetch and verify the deposited archive,
# reshape the case data, then every published table and figure, then the in-text
# quantities. Every script is self-contained and can also be run on its own,
# except that the figure and in-text scripts read what the scripts above them
# write.

library(here)
here::i_am("run_all.R")

# Deposited archive ----
# Downloads from Dataverse on a fresh clone; verifies checksums either way.
source(here::here("download_original.R"))

# Data ----
# apply_appendix_c_corrections.R restores the seven imputation probabilities the
# deposited case file transcribes differently from the appendix C narrative that
# states them, and writes the corrected case file every script below reads.
source(here::here("maintained", "apply_appendix_c_corrections.R"))
source(here::here("maintained", "clean_cases.R"))

# Tables ----
source(here::here("maintained", "table_3_toy_example.R"))
source(here::here("maintained", "table_4_probabilistic.R"))
source(here::here("maintained", "table_5_imputation_summary.R"))
source(here::here("maintained", "table_b1_b2_case_dataset.R"))

# Figures ----
# figures_2_a1 and figures_3_a2 read output/cases_long.rds from clean_cases.R.
source(here::here("maintained", "figure_1_toy_bounds.R"))
source(here::here("maintained", "figures_2_a1_ate_bounds.R"))
source(here::here("maintained", "figures_3_a2_att_atu_bounds.R"))
source(here::here("maintained", "figure_4_expert_validation.R"))

# In-text quantities ----
# text_summary_stats.R and text_seed_sensitivity.R read the figure output, so
# they run after the figures. text_seed_sensitivity.R repeats the Figure 2 and A1
# simulation twenty times and takes about a minute.
source(here::here("maintained", "text_expert_agreement.R"))
source(here::here("maintained", "text_imputation_counts.R"))
source(here::here("maintained", "text_summary_stats.R"))
source(here::here("maintained", "text_expected_bounds.R"))
source(here::here("maintained", "text_seed_sensitivity.R"))

# Ground truth ----
# Checks the published claims against both instruments: a row in the ground truth
# and a block in maintained/in_text_claims.R, which this script runs. It halts the
# run if a published claim is checked by neither, or if the two disagree.
source(here::here("ground_truth", "build_ground_truth.R"))

# Deposited archive, again ----
# The check at the top of this file is a precondition: it says original/ was intact
# before anything ran. Nothing above writes to original/, and this second pass is what
# demonstrates it rather than assuming it. Nothing is downloaded; the files are already
# present and are re-checked against the manifest on checksum, byte size and membership.
source(here::here("download_original.R"))
