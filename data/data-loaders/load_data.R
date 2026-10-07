library(here)
library(dplyr)
library(tidyr)

# add args later to turn off ds filtering or smth idk
load_data <- function(match_vars = c('registration_number',
                                     'track_id',
                                     'distance_id',
                                     'surface')) {
  
  match_vars_lasix <- append(match_vars, 'lasix_ind')
  
  # load initial dataset: race info + results for all horses who have raced with
  # furosemide at least once and without furosemide at least once.
  data <- readRDS(file.path(here(), 'data', 'datasets', 'lnl_money.rds')) |>
    # filter implausible post positions, set date cut off, and filter out
    # odds == 0, which is impossible/means no reliable odds measurement was
    # collected.
    filter(post_position < 25,
           lubridate::year(race_date) <= 2024,
           odds != 0) |>
    mutate(total_other_horses = total_horses - 1,
           total_other_horses_lasix = if_else(med_description == 'Lasix',
                                              total_horses_lasix - 1,
                                              total_horses_lasix),
           frac_lasix = (total_other_horses_lasix/total_other_horses)*100) 
  
  # two-year-olds filtered dataset to be joined back with rest of data
  join_2yo_ds <- data |>
    # just two-year-olds
    filter(age_restriction == '02') |>
    # the number of races matched on track, distance, and surface that each horse
    # has completed
    group_by(across(all_of(match_vars_lasix))) |>
    summarize(count = n()) |>
    # filter so that we only have horses who have raced at the same track, same
    # distance, same surface, both with and without furosemide at least once.
    group_by(across(all_of(match_vars))) |> 
    filter(n() > 1) |> 
    distinct(across(all_of(match_vars))) |>
    ungroup()
  
  # join filter set with rest of data to add back vars
  data_2yo_ds <- join_2yo_ds |>
    left_join(data |>
                filter(age_restriction == '02'),
              by = match_vars)
  
  # fetch odds cutoff
  odds_cutoff <- quantile(data_2yo_ds$odds, .75)
  cat('odds cutofff is', odds_cutoff)
  
  # data filtered so that odds do not exceed 75th percentile
  data_ds_cut <- data |>
    filter(odds <= odds_cutoff)
  
  # two year olds filtering dataset to be joined back with rest of data, now
  # with odds cut off filtering.
  join_2yo_ds_cut <- data_ds_cut |>
    filter(age_restriction == '02') |>
    group_by(across(all_of(match_vars_lasix))) |>
    summarize(count = n()) |>
    group_by(across(all_of(match_vars))) |> 
    filter(n() > 1) |> 
    distinct(across(all_of(match_vars))) |>
    ungroup()
  
  # join odds cut off filtered dataset with rest of data to add back vars
  data_2yo_ds_cut <- join_2yo_ds_cut |>
    left_join(data_ds_cut |>
                filter(age_restriction == '02'),
              by = match_vars) |>
    # TODO: specify all variables here that need selection
    dplyr::select(registration_number, 
                  track_id,
                  distance_id,
                  jockey_id, 
                  post_position,
                  med_description,
                  lasix_ind,
                  frac_lasix,
                  total_other_horses,
                  odds,
                  in_the_money)
  
  # basic info about how many races and horses were filtered out using the odds
  # cut off logic.
  cat(nrow(data_2yo_ds), 'rows in full dset\n',
               nrow(data_2yo_ds_cut), 'rows in odds cutoff dset\n',
               nrow(data_2yo_ds) - nrow(data_2yo_ds_cut), 'rows removed\n')
  
  cat(length(unique(data_2yo_ds$registration_number)),
             'horses in full dset\n',
             length(unique(data_2yo_ds_cut$registration_number)),
             'horses in odds cutoff dset\n',
            length(unique(data_2yo_ds$registration_number)) -
                     length(unique(data_2yo_ds_cut$registration_number)),
            'horses removed')
  
  return(data_2yo_ds_cut)
  
}