# coppock_kaur_2022/maintained/text_expected_bounds.R
# Output: output/text_expected_bounds.csv
# Depends on: helpers.R, clean_cases.R output, figures_2_a1_ate_bounds.R output,
#             figures_3_a2_att_atu_bounds.R output
# Description: Every bound Figures 2, 3, A.1 and A.2 plot, beside what the
#              deposited archive's method gives for the same quantity.
#
#   The bounds are affine in the imputed potential outcomes, so the distribution
#   the deposit samples from is available exactly, and the figures here enumerate
#   it rather than drawing from it: the plotted estimate is the mean of that
#   distribution and is read back into the first two columns below. The deposit
#   instead averages 1,000 draws for Figures 2 and A.1 and 10,000 for Figures 3
#   and A.2, and sets no seed, so its labels are one draw. This script runs that
#   method once at a fixed seed and records what it gives.
#
#   The two columns must agree to within the Monte Carlo error of the simulated
#   one, and the last check below is that they do: the standard error of the
#   simulated estimate is known in closed form too, because each realisation
#   contributes 1/n to the bound, and the gap is expressed in units of it. A
#   simulated estimate more than five standard errors from the exact value would
#   mean the two are not the same quantity, which is what this file exists to
#   rule out.
#
#   It matters for one quantity in particular. Once South Africa (1910-1994)
#   carries the 0.8 that appendix C states, the democratization ATT is exactly
#   -22.5 points, which sits on the boundary between -22 and -23 at the
#   whole-number rounding the published figures use, so no whole-number label is
#   determined. The figures print such a value at the one decimal that states it.

source(here::here("maintained", "helpers.R"))

set.seed(12345)

cases_long <- read_rds(here::here("maintained", "output", "cases_long.rds"))

# The exact bounds, read back from the figures that plot them rather than
# recomputed, so this file cannot come to describe a figure it is not looking at.
exact_ate <- read_csv(here::here("maintained", "output", "figures_2_a1_gg_df.csv"),
                      show_col_types = FALSE) |>
  transmute(transition_fac, step, estimand = "ATE",
            expected_low = estimate_low_est, expected_high = estimate_high_est)

exact_att_atu <- read_csv(here::here("maintained", "output", "figures_3_a2_gg_df.csv"),
                          show_col_types = FALSE) |>
  transmute(transition_fac, step, estimand = if_else(treatment == 1, "ATT", "ATU"),
            expected_low = estimate_low_est, expected_high = estimate_high_est)

# The deposit's method, at the number of draws the deposited script uses for each
# pair of figures. The standard error is that of the mean of those draws: each
# probabilistic entry is a Bernoulli contributing 1/n to the bound, and both
# bounds carry the same random part, so one standard error serves both.
simulated_standard_error <- function(y0, y1, sims) {
  variance <- sum(y0 * (1 - y0), na.rm = TRUE) + sum(y1 * (1 - y1), na.rm = TRUE)
  sqrt(variance / sims) / length(y0) * 100
}

simulated_ate <- cases_long |>
  group_by(step, transition_fac) |>
  reframe(sample_bounds(y0, y1, sims = 1000)) |>
  summarise(estimate = mean(value) * 100, .by = c(step, transition_fac, name)) |>
  pivot_wider(id_cols = c(step, transition_fac), names_from = name,
              values_from = estimate) |>
  transmute(transition_fac, step, estimand = "ATE",
            simulated_low = low_est, simulated_high = high_est)

simulated_att_atu <- cases_long |>
  group_by(step, transition_fac, treatment) |>
  reframe(sample_bounds(y0, y1, sims = 10000)) |>
  summarise(estimate = mean(value) * 100, .by = c(step, transition_fac, treatment, name)) |>
  pivot_wider(id_cols = c(step, transition_fac, treatment), names_from = name,
              values_from = estimate) |>
  transmute(transition_fac, step, estimand = if_else(treatment == 1, "ATT", "ATU"),
            simulated_low = low_est, simulated_high = high_est)

standard_errors <- bind_rows(
  cases_long |>
    reframe(simulated_se = simulated_standard_error(y0, y1, 1000),
            .by = c(transition_fac, step)) |>
    mutate(estimand = "ATE"),
  cases_long |>
    reframe(simulated_se = simulated_standard_error(y0, y1, 10000),
            .by = c(transition_fac, step, treatment)) |>
    mutate(estimand = if_else(treatment == 1, "ATT", "ATU")) |>
    select(-treatment)
)

expected_bounds <- bind_rows(exact_ate, exact_att_atu) |>
  left_join(bind_rows(simulated_ate, simulated_att_atu),
            by = c("transition_fac", "step", "estimand"),
            relationship = "one-to-one") |>
  left_join(standard_errors,
            by = c("transition_fac", "step", "estimand"),
            relationship = "one-to-one") |>
  mutate(
    description = factor(step, levels = quimpo_step_levels, labels = quimpo_step_labels),
    label_low = round(simulated_low, 0),
    label_high = round(simulated_high, 0),
    # An expectation sitting exactly halfway between two integers has no
    # whole-number label: which one a figure rounding to whole points printed
    # would be decided by the tie-breaking rule rather than by the quantity, so
    # it is flagged, and the figures print it at one decimal.
    on_rounding_boundary = near(expected_low %% 1, 0.5) | near(expected_high %% 1, 0.5)
  ) |>
  select(transition_fac, estimand, step, description,
         expected_low, expected_high, simulated_low, simulated_high, simulated_se,
         label_low, label_high, on_rounding_boundary) |>
  arrange(transition_fac, estimand, description, .locale = "en")

# The simulated estimate must sit within Monte Carlo error of the exact value,
# and where nothing is probabilistic the two must be identical.
agreement <- expected_bounds |>
  mutate(
    gap_low = abs(simulated_low - expected_low),
    gap_high = abs(simulated_high - expected_high),
    gap_in_ses = if_else(simulated_se > 0, pmax(gap_low, gap_high) / simulated_se, 0)
  )

stopifnot(
  max(agreement$gap_in_ses) < 5,
  all(agreement$gap_low[agreement$simulated_se == 0] < 1e-10),
  all(agreement$gap_high[agreement$simulated_se == 0] < 1e-10)
)

print(expected_bounds, n = nrow(expected_bounds))
print(filter(expected_bounds, on_rounding_boundary))
print(tibble(
  claim = c("bounds compared",
            "of them with no probabilistic imputation, where the two agree exactly",
            "largest gap between the simulated and the exact bound, in points",
            "largest gap in standard errors of the simulated estimate"),
  value = c(2 * nrow(expected_bounds),
            2 * sum(agreement$simulated_se == 0),
            max(agreement$gap_low, agreement$gap_high),
            max(agreement$gap_in_ses))
))

write_csv(expected_bounds, here::here("maintained", "output", "text_expected_bounds.csv"))
