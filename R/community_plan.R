#### Download and clean community data from OSF ####

community_plan <- list(

  # download
  tar_target(
    name = sp_download,
    command = get_file(node = "smbqh",
                       file = "PFTC4_Svalbard_2018_speciesList.csv",
                       path = "raw_data",
                       remote_path = "RawData/RawData_Community"),
    format = "file"
  ),

  tar_target(
    name = sp_raw,
    command = read_csv(file = sp_download)
  ),


  #### Gradient data ####
  # download
  tar_target(
    name = community_gradient_download,
    command = get_file(node = "smbqh",
                        file = "PFTC4_Svalbard_2018_Community.csv",
                        path = "raw_data",
                        remote_path = "RawData/RawData_Community"),
    format = "file"
  ),

  tar_target(
    name = community_gradient_raw,
    command = read_csv(file = community_gradient_download)
  ),

  # draba dictionary
  tar_target(
    name = draba_dic_download,
    command = get_file(node = "smbqh",
                        file = "PFTC4_Svalbard_2018_Draba_dictionary.xlsx",
                        path = "raw_data",
                        remote_path = "RawData/RawData_Community"),
    format = "file"
  ),

  tar_target(
    name = draba_dic_raw,
    command =  read_excel(path = draba_dic_download) %>%
      pivot_longer(cols = c(`No Drabas`:`Draba lactea`), names_to = "Draba", values_to = "Precense") %>%
      rename(Gradient = site, Site = transect, PlotID = plot) %>%
      filter(Precense == 1)
  ),

  # clean community data
  tar_target(
    name = community_gradient_clean,
    command =  clean_comm_gradient(community_gradient_raw, draba_dic_raw, coords)
  ),

  tar_target(
    name = community_gradient_output,
    command =  save_csv(community_gradient_clean,
                        name = "PFTC4_Svalbard_2018_Community_Gradient.csv"),
    format = "file"
  ),

  # clean community structure data
  tar_target(
    name = comm_structure_gradient_clean,
    command =  clean_comm_structure_grad(community_gradient_raw, coords)
  ),

  tar_target(
    name = comm_structure_gradient_output,
    command =  save_csv(comm_structure_gradient_clean,
                        name = "PFTC4_Svalbard_2018_Community_Structure_Gradient.csv"),
    format = "file"
  ),

  #### ITEX DATA ####
  # download
  tar_target(
    name = community_itex_download,
    command =  get_file(node = "smbqh",
                        file = "ENDALEN_ALL-YEARS_TraitTrain.xlsx",
                        path = "raw_data",
                        remote_path = "RawData/RawData_Community"),
    format = "file"
  ),

  tar_target(
    name = sp_itex_download,
    command =  get_file(node = "smbqh",
                        file = "Species lists_Iceland_Svalbard.xlsx",
                        path = "raw_data",
                        remote_path = "RawData/RawData_Community"),
    format = "file"
  ),

  # download coordinates itex
  tar_target(
    name = coordinate_itex_download,
    command =  get_file(node = "smbqh",
                        file = "PFTC4_Svalbard_Coordinates_ITEX.xlsx",
                        path = "clean_data",
                        remote_path = "MetaData"),
    format = "file"
  ),

  # Read in
  tar_target(
    name = coords_itex,
    command = read_excel(path = coordinate_itex_download) %>%
      filter(Project == "T",
             Site %in% c("CAS", "BIS", "DRY") |is.na(Site))
  ),

  # import
  tar_target(
    name = community_itex_raw,
    command = read_excel(path = community_itex_download, sheet = "SP-ABUND")
  ),

  # structure
  tar_target(
    name = height_itex_raw,
    command = read_excel(path = community_itex_download, sheet = "HEIGHT")
  ),

  tar_target(
    name = sp_itex_raw,
    command = read_excel(path = sp_itex_download, sheet = "Endalen")
  ),

  # clean
  tar_target(
    name = sp_itex,
    command = sp_itex_raw %>%
      select(SPP, GFNARROWarft, GENUS, SPECIES) %>%
      slice(-1) %>%
      mutate(GFNARROWarft = tolower(GFNARROWarft)) %>%
      rename(Spp = SPP, FunctionalGroup = GFNARROWarft, Genus = GENUS, Species = SPECIES)
  ),

  tar_target(
    name = community_itex_clean,
    command = clean_comm_itex(community_itex_raw, sp_itex, coords_itex)
  ),

  tar_target(
    name = community_itex_output,
    command =  save_csv(community_itex_clean,
                        name = "PFTC4_Svalbard_2003_2015_ITEX_Community.csv"),
    format = "file"
  ),

  tar_target(
    name = height_itex_clean,
    command = clean_height_itex(height_itex_raw)
  ),

  tar_target(
    name = height_itex_output,
    command =  save_csv(height_itex_clean,
                        name = "PFTC4_Svalbard_2003_2015_ITEX_Community_Structure.csv"),
    format = "file"
  ),

  ### Species list
  # download
  tar_target(
    name = tnrs_download,
    command =  get_file(node = "smbqh",
                        file = "TNRS_result.csv",
                        path = "raw_data",
                        remote_path = "RawData/RawData_Community"),
    format = "file"
  ),

  tar_target(
    name = tnrs,
    command =  read_csv(tnrs_download)
  ),

  tar_target(
    name = species_list,
    command =  make_sp_list(tnrs, sp_raw, community_itex_clean, traits_itex_clean, community_gradient_clean, traits_gradient_clean)
  ),

  tar_target(
    name = species_list_out,
    command =  write_csv(species_list, "clean_data/PFTC4_Svalbard_2018_Species_list.csv")
  )

)
