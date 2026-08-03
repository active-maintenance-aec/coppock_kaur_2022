# coppock_kaur_2022/maintained/figures_3_a2_att_atu_bounds.R
# Output: output/figure_3_dem_att_atu_bounds.pdf/.png,
#         output/figure_a2_eoc_att_atu_bounds.pdf/.png,
#         output/figures_3_a2_gg_df.csv
# Depends on: helpers.R, clean_cases.R output
# Description: Figures 3 and A2, the extreme value bounds on the ATT and the ATU
#              after each imputation step with 95% simulation intervals. Figure 3
#              is the democratization sample, Figure A2 the end-of-conflict
#              sample. The two figures come from one simulation, so one script
#              writes both.

source(here::here("maintained", "helpers.R"))

set.seed(12345)

cases_long <- read_rds(here::here("maintained", "output", "cases_long.rds"))

sims <- cases_long |>
  group_by(step, transition_fac, treatment) |>
  reframe(sample_bounds(y0, y1, sims = 10000))

gg_df <- sims |>
  summarise(
    estimate = mean(value) * 100,
    conf_low = quantile(value, 0.025) * 100,
    conf_high = quantile(value, 0.975) * 100,
    .by = c(step, transition_fac, treatment, name)
  ) |>
  pivot_wider(
    id_cols = c(step, transition_fac, treatment),
    names_from = name,
    values_from = c(estimate, conf_low, conf_high)
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
      aes(x = round(estimate_low_est, 0), label = round(estimate_low_est, 0)),
      nudge_y = 0.35, size = 3
    ) +
    geom_text(
      aes(x = round(estimate_high_est, 0), label = round(estimate_high_est, 0)),
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
