# coppock_kaur_2022/maintained/text_expert_agreement.R
# Output: output/text_expert_agreement.csv, output/text_expert_agreement_counts.csv
# Depends on: helpers.R, apply_appendix_c_corrections.R output
# Description: The in-text quantities of the Expert Survey section: how often the
#              experts' imputations agreed with the authors', how many cases each
#              side imputed, and the asymmetry between treated and untreated cases
#              among the experts who declined.
#
#   Agreement is defined over the point imputations, so the appendix C
#   corrections leave every count here unchanged.

source(here::here("maintained", "helpers.R"))

dat <- read_rds(here::here("maintained", "output", "cases_corrected.rds"))

# The missing potential outcome is Y0 for a treated case and Y1 for an untreated
# one, so the comparison is between whichever side each respondent was asked for.
responded_df <- dat |>
  filter(transition_fac == "Democratization", responded_expert == 1) |>
  mutate(
    expert_imputation = if_else(treatment == 1, y0_expert, y1_expert),
    our_imputation = if_else(treatment == 1, y0_s4, y1_s4),
    observed_outcome = if_else(treatment == 1, y1_obs, y0_obs),
    agreement_coding = case_when(
      is.na(expert_imputation) & is.na(our_imputation) ~ "agreement",
      is.na(expert_imputation) & !is.na(our_imputation) ~ "They declined, we imputed",
      !is.na(expert_imputation) & is.na(our_imputation) ~ "They imputed, we declined",
      expert_imputation == our_imputation ~ "agreement",
      .default = "disagreement"
    )
  )

agreement_counts <- responded_df |>
  count(agreement_coding, name = "cases")

text_claims <- tibble(
  claim = c(
    "expert responses received",
    "democratization cases without an expert response",
    "cases the experts imputed",
    "cases we imputed",
    "experts who declined to impute",
    "declining experts assigned to an untreated case",
    "expert imputations differing from the observed outcome"
  ),
  value = c(
    nrow(responded_df),
    sum(dat$transition_fac == "Democratization") - nrow(responded_df),
    sum(!is.na(responded_df$expert_imputation)),
    sum(!is.na(responded_df$our_imputation)),
    sum(is.na(responded_df$expert_imputation)),
    sum(is.na(responded_df$expert_imputation) & responded_df$treatment == 0),
    sum(responded_df$expert_imputation != responded_df$observed_outcome, na.rm = TRUE)
  )
)

print(agreement_counts)
print(text_claims)

write_csv(agreement_counts,
          here::here("maintained", "output", "text_expert_agreement_counts.csv"))
write_csv(text_claims,
          here::here("maintained", "output", "text_expert_agreement.csv"))
