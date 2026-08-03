# coppock_kaur_2022/maintained/apply_appendix_c_corrections.R
# Output: output/cases_corrected.rds, output/appendix_c_corrections.csv
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

write_csv(appendix_c_corrections,
          here::here("maintained", "output", "appendix_c_corrections.csv"))
write_rds(cases_corrected,
          here::here("maintained", "output", "cases_corrected.rds"))
