# coppock_kaur_2022/maintained/in_text_claims.R
# Output: printed to stdout, one CLAIM line per published claim
# Depends on: helpers.R, every table, figure and in-text script's output in
#             maintained/output/, and ground_truth/published_appendix_values.csv
#             for the two appendix tables whose claims are counts of published cells
# Description: Every number the article and its supporting information print,
#   paired with the sentence or the float cell it comes from, computed here from
#   maintained/output/ and printed in the article's own units and to the precision
#   the page uses.
#
#   This file recomputes. It reads the same outputs the ground truth reads and
#   does its own selection, unit conversion and rounding, so the two arrive at
#   each claimed number by separate paths. It never reads the ground-truth CSV and
#   it never refits: the analysis scripts have already produced the estimates.
#   ground_truth/build_ground_truth.R runs this file, counts the CLAIM lines
#   against ground_truth/published_claims.csv, and compares the two instruments
#   line by line, so a disagreement between them stops the build.
#
#   Each block carries a "# covers:" line naming the claims it prints, as a
#   claim_id or a prefix ending in *. Prose claims carry the article's sentence
#   verbatim above them; float cells do not, because a cell is read off a page
#   rather than out of a sentence.
#
#   cat() is used throughout, which is allowed here and nowhere else: the whole
#   output is a human-read audit trail and every value needs a label beside it.

source(here::here("maintained", "helpers.R"))

options(width = 200)

out <- function(file) read_csv(here::here("maintained", "output", file), show_col_types = FALSE)

table_3 <- out("table_3_toy_example.csv")
table_3_bounds <- out("table_3_bounds.csv")
table_4 <- out("table_4_probabilistic.csv")
table_4_summary <- out("table_4_summary.csv")
table_5 <- out("table_5_imputation_summary.csv")
table_b1_b2 <- out("table_b1_b2_case_dataset.csv")
figure_1 <- out("figure_1_toy_bounds.csv")
figures_2_a1 <- out("figures_2_a1_gg_df.csv")
figures_3_a2 <- out("figures_3_a2_gg_df.csv")
figure_4 <- out("figure_4_expert_validation.csv")
summary_stats <- out("text_summary_stats.csv")
expert_agreement <- out("text_expert_agreement.csv")
imputation_counts <- out("text_imputation_counts.csv")

# The published transcription of appendix Tables B.1 and B.2. It is a reading of
# the article, not a comparison against it, and the claims those two tables carry
# are counts of the cells the pages print, so this file needs it.
published_appendix <- read_csv(
  here::here("ground_truth", "published_appendix_values.csv"),
  show_col_types = FALSE, col_types = cols(.default = "c")
)

# Printing ----
# One line per claim, carrying the claim identifier so the audit trail reads
# straight down and build_ground_truth.R can match it line by line.
claim <- function(id, value) cat("CLAIM ", id, " = ", value, "\n", sep = "")

# A value that rounds to zero from below prints as -0, which no page ever shows.
pp <- function(x, decimals = 0) {
  printed <- sprintf(str_c("%.", decimals, "f"), x)
  if_else(str_detect(printed, "^-0(\\.0+)?$"), str_remove(printed, "^-"), printed)
}

# The identifier a claim carries is the ground truth's own label, slugged. Float
# blocks build it from the label the pipeline itself writes, so a block cannot
# read one row and print another's identifier.
slug <- function(x) {
  x |> str_to_lower() |> str_replace_all("[^a-z0-9]+", "_") |> str_replace_all("^_|_$", "")
}

id_for <- function(float, ...) str_c(float, "|", slug(str_c(...)))

# Accessors ----
# Each names the row it wants and stops if the selection is not exactly one row,
# so a block cannot print a right-looking number that belongs to something else.
summary_value <- function(which_claim) {
  hit <- summary_stats$value[summary_stats$claim == which_claim]
  stopifnot(length(hit) == 1, !is.na(hit))
  hit
}

