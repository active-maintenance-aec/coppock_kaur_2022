# coppock_kaur_2022/maintained/text_seed_sensitivity.R
# Output: output/text_seed_sensitivity.csv
# Depends on: helpers.R, clean_cases.R output, figures_2_a1_ate_bounds.R output,
#             figures_3_a2_att_atu_bounds.R output
# Description: How far the deposited archive's method can land from the bound it
#              is estimating, measured over twenty seeds.
#
#   What this file reports changed when the figures stopped simulating. The
#   bounds are affine in the imputed potential outcomes, so the distribution the
#   deposited script samples from is available exactly, and Figures 2, 3, A.1 and
#   A.2 now enumerate it. Nothing in this repository depends on a seed any more,
#   so a sensitivity check on the rewrite's own output would have nothing to
#   report. What remains worth reporting is the deposit's method, which is what a
#   reader running `figures_2_3_A1_A2.R` today gets: it averages 1,000 draws for
#   Figures 2 and A.1 and 10,000 for Figures 3 and A.2, it sets no seed, and its
#   labels are therefore one draw of a quantity that has an exact value.
#
#   So the comparison is against the exact bound rather than against a reference
#   draw. Of the 84 bounds the four figures carry, most have a whole-number label
#   the exact value determines, and the count below is how many of those the
#   deposit's method rounds differently. The rest sit exactly halfway between two
#   whole numbers and have no whole-number label at all; for those the method
#   prints whichever side the draw fell on, and the democratization ATT, the
#   quantity the article summarises in a sentence, is one of them.

source(here::here("maintained", "helpers.R"))

cases_long <- read_rds(here::here("maintained", "output", "cases_long.rds"))

exact <- bind_rows(
  read_csv(here::here("maintained", "output", "figures_2_a1_gg_df.csv"),
           show_col_types = FALSE) |>
    transmute(step, transition_fac, estimand = "ATE",
              exact_low = estimate_low_est, exact_high = estimate_high_est),
  read_csv(here::here("maintained", "output", "figures_3_a2_gg_df.csv"),
           show_col_types = FALSE) |>
    transmute(step, transition_fac, estimand = if_else(treatment == 1, "ATT", "ATU"),
              exact_low = estimate_low_est, exact_high = estimate_high_est)
) |>
  mutate(
    exact_label = str_c("[", bound_label(exact_low), ", ", bound_label(exact_high), "]"),
    # A label is determined when the exact bound is not halfway between two whole
    # numbers. bound_label() prints a decimal point exactly when it is not.
    low_determined = !str_detect(bound_label(exact_low), fixed(".")),
    high_determined = !str_detect(bound_label(exact_high), fixed("."))
  )

draw_labels <- function(seed) {
  set.seed(seed)
  drawn <- bind_rows(
    cases_long |>
      group_by(step, transition_fac) |>
      reframe(sample_bounds(y0, y1, sims = 1000)) |>
      summarise(estimate = mean(value) * 100, .by = c(step, transition_fac, name)) |>
      pivot_wider(id_cols = c(step, transition_fac), names_from = name,
                  values_from = estimate) |>
      mutate(estimand = "ATE"),
    cases_long |>
      group_by(step, transition_fac, treatment) |>
      reframe(sample_bounds(y0, y1, sims = 10000)) |>
      summarise(estimate = mean(value) * 100,
                .by = c(step, transition_fac, treatment, name)) |>
      pivot_wider(id_cols = c(step, transition_fac, treatment), names_from = name,
                  values_from = estimate) |>
      mutate(estimand = if_else(treatment == 1, "ATT", "ATU")) |>
      select(-treatment)
  ) |>
    left_join(exact, by = c("step", "transition_fac", "estimand"),
              relationship = "one-to-one") |>
    mutate(drawn_label = str_c("[", sprintf("%.0f", low_est), ", ",
                               sprintf("%.0f", high_est), "]"))

  stopifnot(nrow(drawn) == nrow(exact))

  drawn_label_for <- function(sample, which_estimand, which_step) {
    hit <- drawn$drawn_label[drawn$transition_fac == sample &
                               drawn$estimand == which_estimand &
                               drawn$step == which_step]
    stopifnot(length(hit) == 1)
    hit
  }

  tibble(
    seed = seed,
    labels_moved =
      sum(drawn$low_determined &
            sprintf("%.0f", drawn$low_est) != sprintf("%.0f", drawn$exact_low)) +
      sum(drawn$high_determined &
            sprintf("%.0f", drawn$high_est) != sprintf("%.0f", drawn$exact_high)),
    # The two labels the article states in a sentence as well as printing in a
    # figure, so that whether they hold across seeds is a recorded number rather
    # than an impression left by a count.
    final_dem_label = drawn_label_for("Democratization", "ATE", "s4"),
    dem_att_label = drawn_label_for("Democratization", "ATT", "s4")
  )
}

seed_sensitivity <- map(1:20, draw_labels) |> bind_rows()

n_determined <- sum(exact$low_determined) + sum(exact$high_determined)

print(seed_sensitivity, n = nrow(seed_sensitivity))
print(tibble(
  claim = c("seeds tested",
            "bounds the four figures carry",
            "of them whose whole-number label the exact bound determines",
            "seeds at which the deposit's method rounds at least one of those differently"),
  value = c(nrow(seed_sensitivity),
            2 * nrow(exact),
            n_determined,
            sum(seed_sensitivity$labels_moved > 0))
))
print(count(seed_sensitivity, final_dem_label))
print(count(seed_sensitivity, dem_att_label))

write_csv(seed_sensitivity,
          here::here("maintained", "output", "text_seed_sensitivity.csv"))
