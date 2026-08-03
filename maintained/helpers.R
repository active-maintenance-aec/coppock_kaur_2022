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
# probabilities and recomputes the bounds. Returns a long tibble. This is the
# deposited archive's method. The figures no longer use it, because the same
# distribution is available exactly through bounds_distribution() below; it is
# kept because what a simulation of these bounds gives is itself something the
# report needs to be able to state.
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

# The distribution of the number of ones among independent Bernoulli draws with
# different probabilities, built by convolving one draw in at a time. A
# probability of exactly 0 or 1 is a draw like any other and simply shifts the
# distribution, so imputed and observed entries go in together.
poisson_binomial <- function(probs) {
  reduce(probs, \(pmf, p) c(pmf * (1 - p), 0) + c(0, pmf * p), .init = 1)
}

# The exact distribution of the extreme value bounds under probabilistic
# imputations, which is the distribution sample_bounds() draws from. Each bound
# is the count of realised ones among the imputed and observed entries, offset by
# the unimputed entries that the bound fills with a constant, and divided by the
# number of units. It is therefore affine in the realisations, so the whole
# distribution is a convolution and does not have to be sampled: the mean of the
# draws estimates a quantity available in closed form, and the quantiles of the
# draws estimate quantiles that can be read off the enumeration. Both bounds move
# together, differing only by the constant each fills its unimputed entries with,
# so one enumeration carries both. Returns each attainable pair of bounds with
# the probability of it, in the shape table_4_probabilistic.R enumerates the toy
# example's four scenarios.
bounds_distribution <- function(Y0, Y1) {
  units <- length(Y0)
  ones_Y0 <- poisson_binomial(Y0[!is.na(Y0)])
  ones_Y1 <- poisson_binomial(Y1[!is.na(Y1)])
  expand_grid(
    realised_Y1 = seq_along(ones_Y1) - 1,
    realised_Y0 = seq_along(ones_Y0) - 1
  ) |>
    mutate(
      prob = ones_Y1[realised_Y1 + 1] * ones_Y0[realised_Y0 + 1],
      low_est = (realised_Y1 - realised_Y0 - sum(is.na(Y0))) / units,
      high_est = (realised_Y1 + sum(is.na(Y1)) - realised_Y0) / units
    ) |>
    summarise(prob = sum(prob), .by = c(low_est, high_est))
}

# The label a figure prints for a bound. The published figures label whole
# percentage points, and a value sitting exactly halfway between two of them has
# no whole-number label at all: which one appeared would be decided by the
# tie-breaking rule rather than by the quantity. Such a value is printed at the
# one decimal that states it. A value rounding to zero from below prints as -0,
# which no page ever shows.
bound_label <- function(x) {
  printed <- sprintf(if_else(near(x %% 1, 0.5), "%.1f", "%.0f"), x)
  if_else(str_detect(printed, "^-0(\\.0+)?$"), str_remove(printed, "^-"), printed)
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
