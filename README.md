# Overview of manuscript repository

This repository contains the code for reproducing the results and figures in 
"A Matched Study Design to Estimate the Effect of Furosemide in Horse Racing".

The folders are organized in the following manner:

- [docs](https://github.com/m-sezgin/horseracing-furosemide-study-TAS/tree/main/docs) -
   files for fitting models and reproducing final figures displayed in the
   manuscript (including supplementary materials)
  + [figures](https://github.com/m-sezgin/horseracing-furosemide-study-TAS/tree/main/docs/figures) -
  folder containing quarto figure file, `figures-tables-all-sections.qmd`, and
  rendered pdf, `figures-tables-all-sections.pdf`.
  + [models](https://github.com/m-sezgin/horseracing-furosemide-study-TAS/tree/main/docs/models) - 
  folder containing model fitting script, `Sec-3.2-A.1-model-fitting.R`.
- [data](https://github.com/m-sezgin/horseracing-furosemide-study-TAS/tree/main/data) - where datasets and model data are stored and loaded from to produce figures and tables.
  + [data-loaders]() - contains data loader file `load_data.R` used to create matched sub-dataset.
  + [datasets]() - is assumed to contain raw dataset pulled from SQL server and cleaned by `load_data()`,
  `lnl_money.rds`, and is assumed to contain model predictions produced in
  `docs/models/Sec-3.2-A.1-model-fitting.R`: `brms_pred_apples.rds`,`brms_preds.rds`.
    NOTE: Though this folder and these objects are assumed to exist in scripts, they are not
    posted in this repository due to data sharing agreements.
  + [models]() - assumed to contain saved model objects from 
  `docs/models/Sec-3.2-A.1-model-fitting.R`: `clogit_fit.rds`, 
  `brms_fit_apples.rds`, `brms_fit_rs.rds`, and `brms_fit.rds`.
  NOTE: Though this folder and these objects are assumed to exist in scripts, they are not
  posted in this repository due to data sharing agreements.

We are unable to publicly post the matched dataset used in this analysis, but we provide
a description of the dataset and the data loader used to create our sub-dataset matched
across relevant characteristics, as outlined in section 2.1.

The original dataset (referenced as `lnl_money.rds`) contains the following relevant covariates
for horses of any age who have raced at least one time with furosemide and once without:

- `registration_id`: Unique horse identifier.
- `track_id`: Track name abbreviation.
- `race_date`: The date of the race.
- `day_evening`: Whether the race occurred in the morning or evening.
- `race_number`: The number of the race, unique to the track, date, and day/evening designation.
- `distance_id`: The distance of the race. Uniquely identifies race distance without
   having to include distance units.
- `distance_units`: The units of the race distance.
- `age_restriction`: The age restriction code for the race. '02' = only two-year-olds
   may compete.
- `surface`: Surface on which the race occured, dirt or turf.
- `med_description`: Whether a horse used furosemide, without any supplementary
  medications, or did not take any medications prior to the race.
- `lasix_ind`: Binary indicator of `med_decription` (1 = furosemide, 0 = no medication).
- `jockey_id`: Unique jockey identifier.
- `in_the_money`: Whether a horse finished "in the money", i.e. first, second, or third.

We then curate our matched dataset from `lnl_money.rds` using `load_data()`
in `data/data-loaders/load_data.R`.
Once the matched dataset is loaded, we fit all models referenced in the manuscript
in `docs/models/Sec-3.2-A.1-model-fitting.R`, saving them in `data/models/` and
the Bayesian model predictions in `data/datasets/`. We then
reload and manipulate the matched dataset, model objects, and model predictions
to produce our manuscript's figures and tables in 
`docs/figures/figures-tables-all-sections.qmd`.

## Contact

Michele Sezgin: [msezgin@andrew.cmu.edu](mailto:msezgin@andrew.cmu.edu)
