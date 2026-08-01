# coppock_kaur_2022/maintained/figures_2_a1_ate_bounds.R
# Output: output/figure_2_dem_ate_bounds.pdf/.png,
#         output/figure_a1_eoc_ate_bounds.pdf/.png,
#         output/figures_2_a1_gg_df.csv
# Depends on: helpers.R, clean_cases.R output
# Description: Figures 2 and A1, the extreme value bounds on the ATE after each
#              imputation step with 95% simulation intervals. Figure 2 is the
#              democratization sample, Figure A1 the end-of-conflict sample. The
#              two figures come from one simulation, so one script writes both.

source(here::here("maintained", "helpers.R"))

set.seed(12345)

cases_long <- read_rds(here::here("maintained", "output", "cases_long.rds"))

sims <- cases_long |>
  group_by(step, transition_fac) |>
  reframe(sample_bounds(y0, y1, sims = 1000))

gg_df <- sims |>
  summarise(
    estimate = mean(value) * 100,
    conf_low = quantile(value, 0.025) * 100,
    conf_high = quantile(value, 0.975) * 100,
    .by = c(step, transition_fac, name)
  ) |>
  pivot_wider(
    id_cols = c(step, transition_fac),
    names_from = name,
    values_from = c(estimate, conf_low, conf_high)
  ) |>
  mutate(
    description = factor(step, levels = quimpo_step_levels, labels = quimpo_step_labels),
    description = fct_rev(description)
  ) |>
  arrange(transition_fac, desc(description))

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
      aes(x = round(estimate_low_est, 0), label = round(estimate_low_est, 0)),
      nudge_y = 0.35, size = 3
    ) +
    geom_text(
      aes(x = round(estimate_high_est, 0), label = round(estimate_high_est, 0)),
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
