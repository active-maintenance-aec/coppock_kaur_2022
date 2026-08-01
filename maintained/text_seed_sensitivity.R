# coppock_kaur_2022/maintained/text_seed_sensitivity.R
# Output: output/text_seed_sensitivity.csv
# Depends on: helpers.R, clean_cases.R output,
#             figures_2_a1_ate_bounds.R output
# Description: The deposited figures_2_3_A1_A2.R sets no seed, so the labels on
#              Figures 2 and A1 are a draw from a simulation. This script repeats
#              the Figure 2 and A1 simulation at twenty seeds and counts how often
#              a rounded label moves off the one it produced at seed 12345, which
#              is the value the rewrite commits and the value the published
#              figures carry. It is a diagnostic about the archive, not a
#              published quantity.

source(here::here("maintained", "helpers.R"))

cases_long <- read_rds(here::here("maintained", "output", "cases_long.rds"))

reference <- read_csv(here::here("maintained", "output", "figures_2_a1_gg_df.csv"),
                      show_col_types = FALSE) |>
  transmute(
    step, transition_fac,
    reference_low = round(estimate_low_est, 0),
    reference_high = round(estimate_high_est, 0)
  )

simulate_labels <- function(seed) {
  set.seed(seed)
  cases_long |>
    group_by(step, transition_fac) |>
    reframe(sample_bounds(y0, y1, sims = 1000)) |>
    summarise(estimate = mean(value) * 100, .by = c(step, transition_fac, name)) |>
    pivot_wider(id_cols = c(step, transition_fac), names_from = name,
                values_from = estimate) |>
    left_join(reference, by = c("step", "transition_fac")) |>
    summarise(
      seed = seed,
      labels_moved = sum(round(low_est, 0) != reference_low |
                           round(high_est, 0) != reference_high)
    )
}

seed_sensitivity <- map(1:20, simulate_labels) |> bind_rows()

print(seed_sensitivity, n = nrow(seed_sensitivity))
print(tibble(
  claim = c("seeds tested",
            "seeds moving at least one rounded label",
            "labels compared per seed"),
  value = c(nrow(seed_sensitivity),
            sum(seed_sensitivity$labels_moved > 0),
            2 * nrow(reference))
))

write_csv(seed_sensitivity,
          here::here("maintained", "output", "text_seed_sensitivity.csv"))
