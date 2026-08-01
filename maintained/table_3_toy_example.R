# coppock_kaur_2022/maintained/table_3_toy_example.R
# Output: output/table_3_toy_example.csv, output/table_3_bounds.csv
# Depends on: helpers.R
# Description: Table 3, the toy potential outcomes table, together with the
#              extreme value bounds printed beneath it at each imputation step.

source(here::here("maintained", "helpers.R"))

toy <- quimpo_toy_example()

question_marks <- function(x) if_else(is.na(x), "?", as.character(x))

table_3 <- tibble(
  unit = seq_along(toy$Z),
  d = toy$Z,
  Y = toy$Y,
  Y0_initial = question_marks(toy$Y0[[2]]),
  Y1_initial = question_marks(toy$Y1[[2]]),
  Y0_easy = question_marks(toy$Y0[[3]]),
  Y1_easy = question_marks(toy$Y1[[3]]),
  Y0_nulls = question_marks(toy$Y0[[4]]),
  Y1_nulls = question_marks(toy$Y1[[4]]),
  Y0_hard = question_marks(toy$Y0[[5]]),
  Y1_hard = question_marks(toy$Y1[[5]])
)

# Bounds beneath the table, in percentage points as the paper reports them.
bounds_df <- tibble(
  step = toy$step_labels,
  low_bound = map2_dbl(toy$Y0, toy$Y1, \(y0, y1) ev_bounds(y0, y1)[["low_est"]]) * 100,
  high_bound = map2_dbl(toy$Y0, toy$Y1, \(y0, y1) ev_bounds(y0, y1)[["high_est"]]) * 100,
  width = high_bound - low_bound
)

print(table_3, n = nrow(table_3))
print(bounds_df)

write_csv(table_3, here::here("maintained", "output", "table_3_toy_example.csv"))
write_csv(bounds_df, here::here("maintained", "output", "table_3_bounds.csv"))
