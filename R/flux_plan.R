#### Download and clean gradient flux data from OSF ####

flux_plan <- list(

  #### Gradient data ####
  # download
  tar_target(
    name = flux_gradient_download,
    command = get_file(node = "smbqh",
                       file = "Cflux_SV_Gradient_2018.csv",
                       path = "raw_data",
                       remote_path = "RawData/RawData_C-Flux"),
    format = "file"
  ),

  tar_target(
    name = soil_resp_gradient_download,
    command = get_file(node = "smbqh",
                       file = "Cflux_SV_GradientSR_2018.csv",
                       path = "raw_data",
                       remote_path = "RawData/RawData_C-Flux"),
    format = "file"
  ),

  tar_target(
    name = cflux_gradient_raw,
    command = read_csv(flux_gradient_download)
  ),

  tar_target(
    name = soil_respiration_gradient_raw,
    command = read_csv(soil_resp_gradient_download)
  ),

  #### ITEX data ####
  # download
  tar_target(
    name = flux_itex_download,
    command = get_file(node = "smbqh",
                       file = "Cflux_SV_ITEX_2018.csv",
                       path = "raw_data",
                       remote_path = "C-Flux"),
    format = "file"
  ),

  tar_target(
    name = flux_itex_raw,
    command = read_csv(flux_itex_download)
  )


)

load("ITEX_all.Rdata", verbose = TRUE)
