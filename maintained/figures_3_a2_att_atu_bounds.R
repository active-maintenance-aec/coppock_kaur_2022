# coppock_kaur_2022/maintained/figures_3_a2_att_atu_bounds.R
# Output: output/figure_3_dem_att_atu_bounds.pdf/.png,
#         output/figure_a2_eoc_att_atu_bounds.pdf/.png,
#         output/figures_3_a2_gg_df.csv
# Depends on: helpers.R, clean_cases.R output
# Description: Figures 3 and A2, the extreme value bounds on the ATT and the ATU
#              after each imputation step with 95% uncertainty intervals. Figure 3
#              is the democratization sample, Figure A2 the end-of-conflict
#              sample. The two figures come from one enumeration, so one script
#              writes both.
#
#   As in figures_2_a1_ate_bounds.R, the bounds are enumerated exactly rather than
#   simulated: the deposited script averages 10,000 draws of a quantity whose
#   distribution bounds_distribution() gives in closed form. It matters most here.
#   Every treated case has both potential outcomes filled in by the second step,
#   so the democratization ATT bounds collapse to a point, and that point is
#   exactly -22.5 percentage points, which sits halfway between two whole numbers.
#   A simulation of it lands on either side with equal probability, which is why
#   the deposited figure's ATT label is not determined by the estimate.

source(here::here("maintained", "helpers.R"))

cases_long <- read_rds(here::here("maintained", "output", "cases_long.rds"))

distributions <- cases_long |>
  group_by(step, transition_fac, treatment) |>
  reframe(bounds_distribution(y0, y1))

gg_df <- distributions |>
  summarise(
    estimate_low_est = sum(low_est * prob) * 100,
    estimate_high_est = sum(high_est * prob) * 100,
    conf_low_low_est = weighted_quantile(low_est, prob, 0.025) * 100,
    conf_high_low_est = weighted_quantile(low_est, prob, 0.975) * 100,
    conf_low_high_est = weighted_quantile(high_est, prob, 0.025) * 100,
    conf_high_high_est = weighted_quantile(high_est, prob, 0.975) * 100,
    .by = c(step, transition_fac, treatment)
  ) |>
  mutate(
    description = factor(step, levels = quimpo_step_levels, labels = quimpo_step_labels),
    description = fct_rev(description),
    estimand = factor(
      treatment,
      levels = 0:1,
      labels = c(
        "Average Treatment Effect\non Untreated Units (ATU)",
        "Average Treatment Effect\non Treated Units (ATT)"
      )
    )
  ) |>
  arrange(transition_fac, estimand, desc(description), .locale = "en")

make_att_atu_plot <- function(df) {
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
    coord_cartesian(xlim = c(-105, 105)) +
    theme_bw() +
    facet_grid(~ estimand) +
    xlab("Extreme Value Bounds on Average Causal Effect in Percentage Points") +
    theme(
      axis.title.y = element_blank(),
      strip.background = element_blank(),
      legend.position = "none",
      text = element_text(size = 10)
    )
}

g_3 <- make_att_atu_plot(filter(gg_df, transition_fac == "Democratization"))
ggsave(here::here("maintained", "output", "figure_3_dem_att_atu_bounds.pdf"),
       plot = g_3, height = 3, width = 6.5)
ggsave(here::here("maintained", "output", "figure_3_dem_att_atu_bounds.png"),
       plot = g_3, height = 3, width = 6.5, dpi = 300)

g_a2 <- make_att_atu_plot(filter(gg_df, transition_fac == "End of conflict"))
ggsave(here::here("maintained", "output", "figure_a2_eoc_att_atu_bounds.pdf"),
       plot = g_a2, height = 3, width = 6.5)
ggsave(here::here("maintained", "output", "figure_a2_eoc_att_atu_bounds.png"),
       plot = g_a2, height = 3, width = 6.5, dpi = 300)

write_csv(gg_df, here::here("maintained", "output", "figures_3_a2_gg_df.csv"))

print(gg_df, n = nrow(gg_df))
