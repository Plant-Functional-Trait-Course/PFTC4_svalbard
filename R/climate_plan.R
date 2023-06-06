#### Download and clean climate data from OSF ####

climate_plan <- list(

  # Gradient climate data
  tar_target(
    name = climate_gradient_download,
    command =  get_file(node = "smbqh",
                        file = "PFTC4_SV_2018_SM.csv",
                        path = "raw_data",
                        remote_path = "RawData/RawData_Climate"),
    format = "file"
  ),

  tar_target(
    name = climate_gradient_raw,
    command =  read_delim(file = climate_gradient_download,
                          delim = ";", locale = locale(decimal_mark = "."))
  ),

  tar_target(
    name = climate_gradient_clean,
    command =  {
      climate_gradient_clean <- climate_gradient_raw %>%
        mutate(Year = 2018,
               LoggerType = "iButton",
               LoggerLocation = "soil") %>%
        mutate(Gradient = str_sub(plot, 1, 1),
               Site = str_sub(plot, 2, 2),
               PlotID = str_sub(plot, 3, 3)) %>%
        # calculate average per plot
        mutate(SoilMoisture = rowMeans(select(., matches("moist\\d")), na.rm = TRUE),
               SoilTemperature = rowMeans(select(., matches("temp\\d")), na.rm = TRUE)) %>%
        select(-c(moist1:moist3, temp1:temp3, moistAVG, tempAVG, plot)) %>%
        pivot_longer(cols = c(SoilMoisture, SoilTemperature), names_to = "Variable", values_to = "Value")

    }
  ),

  tar_target(
    name = climate_gradient_output,
    command =  save_csv(climate_gradient_clean,
                        name = "PFTC4_Svalbard_2018_Gradient_Climate.csv"),
    format = "file"
  ),


  # Itex climate data
  tar_target(
    name = climate_itex_download,
    command =  {
      get_file(node = "smbqh",
               file = "Climate_Data_ITEX_2015_2018.zip",
               path = "raw_data",
               remote_path = "RawData/RawData_Climate")
      # unzip file
      unzip("raw_data/Climate_Data_ITEX_2015_2018.zip",
            exdir = "raw_data")
    },
    format = "file"

  ),

  # iButton data
  tar_target(
    name = temperature_itex_clean,
    command =  {
      iButton = load_iButton(metaItex)
      tinytag = load_tinytag()

      temperature_itex = bind_rows(
        TinyTag = tinytag,
        iButton = iButton,
        .id = "LoggerType") %>%
        # rename site and plot names
        mutate(Site = case_when(Site == "BIS" ~ "SB",
                                Site == "CAS" ~ "CH",
                                Site == "DRY" ~ "DH"),
               PlotID = str_replace(PlotID, "BIS", "SB"),
               PlotID = str_replace(PlotID, "CAS", "CH"),
               PlotID = str_replace(PlotID, "DRY", "DH"))

    }
  ),

  tar_target(
    name = climate_itex_clean,
    command =  load_endalen()

  ),

  tar_target(
    name = temperature_itex_output,
    command =  save_csv(temperature_itex_clean,
                        name = "PFTC4_Svalbard_2005_2018_ITEX_Temperature.csv"),
    format = "file"
  ),

  tar_target(
    name = climate_itex_output,
    command =  save_csv(climate_itex_clean,
                        name = "PFTC4_Svalbard_2015_2018_ITEX_Climate.csv"),
    format = "file"
  )

)
