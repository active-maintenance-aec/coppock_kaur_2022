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
      estimate_lower_expert = ev_bounds(y0_expert, y1_expert)[["estimate_lower"]] * 100,
      estimate_upper_expert = ev_bounds(y0_expert, y1_expert)[["estimate_upper"]] * 100,
      estimate_lower_us = ev_bounds(y0_s4, y1_s4)[["estimate_lower"]] * 100,
      estimate_upper_us = ev_bounds(y0_s4, y1_s4)[["estimate_upper"]] * 100,
      estimate_lower_combined = ev_bounds(y0_combined, y1_combined)[["estimate_lower"]] * 100,
      estimate_upper_combined = ev_bounds(y0_combined, y1_combined)[["estimate_upper"]] * 100
    )
  if (!combined) out <- select(out, -estimate_lower_combined, -estimate_upper_combined)
  out |>
    # The bound name now carries an underscore of its own, so the split is by
    # pattern rather than at the first delimiter: estimate_lower_expert is the
    # lower bound for the expert imputations, not an "estimate" bound belonging
    # to a "lower_expert".
    pivot_longer(everything(),
                 names_to = c("bound", "person"),
                 names_pattern = "^(estimate_(?:lower|upper))_(.+)$") |>
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
    width = estimate_upper - estimate_lower
  )

g <- ggplot(gg_df, aes(y = description)) +
  geom_linerange(aes(xmin = estimate_lower, xmax = estimate_upper), linewidth = 2) +
  geom_text(
    aes(x = (estimate_lower + estimate_upper) / 2, label = paste0("[", round(estimate_lower, 0), ", ", round(estimate_upper, 0), "]")),
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
