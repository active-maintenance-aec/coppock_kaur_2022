# coppock_kaur_2022/maintained/figures_2_a1_ate_bounds.R
# Output: output/figure_2_dem_ate_bounds.pdf/.png,
#         output/figure_a1_eoc_ate_bounds.pdf/.png,
#         output/figures_2_a1_gg_df.csv
# Depends on: helpers.R, clean_cases.R output
# Description: Figures 2 and A1, the extreme value bounds on the ATE after each
#              imputation step with 95% uncertainty intervals. Figure 2 is the
#              democratization sample, Figure A1 the end-of-conflict sample. The
#              two figures come from one enumeration, so one script writes both.
#
#   The deposited figure script estimates each bound by simulation, drawing binary
#   potential outcomes from the imputed probabilities 1,000 times and averaging.
#   The bounds are affine in those realisations, so the distribution the draws
#   sample from is available exactly, and bounds_distribution() enumerates it: the
#   point estimate below is the mean of that distribution rather than of a sample
#   from it, and the interval its 2.5th and 97.5th quantiles. Nothing here depends
#   on a seed. maintained/text_expected_bounds.R records what the deposit's method
#   gives for the same quantities.

source(here::here("maintained", "helpers.R"))

cases_long <- read_rds(here::here("maintained", "output", "cases_long.rds"))

distributions <- cases_long |>
  group_by(step, transition_fac) |>
  reframe(bounds_distribution(y0, y1))

gg_df <- distributions |>
  summarise(
    estimate_low_est = sum(low_est * prob) * 100,
    estimate_high_est = sum(high_est * prob) * 100,
    conf_low_low_est = weighted_quantile(low_est, prob, 0.025) * 100,
    conf_high_low_est = weighted_quantile(low_est, prob, 0.975) * 100,
    conf_low_high_est = weighted_quantile(high_est, prob, 0.025) * 100,
    conf_high_high_est = weighted_quantile(high_est, prob, 0.975) * 100,
    .by = c(step, transition_fac)
  ) |>
  mutate(
    description = factor(step, levels = quimpo_step_levels, labels = quimpo_step_labels),
    description = fct_rev(description)
  ) |>
  arrange(transition_fac, desc(description), .locale = "en")

make_ate_plot <- function(df) {
  ggplot(df, aes(y = description)) +
    geom_point(aes(x = estimate_low_est), size = 2) +
    geom_point(aes(x = estimate_high_est), size = 2) +
    geom_errorbar(
      aes(xmin = conf_low_high_est, xmax = conf_high_high_est),
      width = 0.3, orientation = "y"
    ) +
    geom_errorbar(
      aes(xmin = conf_low_low_est, xmax = conf_high_low_est),
      width = 0.3, orientation = "y"
    ) +
    geom_linerange(
      aes(xmin = estimate_low_est, xmax = estimate_high_est),
      linewidth = 2, alpha = 0.2
    ) +
    geom_text(
      aes(x = estimate_low_est, label = bound_label(estimate_low_est)),
      nudge_y = 0.35, size = 3
    ) +
    geom_text(
      aes(x = estimate_high_est, label = bound_label(estimate_high_est)),
      nudge_y = 0.35, size = 3
    ) +
    theme_bw() +
    xlab("Extreme Value Bounds on Average Treatment Effect in Percentage Points") +
    theme(
      axis.title.y = element_blank(),
      strip.background = element_blank(),
      legend.position = "none",
      text = element_text(size = 10)
    )
}

g_2 <- make_ate_plot(filter(gg_df, transition_fac == "Democratization"))
ggsave(here::here("maintained", "output", "figure_2_dem_ate_bounds.pdf"),
       plot = g_2, height = 3, width = 6.5)
ggsave(here::here("maintained", "output", "figure_2_dem_ate_bounds.png"),
       plot = g_2, height = 3, width = 6.5, dpi = 300)

g_a1 <- make_ate_plot(filter(gg_df, transition_fac == "End of conflict"))
ggsave(here::here("maintained", "output", "figure_a1_eoc_ate_bounds.pdf"),
       plot = g_a1, height = 3, width = 6.5)
ggsave(here::here("maintained", "output", "figure_a1_eoc_ate_bounds.png"),
       plot = g_a1, height = 3, width = 6.5, dpi = 300)

write_csv(gg_df, here::here("maintained", "output", "figures_2_a1_gg_df.csv"))

print(gg_df, n = nrow(gg_df))