expert_value <- function(which_claim) {
  hit <- expert_agreement$value[expert_agreement$claim == which_claim]
  stopifnot(length(hit) == 1, !is.na(hit))
  hit
}

count_value <- function(sample, quantity_label) {
  hit <- imputation_counts$value[imputation_counts$transition_fac == sample &
                                   imputation_counts$quantity == quantity_label]
  stopifnot(length(hit) == 1, !is.na(hit))
  hit
}

ate_bound <- function(sample, which_step, side) {
  row <- figures_2_a1 |> filter(transition_fac == sample, step == which_step)
  stopifnot(nrow(row) == 1)
  row[[str_c("estimate_", side, "_est")]]
}

case_field <- function(which_case, field) {
  hit <- table_b1_b2[[field]][table_b1_b2$case == which_case]
  stopifnot(length(hit) == 1)
  hit
}

# Abstract ----

# "Prior to any analysis, the extreme value bounds around the average treatment
# effect on authoritarian resumption are 100 percentage points wide; imputation
# shrinks the width of these bounds to 51 points."
# covers: abstract|bounds_width_prior_to_any_analysis abstract|bounds_width_after_imputation
claim("abstract|bounds_width_prior_to_any_analysis",
      pp(summary_value("dem: bounds width once the world reveals half the potential outcomes")))
claim("abstract|bounds_width_after_imputation",
      pp(summary_value("dem: final ATE bounds width")))

# "We further demonstrate our method by aggregating specialists' beliefs about
# causal effects gathered through an expert survey, shrinking the width of the
# bounds to 44 points."
# covers: abstract|bounds_width_after_the_expert_survey
claim("abstract|bounds_width_after_the_expert_survey",
      pp(summary_value("expert: combined bounds width, all 63 cases")))

# The Procedure ----

# "Before any data are collected, the extreme value bounds are 200 percentage
# points wide."
# covers: text|bounds_width_before_any_data_are_collected
claim("text|bounds_width_before_any_data_are_collected",
      pp(summary_value("dem: bounds width before any data")))

# "After data collection, the extreme value bounds shrink from 200 points wide to
# 100 points wide."
# covers: text|bounds_width_once_half_the_potential_outcomes_are_revealed
claim("text|bounds_width_once_half_the_potential_outcomes_are_revealed",
      pp(summary_value("dem: bounds width once the world reveals half the potential outcomes")))

# A Toy Example ----

# "Consider a population of N = 10 units, seven of whom have been treated and
# three of whom have not."
# covers: text|toy_example_units text|toy_example_treated_units text|toy_example_untreated_units
claim("text|toy_example_units", pp(nrow(table_3)))
claim("text|toy_example_treated_units", pp(sum(table_3$d == 1)))
claim("text|toy_example_untreated_units", pp(sum(table_3$d == 0)))

# "The outcome for three of the treated units and one of the untreated units is 1;
# the outcome is equal to 0 for the remaining units."
# covers: text|toy_example_treated_units_with_outcome_1 text|toy_example_untreated_units_with_outcome_1
claim("text|toy_example_treated_units_with_outcome_1",
      pp(sum(table_3$d == 1 & table_3$Y == 1)))
claim("text|toy_example_untreated_units_with_outcome_1",
      pp(sum(table_3$d == 0 & table_3$Y == 1)))

# "Before adding any qualitative information, the bounds on the ATE extend from
# -40 percentage points to 60 percentage points."
# covers: text|toy_example_bounds_width_before_any_data
claim("text|toy_example_bounds_width_before_any_data",
      pp(table_3_bounds$width[table_3_bounds$step == "Before Any Data"]))

# "The fourth and fifth columns describe the imputation of five 'easy' cases."
# covers: text|toy_example_easy_imputations
easy_imputations <- sum(table_3$Y0_initial == "?" & table_3$Y0_easy != "?") +
  sum(table_3$Y1_initial == "?" & table_3$Y1_easy != "?")
claim("text|toy_example_easy_imputations", pp(easy_imputations))

