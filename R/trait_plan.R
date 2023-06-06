#### Download and import meta data from OSF ####

trait_plan <- list(

  # download meta data Itex
  tar_target(
    name = leaf_area_download,
    command = get_file(node = "smbqh",
                       file = "PFTC4_Svalbard_2018_Raw_LeafArea.csv",
                       path = "raw_data",
                       remote_path = "RawData/RawData_Traits")
  ),

  tar_target(
    name = leaf_area_raw,
    command = read_csv(file = leaf_area_download)
  ),

)
