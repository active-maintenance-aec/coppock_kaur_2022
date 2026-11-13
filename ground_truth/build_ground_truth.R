# coppock_kaur_2022/ground_truth/build_ground_truth.R
# Output: ground_truth/coppock_kaur_2022_ground_truth.csv (rewritten in the
#         canonical column order), ground_truth/claims_coverage.csv,
#         ground_truth/float_coverage.csv; halts the run on any coverage or
#         instrument failure
# Depends on: ground_truth/published_claims.csv,
#             ground_truth/coppock_kaur_2022_ground_truth.csv,
#             errata_entries.csv, maintained/in_text_claims.R and every output
#             it reads
# Description: The gate standing between the article's published numbers and the
#   two instruments that check them.
#
#   ground_truth/published_claims.csv is the exhaustive extraction: every numeric
#   token the article and its supporting information print, with the section or
#   float it appears in and a hand-assigned classification. Every claim classified
#   pipeline or descriptive must be checked twice, once by a row in the ground
#   truth and once by a block in maintained/in_text_claims.R, which reaches the
#   same number by its own path through the same outputs. A claim with neither is
#   the coverage failure this file exists to catch, and it stops the build.
#
#   The claims file is read as a program rather than as text. Matching "# covers:"
#   comments would prove a block was written, not that it runs: a block that errors
#   or prints nothing satisfies a textual check completely. So the file is sourced,
#   its stdout captured, and the CLAIM lines counted against the extraction.
#
#   Definitional, structural and transcribed claims are exempt by classification.
#   Nothing in the pipeline can move them, and they are verified where they are
#   used: an interval level is visible in the 0.025 and 0.975 quantile calls of the
#   two simulation scripts, a scale endpoint in the article's own methods, a value
#   copied from another author's paper in that paper.

library(here)
library(tidyverse)

here::i_am("ground_truth/build_ground_truth.R")

paper_id <- "coppock_kaur_2022"

published_claims <- read_csv(
  here::here("ground_truth", "published_claims.csv"),
  show_col_types = FALSE, col_types = cols(.default = "c")
)

# The ground truth is read and written back by this file. The columns read here are
# the ones typed by hand; location, claim_type, digits, holds, disposition, and
# disposition_reason are derived below on every run and whatever the file holds for
# them is discarded, so they cannot drift from the extraction and the errata spine
# they are derived from. Every column is read as character so that a published
# "0.20" is not turned into 0.2; the two verdicts are then made logical.
ground_truth <- read_csv(
  here::here("ground_truth", str_c(paper_id, "_ground_truth.csv")),
  show_col_types = FALSE, col_types = cols(.default = "c")
) |>
  select(paper_id, claim_id, location, claim, value_paper, value_script, match,
         value_rewrite, match_rewrite, defect_locus, notes) |>
  mutate(across(c(match, match_rewrite), as.logical))

# claim_id was first derived from the float or section and the quantity, and is now
# carried in the file itself, which is what lets an errata entry cite the rows it
# corrects. It must be present and unique.
stopifnot(!anyNA(ground_truth$claim_id),
          !any(duplicated(ground_truth$claim_id)),
          !any(duplicated(published_claims$claim_id)))

# Gate: the extraction and the ground truth describe the same claims ----
must_be_checked <- published_claims |> filter(claim_type %in% c("pipeline", "descriptive"))

missing_row <- setdiff(must_be_checked$claim_id, ground_truth$claim_id)

if (length(missing_row) > 0) {
  stop(str_glue("{length(missing_row)} published claims have no ground truth row: ",
                "{str_c(head(missing_row, 20), collapse = ', ')}"))
}

# A ground truth row with no counterpart in the extraction is a quantity the
# pipeline produces and the article never prints. That is legitimate and has to be
# named rather than tolerated silently, so the set is written out here.
unpublished <- setdiff(ground_truth$claim_id, published_claims$claim_id)

stopifnot(
  setequal(
    unpublished,
    str_c("table_5|end_of_conflict_",
          c("negative_effect", "no_effect", "positive_effect", "unimputed"))
  ),
  all(is.na(ground_truth$value_paper[ground_truth$claim_id %in% unpublished]))
)

# Gate: the two files agree on what the article prints ----
# The extraction and the ground truth both carry the published string, filled from
# the article by two separate readings. A disagreement between them is a
# transcription error in one of the two and is not visible anywhere else.
transcription <- ground_truth |>
  inner_join(select(published_claims, claim_id, claim_type, extraction_value = value_paper),
             by = "claim_id", relationship = "one-to-one") |>
  filter(!is.na(value_paper) | !is.na(extraction_value)) |>
  filter(is.na(value_paper) != is.na(extraction_value) | value_paper != extraction_value)