# "These are scenarios in which the untreated outcomes for units 1, 2, and 5 are
# obviously (to the researcher) 1, 1, and 0, respectively. Similarly, the treated
# outcomes of units 8 and 9 are 1 and 0."
# covers: text|toy_example_untreated_outcomes_for_units_1_2_and_5 text|toy_example_treated_outcomes_for_units_8_and_9
claim("text|toy_example_untreated_outcomes_for_units_1_2_and_5",
      str_c(table_3$Y0_easy[c(1, 2, 5)], collapse = ", "))
claim("text|toy_example_treated_outcomes_for_units_8_and_9",
      str_c(table_3$Y1_easy[c(8, 9)], collapse = ", "))

# "The incorporation of empirical information and qualitative beliefs reduces the
# width of the bounds from 200 points to 10 points, corresponding to a dramatic
# reduction in fundamental uncertainty."
# covers: text|toy_example_final_bounds_width
claim("text|toy_example_final_bounds_width",
      pp(table_3_bounds$width[table_3_bounds$step == "Hard Cases"]))

# Table 3 ----
# The potential outcomes table, one claim per printed column read down the ten
# units, and the extreme value bounds printed beneath it at each step.
# covers: table_3|column_* table_3|ev_bounds_*
walk(
  c("d", "Y", "Y0_initial", "Y1_initial", "Y0_easy", "Y1_easy",
    "Y0_nulls", "Y1_nulls", "Y0_hard", "Y1_hard"),
  \(column) claim(id_for("table_3", "column ", column),
                  str_c(table_3[[column]], collapse = ","))
)

table_3_bounds |>
  filter(step != "Before Any Data") |>
  pwalk(\(step, low_bound, high_bound, width) {
    claim(id_for("table_3", "EV bounds low, ", step), pp(low_bound))
    claim(id_for("table_3", "EV bounds high, ", step), pp(high_bound))
  })

# Figure 1 ----
# The bounds at each step of the toy example, as the figure prints them.
# covers: figure_1|*
figure_1 |>
  pwalk(\(description, li, ui) {
    claim(id_for("figure_1", "low bound, ", description), pp(li))
    claim(id_for("figure_1", "high bound, ", description), pp(ui))
  })

# Probabilistic Extension ----

# "Instead of being sure that the untreated potential outcomes for units 6 and 7
# are 0, we think the probabilities of being a '1' for units 6 and 7 are .3 and
# .4, respectively (k = 2)."
#
# The two probabilities are not written into the enumeration; they are recovered
# from it, as the total probability of the scenarios in which each unit is a 1.
# covers: table_4|probability_that_unit_6_has_y0_1 table_4|probability_that_unit_7_has_y0_1
claim("table_4|probability_that_unit_6_has_y0_1",
      pp(sum(table_4$prob[table_4$unit_6 == 1]), 1))
claim("table_4|probability_that_unit_7_has_y0_1",
      pp(sum(table_4$prob[table_4$unit_7 == 1]), 1))

# "We now have to consider 2^2 = 4 possibilities for units 6 and 7 which occur
# according to the researcher's probabilistic beliefs."
# covers: text|probabilistic_extension_possible_sets_of_potential_outcomes
claim("text|probabilistic_extension_possible_sets_of_potential_outcomes", pp(nrow(table_4)))

# "The point estimate for each bound is a probability-weighted average: [-5, 25].
# We can characterize the uncertainty attending to the bounds with reference to
# the 2.5th and 97.5th quantiles of the distributions of each bound: [-20, 0] for
# the lower bound and [10, 30] for the upper bound."
# covers: table_4|probability_weighted_point_estimate_* table_4|*_quantile_of_the_*_bound
claim("table_4|probability_weighted_point_estimate_lower_bound",
      pp(table_4_summary$point_estimate[table_4_summary$quantity == "low_est"]))
claim("table_4|probability_weighted_point_estimate_upper_bound",
      pp(table_4_summary$point_estimate[table_4_summary$quantity == "high_est"]))
claim("table_4|2_5th_quantile_of_the_lower_bound",
      pp(table_4_summary$q025[table_4_summary$quantity == "low_est"]))
