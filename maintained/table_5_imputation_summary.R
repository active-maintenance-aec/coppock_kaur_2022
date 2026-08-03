# coppock_kaur_2022/maintained/table_5_imputation_summary.R
# Output: output/table_5_imputation_summary.csv
# Depends on: helpers.R, apply_appendix_c_corrections.R output
# Description: Table 5, the distribution of imputed unit-level causal effects.
#              The paper prints the democratization row; the end-of-conflict row
#              is written out alongside it.
#
#   The table reads tau_i, the difference of the two point imputations. The
#   appendix C corrections touch probabilities only, so no cell here moves.

source(here::here("maintained", "helpers.R"))

dat <- read_rds(here::here("maintained", "output", "cases_corrected.rds"))

guess_levels <- c("Negative Effect", "No Effect", "Positive Effect", "Unimputed")

table_5 <- dat |>
  mutate(
    guess = factor(
      case_when(
        tau_i == -1 ~ "Negative Effect",
        tau_i == 0 ~ "No Effect",
        tau_i == 1 ~ "Positive Effect",
        is.na(tau_i) ~ "Unimputed"
      ),
      levels = guess_levels
    )
  ) |>
  tabyl(transition_fac, guess) |>
  adorn_percentages("row") |>
  adorn_pct_formatting(digits = 0) |>
  adorn_ns()

print(table_5)

write_csv(table_5, here::here("maintained", "output", "table_5_imputation_summary.csv"))