if (nrow(transcription) > 0) {
  print(select(transcription, claim_id, value_paper, extraction_value), n = 30)
  stop(nrow(transcription), " claims are transcribed differently in the ground truth ",
       "and in the extraction")
}

# Gate: the second instrument runs, prints, and agrees ----
# Sourcing the claims file is what makes this a check on a program rather than on
# a comment. R does not auto-print under source(), so a block that computes without
# printing contributes no CLAIM line and is counted as uncovered, which is the
# intended verdict.
claims_output <- capture.output(source(here::here("maintained", "in_text_claims.R"),
                                        local = new.env()))

# Each line reads CLAIM <id> = <value> || [verdict] <label>, and a verdict other than
# match appends what the article prints in square brackets. The CLAIM SUMMARY lines
# do not match the pattern and fall out here.
claim_lines <- str_match(claims_output,
                         "^CLAIM (\\S+) = (\\S+) \\|\\| \\[(\\w+)\\] (.*)$")
in_text_claims <- tibble(
  claim_id = claim_lines[, 2],
  value_in_text = claim_lines[, 3],
  verdict = claim_lines[, 4],
  label = str_remove(claim_lines[, 5], " \\[(article prints|the sentence names) .*\\]$")
) |>
  filter(!is.na(claim_id))

stopifnot(!any(duplicated(in_text_claims$claim_id)))

blockless <- setdiff(must_be_checked$claim_id, in_text_claims$claim_id)
unclaimed <- setdiff(in_text_claims$claim_id, published_claims$claim_id)

if (length(blockless) > 0) {
  stop(str_glue("{length(blockless)} published claims print no CLAIM line from ",
                "maintained/in_text_claims.R: {str_c(head(blockless, 20), collapse = ', ')}"))
}
if (length(unclaimed) > 0) {
  stop(str_glue("maintained/in_text_claims.R prints {length(unclaimed)} claims the ",
                "article does not make: {str_c(head(unclaimed, 20), collapse = ', ')}"))
}

# The count is the check. Equal sets with unequal counts would mean a claim printed
# twice, which the duplicate test above already forbids; the count is asserted
# anyway because it is the number a reader of the log can compare at a glance.
stopifnot(nrow(in_text_claims) == nrow(must_be_checked))

# Gate: the two instruments reach the same number ----
# The ground truth and the claims file filter, convert and round independently, so
# where they disagree one of them is wrong. A number is compared at the coarser of
# the two precisions: the claims file prints at the precision the article prints, or
# at the correction's where an erratum publishes one, and the ground truth records a
# bound at the precision that states it. A claim whose rewrite value is not a single
# number (a sequence of cells, a share with its count, a comparison) is compared on
# the label the claims file prints for it, which carries that same string. A claim
# the deposit cannot support has no value in either.
decimals <- function(x) replace_na(str_length(str_extract(x, "(?<=\\.)[0-9]+$")), 0L)

disagreement <- ground_truth |>
  inner_join(in_text_claims, by = "claim_id", relationship = "one-to-one") |>
  mutate(
    scalar = str_detect(value_rewrite, "^-?[0-9]+(\\.[0-9]+)?$"),
    at = pmin(decimals(value_rewrite), decimals(value_in_text)),
    rewrite_number = as.numeric(if_else(scalar, value_rewrite, NA)),
    text_number = as.numeric(if_else(scalar, value_in_text, NA)),
    agrees = case_when(
      is.na(value_rewrite) ~ value_in_text == "NA",
      scalar ~ sprintf("%.*f", at, rewrite_number) == sprintf("%.*f", at, text_number),
      .default = label == value_rewrite
    )
  ) |>
  filter(!agrees)

if (nrow(disagreement) > 0) {
  print(select(disagreement, claim_id, value_rewrite, value_in_text, label), n = 30)
  stop("the ground truth and maintained/in_text_claims.R disagree on ",
       nrow(disagreement), " claims")
}

# Gate: the two instruments reach the same verdict ----
# The claims file scores each claim against the extraction and the errata spine; the
# ground truth records by hand whether the rewrite reproduces the article. A claim
# the claims file scores match must be one the ground truth says is reproduced, and
# a claim it scores corrected must be one the ground truth says is not. The shape
# and absent claims assert nothing and are not compared.
verdict_disagreement <- ground_truth |>
  inner_join(in_text_claims, by = "claim_id", relationship = "one-to-one") |>
  filter(verdict %in% c("match", "corrected"),
         is.na(match_rewrite) | match_rewrite != (verdict == "match"))