claim("table_4|97_5th_quantile_of_the_lower_bound",
      pp(table_4_summary$q975[table_4_summary$quantity == "low_est"]))
claim("table_4|2_5th_quantile_of_the_upper_bound",
      pp(table_4_summary$q025[table_4_summary$quantity == "high_est"]))
claim("table_4|97_5th_quantile_of_the_upper_bound",
      pp(table_4_summary$q975[table_4_summary$quantity == "high_est"]))

# Table 4 ----
# The four realisations of the uncertain imputations for units 6 and 7, with the
# bounds and the probability each implies.
# covers: table_4|ev_bounds_* table_4|probability_unit_*
table_4 |>
  pwalk(\(unit_6, unit_7, ev_bounds, low_est, high_est, prob) {
    scenario <- str_c("unit 6 = ", unit_6, ", unit 7 = ", unit_7)
    claim(id_for("table_4", "EV bounds low, ", scenario), pp(low_est))
    claim(id_for("table_4", "EV bounds high, ", scenario), pp(high_est))
    claim(id_for("table_4", "probability, ", scenario), pp(prob, 2))
  })

# Application to the Average Effect of Truth Commissions ----

# "We obtained information on transitions to democratic rule after a period of
# authoritarianism and arrive at a dataset of 63 observations that have a
# probability of experiencing a TTC between 0 and 1, exclusive."
# covers: text|democratization_cases
claim("text|democratization_cases", pp(count_value("Democratization", "cases")))

# Footnote 4: "See the Supporting Information (SI) for an application of our
# method to the study of truth commission in 54 post-conflict cases."
#
# The same quantity Appendix A states, so the two are printed from one source and
# a disagreement between the article's two statements of it would be visible here.
# covers: text|end_of_conflict_cases_stated_in_the_main_text_footnote
claim("text|end_of_conflict_cases_stated_in_the_main_text_footnote",
      pp(count_value("End of conflict", "cases")))

# Imputing Missing Potential Outcomes ----

# "In this empirical example, we used the probabilistic version of the procedure.
# For all 63 unobserved potential outcomes, we imputed 5 with certainty, 26
# probabilistically and we left 32 unimputed."
# covers: text|unobserved_potential_outcomes text|unobserved_potential_outcomes_imputed_with_certainty text|unobserved_potential_outcomes_imputed_probabilistically text|unobserved_potential_outcomes_left_unimputed
claim("text|unobserved_potential_outcomes", pp(count_value("Democratization", "cases")))
claim("text|unobserved_potential_outcomes_imputed_with_certainty",
      pp(count_value("Democratization", "imputed_with_certainty")))
claim("text|unobserved_potential_outcomes_imputed_probabilistically",
      pp(count_value("Democratization", "imputed_probabilistically")))
claim("text|unobserved_potential_outcomes_left_unimputed",
      pp(count_value("Democratization", "left_unimputed")))

# "Step 1: Disbanded and Discredited Cases. We first identify truth commissions
# that were disbanded before completion (Bolivia in 1982 and the Philippines in
# 1986). These units reveal their untreated outcome. The observed outcome Yi(0)
# in each of these four cases was 0, as authoritarianism did not resume within 10
# years of transition."
# covers: text|disbanded_and_discredited_democratization_cases text|observed_outcome_in_the_disbanded_and_discredited_cases
claim("text|disbanded_and_discredited_democratization_cases",
      pp(count_value("Democratization", "cases at step: Disbanded and Discredited Cases")))
disbanded_outcomes <- table_b1_b2 |>
  filter(table == "B.2", step == "Disbanded and Discredited Cases") |>
  pull(observed) |>
  unique()
stopifnot(length(disbanded_outcomes) == 1)
claim("text|observed_outcome_in_the_disbanded_and_discredited_cases", disbanded_outcomes)

