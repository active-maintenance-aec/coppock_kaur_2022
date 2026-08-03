# coppock_kaur_2022/ground_truth/build_ground_truth.R
# Output: ground_truth/claims_coverage.csv; halts the run on any coverage or
#         instrument failure
# Depends on: ground_truth/published_claims.csv,
#             ground_truth/coppock_kaur_2022_ground_truth.csv,
#             maintained/in_text_claims.R and every output it reads
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

ground_truth <- read_csv(
  here::here("ground_truth", str_c(paper_id, "_ground_truth.csv")),
  show_col_types = FALSE, col_types = cols(.default = "c")
)

# The ground truth carries the float or section in one column and the quantity in
# another; the extraction carries one identifier. Building the identifier here from
# the ground truth's own two columns is what keeps the two files joinable without a
# hand-typed crosswalk between them.
slug <- function(x) {
  x |> str_to_lower() |> str_replace_all("[^a-z0-9]+", "_") |> str_replace_all("^_|_$", "")
}

ground_truth <- ground_truth |>
  mutate(claim_id = str_c(slug(table_figure), "|", slug(claim)))

stopifnot(!any(duplicated(ground_truth$claim_id)),
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
claims_output <- capture.output(source(here::here("maintained", "in_text_claims.R")))

in_text_claims <- tibble(line = claims_output) |>
  filter(str_starts(line, "CLAIM ")) |>
  transmute(
    claim_id = str_match(line, "^CLAIM (.*?) = ")[, 2],
    value_in_text = str_match(line, " = (.*)$")[, 2]
  )

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
# where they disagree one of them is wrong. A claim the deposit cannot support has
# no value in the ground truth and says so in the claims file, and those are
# compared on that fact rather than on a number.
disagreement <- ground_truth |>
  inner_join(in_text_claims, by = "claim_id", relationship = "one-to-one") |>
  filter(!(is.na(value_rewrite) & !str_detect(value_in_text, "^-?[0-9]")),
         is.na(value_rewrite) | value_rewrite != value_in_text)

if (nrow(disagreement) > 0) {
  print(select(disagreement, claim_id, value_rewrite, value_in_text), n = 30)
  stop("the ground truth and maintained/in_text_claims.R disagree on ",
       nrow(disagreement), " claims")
}

# Gate: a verdict and a locus go together ----
# A match_rewrite of zero without a locus reads as a failure of the rewrite, which
# it almost never is; a locus without a zero is a verdict nothing supports.
locus <- ground_truth |>
  filter(xor(!is.na(defect_locus),
             (!is.na(match_rewrite) & match_rewrite == "0") | is.na(value_rewrite)))

if (nrow(locus) > 0) {
  print(select(locus, claim_id, value_paper, value_rewrite, match_rewrite, defect_locus), n = 30)
  stop(nrow(locus), " ground truth rows carry a verdict and a locus that do not go together")
}

coverage <- published_claims |>
  mutate(
    in_ground_truth = claim_id %in% ground_truth$claim_id,
    in_claims_script = claim_id %in% in_text_claims$claim_id
  )

write_csv(coverage, here::here("ground_truth", "claims_coverage.csv"), na = "")

print(count(coverage, claim_type, in_ground_truth, in_claims_script))

print(str_glue(
  "Extraction: {nrow(published_claims)} published numeric claims, ",
  "{nrow(must_be_checked)} of them pipeline or descriptive. ",
  "Ground truth rows: {nrow(ground_truth)}. ",
  "CLAIM lines printed by maintained/in_text_claims.R: {nrow(in_text_claims)}. ",
  "Rewrite matches published: {sum(ground_truth$match_rewrite == '1', na.rm = TRUE)} of ",
  "{sum(!is.na(ground_truth$match_rewrite))} comparable."
))
