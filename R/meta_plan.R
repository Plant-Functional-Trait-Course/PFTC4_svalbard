#### Download and import meta data from OSF ####

meta_plan <- list(

  # download meta data Itex
  tar_target(
    name = metaItex_download,
    command =  get_file(node = "smbqh",
                        file = "PFTC4_Svalbard_2018_metaItex.csv",
                        path = "clean_data",
                        remote_path = "MetaData"),
    format = "file"
  ),

  # Read in
  tar_target(
    name = metaItex,
    command = read_csv(file = metaItex_download)
  ),

  # download coordinates
  tar_target(
    name = coordinates_download,
    command =  get_file(node = "smbqh",
                        file = "PFTC4_Svalbard_Coordinates_Gradient.csv",
                        path = "clean_data",
                        remote_path = "MetaData"),
    format = "file"
  ),

  # Read in
  tar_target(
    name = coords,
    command = read_csv(file = coordinates_download)
  )

)