# "We impute the treated potential outcome in each of these cases to be
# Yi(0) = Yi(1) = 0, with a probability of .1 that the imputed outcomes would take
# on the value 1 instead."
# covers: text|disbanded_cases_probability_the_imputed_outcome_equals_1
disbanded_probabilities <- table_b1_b2 |>
  filter(table == "B.2", step == "Disbanded and Discredited Cases") |>
  pull(probability) |>
  unique()
stopifnot(length(disbanded_probabilities) == 1)
claim("text|disbanded_cases_probability_the_imputed_outcome_equals_1", disbanded_probabilities)

# "We therefore interpret the South African case as one where, in the absence of
# the TTC, the transition would have been incomplete and repression would have
# been very likely to resume. In other words, Yi(0) = 1 with a probability of .8."
# covers: text|south_africa_probability_the_imputed_untreated_outcome_equals_1
claim("text|south_africa_probability_the_imputed_untreated_outcome_equals_1",
      case_field("South Africa (1910-1994)", "probability"))

# "That is, we impute Yi(1) = Yi(0) = 0 with a probability of .1 that the imputed
# outcome would take on the value of 1."
# covers: text|nigeria_probability_the_imputed_untreated_outcome_equals_1
claim("text|nigeria_probability_the_imputed_untreated_outcome_equals_1",
      case_field("Nigeria (1993-1999)", "probability"))

# "Next, we turn to the eight cases treated with bona fide TTCs."
# covers: text|treated_democratization_cases
claim("text|treated_democratization_cases", pp(count_value("Democratization", "treated")))

# Summary ----

# "Before any data collection, the extreme value bounds are 200 points wide. After
# the world reveals half the potential outcomes, the width of the bounds shrink to
# 100 points. The four steps above shrink the uncertainty further as missing
# potential outcomes are filled in. The final bounds around the ATE are [-2, 49]
# (51 points wide)."
# covers: text|final_ate_lower_bound text|final_ate_upper_bound text|final_ate_bounds_width
claim("text|final_ate_lower_bound", pp(summary_value("dem: final ATE lower bound")))
claim("text|final_ate_upper_bound", pp(summary_value("dem: final ATE upper bound")))
claim("text|final_ate_bounds_width", pp(summary_value("dem: final ATE bounds width")))

# "The bounds include zero. The data and our state of knowledge are currently
# consistent with positive, negative and zero average effects."
# covers: text|the_bounds_around_the_ate_include_zero
final_low <- round(summary_value("dem: final ATE lower bound"))
final_high <- round(summary_value("dem: final ATE upper bound"))
claim("text|the_bounds_around_the_ate_include_zero",
      str_c("[", pp(final_low), ", ", pp(final_high), "] ",
            if_else(final_low <= 0 & final_high >= 0, "contains", "excludes"), " 0"))

# "In our view, the most important pattern is that we impute non-zero causal
# effects only six times in these democratization cases."
# covers: text|cases_imputed_as_a_non_zero_causal_effect
claim("text|cases_imputed_as_a_non_zero_causal_effect",
      pp(summary_value("dem: cases imputed as a non-zero causal effect")))

# "Another important pattern is that we are unable to make imputations in about
# half the total number of cases, hence the bounds remain wide and the gaps in our
# knowledge persist."
# covers: text|unimputed_cases_as_a_share_of_the_total
unimputed <- count_value("Democratization", "left_unimputed")
democratization_cases <- count_value("Democratization", "cases")
claim("text|unimputed_cases_as_a_share_of_the_total",
      str_c(pp(unimputed), " of ", pp(democratization_cases), ", ",
            pp(100 * unimputed / democratization_cases, 1), "%"))

# Table 5 ----
# The distribution of imputed unit-level effects. The article prints the
# democratization row only; the end-of-conflict row is written out alongside it
# and has no published counterpart.
# covers: table_5|democratization_*
walk(
  c("Negative Effect", "No Effect", "Positive Effect", "Unimputed"),
  \(column) claim(id_for("table_5", "democratization, ", column),
                  table_5[[column]][table_5$transition_fac == "Democratization"])
)