if (nrow(verdict_disagreement) > 0) {
  print(select(verdict_disagreement, claim_id, value_paper, value_rewrite, match_rewrite,
               verdict), n = 30)
  stop("the ground truth and maintained/in_text_claims.R reach different verdicts on ",
       nrow(verdict_disagreement), " claims")
}

# Gate: a verdict and a locus go together ----
# A match_rewrite of FALSE without a locus reads as a failure of the rewrite, which
# it almost never is; a locus without a FALSE is a verdict nothing supports.
locus <- ground_truth |>
  filter(xor(!is.na(defect_locus),
             (!is.na(match_rewrite) & !match_rewrite) | is.na(value_rewrite)))

if (nrow(locus) > 0) {
  print(select(locus, claim_id, value_paper, value_rewrite, match_rewrite, defect_locus), n = 30)
  stop(nrow(locus), " ground truth rows carry a verdict and a locus that do not go together")
}

# Errata spine gate ----
# Every claim id an errata entry names has to exist here. A missing one is a typo or a
# claim that has since been renamed, and a published correction pointing at a row that
# is not in the table is a dangling reference the build should refuse to carry.
errata_spine <- read_csv(here::here("errata_entries.csv"), show_col_types = FALSE,
                         col_types = cols(.default = "c"))
cited_claim_ids <- errata_spine$claim_ids |>
  str_split(";") |>
  unlist() |>
  str_trim()
cited_claim_ids <- cited_claim_ids[!is.na(cited_claim_ids) & cited_claim_ids != ""]
if (length(setdiff(cited_claim_ids, ground_truth$claim_id)) > 0) {
  print(setdiff(cited_claim_ids, ground_truth$claim_id))
}
stopifnot(length(setdiff(cited_claim_ids, ground_truth$claim_id)) == 0)

# Location, claim type, and printed precision, from the extraction ----
# A row the extraction holds takes its location, claim type, and digits from there, so
# the ground truth reads on its own. The four end-of-conflict Table 5 cells the
# article never prints have no extraction row: they are pipeline quantities and keep
# the float label they were recorded under.
ground_truth <- ground_truth |>
  left_join(select(published_claims, claim_id, extracted_location = location,
                   claim_type, digits),
            by = "claim_id", relationship = "one-to-one") |>
  mutate(
    location = coalesce(extracted_location, location),
    claim_type = replace_na(claim_type, "pipeline"),
    digits = coalesce(as.integer(digits), excheckr::claim_digits(value_paper))
  )

stopifnot(
  all(ground_truth$claim_id %in% c(published_claims$claim_id, unpublished)),
  !anyNA(ground_truth$location),
  all(ground_truth$claim_type %in% c("pipeline", "descriptive")),
  identical(is.na(ground_truth$digits), is.na(ground_truth$value_paper))
)

# A descriptive claim's verdict is whether the sentence holds, which is what
# match_rewrite records for it here; holds carries it so a reader need not know that.
ground_truth <- ground_truth |>
  mutate(holds = if_else(claim_type == "descriptive", match_rewrite, NA))

# Disposition: what became of each defect ----
# corrected_here is computed from the errata spine and never typed: a row is
# corrected here exactly when an entry's claim_ids names it. No other judgment has
# been recorded for this paper, so every other row with a locus stays NA, and a
# paper_internal row left NA stops the build.
ground_truth <- ground_truth |>
  mutate(
    disposition = if_else(!is.na(defect_locus) & claim_id %in% cited_claim_ids,
                          "corrected_here", NA_character_),
    disposition_reason = NA_character_
  )

undisposed <- ground_truth |> filter(defect_locus == "paper_internal", is.na(disposition))
if (nrow(undisposed) > 0) {
  print(select(undisposed, claim_id, location, claim), n = nrow(undisposed))
  stop(nrow(undisposed), " paper_internal rows carry no disposition")
}
print(ground_truth |> filter(!is.na(defect_locus)) |> count(defect_locus, disposition))

