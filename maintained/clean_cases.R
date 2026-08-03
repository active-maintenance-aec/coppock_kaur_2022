# coppock_kaur_2022/maintained/clean_cases.R
# Output: output/cases_long.rds
# Depends on: helpers.R, apply_appendix_c_corrections.R output
# Description: Reshapes the case data to one row per unit and imputation step,
#              carrying the probabilistic Y0 and Y1 imputations that the Figure
#              2, 3, A1 and A2 simulations draw from.

source(here::here("maintained", "helpers.R"))

dat <- read_rds(here::here("maintained", "output", "cases_corrected.rds"))

cases_long <- dat |>
  select(
    unique_id, transition_fac, treatment,
    y0_obs, y0_agnostic, y0_s0_prob, y0_s1_prob, y0_s2_prob, y0_s3_prob, y0_s4_prob,
    y1_obs, y1_agnostic, y1_s0_prob, y1_s1_prob, y1_s2_prob, y1_s3_prob, y1_s4_prob
  ) |>
  pivot_longer(
    cols = -c(unique_id, transition_fac, treatment),
    names_to = "variable",
    values_to = "value"
  ) |>
  separate_wider_delim(
    variable,
    delim = "_",
    names = c("PO", "step"),
    too_many = "drop"
  ) |>
  pivot_wider(
    id_cols = c(unique_id, transition_fac, treatment, step),
    names_from = PO,
    values_from = value
  )

print(count(cases_long, transition_fac, step))

write_rds(cases_long, here::here("maintained", "output", "cases_long.rds"))
