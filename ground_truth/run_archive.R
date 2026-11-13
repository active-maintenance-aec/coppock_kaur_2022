# coppock_kaur_2022/ground_truth/run_archive.R
# Output: ground_truth/archive_run_status.csv, ground_truth/archive_overwrites.csv
# Depends on: original/ (run download_original.R first)
# Description: Runs every deposited analysis script on a current R installation
#   and records what happened, one row per script per pass, together with every
#   file a run adds to, writes over, or deletes from its copy of the deposit.
#
#   The deposit is copied to a scratch directory and never written to. Each script
#   runs as its own Rscript process with the copy as its working directory, which
#   is how the deposit's README.txt asks to be run, in the order that file lists
#   them. quimpo_helpers.R is only ever sourced by the other scripts and has no
#   row of its own.
#
#   Two passes. as_shipped runs a copy of the whole deposit. stripped runs a copy
#   holding only the deposited data and code, which is the test of whether a
#   script passes on its own work or on a file the deposit happens to ship. The
#   deposit ships no intermediate (cases_clean.csv is its one data file and no
#   script writes it), so nothing is withheld and the two copies differ only in
#   the log, the codebook, and the README, none of which any script reads.
#
#   This script is not part of run_all.R. It needs the packages the deposit was
#   written against (xtable, reshape2, and janitor besides the tidyverse), which
#   the maintained rewrite does not, and its two passes take a few minutes.
#   value_script in the ground truth is transcribed from runs of the same scripts
#   and is not read from here.

library(here)
library(tidyverse)

here::i_am("ground_truth/run_archive.R")

deposit_dir <- here::here("original", "replication_archive")

analysis_scripts <- c("table_3_figure_1.R", "table_4.R", "figures_2_3_A1_A2.R",
                      "table_5.R", "figure_4.R")
data_and_code <- c("cases_clean.csv", "quimpo_helpers.R", analysis_scripts)

stopifnot(all(file.exists(file.path(deposit_dir, data_and_code))))

# One pass ----
# Files are fingerprinted before and after the run, so a file the run writes is
# caught whether it is new, rewritten with different contents, or rewritten with
# the same contents (which only its modification time shows).
fingerprint <- function(dir) {
  files <- list.files(dir, recursive = TRUE)
  tibble(
    file = files,
    md5 = unname(tools::md5sum(file.path(dir, files))),
    mtime = file.mtime(file.path(dir, files))
  )
}

run_pass <- function(pass, files) {
  scratch <- file.path(tempdir(), str_c("coppock_kaur_2022_", pass))
  unlink(scratch, recursive = TRUE)
  dir.create(scratch)
  stopifnot(all(file.copy(file.path(deposit_dir, files), scratch, copy.date = TRUE)))
  before <- fingerprint(scratch)

  status <- map(analysis_scripts, \(script) {
    run <- processx::run("Rscript", c("--vanilla", script), wd = scratch,
                         error_on_status = FALSE, timeout = 900)
    error_line <- str_subset(read_lines(I(run$stderr)), "^Error")
    tibble(
      pass = pass,
      script = script,
      role = "analysis",
      exit_status = if (run$timeout) NA_integer_ else as.integer(run$status),
      outcome = case_when(
        run$timeout ~ "timeout",
        run$status == 0 ~ "clean",
        .default = "error"
      ),
      stopped_at = if (length(error_line) > 0) error_line[1] else NA_character_
    )
  }) |>
    list_rbind()

  after <- fingerprint(scratch)
  changes <- full_join(before, after, by = "file", suffix = c("_before", "_after")) |>
    mutate(
      effect = case_when(
        is.na(md5_before) ~ "added",
        is.na(md5_after) ~ "deleted",
        md5_before != md5_after | mtime_before != mtime_after ~ "overwritten",
        .default = NA_character_
      ),
      matches_deposit = if_else(effect == "overwritten", md5_before == md5_after, NA)
    ) |>
    filter(!is.na(effect)) |>
    transmute(pass, file, effect, matches_deposit)

  list(status = status, changes = changes)
}

# Run ----
as_shipped <- run_pass("as_shipped", list.files(deposit_dir))
stripped <- run_pass("stripped", data_and_code)

run_status <- bind_rows(as_shipped$status, stripped$status)
overwrites <- bind_rows(as_shipped$changes, stripped$changes)

stopifnot(
  nrow(run_status) == 2 * length(analysis_scripts),
  all(run_status$outcome %in% c("clean", "error", "timeout", "not_run")),
  all(overwrites$effect %in% c("added", "overwritten", "rebuilt", "withheld", "deleted"))
)

write_csv(run_status, here::here("ground_truth", "archive_run_status.csv"))
write_csv(overwrites, here::here("ground_truth", "archive_overwrites.csv"))

print(run_status, width = 200)
print(overwrites)
