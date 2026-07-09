# PURPOSE: Bayesian hierarchical logistic regression model code

library(survival)
library(lme4)
library(dplyr)
library(here)
library(ggplot2)
library(brms)

set.seed(2026)

source(here('data', 'data-loaders', 'load_data.R'))

data_clean <- load_data(match_vars = c('registration_number',
                                       'track_id',
                                       'distance_id',
                                       'surface'))

data_clean_jockey <- load_data(match_vars = c('registration_number',
                                              'track_id',
                                              'distance_id',
                                              'surface',
                                              'jockey_id'))

# random slope lasix
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

# no jockey
brms_fit_nj <- brm(in_the_money ~ med_description +
                     # (1 | registration_number) +
                     (1 | registration_number) +
                     (1 | track_id/post_position) +
                     splines::ns(odds, df = 4) +
                     frac_lasix +
                     total_other_horses,
                   data = data_clean,
                   adapt_delta = .95,
                   iter = getOption("brms.iter", 8000),
                   family = bernoulli(),
                   cores = 4,
                   backend = "cmdstanr")

# case control matching
brms_fit_cc <- brm(in_the_money ~ med_description +
                     (1 | registration_number) +
                     (1 | track_id/post_position) +
                     (1 | jockey_id) +
                     splines::ns(odds, df = 4) +
                     frac_lasix +
                     total_other_horses,
                   data = test_data,
                   adapt_delta = .95,
                   iter = getOption("brms.iter", 8000),
                   family = bernoulli(),
                   cores = 4,
                   backend = "cmdstanr")

# apples to apples

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

# final mod
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
saveRDS(brms_fit_rs, here('data', 'models', 'brms_fit_rs.rds'))
saveRDS(brms_fit_cc, here('data', 'models', 'brms_fit_cc.rds'))
saveRDS(brms_fit_apples, here('data', 'models', 'brms_fit_apples.rds'))
brms_fit <- readRDS(here('data', 'models', 'brms_fit.rds'))
brms_fit_cc <- readRDS(here('data', 'models', 'brms_fit_cc.rds'))
brms_fit_apples <- readRDS(here('data', 'models', 'brms_fit_apples.rds'))

brms_data <- brms_fit$fit@sim$samples |>
  purrr::list_rbind(names_to = 'index') |>
  group_by(index) |>
  mutate(iter = 1:n())

brms_rs_data <- brms_fit_rs$fit@sim$samples |>
  purrr::list_rbind(names_to = 'index') |>
  group_by(index) |>
  mutate(iter = 1:n())

data_pred <- predict(brms_fit)
saveRDS(data_pred, here('data', 'datasets', 'brms_preds.rds'))

data_pred_apples <- predict(brms_fit_apples)
saveRDS(data_pred_apples, here('data', 'datasets', 'brms_preds_apples.rds'))

data_pred_rs <- predict(brms_fit_rs)
saveRDS(data_pred_rs, here('data', 'datasets', 'brms_preds_rs.rds'))
