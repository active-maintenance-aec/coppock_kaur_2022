# coppock_kaur_2022/maintained/figure_1_toy_bounds.R
# Output: output/figure_1_toy_bounds.pdf, output/figure_1_toy_bounds.png,
#         output/figure_1_toy_bounds.csv
# Depends on: helpers.R
# Description: Figure 1, the extreme value bounds on the ATE at each step of the
#              toy example.

source(here::here("maintained", "helpers.R"))

toy <- quimpo_toy_example()

gg_df <- tibble(
  description = factor(toy$step_labels, levels = rev(toy$step_labels)),
  li = map2_dbl(toy$Y0, toy$Y1, \(y0, y1) ev_bounds(y0, y1)[["low_est"]]) * 100,
  ui = map2_dbl(toy$Y0, toy$Y1, \(y0, y1) ev_bounds(y0, y1)[["high_est"]]) * 100
)

g <- ggplot(gg_df, aes(y = description)) +
  geom_linerange(aes(xmin = li, xmax = ui), linewidth = 2) +
  geom_text(
    aes(x = (li + ui) / 2, label = paste0("[", li, ", ", ui, "]")),
    nudge_y = 0.3
  ) +
  theme_bw() +
  xlab("Extreme Value Bounds on Average Treatment Effect") +
  theme(axis.title.y = element_blank(), legend.position = "none")

ggsave(here::here("maintained", "output", "figure_1_toy_bounds.pdf"),
       plot = g, width = 6.5, height = 3)
ggsave(here::here("maintained", "output", "figure_1_toy_bounds.png"),
       plot = g, width = 6.5, height = 3, dpi = 300)
write_csv(gg_df, here::here("maintained", "output", "figure_1_toy_bounds.csv"))

print(gg_df)
