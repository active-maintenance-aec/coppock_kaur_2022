# coppock_kaur_2022/maintained/text_summary_stats.R
# Output: output/text_summary_stats.csv
# Depends on: helpers.R, figures_2_a1_ate_bounds.R output,
#             figures_3_a2_att_atu_bounds.R output,
#             figure_4_expert_validation.R output,
#             original/replication_archive/cases_clean.csv
# Description: The bounds widths and summary effects quoted in the abstract, the
#              body and Appendix A. Every value is read back from the figure
#              output that produced it, so the text and the figures cannot
#              disagree.

source(here::here("maintained", "helpers.R"))

ate <- read_csv(here::here("maintained", "output", "figures_2_a1_gg_df.csv"),
                show_col_types = FALSE)
att_atu <- read_csv(here::here("maintained", "output", "figures_3_a2_gg_df.csv"),
                    show_col_types = FALSE)
expert <- read_csv(here::here("maintained", "output", "figure_4_expert_validation.csv"),
                   show_col_types = FALSE)
dat <- read_csv(here::here("original", "replication_archive", "cases_clean.csv"),
                show_col_types = FALSE)

ate_width <- function(sample, which_step) {
  row <- ate |> filter(transition_fac == sample, step == which_step)
  row$estimate_high_est - row$estimate_low_est
}

ate_bound <- function(sample, which_step, side) {
  row <- ate |> filter(transition_fac == sample, step == which_step)
  row[[paste0("estimate_", side, "_est")]]
}

att_atu_bound <- function(sample, which_treatment, which_step, side) {
  row <- att_atu |>
    filter(transition_fac == sample, treatment == which_treatment, step == which_step)
  row[[paste0("estimate_", side, "_est")]]
}

expert_width <- function(which_set, which_person) {
  row <- expert |> filter(set == which_set, person == which_person)
  row$width
}

text_summary <- tibble(
  claim = c(
    "dem: bounds width before any data",
    "dem: bounds width once the world reveals half the potential outcomes",
    "dem: final ATE lower bound",
    "dem: final ATE upper bound",
    "dem: final ATE bounds width",
    "dem: ATU final bounds width",
    "dem: ATT final lower bound",
    "dem: ATT final upper bound",
    "expert: our bounds width, 20 responding cases",
    "expert: expert bounds width, 20 responding cases",
    "expert: our bounds width, all 63 cases",
    "expert: expert bounds width, all 63 cases",
    "expert: combined bounds width, all 63 cases",
    "dem: cases imputed as a non-zero causal effect",
    "eoc: bounds width once the world reveals half the potential outcomes",
    "eoc: final ATE lower bound",
    "eoc: final ATE upper bound",
    "eoc: final ATE bounds width",
    "eoc: ATT final lower bound",
    "eoc: ATT final upper bound"
  ),
  value = c(
    ate_width("Democratization", "agnostic"),
    ate_width("Democratization", "obs"),
    ate_bound("Democratization", "s4", "low"),
    ate_bound("Democratization", "s4", "high"),
    ate_width("Democratization", "s4"),
    att_atu_bound("Democratization", 0, "s4", "high") -
      att_atu_bound("Democratization", 0, "s4", "low"),
    att_atu_bound("Democratization", 1, "s4", "low"),
    att_atu_bound("Democratization", 1, "s4", "high"),
    expert_width("The 20 Cases with Expert Responses", "us"),
    expert_width("The 20 Cases with Expert Responses", "expert"),
    expert_width("All 63 Democratization Cases", "us"),
    expert_width("All 63 Democratization Cases", "expert"),
    expert_width("All 63 Democratization Cases", "combined"),
    sum(dat$transition_fac == "Democratization" & dat$tau_i != 0, na.rm = TRUE),
    ate_width("End of conflict", "obs"),
    ate_bound("End of conflict", "s4", "low"),
    ate_bound("End of conflict", "s4", "high"),
    ate_width("End of conflict", "s4"),
    att_atu_bound("End of conflict", 1, "s4", "low"),
    att_atu_bound("End of conflict", 1, "s4", "high")
  )
) |>
  mutate(rounded = round(value, 0))

print(text_summary, n = nrow(text_summary))

write_csv(text_summary, here::here("maintained", "output", "text_summary_stats.csv"))