# Figure 2 and Figure A.1 ----
# The bounds on the ATE after each imputation step, democratization in Figure 2
# and end of conflict in Figure A.1, as the figures label them.
# covers: figure_2|* figure_a1|*
figures_2_a1 |>
  pwalk(\(transition_fac, description, estimate_low_est, estimate_high_est, ...) {
    float <- if (transition_fac == "Democratization") "figure_2" else "figure_a1"
    claim(id_for(float, "low bound, ", description), pp(estimate_low_est))
    claim(id_for(float, "high bound, ", description), pp(estimate_high_est))
  })

# Figure 3 and Figure A.2 ----
# The same bounds split by treatment status.
# covers: figure_3|* figure_a2|*
figures_3_a2 |>
  mutate(estimand_short = if_else(treatment == 1, "ATT", "ATU")) |>
  pwalk(\(transition_fac, description, estimand_short,
          estimate_low_est, estimate_high_est, ...) {
    float <- if (transition_fac == "Democratization") "figure_3" else "figure_a2"
    claim(id_for(float, "low bound, ", estimand_short, ", ", description), pp(estimate_low_est))
    claim(id_for(float, "high bound, ", estimand_short, ", ", description), pp(estimate_high_est))
  })

# "There are far more untreated units than treated units, and we know far less
# about them. The bounds on the ATU are greater than 58 points wide, compared with
# the bounds on the ATT, which shrink all the way down to a point. We can
# summarize the ATT as a -15 percentage point effect on return to authoritarianism."
# covers: text|atu_final_bounds_width text|att_summarised_as_a_point_effect text|the_att_bounds_shrink_to_a_point text|the_atu_bounds_are_wider_than_the_att_bounds
atu_width <- round(summary_value("dem: ATU final bounds width"))
att_low <- round(summary_value("dem: ATT final lower bound"))
att_high <- round(summary_value("dem: ATT final upper bound"))
claim("text|atu_final_bounds_width", pp(atu_width))
claim("text|att_summarised_as_a_point_effect", pp(att_low))
claim("text|the_att_bounds_shrink_to_a_point",
      str_c("[", pp(att_low), ", ", pp(att_high), "], width ", pp(att_high - att_low)))
claim("text|the_atu_bounds_are_wider_than_the_att_bounds",
      str_c(pp(atu_width), " against ", pp(att_high - att_low)))

# Expert Survey ----

# "We conducted an email survey with country experts for each of our 63 cases...
# We received 20 responses to our survey, the text of which is reproduced in the SI."
# covers: text|expert_responses_received text|democratization_cases_without_an_expert_response
claim("text|expert_responses_received", pp(expert_value("expert responses received")))
claim("text|democratization_cases_without_an_expert_response",
      pp(expert_value("democratization cases without an expert response")))

# "We first assessed whether the experts agreed with our characterization of the
# observed outcome and the observed treatment status. All but five did agree."
#
# The deposited case file records which experts responded and what they imputed,
# and records nothing about whether they accepted our coding, so this quantity has
# no counterpart anywhere in the deposit.
# covers: text|experts_disagreeing_with_our_coding_of_treatment_and_outcome
claim("text|experts_disagreeing_with_our_coding_of_treatment_and_outcome",
      "not recorded in the deposit")

# "Of these 20 cases, the imputations fully agreed with ours seven times (we either
# made the same imputations or both declined to impute) and directly conflicted
# three times (we made different imputations). In three cases, we imputed but the
# experts did not, and in the final seven cases, the experts imputed where we did
# not. Perhaps reflecting the experts' greater case knowledge, they gave
# imputations in 14 total cases compared with our 10."
# covers: text|expert_and_author_imputations_agreed text|expert_and_author_imputations_conflicted text|we_imputed_the_experts_did_not text|the_experts_imputed_we_did_not text|cases_the_experts_imputed text|cases_we_imputed
agreement_counts <- out("text_expert_agreement_counts.csv")
agreement_count <- function(coding) {
  hit <- agreement_counts$cases[agreement_counts$agreement_coding == coding]
  stopifnot(length(hit) == 1)
  hit
}
claim("text|expert_and_author_imputations_agreed", pp(agreement_count("agreement")))
claim("text|expert_and_author_imputations_conflicted", pp(agreement_count("disagreement")))
claim("text|we_imputed_the_experts_did_not", pp(agreement_count("They declined, we imputed")))
claim("text|the_experts_imputed_we_did_not", pp(agreement_count("They imputed, we declined")))
claim("text|cases_the_experts_imputed", pp(expert_value("cases the experts imputed")))
claim("text|cases_we_imputed", pp(expert_value("cases we imputed")))

