# PURPOSE: model fitting code for "A Matched Study Design to Estimate the
# Effect of Furosemide in Horse Racing"

# Prepare environment -----------------------------------------------------

library(survival)
library(lme4)
library(dplyr)
library(here)
library(ggplot2)
library(brms)

set.seed(2026)

source(here('data', 'data-loaders', 'load_data.R'))

# two-year-olds matched on track, distance, surface
data_clean <- load_data(match_vars = c('registration_number',
                                       'track_id',
                                       'distance_id',
                                       'surface'))

# Fit Models --------------------------------------------------------------

### Section 3.2.1: Conditional Logistic Regression

clogit_fit <- clogit(in_the_money ~ med_description +
                       post_position +
                       splines::ns(odds, df = 4) + frac_lasix +
                       total_other_horses +
                       strata(registration_number),
                     data = data_clean)

saveRDS(clogit_fit,  here('data', 'models', 'clogit_fit.rds'))

### Section 3.2.2: BHLR

# apples to apples - ie this is the same type of model as the conditional
# logistic regression - just Bayesian.
brms_fit_apples <- brm(in_the_money ~ med_description +
                         (1 | registration_number) +
                         splines::ns(odds, df = 4) +
                         post_position +
                         frac_lasix +
                         total_other_horses,
                       data = data_clean,
                       adapt_delta = .95,
                       iter = getOption("brms.iter", 8000),
                       family = bernoulli(),
                       cores = 4,
                       backend = "cmdstanr")

saveRDS(brms_fit_apples, here('data', 'models', 'brms_fit_apples.rds'))

### Section A.1: BHLR with more random effects

# This is the code for fitting the random slope for the furosemide effect. This
# model is briefly  described in A.1, as a way to test the assumption that
# furosemide may impact different horses differently. Results for this model are
# not shown in the paper, as the model provided low support for the random
# slope structure.
brms_fit_rs <- brm(in_the_money ~ med_description +
                     (med_description | registration_number) +
                     (1 | track_id/post_position) +
                     (1 | jockey_id) +
                     splines::ns(odds, df = 4) +
                     frac_lasix +
                     total_other_horses,
                   data = data_clean,
                   adapt_delta = .95,
                   iter = getOption("brms.iter", 8000),
                   family = bernoulli(),
                   cores = 4,
                   backend = "cmdstanr")

saveRDS(brms_fit_rs, here('data', 'models', 'brms_fit_rs.rds'))

# The model with nested track-post effects and jockey effects described in
# section A.1 and specified by equation (A.1).
brms_fit <- brm(in_the_money ~ med_description +
                  (1 | registration_number) +
                  (1 | track_id/post_position) +
                  (1 | jockey_id) +
                  splines::ns(odds, df = 4) +
                  frac_lasix +
                  total_other_horses,
                data = data_clean,
                adapt_delta = .95,
                iter = getOption("brms.iter", 8000),
                family = bernoulli(),
                cores = 4,
                backend = "cmdstanr")

saveRDS(brms_fit, here('data', 'models', 'brms_fit.rds'))

# Extract BHLR Model Preds -------------------------------------------------

# read models back in if necessary
brms_fit <- readRDS(here('data', 'models', 'brms_fit.rds'))
brms_fit_rs <- readRDS(here('data', 'models', 'brms_fit_rs.rds'))
brms_fit_apples <- readRDS(here('data', 'models', 'brms_fit_apples.rds'))

# takes a while to predict, so do it here and load predictions back in for 
# figures in docs/figures/figures.qmd

data_pred <- predict(brms_fit)
saveRDS(data_pred, here('data', 'datasets', 'brms_preds.rds'))

data_pred_apples <- predict(brms_fit_apples)
saveRDS(data_pred_apples, here('data', 'datasets', 'brms_preds_apples.rds'))
