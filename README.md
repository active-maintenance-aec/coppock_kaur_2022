# Active Maintenance Report: coppock_kaur_2022

2026-08-01

- [Summary](#summary)
  - [Does the deposited archive run?](#does-the-deposited-archive-run)
  - [Does the maintained rewrite reproduce the
    paper?](#does-the-maintained-rewrite-reproduce-the-paper)
- [Paper overview](#paper-overview)
- [Original archive reproducibility](#original-archive-reproducibility)
  - [The unseeded simulation](#the-unseeded-simulation)
  - [Checksums](#checksums)
- [Errata](#errata)
- [Number-by-number comparison](#number-by-number-comparison)
- [Maintained rewrite](#maintained-rewrite)
  - [Architecture](#architecture)
  - [Deprecated patterns replaced](#deprecated-patterns-replaced)
- [Figures](#figures)
- [Expert survey verification](#expert-survey-verification)
- [In-text quantities](#in-text-quantities)
- [R environment](#r-environment)

*Drafted by Claude Opus 5 under the supervision of Alex Coppock.*

This repository holds the actively maintained replication code for
Coppock and Kaur (2022), together with the reproducibility report that
documents what the original archive did and did not do. It is part of a
program applying the maintenance proposal in Peer, Orr and Coppock
(2021, *PS: Political Science & Politics*, doi
[10.1017/S1049096521000366](https://doi.org/10.1017/S1049096521000366))
to a set of published archives.

|  |  |
|----|----|
| Article | [10.1111/ajps.12697](https://doi.org/10.1111/ajps.12697) |
| Replication archive | [10.7910/DVN/2IVKXD](https://doi.org/10.7910/DVN/2IVKXD) |

**The data are not redistributed here.** The deposit is 10 files and
about 0.7 MB, and lives at Harvard Dataverse, which is the only copy
this repository points at. `download_original.R` fetches it and verifies
every file; `original_manifest.csv` pins the file identifiers, sizes and
checksums, so the exact bytes this code was written against are recorded
in version control even though the bytes themselves are not.

**Repository layout.** `maintained/` is the maintained rewrite: one
script per published table or figure, writing to `output/`, which is
committed so a reader can compare a fresh run against it without
downloading anything. `ground_truth/` ties every published number to the
code that produces it. `original/` is created by the download script and
is deliberately absent from the repository. This file is the
reproducibility report, also available as a PDF in `report/`.

**License.** CC0 1.0 Universal, matching the terms of the deposit this
repository maintains. See `LICENSE`.

**To reproduce.** Clone or download the repository, open
`coppock_kaur_2022.Rproj`, and run:

``` r
source("run_all.R")
```

That fetches the deposit, verifies its 10 files, and produces every
table and figure into `maintained/output/`. Required packages:
tidyverse, janitor, here, and for this report knitr and kableExtra.
Paths resolve through `here`, so nothing depends on the working
directory. The full run takes about a minute, most of it in the
twenty-seed sensitivity check at the end. A successful run overwrites
`maintained/output/`, which is committed: **`git diff` on that folder is
the reproduction check.** The figure PDFs always differ, because a PDF
records the time it was written; the CSV and PNG output comes back
byte-identical.

# Summary

Two questions, answered before the detail.

## Does the deposited archive run?

Yes. All five analysis scripts and the helpers file execute without
error on R 4.6.0. Every package the archive names still installs from
CRAN: tidyverse, xtable, janitor and reshape2. Nothing in the archive
has been removed from the language; what has accumulated is deprecation.
`geom_errorbarh()` and the `<ggplot> %+% data` idiom were deprecated in
ggplot2 4.0.0, the `size` aesthetic for lines in 3.4.0, and
`reshape2::melt` and `dcast` are superseded by tidyr. All of them still
work and all of them warn. Everything that stands between this archive
and a clean run is resolvable by substitution.

Running is not the same as reproducing, and one thing keeps the archive
from reproducing its own figures exactly. `figures_2_3_A1_A2.R`
estimates the bounds by simulation, 1,000 draws for Figures 2 and A1 and
10,000 for Figures 3 and A2, and it sets no seed. The published figures
are labelled with rounded percentage points, so most of the simulation
noise is absorbed by the rounding, but not all of it: repeating the
Figure 2 and A1 simulation at twenty seeds moves at least one of the 28
rounded labels off its published value in 9 of them. A reader running
the deposited script today has close to even odds of seeing a figure
that disagrees with the article somewhere, with no error and no warning.
The maintained rewrite fixes the seed at 12345, which reproduces all 28
published labels of Figures 2 and A1 and all 56 of Figures 3 and A2.

Two smaller things. `table_4.R` prints its bounds as fractions where the
paper prints percentage points, so the deposited output reads `[0, 0.3]`
against the article’s `[0, 30]`. It is a display inconsistency and not a
numerical one. And the writing of every table and figure is commented
out: each script builds the object and prints it, but the `xtable` and
`ggsave` calls that would put it on disk are behind `#`. The archive is
a set of scripts that show their work rather than a pipeline that
produces the article’s floats.

## Does the maintained rewrite reproduce the paper?

Yes. 183 of the 187 verifiable ground truth claims match the published
values to reported precision: every cell and bound of Table 3, every
bound of Figure 1, every row of Table 4, the democratization row of
Table 5, all 28 labels of Figures 2 and A1, all 56 of Figures 3 and A2,
all ten bounds of Figure 4, and every in-text quantity from the
abstract, the Expert Survey section and Appendix A.

The 4 that do not match are places where the article’s prose disagrees
with the article’s own tables and figures, and they are set out in the
errata section below. The rewrite agrees with the tables and figures in
every case; it is the sentences that are wrong. The remaining 4 recorded
quantities are the end-of-conflict row of the imputation summary, which
the rewrite computes and neither the article nor the appendix prints, so
they are marked unverifiable rather than matched.

# Paper overview

**Citation**: Coppock, A. and Kaur, D. (2022). “Qualitative imputation
of missing potential outcomes.” *American Journal of Political Science*,
66(3), 681-695. DOI: 10.1111/ajps.12697

**Summary**: The paper proposes a framework for meta-analysing
qualitative causal inferences. A causal claim about a single case is a
claim about the value of a missing potential outcome, so a set of such
claims can be treated as imputations and fed into Manski (1999) extreme
value bounds, which are the logical range of average causal effects
consistent with what has been observed. Bounds on a binary outcome start
200 percentage points wide and narrow to 100 once the world reveals half
the potential outcomes; each qualitative imputation narrows them
further, and cases too murky to call are left unimputed rather than
guessed. Where the analyst holds a probability rather than a point
belief, the extension enumerates the 2^k consistent worlds and takes the
probability-weighted bounds. The application is to 63 cases eligible for
a transitional truth commission upon democratization, eight of which
received one, with authoritarian resumption within ten years as the
outcome. Imputation in four steps takes the bounds on the ATE to \[-2,
49\], 51 points wide. An email survey of country experts, 20 of whom
responded, supplies an independent set of imputations; deferring to the
experts where they answered narrows the bounds to 44 points. Appendix A
repeats the exercise for 54 end-of-conflict cases.

# Original archive reproducibility

| Script | Status on current R | Resolution |
|:---|:---|:---|
| quimpo_helpers.R | Clean (sourced by the analysis scripts) | %\>% to \|\>, map_df() to map() + bind_rows() |
| table_3_figure_1.R | Runs; deprecation warning | size= to linewidth= |
| table_4.R | Runs clean | Multiply the bounds by 100 to print percentage points, as the paper does |
| table_5.R | Runs clean | recode_factor() to case_when() + factor() |
| figures_2_3_A1_A2.R | Runs; three deprecation warnings; unseeded simulation | melt/dcast to pivot_longer/pivot_wider; geom_errorbarh() to geom_errorbar(orientation=‘y’); %+% to a named plot function; do() to reframe(); set.seed(12345) |
| figure_4.R | Runs; deprecation warning and a melt() id-variable warning | melt to pivot_longer with an explicit names_to; size= to linewidth= |

Original archive reproducibility, checked against R 4.6.0 on 1 August
2026.

## The unseeded simulation

The probabilistic extension is what makes Figures 2, 3, A1 and A2
stochastic. Where the authors hold a probability rather than a point
belief about a missing potential outcome, `sample_bounds()` draws binary
potential outcomes from those probabilities and recomputes the bounds,
and the reported estimate is the mean over draws. That is a design
decision the paper explains and the rewrite keeps. What the archive
omits is `set.seed()`, so the figures are one unlabelled draw.

| Rounded labels moved | Seeds |
|---------------------:|------:|
|                    0 |    11 |
|                    1 |     6 |
|                    2 |     3 |

Repeating the Figure 2 and A1 simulation at twenty seeds. Of the 28
rounded labels those two figures carry, the number that move off the
value the rewrite commits, which is also the value the published figures
carry.

The size of the disturbance is one percentage point in the rounded
label, never more, and it never touches the substantive claims: the
final bounds are \[-2, 49\] at every seed tested. The point is not that
the archive gets a different answer but that it gets a slightly
different figure each time it is run, and it offers a reader no way to
tell whether a discrepancy is noise or a mistake.

## Checksums

| File                     |  Bytes | MD5 served (first 12) | Published MD5 agrees |
|:-------------------------|-------:|:----------------------|:---------------------|
| cases_clean.csv          |  21433 | 0a238c073307          | yes                  |
| codebook_cases_clean.pdf | 348561 | 87154446febf          | yes                  |
| figure_4.R               |   4282 | d62dbb3dc25a          | yes                  |
| figures_2_3_A1_A2.R      |   5859 | b06b1c39bfba          | yes                  |
| logfile.html             | 278521 | 831c13a4b09c          | yes                  |
| quimpo_helpers.R         |   1517 | 876ec89e03d6          | yes                  |
| README.txt               |   1712 | 634560b77b47          | yes                  |
| table_3_figure_1.R       |   3456 | e8fb68e7b478          | yes                  |
| table_4.R                |   2220 | 237c27908efb          | yes                  |
| table_5.R                |   1184 | fd0efb3ad0e6          | yes                  |

The deposit as Dataverse serves it with ?format=original. All ten files
match the checksums Dataverse publishes, and all ten match the copy this
program downloaded in March 2026.

Harvard Dataverse ingests `cases_clean.csv` as tabular data and derives
a `.tab` representation from it, so the manifest records
`originalFileName` and `originalFileSize` rather than the derived names
and sizes, and `download_original.R` asks for `?format=original`. The
published MD5 describes the deposited bytes, not the derived ones, and
here it verifies them exactly. Other deposits in this program carry
published checksums that verify neither file, so the download script
checks against the served checksum and reports any published
disagreement rather than failing on it.

# Errata

Nothing in the deposited code is wrong. Three claims in the article’s
prose are, each contradicted by a table or figure in the same article,
and the maintained rewrite therefore disagrees with the sentence and
agrees with the float.

**The toy example’s treated outcomes.** The text introducing the toy
example says “the outcome for three of the treated units and one of the
untreated units is 1”. Table 3 on the facing page shows units 1 through
4 treated with an observed outcome of 1, which is four, and the
deposited `Y <- rep(c(1, 0, 1, 0), c(4, 3, 1, 2))` encodes four. Four is
also what the bounds require: the initial bounds of \[-40, 60\] follow
from four treated ones and would be \[-50, 50\] with three.

**The probabilistic extension’s probabilities.** The text says that
instead of imputing 0 for units 6 and 7, “we think the probabilities of
being a ‘1’ for units 6 and 7 are .3 and .4”. Table 4 gives the four
scenario probabilities as 0.56, 0.14, 0.24 and 0.06, which is the
product distribution of 0.2 and 0.3, not of 0.3 and 0.4, which would
give 0.42, 0.18, 0.28 and 0.12. The deposited `table_4.R` uses 0.2 and
0.3 and reproduces Table 4 exactly, as does the rewrite.

**Appendix A’s bounds width.** Appendix A says the imputations shrink
“the width of the extreme value bounds from 100 to 41 points” and then,
in the next sentence, that “the bounds come to \[-3, 42\] (only 45
points wide)”. Both cannot hold. The pipeline gives final
end-of-conflict bounds of \[-2.9, 41.5\], a width of 44.4 points, which
rounds to 44 and which is 45 if taken as the difference of the rounded
endpoints, as the second sentence does. The 41 matches nothing.

None of the three changes a substantive conclusion, and no ground truth
row is marked `match_rewrite = 0` for a reason other than these.

# Number-by-number comparison

| Location | Quantity | Paper | Archive | Rewrite | Match | Match (rw) |
|:---|:---|:---|:---|:---|:---|:---|
| table_3 | column d | 1,1,1,1,1,1,1,0,0,0 | 1,1,1,1,1,1,1,0,0,0 | 1,1,1,1,1,1,1,0,0,0 | 1 | 1 |
| table_3 | column Y | 1,1,1,1,0,0,0,1,0,0 | 1,1,1,1,0,0,0,1,0,0 | 1,1,1,1,0,0,0,1,0,0 | 1 | 1 |
| table_3 | column Y0_initial | ?,?,?,?,?,?,?,1,0,0 | ?,?,?,?,?,?,?,1,0,0 | ?,?,?,?,?,?,?,1,0,0 | 1 | 1 |
| table_3 | column Y1_initial | 1,1,1,1,0,0,0,?,?,? | 1,1,1,1,0,0,0,?,?,? | 1,1,1,1,0,0,0,?,?,? | 1 | 1 |
| table_3 | column Y0_easy | 1,1,?,?,0,?,?,1,0,0 | 1,1,?,?,0,?,?,1,0,0 | 1,1,?,?,0,?,?,1,0,0 | 1 | 1 |
| table_3 | column Y1_easy | 1,1,1,1,0,0,0,1,0,? | 1,1,1,1,0,0,0,1,0,? | 1,1,1,1,0,0,0,1,0,? | 1 | 1 |
| table_3 | column Y0_nulls | 1,1,?,?,0,0,0,1,0,0 | 1,1,?,?,0,0,0,1,0,0 | 1,1,?,?,0,0,0,1,0,0 | 1 | 1 |
| table_3 | column Y1_nulls | 1,1,1,1,0,0,0,1,0,? | 1,1,1,1,0,0,0,1,0,? | 1,1,1,1,0,0,0,1,0,? | 1 | 1 |
| table_3 | column Y0_hard | 1,1,0,0,0,0,0,1,0,0 | 1,1,0,0,0,0,0,1,0,0 | 1,1,0,0,0,0,0,1,0,0 | 1 | 1 |
| table_3 | column Y1_hard | 1,1,1,1,0,0,0,1,0,? | 1,1,1,1,0,0,0,1,0,? | 1,1,1,1,0,0,0,1,0,? | 1 | 1 |
| table_3 | EV bounds low, Initial Values | -40 | -40 | -40 | 1 | 1 |
| table_3 | EV bounds high, Initial Values | 60 | 60 | 60 | 1 | 1 |
| table_3 | EV bounds low, Easy Cases | -20 | -20 | -20 | 1 | 1 |
| table_3 | EV bounds high, Easy Cases | 30 | 30 | 30 | 1 | 1 |
| table_3 | EV bounds low, Nulls for 6&7 | 0 | 0 | 0 | 1 | 1 |
| table_3 | EV bounds high, Nulls for 6&7 | 30 | 30 | 30 | 1 | 1 |
| table_3 | EV bounds low, Hard Cases | 20 | 20 | 20 | 1 | 1 |
| table_3 | EV bounds high, Hard Cases | 30 | 30 | 30 | 1 | 1 |
| figure_1 | low bound, Before Any Data | -100 | -100 | -100 | 1 | 1 |
| figure_1 | high bound, Before Any Data | 100 | 100 | 100 | 1 | 1 |
| figure_1 | low bound, Initial Values | -40 | -40 | -40 | 1 | 1 |
| figure_1 | high bound, Initial Values | 60 | 60 | 60 | 1 | 1 |
| figure_1 | low bound, Easy Cases | -20 | -20 | -20 | 1 | 1 |
| figure_1 | high bound, Easy Cases | 30 | 30 | 30 | 1 | 1 |
| figure_1 | low bound, Nulls for 6&7 | 0 | 0 | 0 | 1 | 1 |
| figure_1 | high bound, Nulls for 6&7 | 30 | 30 | 30 | 1 | 1 |
| figure_1 | low bound, Hard Cases | 20 | 20 | 20 | 1 | 1 |
| figure_1 | high bound, Hard Cases | 30 | 30 | 30 | 1 | 1 |
| table_4 | EV bounds low, unit 6 = 0, unit 7 = 0 | 0 | 0 | 0 | 1 | 1 |
| table_4 | EV bounds high, unit 6 = 0, unit 7 = 0 | 30 | 30 | 30 | 1 | 1 |
| table_4 | probability, unit 6 = 0, unit 7 = 0 | 0.56 | 0.56 | 0.56 | 1 | 1 |
| table_4 | EV bounds low, unit 6 = 1, unit 7 = 0 | -10 | -10 | -10 | 1 | 1 |
| table_4 | EV bounds high, unit 6 = 1, unit 7 = 0 | 20 | 20 | 20 | 1 | 1 |
| table_4 | probability, unit 6 = 1, unit 7 = 0 | 0.14 | 0.14 | 0.14 | 1 | 1 |
| table_4 | EV bounds low, unit 6 = 0, unit 7 = 1 | -10 | -10 | -10 | 1 | 1 |
| table_4 | EV bounds high, unit 6 = 0, unit 7 = 1 | 20 | 20 | 20 | 1 | 1 |
| table_4 | probability, unit 6 = 0, unit 7 = 1 | 0.24 | 0.24 | 0.24 | 1 | 1 |
| table_4 | EV bounds low, unit 6 = 1, unit 7 = 1 | -20 | -20 | -20 | 1 | 1 |
| table_4 | EV bounds high, unit 6 = 1, unit 7 = 1 | 10 | 10 | 10 | 1 | 1 |
| table_4 | probability, unit 6 = 1, unit 7 = 1 | 0.06 | 0.06 | 0.06 | 1 | 1 |
| table_4 | probability-weighted point estimate, lower bound | -5 |  | -5 |  | 1 |
| table_4 | probability-weighted point estimate, upper bound | 25 |  | 25 |  | 1 |
| table_4 | 2.5th quantile of the lower bound | -20 |  | -20 |  | 1 |
| table_4 | 97.5th quantile of the lower bound | 0 |  | 0 |  | 1 |
| table_4 | 2.5th quantile of the upper bound | 10 |  | 10 |  | 1 |
| table_4 | 97.5th quantile of the upper bound | 30 |  | 30 |  | 1 |
| table_4 | probability that unit 6 has Y0 = 1 | 0.3 | 0.2 | 0.2 | 0 | 0 |
| table_4 | probability that unit 7 has Y0 = 1 | 0.4 | 0.3 | 0.3 | 0 | 0 |
| table_5 | democratization, Negative Effect | 2% (1) | 2% (1) | 2% (1) | 1 | 1 |
| table_5 | end of conflict, Negative Effect |  | 0% (0) | 0% (0) |  |  |
| table_5 | democratization, No Effect | 40% (25) | 40% (25) | 40% (25) | 1 | 1 |
| table_5 | end of conflict, No Effect |  | 43% (23) | 43% (23) |  |  |
| table_5 | democratization, Positive Effect | 8% (5) | 8% (5) | 8% (5) | 1 | 1 |
| table_5 | end of conflict, Positive Effect |  | 13% (7) | 13% (7) |  |  |
| table_5 | democratization, Unimputed | 51% (32) | 51% (32) | 51% (32) | 1 | 1 |
| table_5 | end of conflict, Unimputed |  | 44% (24) | 44% (24) |  |  |
| figure_2 | low bound, Before Any Data | -100 | -100 | -100 | 1 | 1 |
| figure_2 | high bound, Before Any Data | 100 | 100 | 100 | 1 | 1 |
| figure_2 | low bound, Initial Values | -25 | -25 | -25 | 1 | 1 |
| figure_2 | high bound, Initial Values | 75 | 75 | 75 | 1 | 1 |
| figure_2 | low bound, Disbanded and Discredited Cases | -25 | -25 | -25 | 1 | 1 |
| figure_2 | high bound, Disbanded and Discredited Cases | 72 | 72 | 72 | 1 | 1 |
| figure_2 | low bound, Treated Cases | -16 | -16 | -16 | 1 | 1 |
| figure_2 | high bound, Treated Cases | 68 | 68 | 68 | 1 | 1 |
| figure_2 | low bound, Non-transitional Cases | -12 | -12 | -12 | 1 | 1 |
| figure_2 | high bound, Non-transitional Cases | 62 | 62 | 62 | 1 | 1 |
| figure_2 | low bound, Untreated Cases | -2 | -2 | -2 | 1 | 1 |
| figure_2 | high bound, Untreated Cases | 49 | 49 | 49 | 1 | 1 |
| figure_2 | low bound, Unimputable Cases | -2 | -2 | -2 | 1 | 1 |
| figure_2 | high bound, Unimputable Cases | 49 | 49 | 49 | 1 | 1 |
| figure_a1 | low bound, Before Any Data | -100 | -100 | -100 | 1 | 1 |
| figure_a1 | high bound, Before Any Data | 100 | 100 | 100 | 1 | 1 |
| figure_a1 | low bound, Initial Values | -33 | -33 | -33 | 1 | 1 |
| figure_a1 | high bound, Initial Values | 67 | 67 | 67 | 1 | 1 |
| figure_a1 | low bound, Disbanded and Discredited Cases | -32 | -32 | -32 | 1 | 1 |
| figure_a1 | high bound, Disbanded and Discredited Cases | 61 | 61 | 61 | 1 | 1 |
| figure_a1 | low bound, Treated Cases | -26 | -26 | -26 | 1 | 1 |
| figure_a1 | high bound, Treated Cases | 56 | 56 | 56 | 1 | 1 |
| figure_a1 | low bound, Non-transitional Cases | -24 | -24 | -24 | 1 | 1 |
| figure_a1 | high bound, Non-transitional Cases | 54 | 54 | 54 | 1 | 1 |
| figure_a1 | low bound, Untreated Cases | -3 | -3 | -3 | 1 | 1 |
| figure_a1 | high bound, Untreated Cases | 42 | 42 | 42 | 1 | 1 |
| figure_a1 | low bound, Unimputable Cases | -3 | -3 | -3 | 1 | 1 |
| figure_a1 | high bound, Unimputable Cases | 42 | 42 | 42 | 1 | 1 |
| figure_3 | low bound, ATU, Before Any Data | -100 | -100 | -100 | 1 | 1 |
| figure_3 | high bound, ATU, Before Any Data | 100 | 100 | 100 | 1 | 1 |
| figure_3 | low bound, ATU, Initial Values | -16 | -16 | -16 | 1 | 1 |
| figure_3 | high bound, ATU, Initial Values | 84 | 84 | 84 | 1 | 1 |
| figure_3 | low bound, ATU, Disbanded and Discredited Cases | -16 | -16 | -16 | 1 | 1 |
| figure_3 | high bound, ATU, Disbanded and Discredited Cases | 80 | 80 | 80 | 1 | 1 |
| figure_3 | low bound, ATU, Treated Cases | -16 | -16 | -16 | 1 | 1 |
| figure_3 | high bound, ATU, Treated Cases | 80 | 80 | 80 | 1 | 1 |
| figure_3 | low bound, ATU, Non-transitional Cases | -12 | -12 | -12 | 1 | 1 |
| figure_3 | high bound, ATU, Non-transitional Cases | 74 | 74 | 74 | 1 | 1 |
| figure_3 | low bound, ATU, Untreated Cases | 0 | 0 | 0 | 1 | 1 |
| figure_3 | high bound, ATU, Untreated Cases | 58 | 58 | 58 | 1 | 1 |
| figure_3 | low bound, ATU, Unimputable Cases | 0 | 0 | 0 | 1 | 1 |
| figure_3 | high bound, ATU, Unimputable Cases | 58 | 58 | 58 | 1 | 1 |
| figure_3 | low bound, ATT, Before Any Data | -100 | -100 | -100 | 1 | 1 |
| figure_3 | high bound, ATT, Before Any Data | 100 | 100 | 100 | 1 | 1 |
| figure_3 | low bound, ATT, Initial Values | -88 | -88 | -88 | 1 | 1 |
| figure_3 | high bound, ATT, Initial Values | 12 | 12 | 12 | 1 | 1 |
| figure_3 | low bound, ATT, Disbanded and Discredited Cases | -88 | -88 | -88 | 1 | 1 |
| figure_3 | high bound, ATT, Disbanded and Discredited Cases | 12 | 12 | 12 | 1 | 1 |
| figure_3 | low bound, ATT, Treated Cases | -15 | -15 | -15 | 1 | 1 |
| figure_3 | high bound, ATT, Treated Cases | -15 | -15 | -15 | 1 | 1 |
| figure_3 | low bound, ATT, Non-transitional Cases | -15 | -15 | -15 | 1 | 1 |
| figure_3 | high bound, ATT, Non-transitional Cases | -15 | -15 | -15 | 1 | 1 |
| figure_3 | low bound, ATT, Untreated Cases | -15 | -15 | -15 | 1 | 1 |
| figure_3 | high bound, ATT, Untreated Cases | -15 | -15 | -15 | 1 | 1 |
| figure_3 | low bound, ATT, Unimputable Cases | -15 | -15 | -15 | 1 | 1 |
| figure_3 | high bound, ATT, Unimputable Cases | -15 | -15 | -15 | 1 | 1 |
| figure_a2 | low bound, ATU, Before Any Data | -100 | -100 | -100 | 1 | 1 |
| figure_a2 | high bound, ATU, Before Any Data | 100 | 100 | 100 | 1 | 1 |
| figure_a2 | low bound, ATU, Initial Values | -29 | -29 | -29 | 1 | 1 |
| figure_a2 | high bound, ATU, Initial Values | 71 | 71 | 71 | 1 | 1 |
| figure_a2 | low bound, ATU, Disbanded and Discredited Cases | -27 | -27 | -27 | 1 | 1 |
| figure_a2 | high bound, ATU, Disbanded and Discredited Cases | 64 | 64 | 64 | 1 | 1 |
| figure_a2 | low bound, ATU, Treated Cases | -27 | -27 | -27 | 1 | 1 |
| figure_a2 | high bound, ATU, Treated Cases | 64 | 64 | 64 | 1 | 1 |
| figure_a2 | low bound, ATU, Non-transitional Cases | -26 | -26 | -26 | 1 | 1 |
| figure_a2 | high bound, ATU, Non-transitional Cases | 62 | 62 | 62 | 1 | 1 |
| figure_a2 | low bound, ATU, Untreated Cases | -2 | -2 | -2 | 1 | 1 |
| figure_a2 | high bound, ATU, Untreated Cases | 48 | 48 | 48 | 1 | 1 |
| figure_a2 | low bound, ATU, Unimputable Cases | -2 | -2 | -2 | 1 | 1 |
| figure_a2 | high bound, ATU, Unimputable Cases | 48 | 48 | 48 | 1 | 1 |
| figure_a2 | low bound, ATT, Before Any Data | -100 | -100 | -100 | 1 | 1 |
| figure_a2 | high bound, ATT, Before Any Data | 100 | 100 | 100 | 1 | 1 |
| figure_a2 | low bound, ATT, Initial Values | -67 | -67 | -67 | 1 | 1 |
| figure_a2 | high bound, ATT, Initial Values | 33 | 33 | 33 | 1 | 1 |
| figure_a2 | low bound, ATT, Disbanded and Discredited Cases | -67 | -67 | -67 | 1 | 1 |
| figure_a2 | high bound, ATT, Disbanded and Discredited Cases | 33 | 33 | 33 | 1 | 1 |
| figure_a2 | low bound, ATT, Treated Cases | -10 | -10 | -10 | 1 | 1 |
| figure_a2 | high bound, ATT, Treated Cases | -10 | -10 | -10 | 1 | 1 |
| figure_a2 | low bound, ATT, Non-transitional Cases | -10 | -10 | -10 | 1 | 1 |
| figure_a2 | high bound, ATT, Non-transitional Cases | -10 | -10 | -10 | 1 | 1 |
| figure_a2 | low bound, ATT, Untreated Cases | -10 | -10 | -10 | 1 | 1 |
| figure_a2 | high bound, ATT, Untreated Cases | -10 | -10 | -10 | 1 | 1 |
| figure_a2 | low bound, ATT, Unimputable Cases | -10 | -10 | -10 | 1 | 1 |
| figure_a2 | high bound, ATT, Unimputable Cases | -10 | -10 | -10 | 1 | 1 |
| figure_4 | low bound, us, The 20 Cases with Expert Responses | -10 | -10 | -10 | 1 | 1 |
| figure_4 | high bound, us, The 20 Cases with Expert Responses | 40 | 40 | 40 | 1 | 1 |
| figure_4 | low bound, expert, The 20 Cases with Expert Responses | -15 | -15 | -15 | 1 | 1 |
| figure_4 | high bound, expert, The 20 Cases with Expert Responses | 15 | 15 | 15 | 1 | 1 |
| figure_4 | low bound, us, All 63 Democratization Cases | -2 | -2 | -2 | 1 | 1 |
| figure_4 | high bound, us, All 63 Democratization Cases | 49 | 49 | 49 | 1 | 1 |
| figure_4 | low bound, expert, All 63 Democratization Cases | -19 | -19 | -19 | 1 | 1 |
| figure_4 | high bound, expert, All 63 Democratization Cases | 59 | 59 | 59 | 1 | 1 |
| figure_4 | low bound, combined, All 63 Democratization Cases | -3 | -3 | -3 | 1 | 1 |
| figure_4 | high bound, combined, All 63 Democratization Cases | 41 | 41 | 41 | 1 | 1 |
| abstract | bounds width prior to any analysis | 100 | 100 | 100 | 1 | 1 |
| abstract | bounds width after imputation | 51 | 51 | 51 | 1 | 1 |
| abstract | bounds width after the expert survey | 44 | 44 | 44 | 1 | 1 |
| text | democratization cases | 63 | 63 | 63 | 1 | 1 |
| text | treated democratization cases | 8 | 8 | 8 | 1 | 1 |
| text | bounds width before any data are collected | 200 | 200 | 200 | 1 | 1 |
| text | bounds width once half the potential outcomes are revealed | 100 | 100 | 100 | 1 | 1 |
| text | final ATE lower bound | -2 | -2 | -2 | 1 | 1 |
| text | final ATE upper bound | 49 | 49 | 49 | 1 | 1 |
| text | final ATE bounds width | 51 | 51 | 51 | 1 | 1 |
| text | toy example: treated units with outcome 1 | 3 | 4 | 4 | 0 | 0 |
| text | toy example: untreated units with outcome 1 | 1 | 1 | 1 | 1 | 1 |
| text | toy example: bounds width before any data | 200 | 200 | 200 | 1 | 1 |
| text | toy example: final bounds width | 10 | 10 | 10 | 1 | 1 |
| text | ATU final bounds width | 58 | 58 | 58 | 1 | 1 |
| text | ATT summarised as a point effect | -15 | -15 | -15 | 1 | 1 |
| text | cases imputed as a non-zero causal effect | 6 | 6 | 6 | 1 | 1 |
| text | expert responses received | 20 | 20 | 20 | 1 | 1 |
| text | democratization cases without an expert response | 43 | 43 | 43 | 1 | 1 |
| text | our bounds width, 20 responding cases | 50 | 50 | 50 | 1 | 1 |
| text | expert bounds width, 20 responding cases | 30 | 30 | 30 | 1 | 1 |
| text | our bounds width, all 63 cases | 51 | 51 | 51 | 1 | 1 |
| text | expert bounds width, all 63 cases | 78 | 78 | 78 | 1 | 1 |
| text | combined bounds width, all 63 cases | 44 | 44 | 44 | 1 | 1 |
| text | expert and author imputations agreed | 7 | 7 | 7 | 1 | 1 |
| text | expert and author imputations conflicted | 3 | 3 | 3 | 1 | 1 |
| text | we imputed, the experts did not | 3 | 3 | 3 | 1 | 1 |
| text | the experts imputed, we did not | 7 | 7 | 7 | 1 | 1 |
| text | cases the experts imputed | 14 | 14 | 14 | 1 | 1 |
| text | cases we imputed | 10 | 10 | 10 | 1 | 1 |
| text | experts who declined to impute | 6 | 6 | 6 | 1 | 1 |
| text | declining experts assigned to an untreated case | 6 | 6 | 6 | 1 | 1 |
| text | expert imputations differing from the observed outcome | 0 | 0 | 0 | 1 | 1 |
| appendix_a | end-of-conflict cases | 54 | 54 | 54 | 1 | 1 |
| appendix_a | treated end-of-conflict cases | 6 | 6 | 6 | 1 | 1 |
| appendix_a | bounds width once half the potential outcomes are revealed | 100 | 100 | 100 | 1 | 1 |
| appendix_a | bounds width after imputation | 41 | 44 | 44 | 0 | 0 |
| appendix_a | final ATE lower bound | -3 | -3 | -3 | 1 | 1 |
| appendix_a | final ATE upper bound | 42 | 42 | 42 | 1 | 1 |
| appendix_a | final ATE bounds width from the rounded endpoints | 45 | 45 | 45 | 1 | 1 |
| appendix_a | ATT summarised as a point effect | -10 | -10 | -10 | 1 | 1 |

Ground truth: the published value against the deposited script and
against the maintained rewrite. A blank Paper column means the quantity
is not stated in the article or its appendix; a blank Archive column
means no deposited script prints it.

Of the 191 recorded claims, 181 can be compared against both the article
and a deposited script, and 177 of those match. Six further claims are
stated in the article but computed by no deposited script: the
probability-weighted point estimate of the bounds in the probabilistic
extension, \[-5, 25\], and the 2.5th and 97.5th quantiles of each bound,
\[-20, 0\] and \[10, 30\]. The rewrite computes all six from the
enumerated scenarios in `table_4_probabilistic.R` and all six match.

# Maintained rewrite

The rewrite lives in `maintained/`: a helpers file, one cleaning script,
three table scripts, four figure scripts and three in-text scripts. It
is a translation, not a reanalysis. `ev_bounds()`, `bounds_width()`,
`sample_bounds()` and the probabilistic-extension functions are the
paper’s contribution and are carried over with their logic unchanged;
what changes is the tidyverse around them.

## Architecture

| Script | Output |
|:---|:---|
| helpers.R | none; packages, the QUIMPO functions and the toy example |
| clean_cases.R | cases_long.rds |
| table_3_toy_example.R | table_3_toy_example.csv, table_3_bounds.csv |
| table_4_probabilistic.R | table_4_probabilistic.csv, table_4_summary.csv |
| table_5_imputation_summary.R | table_5_imputation_summary.csv |
| figure_1_toy_bounds.R | figure_1_toy_bounds.pdf/.png/.csv |
| figures_2_a1_ate_bounds.R | figure_2_dem_ate_bounds.pdf/.png, figure_a1_eoc_ate_bounds.pdf/.png, figures_2_a1_gg_df.csv |
| figures_3_a2_att_atu_bounds.R | figure_3_dem_att_atu_bounds.pdf/.png, figure_a2_eoc_att_atu_bounds.pdf/.png, figures_3_a2_gg_df.csv |
| figure_4_expert_validation.R | figure_4_expert_validation.pdf/.png/.csv |
| text_expert_agreement.R | text_expert_agreement.csv, text_expert_agreement_counts.csv |
| text_summary_stats.R | text_summary_stats.csv |
| text_seed_sensitivity.R | text_seed_sensitivity.csv |

The maintained rewrite.

Three departures from a line-by-line translation are worth naming.

The toy example is defined once, in `quimpo_toy_example()` in
`helpers.R`, rather than retyped in each of the three scripts that need
it. In the archive, `table_3_figure_1.R` and `table_4.R` each set up the
ten units and walk them through the imputation steps independently,
which is the arrangement in which Table 3, Figure 1 and Table 4 can
silently come to describe different examples.

Figures 2 and A1 come from one script and Figures 3 and A2 from another,
because in each pair the two figures are two facets of a single
simulation and splitting them would mean running it twice at the same
seed. The archive’s `figures_2_3_A1_A2.R` puts all four in one file; the
rewrite splits along the simulation boundary rather than the file
boundary.

`text_summary_stats.R` reads the bounds back out of the figure output
rather than recomputing them, so the widths quoted in the abstract and
the body cannot drift from the figures they summarise. Every number it
prints is traceable to a committed CSV, and no published value is typed
into any script in `maintained/`.

## Deprecated patterns replaced

| Original pattern | Replacement |
|:---|:---|
| `rm(list = ls())` | (omitted) |
| commented-out `setwd()` | `here::here()` |
| magrittr pipe | native pipe |
| `reshape2::melt()` / `dcast()` | `pivot_longer()` / `pivot_wider()` |
| `do(sample_bounds(...))` | `reframe(sample_bounds(...))` |
| `map_df(enframe, .id = )` | `map(enframe) &#124;> bind_rows(.id = )` |
| `geom_errorbarh(height = )` | `geom_errorbar(orientation = "y", width = )` |
| `geom_linerange(size = )` | `geom_linerange(linewidth = )` |
| `<ggplot> %+% data` | a named plot function taking the data as an argument |
| `separate()` | `separate_wider_delim()` |
| `recode_factor()` | `case_when()` + `factor()` |
| `xtable` + `print.xtable` (commented out) | `write_csv()` to `output/` |
| `ggsave()` (commented out) | `ggsave()` to `output/`, PDF and PNG |
| unseeded `rbinom()` simulation | `set.seed(12345)` |
| bounds printed as fractions in `table_4.R` | multiplied by 100, as the paper prints them |

Deprecated patterns and their replacements in the maintained rewrite.

# Figures

<img src="maintained/output/figure_1_toy_bounds.png"
style="width:100.0%"
alt="Figure 1: extreme value bounds at each step of the toy example." />

<img src="maintained/output/figure_2_dem_ate_bounds.png"
style="width:100.0%"
alt="Figure 2: transitional truth commissions, extreme value bounds on the ATE." />

<img src="maintained/output/figure_3_dem_att_atu_bounds.png"
style="width:100.0%"
alt="Figure 3: extreme value bounds by treatment status." />

<img src="maintained/output/figure_4_expert_validation.png"
style="width:100.0%"
alt="Figure 4: extreme value bounds implied by the expert imputations." />

<img src="maintained/output/figure_a1_eoc_ate_bounds.png"
style="width:100.0%"
alt="Figure A1: end-of-conflict cases, extreme value bounds on the ATE." />

<img src="maintained/output/figure_a2_eoc_att_atu_bounds.png"
style="width:100.0%"
alt="Figure A2: end-of-conflict cases, extreme value bounds by treatment status." />

# Expert survey verification

The Expert Survey section carries eleven quantities that no deposited
script writes to disk, three of them recorded only in a code comment in
`figure_4.R`. `text_expert_agreement.R` recomputes all of them from the
deposited case data.

| Quantity                                               | Rewrite | Paper |
|:-------------------------------------------------------|--------:|------:|
| agreement                                              |       7 |     7 |
| disagreement                                           |       3 |     3 |
| They declined, we imputed                              |       3 |     3 |
| They imputed, we declined                              |       7 |     7 |
| expert responses received                              |      20 |    20 |
| democratization cases without an expert response       |      43 |    43 |
| cases the experts imputed                              |      14 |    14 |
| cases we imputed                                       |      10 |    10 |
| experts who declined to impute                         |       6 |     6 |
| declining experts assigned to an untreated case        |       6 |     6 |
| expert imputations differing from the observed outcome |       0 |     0 |

The Expert Survey section, recomputed. Agreement means the two sides
made the same imputation or both declined; the last row checks the claim
that all 20 respondents either declined or imputed the observed outcome.

The archive’s `figure_4.R` computes the agreement coding and prints it
with `table()`, then records the answer in three comment lines:
“uruguay, burundi, south africa are ‘disagreements’”, “7 cases, they
imputed when we did not”, “3 cases, we imputed and they did not”. All
three are correct. They are also the only place the numbers exist, which
is the pattern this program treats as a defect regardless of whether the
comment is right: a comment is not an output, and nothing checks it.

# In-text quantities

| Quantity | Rewrite | Rounded |
|:---|:---|---:|
| dem: bounds width before any data | 200.00 | 200 |
| dem: bounds width once the world reveals half the potential outcomes | 100.00 | 100 |
| dem: final ATE lower bound | -2.14 | -2 |
| dem: final ATE upper bound | 48.66 | 49 |
| dem: final ATE bounds width | 50.79 | 51 |
| dem: ATU final bounds width | 58.18 | 58 |
| dem: ATT final lower bound | -15.05 | -15 |
| dem: ATT final upper bound | -15.05 | -15 |
| expert: our bounds width, 20 responding cases | 50.00 | 50 |
| expert: expert bounds width, 20 responding cases | 30.00 | 30 |
| expert: our bounds width, all 63 cases | 50.79 | 51 |
| expert: expert bounds width, all 63 cases | 77.78 | 78 |
| expert: combined bounds width, all 63 cases | 44.44 | 44 |
| dem: cases imputed as a non-zero causal effect | 6.00 | 6 |
| eoc: bounds width once the world reveals half the potential outcomes | 100.00 | 100 |
| eoc: final ATE lower bound | -2.91 | -3 |
| eoc: final ATE upper bound | 41.53 | 42 |
| eoc: final ATE bounds width | 44.44 | 44 |
| eoc: ATT final lower bound | -10.14 | -10 |
| eoc: ATT final upper bound | -10.14 | -10 |

Bounds widths and summary effects quoted in the abstract, the body and
Appendix A, read back out of the figure output that produced them.

The abstract and the body describe the same starting point in two ways,
and both are right. The body says the bounds are 200 points wide “before
any data are collected” and shrink to 100 “after the world reveals half
the potential outcomes”. The abstract skips the first of those and says
the bounds are 100 points wide “prior to any analysis”, meaning after
data collection and before imputation. Both numbers are in the pipeline
and both reproduce.

# R environment

| Package    | Version |
|:-----------|:--------|
| tidyverse  | 2.0.0   |
| here       | 1.0.2   |
| janitor    | 2.2.1   |
| knitr      | 1.51    |
| kableExtra | 1.4.0   |
| ggplot2    | 4.0.3   |
| dplyr      | 1.2.1   |
| tidyr      | 1.3.2   |

Package versions used for this report.

R version: R version 4.6.0 (2026-04-24). The archive was written against
R 4.1.2.
