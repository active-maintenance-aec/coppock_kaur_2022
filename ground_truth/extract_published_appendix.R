# coppock_kaur_2022/ground_truth/extract_published_appendix.R
# Output: ground_truth/published_appendix_values.csv
# Depends on: the published supporting information PDF, whose path is taken from
#             the CK2022_APPENDIX_PDF environment variable. The repo does not
#             redistribute the article, so there is no default: set the variable
#             to a local copy of the supporting information downloaded from
#             https://doi.org/10.1111/ajps.12697.
# Description: Transcribes appendix Tables B.1 and B.2, the full case datasets,
#              off the published pages: 117 rows and every cell each row prints.
#              This is the only place a published appendix value is read, and the
#              result is committed so nothing else in the pipeline needs the PDF.
#
#   Not run by run_all.R. It transcribes a frozen document, so it runs once and
#   its output is checked by hand against a rendered page.
#
#   The parse is positional rather than in reading order. Each row prints a case
#   label, then a run of single-character cells whose meaning depends on the
#   treatment indicator: an untreated case shows its observed untreated outcome
#   and an imputed treated outcome, a treated case shows the reverse, and the
#   parenthesised number is the stated probability that the imputed potential
#   outcome equals 1. An unimputable case stops early and prints question marks.

library(here)
library(tidyverse)

here::i_am("ground_truth/extract_published_appendix.R")

appendix_pdf <- Sys.getenv("CK2022_APPENDIX_PDF")

stopifnot(nzchar(appendix_pdf), file.exists(appendix_pdf))

page_lines <- system2(
  "pdftotext",
  c("-layout", "-f", "3", "-l", "6", shQuote(appendix_pdf), "-"),
  stdout = TRUE
)

nth_token <- function(tokens, i) {
  map_chr(tokens, \(x) if (length(x) >= i) x[i] else NA_character_)
}

published_appendix <- tibble(line = page_lines) |>
  mutate(
    table = case_when(
      str_detect(line, fixed("Table B.1")) ~ "B.1",
      str_detect(line, fixed("Table B.2")) ~ "B.2",
      .default = NA_character_
    ),
    step = str_trim(str_match(line, "^\\s*Step \\d: (.+?)\\s{2,}")[, 2])
  ) |>
  fill(table, step, .direction = "down") |>
  mutate(
    case = str_trim(str_match(line, "^\\s*(\\S.*?\\S)\\s{2,}")[, 2]),
    cells = str_trim(str_remove(line, "^\\s*\\S.*?\\S\\s{2,}"))
  ) |>
  filter(!is.na(case), str_detect(cells, "^[01]\\s")) |>
  mutate(
    token = str_split(cells, "\\s+"),
    d = nth_token(token, 1),
    Y = nth_token(token, 2),
    observed = nth_token(token, 3),
    imputed_y0 = nth_token(token, 4),
    imputed_y1 = if_else(d == "1", nth_token(token, 6), nth_token(token, 5)),
    probability = if_else(d == "1", nth_token(token, 5), nth_token(token, 6)),
    probability = if_else(str_detect(probability, "^\\("), str_remove_all(probability, "[()]"),
                          NA_character_),
    tau = nth_token(token, 7),
    tau = replace_na(tau, "?")
  ) |>
  select(table, step, case, d, Y, observed, imputed_y0, imputed_y1, probability, tau)

stopifnot(
  nrow(published_appendix) == 117,
  sum(published_appendix$table == "B.1") == 54,
  sum(published_appendix$table == "B.2") == 63,
  !any(duplicated(paste(published_appendix$table, published_appendix$case))),
  all(published_appendix$d %in% c("0", "1")),
  all(published_appendix$imputed_y1 %in% c("0", "1", "?"))
)

print(published_appendix, n = 20)

write_csv(published_appendix, here::here("ground_truth", "published_appendix_values.csv"))
