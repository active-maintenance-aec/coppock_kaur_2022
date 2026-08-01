# coppock_kaur_2022/maintained/helpers.R
# Output: none
# Depends on: nothing
# Description: Packages and the QUIMPO helper functions shared by every script.

library(here)
library(tidyverse)
library(janitor)

# Extreme value bounds ----
# Given Y0 and Y1 vectors, possibly with NAs for unimputed potential outcomes,
# fill the missing entries with the best and worst cases and return the implied
# bounds on the average treatment effect.
ev_bounds <- function(Y0, Y1, min = 0, max = 1) {
  Y0_low <- Y0_high <- Y0
  Y1_low <- Y1_high <- Y1
  Y0_low[is.na(Y0)] <- min
  Y1_low[is.na(Y1)] <- min
  Y0_high[is.na(Y0)] <- max
  Y1_high[is.na(Y1)] <- max
  c(
    low_est = mean(Y1_low) - mean(Y0_high),
    high_est = mean(Y1_high) - mean(Y0_low)
  )
}

# Width of the extreme value bounds, a function of how many potential outcomes
# are missing and of the range of the outcome.
bounds_width <- function(Y0, Y1, min = 0, max = 1) {
  (sum(is.na(Y0)) + sum(is.na(Y1))) * (max - min) / length(Y0)
}

# Simulate the sampling distribution of the bounds under probabilistic
# imputations: each draw realises binary potential outcomes from the imputed
# probabilities and recomputes the bounds. Returns a long tibble.
sample_bounds <- function(Y0, Y1, sims) {
  map(
    seq_len(sims),
    \(i) enframe(ev_bounds(
      Y0 = suppressWarnings(rbinom(length(Y0), 1, prob = Y0)),
      Y1 = suppressWarnings(rbinom(length(Y1), 1, prob = Y1))
    ))
  ) |>
    bind_rows(.id = "sim")
}

# Probabilistic extension ----
# Positions holding a probabilistic (strictly between 0 and 1) imputation.
is_prob <- function(x) {
  !is.na(x) & x > 0 & x < 1
}

put_this_there <- function(x, this, there) {
  x[there] <- this
  x
}

# Every binary vector consistent with the probabilistic entries of x: 2^k of
# them, where k is the number of probabilistic imputations.
make_possible_vectors <- function(x) {
  which_prob <- which(is_prob(x))
  grid <- expand.grid(rep(list(c(0, 1)), length(which_prob)))
  grid |>
    split(seq_len(nrow(grid))) |>
    map(\(row) put_this_there(x, as.numeric(row), which_prob))
}

# Joint probability of one realisation of the probabilistic entries.
calc_probs <- function(possible_vec, x) {
  vals <- possible_vec[which(is_prob(x))]
  probs <- x[is_prob(x)]
  prod(vals * probs + (1 - vals) * (1 - probs))
}

get_vector_probabilities <- function(x) {
  make_possible_vectors(x) |>
    map(\(v) calc_probs(v, x))
}

# Quantile of a discrete distribution given by values and their probabilities:
# the smallest value whose cumulative probability reaches p. Used to express the
# uncertainty attending the bounds when the set of possibilities is enumerable
# rather than sampled.
weighted_quantile <- function(values, probs, p) {
  ord <- order(values)
  values[ord][which(cumsum(probs[ord]) >= p - 1e-12)[1]]
}

# Imputation steps ----
# The order in which missing potential outcomes are filled in, and the labels the
# published figures give each step. Shared by Figures 2, 3, A1 and A2.
quimpo_step_levels <- c("agnostic", "obs", "s0", "s1", "s2", "s3", "s4")

quimpo_step_labels <- c(
  "Before Any Data",
  "Initial Values",
  "Disbanded and Discredited Cases",
  "Treated Cases",
  "Non-transitional Cases",
  "Untreated Cases",
  "Unimputable Cases"
)

# Toy example ----
# The ten-unit example behind Table 3, Figure 1 and Table 4. Seven units are
# treated and three are not; missing potential outcomes are imputed in four
# steps. Defined once here because three scripts read it and they must agree.
quimpo_toy_example <- function() {
  Z <- rep(c(1, 0), c(7, 3))
  Y <- rep(c(1, 0, 1, 0), c(4, 3, 1, 2))

  # Initial values: the world reveals Y1 for the treated and Y0 for the untreated.
  Y0_step1 <- Y1_step1 <- Y
  Y0_step1[Z == 1] <- NA
  Y1_step1[Z == 0] <- NA

  # Easy cases: untreated outcomes for units 1, 2 and 5, treated outcomes for 8 and 9.
  Y0_step2 <- Y0_step1
  Y1_step2 <- Y1_step1
  Y0_step2[c(1, 2)] <- 1
  Y0_step2[5] <- 0
  Y1_step2[8] <- 1
  Y1_step2[9] <- 0

  # Nulls for units 6 and 7: the treatment is judged to have had no effect.
  Y0_step3 <- Y0_step2
  Y1_step3 <- Y1_step2
  Y0_step3[c(6, 7)] <- 0

  # Hard cases: units 3 and 4 resolved, unit 10 left unimputed.
  Y0_step4 <- Y0_step3
  Y1_step4 <- Y1_step3
  Y0_step4[c(3, 4)] <- 0

  list(
    Z = Z,
    Y = Y,
    step_labels = c("Before Any Data", "Initial Values", "Easy Cases",
                    "Nulls for 6&7", "Hard Cases"),
    Y0 = list(rep(NA_real_, 10), Y0_step1, Y0_step2, Y0_step3, Y0_step4),
    Y1 = list(rep(NA_real_, 10), Y1_step1, Y1_step2, Y1_step3, Y1_step4)
  )
}
