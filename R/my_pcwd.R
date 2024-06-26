#' @export


my_pcwd <- function(data){

  # loading libraries
  library(tidyr)
  library(cwd)
  library(rpmodel)
  library(dplyr)


  # convert tibble to dataframe
  vars_df <- as.data.frame(data)


  # unit conversions
  ## precipitation
  vars_df$pr <- vars_df$pr * 86400 # conversion to mm day-1

  ## temperature
  vars_df$tas <- vars_df$tas - 273.15 # conversion to °C


  # pet-calculation
  ## calculate surface pressure
  source(paste0(here::here(), "/R/calc_patm.R"))
  vars_df$patm <- calc_patm(vars_df$elevation)


  ## apply pet() function
  vars_df <- vars_df |>
    mutate(pet = 60 * 60 * 24 * pet(net_radiation, tas, patm))


  # snow simulation
  vars_df <- vars_df |>
    mutate(precipitation = ifelse(tas < 0, 0, pr),
           snow = ifelse(tas < 0, pr, 0)) |>
    simulate_snow(varnam_prec = "precipitation", varnam_snow = "snow", varnam_temp = "tas")


  vars_df <- vars_df |>
    mutate(wbal_pet = liquid_to_soil - pet)


  # pcwd
  ## calculate potential cumulative water deficit
  out_pcwd <- cwd(vars_df,
                  varname_wbal = "wbal_pet",
                  varname_date = "time",
                  thresh_terminate = 0.0,
                  thresh_drop = 0.0)

  out_pcwd$inst <- out_pcwd$inst |>
    filter(len >= 20)

  out_pcwd$df <- out_pcwd$df |>
    select(time, deficit)


  # return a data frame
  return(out_pcwd$df)
}
