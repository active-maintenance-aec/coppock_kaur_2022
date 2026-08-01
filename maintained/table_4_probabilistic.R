# coppock_kaur_2022/maintained/table_4_probabilistic.R
# Output: output/table_4_probabilistic.csv, output/table_4_summary.csv
# Depends on: helpers.R
# Description: Table 4, the probabilistic extension of the toy example. Enumerates
#              the four binary realisations of the uncertain imputations for units
#              6 and 7, with the bounds and probability each implies. The second
#              output holds the probability-weighted point estimate and the 2.5th
#              and 97.5th quantiles the surrounding text reports; both come from
#              the same enumeration, so they are written by one script.

source(here::here("maintained", "helpers.R"))

toy <- quimpo_toy_example()

# Instead of committing to Y0 = 0 for units 6 and 7, the researcher states
# probabilities that each is a 1.
Y0_prob <- toy$Y0[[3]]
Y1_prob <- toy$Y1[[3]]
Y0_prob[c(6, 7)] <- c(0.2, 0.3)

possible_Y0s <- make_possible_vectors(Y0_prob)
probs_Y0s <- get_vector_probabilities(Y0_prob)

table_4 <- map2(
  possible_Y0s,
  probs_Y0s,
  \(y0_vec, prob) {
    bounds <- ev_bounds(Y0 = y0_vec, Y1 = Y1_prob)
    tibble(
      unit_6 = y0_vec[6],
      unit_7 = y0_vec[7],
      low_est = bounds[["low_est"]] * 100,
      high_est = bounds[["high_est"]] * 100,
      prob = prob
    )
  }
) |>
  bind_rows() |>
  mutate(ev_bounds = paste0("[", low_est, ", ", high_est, "]"))

# Point estimate and uncertainty interval for each bound.
summary_df <- tibble(
  quantity = c("low_est", "high_est"),
  point_estimate = c(
    sum(table_4$low_est * table_4$prob),
    sum(table_4$high_est * table_4$prob)
  ),
  q025 = c(
    weighted_quantile(table_4$low_est, table_4$prob, 0.025),
    weighted_quantile(table_4$high_est, table_4$prob, 0.025)
  ),
  q975 = c(
    weighted_quantile(table_4$low_est, table_4$prob, 0.975),
    weighted_quantile(table_4$high_est, table_4$prob, 0.975)
  )
)

print(select(table_4, unit_6, unit_7, ev_bounds, prob))
print(summary_df)

write_csv(
  select(table_4, unit_6, unit_7, ev_bounds, low_est, high_est, prob),
  here::here("maintained", "output", "table_4_probabilistic.csv")
)
write_csv(summary_df, here::here("maintained", "output", "table_4_summary.csv"))
