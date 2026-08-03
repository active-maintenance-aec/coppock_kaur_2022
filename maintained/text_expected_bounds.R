# coppock_kaur_2022/maintained/text_expected_bounds.R
# Output: output/text_expected_bounds.csv
# Depends on: helpers.R, clean_cases.R output, figures_2_a1_ate_bounds.R output,
#             figures_3_a2_att_atu_bounds.R output
# Description: The exact expected value of every bound Figures 2, 3, A.1 and A.2
#              plot, beside the simulated estimate the figures actually label.
#
#   The bounds are linear in the imputed potential outcomes, so the quantity the
#   simulation estimates has a closed form: filling the unimputed entries with 0
#   for the low bound and 1 for the high bound and averaging the imputation
#   probabilities gives the expectation exactly. The deposited figure script sets
#   no seed, so the published labels are one draw, and the gap between the two
#   columns here is the Monte Carlo error carried by that draw.
#
#   It matters for one quantity in particular. Once South Africa (1910-1994)
#   carries the 0.8 that appendix C states, the democratization ATT is exactly
#   -22.5 points, which sits on the boundary between -22 and -23 at the
#   whole-number rounding the figures use, so the label is not determined.

source(here::here("maintained", "helpers.R"))

cases_long <- read_rds(here::here("maintained", "output", "cases_long.rds"))

expected_ate <- cases_long |>
  summarise(
    expected_low = (mean(replace_na(y1, 0)) - mean(replace_na(y0, 1))) * 100,
    expected_high = (mean(replace_na(y1, 1)) - mean(replace_na(y0, 0))) * 100,
    .by = c(transition_fac, step)
  ) |>
  mutate(estimand = "ATE")

expected_att_atu <- cases_long |>
  summarise(
    expected_low = (mean(replace_na(y1, 0)) - mean(replace_na(y0, 1))) * 100,
    expected_high = (mean(replace_na(y1, 1)) - mean(replace_na(y0, 0))) * 100,
    .by = c(transition_fac, treatment, step)
  ) |>
  mutate(estimand = if_else(treatment == 1, "ATT", "ATU")) |>
  select(-treatment)

simulated_ate <- read_csv(here::here("maintained", "output", "figures_2_a1_gg_df.csv"),
                          show_col_types = FALSE) |>
  transmute(transition_fac, step, estimand = "ATE",
            simulated_low = estimate_low_est, simulated_high = estimate_high_est)

simulated_att_atu <- read_csv(here::here("maintained", "output", "figures_3_a2_gg_df.csv"),
                              show_col_types = FALSE) |>
  transmute(transition_fac, step, estimand = if_else(treatment == 1, "ATT", "ATU"),
            simulated_low = estimate_low_est, simulated_high = estimate_high_est)

expected_bounds <- bind_rows(expected_ate, expected_att_atu) |>
  left_join(bind_rows(simulated_ate, simulated_att_atu),
            by = c("transition_fac", "step", "estimand"),
            relationship = "one-to-one") |>
  mutate(
    description = factor(step, levels = quimpo_step_levels, labels = quimpo_step_labels),
    label_low = round(simulated_low, 0),
    label_high = round(simulated_high, 0),
    # An expectation sitting exactly halfway between two integers has no
    # whole-number label: which one the figure prints is decided by the draw
    # rather than by the quantity, so it is flagged rather than rounded.
    on_rounding_boundary = near(abs(expected_low %% 1), 0.5) |
      near(abs(expected_high %% 1), 0.5)
  ) |>
  select(transition_fac, estimand, step, description,
         expected_low, expected_high, simulated_low, simulated_high,
         label_low, label_high, on_rounding_boundary) |>
  arrange(transition_fac, estimand, description, .locale = "en")

print(expected_bounds, n = nrow(expected_bounds))
print(filter(expected_bounds, on_rounding_boundary))

write_csv(expected_bounds, here::here("maintained", "output", "text_expected_bounds.csv"))
