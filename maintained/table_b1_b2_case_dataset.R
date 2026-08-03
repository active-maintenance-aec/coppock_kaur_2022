# coppock_kaur_2022/maintained/table_b1_b2_case_dataset.R
# Output: output/table_b1_b2_case_dataset.csv
# Depends on: helpers.R, original/replication_archive/cases_clean.csv
# Description: Appendix Tables B.1 and B.2, the full case datasets the article
#              prints: one row per case with its treatment indicator, observed
#              outcome, observed and imputed potential outcomes, the stated
#              probability that the imputed potential outcome equals 1, and the
#              implied unit-level effect. B.1 is the end-of-conflict sample and
#              B.2 the democratization sample.
#
#   The deposited archive has no script for either table, so the published pages
#   had nothing on our side to be compared against. Every cell is read out of the
#   deposited case file; nothing here is estimated.

source(here::here("maintained", "helpers.R"))

dat <- read_csv(
  here::here("original", "replication_archive", "cases_clean.csv"),
  show_col_types = FALSE
)

# The published tables print a question mark where a potential outcome is left
# unimputed, and print the treatment indicator, outcomes and effects as integers.
as_cell <- function(x) if_else(is.na(x), "?", format(x, trim = TRUE))

table_b1_b2 <- dat |>
  transmute(
    table = if_else(transition_fac == "End of conflict", "B.1", "B.2"),
    step = step_imputed,
    case = str_c(location, " (", conflict_start, "-", conflict_end, ")"),
    d = as_cell(treatment),
    Y = as_cell(outcome),
    observed = as_cell(if_else(treatment == 1, y1_obs, y0_obs)),
    imputed_y0 = as_cell(y0_s4),
    imputed_y1 = as_cell(y1_s4),
    probability = if_else(is.na(probability), NA_character_,
                          format(probability, trim = TRUE, drop0trailing = TRUE)),
    tau = as_cell(tau_i)
  ) |>
  arrange(table, case)

# The switching equation is what makes the observed column meaningful: an untreated
# case reveals Yi(0) and a treated case reveals Yi(1), and either way the revealed
# potential outcome is the observed outcome. One deposited case breaks it, so this
# is recorded as a column rather than asserted.
table_b1_b2 <- table_b1_b2 |>
  mutate(switching_holds = observed == Y)

print(count(table_b1_b2, table, step))
print(filter(table_b1_b2, !switching_holds))

write_csv(table_b1_b2, here::here("maintained", "output", "table_b1_b2_case_dataset.csv"))
