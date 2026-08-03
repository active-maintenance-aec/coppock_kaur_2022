# coppock_kaur_2022/maintained/text_imputation_counts.R
# Output: output/text_imputation_counts.csv
# Depends on: helpers.R, original/replication_archive/cases_clean.csv
# Description: The case counts the Application and Appendix A sections state in
#              prose: how many cases each sample holds, how many are treated, how
#              many missing potential outcomes were imputed with certainty, how
#              many probabilistically, how many left unimputed, and how many cases
#              each imputation step covers.
#
#   The deposited archive computes none of these. An imputation is made with
#   certainty when the stated probability that the missing potential outcome
#   equals 1 is exactly 0 or exactly 1, probabilistically when it lies strictly
#   between, and not at all when it is absent.

source(here::here("maintained", "helpers.R"))

dat <- read_csv(
  here::here("original", "replication_archive", "cases_clean.csv"),
  show_col_types = FALSE
)

# The missing potential outcome is Y0 for a treated case and Y1 for an untreated
# one, so the probability that governs it is whichever of the two the case lacks.
cases <- dat |>
  mutate(missing_po_probability = if_else(treatment == 1, y0_s4_prob, y1_s4_prob))

counts <- cases |>
  summarise(
    cases = n(),
    treated = sum(treatment),
    imputed_with_certainty = sum(missing_po_probability %in% c(0, 1)),
    imputed_probabilistically = sum(missing_po_probability > 0 &
                                      missing_po_probability < 1, na.rm = TRUE),
    left_unimputed = sum(is.na(missing_po_probability)),
    .by = transition_fac
  ) |>
  pivot_longer(-transition_fac, names_to = "quantity", values_to = "value")

by_step <- cases |>
  count(transition_fac, step_imputed, name = "value") |>
  mutate(quantity = str_c("cases at step: ", step_imputed)) |>
  select(transition_fac, quantity, value)

text_imputation_counts <- bind_rows(counts, by_step) |>
  arrange(transition_fac, quantity)

print(text_imputation_counts, n = nrow(text_imputation_counts))

write_csv(text_imputation_counts,
          here::here("maintained", "output", "text_imputation_counts.csv"))
