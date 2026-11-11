# coppock_kaur_2022/maintained/apply_appendix_c_corrections.R
# Output: output/cases_corrected.rds, output/appendix_c_corrections.csv,
#   output/revealed_outcome_corrections.csv
# Depends on: helpers.R, original/replication_archive/cases_clean.csv
# Description: The imputed potential outcomes in this article are not
#   measurements. They are qualitative judgments, written out case by case in
#   appendix C with the reasoning behind each one, and the deposited
#   cases_clean.csv is a transcription of them. Seven of its imputation
#   probabilities do not match the probability the appendix C narrative for that
#   case states. This script restores the stated values and writes the corrected
#   case file that every analysis script downstream reads.
#
#   Appendix C states a probability for 30 of the 31 imputed democratization
#   cases (Thailand 1991-1992 refers to the entry above it and gives no number of
#   its own). Twenty-three agree with the deposit exactly. In all seven that do
#   not, the deposited point imputation agrees with the appendix and only the
#   probability differs, so the deposit contradicts itself in three of them, where
#   an imputed value of 1 sits beside a probability below one half.
#
#   The probability columns are cumulative: a case imputed at step s carries its
#   probability in every column from y*_s<s>_prob through y*_s4_prob, and
#   `probability` repeats it. Every one of those columns is corrected, and the
#   deposited value in each is asserted before it is overwritten, so a change to
#   the deposit would stop the run rather than be silently absorbed.
#
#   The second section corrects two observed values rather than imputed ones.
#   Azerbaijan (1991-1992) and Bangladesh (1982-1990) carry revealed untreated
#   outcomes transposed between them: each case's y0 columns hold the other's
#   value, while the deposited `outcome` column holds the right one. See that
#   section for the evidence.

source(here::here("maintained", "helpers.R"))

dat <- read_csv(
  here::here("original", "replication_archive", "cases_clean.csv"),
  show_col_types = FALSE
)

# One row per correction: the case, the appendix C entry that states the
# probability, the potential outcome the case is missing, the imputation step at
# which it is filled in, the value the deposit carries and the value appendix C
# states. The deposited value is kept here so the change is readable beside what
# it replaces rather than only in the diff of a data file. The rows are in the
# order appendix Table B.2 prints them, which is the order the errata reprints.
appendix_c_corrections <- tribble(
  ~location,             ~conflict_start, ~conflict_end, ~appendix_c, ~missing_po, ~imputed_from_step, ~imputed_value, ~deposited_probability, ~appendix_c_probability,
  "South Africa",                   1910,          1994, "C.2.7",     "y0",        1,                  1,              0.2,                    0.8,
  "Ghana",                          1981,          1993, "C.3.2",     "y1",        2,                  0,              0.1,                    0.2,
  "Uruguay",                        1973,          1984, "C.3.6",     "y1",        2,                  1,              1.0,                    0.9,
  "Sierra Leone",                   1997,          1998, "C.4.8",     "y1",        3,                  0,              0.2,                    0.1,
  "Nicaragua",                      1979,          1990, "C.4.10",    "y1",        3,                  1,              0.8,                    0.9,
  "Central African Rep",            1981,          1993, "C.4.12",    "y1",        3,                  1,              0.3,                    0.7,
  "Sierra Leone",                   1992,          1996, "C.4.13",    "y1",        3,                  1,              0.3,                    0.7
)

cases_corrected <- dat

for (i in seq_len(nrow(appendix_c_corrections))) {
  correction <- appendix_c_corrections[i, ]

  row <- which(
    cases_corrected$location == correction$location &
      cases_corrected$conflict_start == correction$conflict_start &
      cases_corrected$conflict_end == correction$conflict_end
  )
  stopifnot(length(row) == 1)

  probability_columns <- c(
    str_c(correction$missing_po, "_s", correction$imputed_from_step:4, "_prob"),
    "probability"
  )
  earlier_columns <- if (correction$imputed_from_step > 0) {
    str_c(correction$missing_po, "_s", 0:(correction$imputed_from_step - 1), "_prob")
  } else {
    character(0)
  }

  # The point imputation is not touched, and it already agrees with appendix C in
  # every one of these cases. Asserting it here is what makes the correction a
  # correction to the probability alone.
  stopifnot(
    cases_corrected[[str_c(correction$missing_po, "_s4")]][row] == correction$imputed_value,
    all(map_dbl(probability_columns, \(column) cases_corrected[[column]][row]) ==
          correction$deposited_probability),
    all(is.na(map_dbl(earlier_columns, \(column) cases_corrected[[column]][row])))
  )

  for (column in probability_columns) {
    cases_corrected[[column]][row] <- correction$appendix_c_probability
  }
}

print(as.data.frame(appendix_c_corrections))

# Revealed untreated outcomes ----
# An untreated case reveals Yi(0), so its observed outcome and its y0 columns must
# agree. In two democratization cases they do not, and in opposite directions. The
# article codes the outcome 1 when authoritarianism resumes within 10 years of the
# transition, and Polity IV, from which the case universe was drawn, settles both:
# Azerbaijan's polity score falls from 1 in 1992 to -3 in 1993, a return to
# authoritarianism within a year, and Bangladesh's stays at 6 from 1991 to 2006,
# falling only in 2007, seventeen years after the transition. The deposited
# `outcome` column records 1 and 0 accordingly; the y0 columns, which are what
# the analysis reads, carry 0 and 1. Both cases are left unimputed, so each
# contributes its revealed Y0 alone, and because the two values are swapped
# rather than both wrong in one direction, the sum of the untreated outcomes is
# unchanged and no bound moves at any step.
revealed_outcome_corrections <- tribble(
  ~location, ~conflict_start, ~conflict_end, ~deposited_y0, ~corrected_y0,
  "Azerbaijan", 1991, 1992, 0, 1,
  "Bangladesh", 1982, 1990, 1, 0
)

# Every column that carries the revealed Yi(0): the observed value, its copy at
# each imputation step, the expert and combined versions the cleaning script
# copies it into, and the probability columns, which hold an observed value as a
# probability of 0 or 1.
y0_columns <- c(
  "y0_obs", str_c("y0_s", 0:4), "y0_expert", "y0_combined",
  str_c("y0_s", 0:4, "_prob"), "y0_expert_prob"
)

for (i in seq_len(nrow(revealed_outcome_corrections))) {
  correction <- revealed_outcome_corrections[i, ]

  row <- which(
    cases_corrected$location == correction$location &
      cases_corrected$conflict_start == correction$conflict_start &
      cases_corrected$conflict_end == correction$conflict_end
  )
  stopifnot(
    length(row) == 1,
    cases_corrected$transition_fac[row] == "Democratization",
    cases_corrected$treatment[row] == 0,
    is.na(cases_corrected$y1_s4[row]),
    cases_corrected$outcome[row] == correction$corrected_y0,
    all(map_dbl(y0_columns, \(column) cases_corrected[[column]][row]) ==
          correction$deposited_y0)
  )

  for (column in y0_columns) {
    cases_corrected[[column]][row] <- correction$corrected_y0
  }
}

# After the correction the switching equation holds for every case in both samples.
stopifnot(with(cases_corrected, all(outcome == if_else(treatment == 1, y1_obs, y0_obs))))

print(as.data.frame(revealed_outcome_corrections))

write_csv(appendix_c_corrections,
          here::here("maintained", "output", "appendix_c_corrections.csv"))
write_csv(revealed_outcome_corrections,
          here::here("maintained", "output", "revealed_outcome_corrections.csv"))
write_rds(cases_corrected,
          here::here("maintained", "output", "cases_corrected.rds"))