# "Our original bounds for this set were 50 points wide; the bounds for the experts
# are 30 points wide, again reflecting their greater case knowledge. Among the full
# set of 63 cases, our original bounds were 51 points wide, but the experts' are 78
# points wide."
# covers: text|our_bounds_width_20_responding_cases text|expert_bounds_width_20_responding_cases text|our_bounds_width_all_63_cases text|expert_bounds_width_all_63_cases text|expert_bounds_are_narrower_than_ours_among_the_20_responding_cases text|expert_bounds_are_wider_than_ours_among_all_63_cases
ours_20 <- round(summary_value("expert: our bounds width, 20 responding cases"))
expert_20 <- round(summary_value("expert: expert bounds width, 20 responding cases"))
ours_63 <- round(summary_value("expert: our bounds width, all 63 cases"))
expert_63 <- round(summary_value("expert: expert bounds width, all 63 cases"))
claim("text|our_bounds_width_20_responding_cases", pp(ours_20))
claim("text|expert_bounds_width_20_responding_cases", pp(expert_20))
claim("text|our_bounds_width_all_63_cases", pp(ours_63))
claim("text|expert_bounds_width_all_63_cases", pp(expert_63))
claim("text|expert_bounds_are_narrower_than_ours_among_the_20_responding_cases",
      str_c(pp(expert_20), " against ", pp(ours_20)))
claim("text|expert_bounds_are_wider_than_ours_among_all_63_cases",
      str_c(pp(expert_63), " against ", pp(ours_63)))

# "The combined bounds are narrower than our original, reflecting a small but
# meaningful increase in cumulative beliefs about causal effects."
# covers: text|combined_bounds_width_all_63_cases text|the_combined_bounds_are_narrower_than_our_original_bounds
combined_63 <- round(summary_value("expert: combined bounds width, all 63 cases"))
claim("text|combined_bounds_width_all_63_cases", pp(combined_63))
claim("text|the_combined_bounds_are_narrower_than_our_original_bounds",
      str_c(pp(combined_63), " against ", pp(ours_63)))

# "Surprisingly, all 20 of our respondents either made no imputation or imputed a
# counterfactual outcome that was equal to the observed outcome: all responses were
# either 'I don't know' or 'no effect'."
# covers: text|expert_imputations_differing_from_the_observed_outcome
claim("text|expert_imputations_differing_from_the_observed_outcome",
      pp(expert_value("expert imputations differing from the observed outcome")))

# "Six experts declined to impute counterfactual outcomes, all six of which were
# untreated cases. By contrast, no expert assigned to a treated case declined to
# impute."
# covers: text|experts_who_declined_to_impute text|declining_experts_assigned_to_an_untreated_case text|no_expert_assigned_to_a_treated_case_declined_to_impute
declined <- expert_value("experts who declined to impute")
declined_untreated <- expert_value("declining experts assigned to an untreated case")
claim("text|experts_who_declined_to_impute", pp(declined))
claim("text|declining_experts_assigned_to_an_untreated_case", pp(declined_untreated))
claim("text|no_expert_assigned_to_a_treated_case_declined_to_impute",
      str_c(pp(declined - declined_untreated), " of ", pp(declined), " declining experts"))

# Figure 4 ----
# The bounds implied by the expert imputations, in both panels.
# covers: figure_4|*
figure_4 |>
  pwalk(\(set, person, li, ui, ...) {
    claim(id_for("figure_4", "low bound, ", person, ", ", set), pp(li))
    claim(id_for("figure_4", "high bound, ", person, ", ", set), pp(ui))
  })