# Float coverage ----
# One row per published float. A table's published_numbers counts the numbers its
# cells print, read off the transcription compared above: every numeric token in a
# cell, so "2% (1)" is two and a Table 3 column of seven question marks and three
# digits is three. Table 4 also prints the scenario columns for units 6 and 7, eight
# 0/1 cells nobody transcribed, which are added to its count and are not covered.
# The appendix case tables are recorded a column at a time as counts of cells, so
# their counts are the sums. Every figure prints its bound labels on its face, so a
# figure's published numbers are those labels, and they are also what it plots.
floats <- tribble(
  ~float, ~carries_data, ~untranscribed, ~cell_counts, ~note,
  "Table 1", FALSE, 0L, FALSE, "Illustrates the fundamental problem of causal inference for one hypothetical unit; carries no data.",
  "Table 2", FALSE, 0L, FALSE, "Defines the four causal types; carries no data.",
  "Table 3", TRUE, 0L, FALSE, NA,
  "Figure 1", TRUE, 0L, FALSE, NA,
  "Table 4", TRUE, 8L, FALSE, "The scenario columns for units 6 and 7 print eight 0/1 cells that are not transcribed.",
  "Figure 2", TRUE, 0L, FALSE, NA,
  "Table 5", TRUE, 0L, FALSE, NA,
  "Figure 3", TRUE, 0L, FALSE, "A bound that collapses to a point prints one label and is transcribed as both of its endpoints.",
  "Figure 4", TRUE, 0L, FALSE, NA,
  "Figure A.1", TRUE, 0L, FALSE, NA,
  "Figure A.2", TRUE, 0L, FALSE, "A bound that collapses to a point prints one label and is transcribed as both of its endpoints.",
  "Table B.1", TRUE, 0L, TRUE, "Recorded a column at a time as counts of printed cells; no deposited script writes the table.",
  "Table B.2", TRUE, 0L, TRUE, "Recorded a column at a time as counts of printed cells; no deposited script writes the table."
)

stopifnot(all(str_subset(ground_truth$location, "^(Table|Figure) ") %in% floats$float))

numbers_in <- function(x) replace_na(str_count(x, "-?[0-9]+(\\.[0-9]+)?"), 0L)

float_cells <- ground_truth |>
  filter(location %in% floats$float, !is.na(value_paper)) |>
  left_join(select(floats, float, cell_counts), by = c("location" = "float")) |>
  mutate(
    printed = coalesce(as.integer(if_else(cell_counts, value_paper, NA)),
                       numbers_in(value_paper)),
    reproduced = coalesce(as.integer(if_else(cell_counts, value_rewrite, NA)),
                          if_else(match_rewrite, printed, 0L))
  ) |>
  summarize(
    covered = sum(printed),
    reproduced_by_rewrite = sum(reproduced, na.rm = TRUE),
    reproduced_by_archive = if (all(is.na(match))) NA_integer_ else
      as.integer(sum(printed[match %in% TRUE])),
    .by = location
  )

float_coverage <- floats |>
  left_join(float_cells, by = c("float" = "location")) |>
  mutate(
    is_figure = str_starts(float, "Figure"),
    across(c(covered, reproduced_by_rewrite), \(x) replace_na(x, 0L)),
    reproduced_by_archive = if_else(carries_data, reproduced_by_archive, 0L),
    published_numbers = covered + untranscribed,
    plotted = if_else(is_figure, covered, NA_integer_),
    plotted_reproduced = if_else(is_figure, reproduced_by_rewrite, NA_integer_)
  ) |>
  select(float, published_numbers, covered, reproduced_by_rewrite, reproduced_by_archive,
         plotted, plotted_reproduced, note)

stopifnot(
  nrow(float_coverage) == nrow(floats),
  all(float_coverage$covered[floats$carries_data] > 0),
  all(float_coverage$covered[!floats$carries_data] == 0)
)

write_csv(float_coverage, here::here("ground_truth", "float_coverage.csv"))
print(float_coverage, n = nrow(float_coverage), width = 200)

coverage <- published_claims |>
  select(claim_id, location, claim_type, value_paper) |>
  mutate(
    in_ground_truth = claim_id %in% ground_truth$claim_id,
    in_claims_script = claim_id %in% in_text_claims$claim_id
  )

# The ground truth, in the canonical column order ----
ground_truth <- ground_truth |>
  select(paper_id, claim_id, location, claim_type, claim, value_paper, digits,
         value_script, match, value_rewrite, match_rewrite, holds, defect_locus,
         disposition, disposition_reason, notes)

write_csv(ground_truth,
          here::here("ground_truth", str_c(paper_id, "_ground_truth.csv")), na = "")
write_csv(coverage, here::here("ground_truth", "claims_coverage.csv"), na = "")

print(count(coverage, claim_type, in_ground_truth, in_claims_script))

print(str_glue(
  "Extraction: {nrow(published_claims)} published numeric claims, ",
  "{nrow(must_be_checked)} of them pipeline or descriptive. ",
  "Ground truth rows: {nrow(ground_truth)}. ",
  "CLAIM lines printed by maintained/in_text_claims.R: {nrow(in_text_claims)}. ",
  "Rewrite matches published: {sum(ground_truth$match_rewrite, na.rm = TRUE)} of ",
  "{sum(!is.na(ground_truth$match_rewrite))} comparable."
))
