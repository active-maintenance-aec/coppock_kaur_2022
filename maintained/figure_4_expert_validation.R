# coppock_kaur_2022/maintained/figure_4_expert_validation.R
# Output: output/figure_4_expert_validation.pdf/.png,
#         output/figure_4_expert_validation.csv
# Depends on: helpers.R, apply_appendix_c_corrections.R output
# Description: Figure 4, the extreme value bounds implied by the expert survey.
#              Left panel: the 20 democratization cases with expert responses.
#              Right panel: all 63, including the bounds that defer to the experts
#              where they answered.
#
#   These bounds are computed from the point imputations rather than from the
#   probabilities, so the appendix C corrections leave every value here unchanged.

source(here::here("maintained", "helpers.R"))

dat <- read_rds(here::here("maintained", "output", "cases_corrected.rds"))

democratization_df <- dat |> filter(transition_fac == "Democratization")

bounds_long <- function(df, combined) {
  out <- df |>
    summarise(
      li_expert = ev_bounds(y0_expert, y1_expert)[["low_est"]] * 100,
      ui_expert = ev_bounds(y0_expert, y1_expert)[["high_est"]] * 100,
      li_us = ev_bounds(y0_s4, y1_s4)[["low_est"]] * 100,
      ui_us = ev_bounds(y0_s4, y1_s4)[["high_est"]] * 100,
      li_combined = ev_bounds(y0_combined, y1_combined)[["low_est"]] * 100,
      ui_combined = ev_bounds(y0_combined, y1_combined)[["high_est"]] * 100
    )
  if (!combined) out <- select(out, -li_combined, -ui_combined)
  out |>
    pivot_longer(everything(), names_to = "variable", values_to = "value") |>
    separate_wider_delim(variable, delim = "_", names = c("bound", "person")) |>
    pivot_wider(id_cols = person, names_from = bound, values_from = value)
}

# The paper draws no combined bar for the 20-case panel: within that subset the
# combined imputations are the expert imputations, so the comparison is empty.
gg_df <- bind_rows(
  `The 20 Cases with Expert Responses` =
    bounds_long(filter(democratization_df, responded_expert == 1), combined = FALSE),
  `All 63 Democratization Cases` =
    bounds_long(democratization_df, combined = TRUE),
  .id = "set"
) |>
  mutate(
    set = factor(
      set,
      levels = c("The 20 Cases with Expert Responses", "All 63 Democratization Cases")
    ),
    description = factor(
      person,
      levels = c("combined", "expert", "us"),
      labels = c(
        "Our bounds, deferring\nto expert imputations",
        "Expert bounds",
        "Our original bounds"
      )
    ),
    width = ui - li
  )

g <- ggplot(gg_df, aes(y = description)) +
  geom_linerange(aes(xmin = li, xmax = ui), linewidth = 2) +
  geom_text(
    aes(x = (li + ui) / 2, label = paste0("[", round(li, 0), ", ", round(ui, 0), "]")),
    nudge_y = 0.35
  ) +
  theme_bw() +
  facet_wrap(~ set) +
  xlab("Extreme Value Bounds on Average Treatment Effect in Percentage Points") +
  theme(
    axis.title.y = element_blank(),
    strip.background = element_blank(),
    legend.position = "none",
    text = element_text(size = 10)
  )

ggsave(here::here("maintained", "output", "figure_4_expert_validation.pdf"),
       plot = g, height = 3, width = 6.5)
ggsave(here::here("maintained", "output", "figure_4_expert_validation.png"),
       plot = g, height = 3, width = 6.5, dpi = 300)

write_csv(gg_df, here::here("maintained", "output", "figure_4_expert_validation.csv"))

print(gg_df)
