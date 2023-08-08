#### Download and clean soil data from OSF ####

soil_plan <- list(

  #### Gradient data ####
  # download
  tar_target(
    name = soil_gradient_download,
    command = get_file(node = "smbqh",
                       file = "PFTC4_Svalbard_raw_CN_2022.xlsx",
                       path = "raw_data",
                       remote_path = "RawData/RawData_Soil"),
    format = "file"
  ),

  tar_target(
    name = soil_gradient_raw,
    command = read_excel(path = soil_gradient_download)
  ),

  tar_target(
    name = soil_gradient_clean,
    command = soil_gradient_raw |>
      # extract meta data
      mutate(Gradient = str_sub(sample_ID, 1, 1),
             Site = as.numeric(str_sub(sample_ID, 2, 2)),
             PlotID = str_sub(sample_ID, 3, 3)) |>
      # join elevation and coordinates
      left_join(coords, by = c("Gradient", "Site", "PlotID")) |>
      rename(C = `%  C`, N = `%  N`) |>
      # long table
      pivot_longer(cols = c(C, N), names_to = "Variable", values_to = "Value") |>
      # add unit
      mutate(Unit = "percentage") |>
      select(Gradient:PlotID, Variable, Value, Unit, Weight_mg = `vekt   mg`, Elevation_m:Latitude_N)
  ),

  tar_target(
    name = soil_gradient_output,
    command =  save_csv(soil_gradient_clean,
                        name = "PFTC4_Svalbard_2022_Gradient_Clean_Soil_CN.csv"),
    format = "file"
  )
)


# check data
# ggplot(soil_gradient_clean, aes(x = Elevation_m, y = Value, colour = Gradient)) +
#   geom_point() +
#   scale_colour_manual(name = "", values = c("grey", "green4"), labels = c("Reference", "Nutrient input")) +
#   facet_wrap(~ Variable, scales = "free")