# Discussion ----

# "Indeed, country experts disagreed with our imputations in three of 20 cases; ex
# post, we agree with them now, because we benefited from their expertise and
# reasoning."
#
# The same quantity the Expert Survey section states, printed a second time so a
# divergence between the article's two statements of it would be visible here.
# covers: text|expert_imputations_conflicting_with_ours_restated_in_the_discussion
claim("text|expert_imputations_conflicting_with_ours_restated_in_the_discussion",
      pp(agreement_count("disagreement")))

# Appendix A ----

# "Specifically, we identify 54 cases that transitioned from civil war between
# 1980-2010, 6 of which are treated."
# covers: appendix_a|end_of_conflict_cases appendix_a|treated_end_of_conflict_cases
claim("appendix_a|end_of_conflict_cases", pp(count_value("End of conflict", "cases")))
claim("appendix_a|treated_end_of_conflict_cases", pp(count_value("End of conflict", "treated")))

# "The incorporation of qualitative beliefs about counterfactuals shrinks the width
# of the extreme value bounds from 100 to 41 points. The bounds come to [-3, 42]
# (only 45 points wide), and the ATT can be summarized as a -10 percentage point
# effect on return to conflict."
#
# The article's two statements of the same width are printed together: the width of
# the unrounded bounds, and the width the rounded endpoints imply.
# covers: appendix_a|bounds_width_once_half_the_potential_outcomes_are_revealed appendix_a|bounds_width_after_imputation appendix_a|final_ate_lower_bound appendix_a|final_ate_upper_bound appendix_a|final_ate_bounds_width_from_the_rounded_endpoints appendix_a|att_summarised_as_a_point_effect
eoc_low <- round(summary_value("eoc: final ATE lower bound"))
eoc_high <- round(summary_value("eoc: final ATE upper bound"))
claim("appendix_a|bounds_width_once_half_the_potential_outcomes_are_revealed",
      pp(summary_value("eoc: bounds width once the world reveals half the potential outcomes")))
claim("appendix_a|bounds_width_after_imputation", pp(summary_value("eoc: final ATE bounds width")))
claim("appendix_a|final_ate_lower_bound", pp(eoc_low))
claim("appendix_a|final_ate_upper_bound", pp(eoc_high))
claim("appendix_a|final_ate_bounds_width_from_the_rounded_endpoints", pp(eoc_high - eoc_low))
claim("appendix_a|att_summarised_as_a_point_effect",
      pp(summary_value("eoc: ATT final lower bound")))

# Appendix Tables B.1 and B.2 ----
# The full case datasets. Each claim is the count of cells one published column
# prints that the deposited case file reproduces, against the count the page
# prints. The deposited archive has no script for either table.
# covers: table_b1|* table_b2|*
appendix_columns <- c(
  "treatment indicator" = "d",
  "observed outcome" = "Y",
  "revealed potential outcome" = "observed",
  "imputed untreated outcome" = "imputed_y0",
  "imputed treated outcome" = "imputed_y1",
  "imputation probability" = "probability",
  "unit-level effect" = "tau"
)

appendix_comparison <- published_appendix |>
  inner_join(table_b1_b2, by = c("table", "case"), suffix = c("_published", "_rewrite"))

stopifnot(nrow(appendix_comparison) == nrow(published_appendix))

walk2(names(appendix_columns), appendix_columns, \(label, column) {
  published <- appendix_comparison[[str_c(column, "_published")]]
  rewritten <- appendix_comparison[[str_c(column, "_rewrite")]]
  agrees <- !is.na(published) & !is.na(rewritten) & published == rewritten
  walk(c("B.1", "B.2"), \(which_table) {
    rows <- appendix_comparison$table == which_table
    float <- if (which_table == "B.1") "table_b1" else "table_b2"
    claim(id_for(float, "cells printed in the ", label, " column"), pp(sum(agrees[rows])))
  })
})
