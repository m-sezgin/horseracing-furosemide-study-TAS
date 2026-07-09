library(here)
library(dplyr)
library(tidyr)

# add args later to turn off ds filtering or smth idk
load_data <- function(match_vars = c('registration_number',
                                     'track_id',
                                     'distance_id',
                                     'surface')) {
  
  match_vars_lasix <- append(match_vars, 'lasix_ind')
  
  # load initial dataset: races for all horses who have race with and without at least once
  data <- readRDS(file.path(here(), 'data', 'datasets', 'lnl_money.rds')) |>
    # filter implausible post positions
    filter(post_position < 25) |>
    mutate(total_other_horses = total_horses - 1,
           total_other_horses_lasix = if_else(med_description == 'Lasix', total_horses_lasix - 1, total_horses_lasix),
           frac_lasix = (total_other_horses_lasix/total_other_horses)*100,
           ym = lubridate::floor_date(race_date, "month"),
           year = lubridate::year(race_date),
           month = lubridate::month(race_date, label = T)) |>
    filter(year <= 2024,
           odds != 0) |>
    group_by(registration_number) |>
    arrange(race_date) |>
    mutate(race_number = 1:n(),
           last_race_date = lag(race_date),
           days_since_last_race = as.numeric(race_date - last_race_date, "days")) |>
    ungroup()
  
  # two year olds filtering dataset to be joined back with rest of data
  join_2yo_ds <- data |>
    filter(age_restriction == '02') |>
    group_by(across(all_of(match_vars_lasix))) |>
    summarize(count = n()) |>
    group_by(across(all_of(match_vars))) |> 
    filter(n() > 1) |> 
    distinct(across(all_of(match_vars))) |>
    ungroup()
  
  # join filter set with rest of data and add some more vars
  data_2yo_ds <- join_2yo_ds |>
    left_join(data |>
                filter(age_restriction == '02'),
              by = match_vars)
  # fetch odds cutoff
  odds_cutoff <- quantile(data_2yo_ds$odds, .75)
  print(paste0('odds cutofff is ', odds_cutoff))
  
  data_ds_cut <- data |>
    filter(odds <= odds_cutoff)
  
  # two year olds filtering dataset to be joined back with rest of data
  join_2yo_ds_cut <- data_ds_cut |>
    filter(age_restriction == '02') |>
    group_by(across(all_of(match_vars_lasix))) |>
    summarize(count = n()) |>
    group_by(across(all_of(match_vars))) |> 
    filter(n() > 1) |> 
    distinct(across(all_of(match_vars))) |>
    ungroup()
  
  # join filter set with rest of data and add some more vars
  data_2yo_ds_cut <- join_2yo_ds_cut |>
    left_join(data_ds_cut |>
                filter(age_restriction == '02'),
              by = match_vars) |>
    mutate(year_fct = factor(year, levels = 1991:2024),
           across(c(odds, frac_lasix, total_other_horses,
                    post_position, race_number, days_since_last_race),
                  .fns = scale,
                  .names = "{.col}_t"),
           track_post = stringr::str_c(track_id, post_position)
    )
  
  cat(paste0(nrow(data_2yo_ds), ' rows in full\n',
               nrow(data_2yo_ds_cut), ' rows in odds cutoff dset\n',
               nrow(data_2yo_ds) - nrow(data_2yo_ds_cut), ' rows removed\n'))
  
  cat(paste0(length(unique(data_2yo_ds$registration_number)),
             ' horses in full\n',
             length(unique(data_2yo_ds_cut$registration_number)),
             ' horses in odds cutoff dset\n',
            length(unique(data_2yo_ds$registration_number)) -
                     length(unique(data_2yo_ds_cut$registration_number)),
            ' horses removed'))
  
  return(data_2yo_ds_cut)
  
}