# coppock_kaur_2022/maintained/table_b1_b2_case_dataset.R
# Output: output/table_b1_b2_case_dataset.csv, output/table_b2_corrected_rows.csv
# Depends on: helpers.R, original/replication_archive/cases_clean.csv,
#             apply_appendix_c_corrections.R output
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
#
#   This is the one script that reads the deposit rather than the corrected case
#   file, and deliberately so. The question these tables answer is whether the
#   published pages print what the deposit holds, and they do: the seven
#   probabilities appendix C states differently are printed here exactly as the
#   deposit carries them, so the published table inherits the transcription error
#   rather than committing a second one. The corrected rows are written out
#   separately, at the bottom of this script.

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
  arrange(table, case, .locale = "en")

# The switching equation is what makes the observed column meaningful: an untreated
# case reveals Yi(0) and a treated case reveals Yi(1), and either way the revealed
# potential outcome is the observed outcome. One deposited case breaks it, so this
# is recorded as a column rather than asserted.
table_b1_b2 <- table_b1_b2 |>
  mutate(switching_holds = observed == Y)

print(count(table_b1_b2, table, step))
print(filter(table_b1_b2, !switching_holds))

write_csv(table_b1_b2, here::here("maintained", "output", "table_b1_b2_case_dataset.csv"))

# The seven Table B.2 rows appendix C states differently, printed as published and
# as corrected side by side. The published order of the block is kept: correcting
# the probabilities would reorder two of the step blocks, which is not part of the
# correction and would make the rows harder to find on the published page.
corrections <- read_csv(here::here("maintained", "output", "appendix_c_corrections.csv"),
                        show_col_types = FALSE)

corrected_cases <- read_rds(here::here("maintained", "output", "cases_corrected.rds")) |>
  transmute(
    case = str_c(location, " (", conflict_start, "-", conflict_end, ")"),
    corrected_probability = probability
  )

table_b2_corrected_rows <- corrections |>
  transmute(
    case = str_c(location, " (", conflict_start, "-", conflict_end, ")"),
    appendix_c,
    published_probability = deposited_probability
  ) |>
  left_join(corrected_cases, by = "case") |>
  left_join(
    table_b1_b2 |>
      filter(table == "B.2") |>
      select(case, d, Y, observed, imputed_y0, imputed_y1, tau),
    by = "case", relationship = "one-to-one"
  )

stopifnot(nrow(table_b2_corrected_rows) == nrow(corrections),
          !anyNA(table_b2_corrected_rows$corrected_probability))

print(as.data.frame(table_b2_corrected_rows))

write_csv(table_b2_corrected_rows,
          here::here("maintained", "output", "table_b2_corrected_rows.csv"))
