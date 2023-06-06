#### Download and clean community data from OSF ####

community_plan <- list(

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
    command =  community_gradient_raw %>%
      select(Site, Elevation, Plot, Day, `Alopecurus ovatus`:`Trisetum spicatum`, Collected_by, Weather) %>%
      pivot_longer(cols = c(`Alopecurus ovatus`:`Trisetum spicatum`),
                   names_to = "Taxon", values_to = "Cover") %>%
      filter(!is.na(Cover),
             !is.na(Day)) %>%
      mutate(Date = dmy(paste(Day, "07", "18", sep = "-"))) %>%
      rename(Gradient = Site, Site = Elevation, PlotID = Plot) %>%
      select(Date, Gradient:PlotID, Taxon, Cover, Weather, Collected_by) %>%
      # Fix draba species
      left_join(draba_dic_raw, by = c("Gradient", "Site", "PlotID")) %>%
      mutate(Taxon = if_else(Taxon %in% c("Draba nivalis", "Draba oxycarpa", "Draba sp1", "Draba sp2"), Draba, Taxon),
             Taxon = if_else(Taxon == "No Drabas", "Unknown sp", Taxon)) %>%
      # Fix Cover column
      separate(Cover, into = c("Cover", "Fertile"), sep = "_") %>%
      mutate(Cover = str_replace_all(Cover, " ", ""),
             Cover = as.numeric(Cover),
             Fertile = as.numeric(Fertile),
             Year = 2018,
             Taxon = tolower(Taxon),
             Weather = case_when(Weather == "Sunny" ~ "sunny",
                                 Weather == "partly cloudy" ~ "partly_cloudy",
                                 Weather %in% c("windy_cloudy", "cloudy_little_wind", "cloudy_wind_SW_partly_sunny", "cloudy_wind") ~ "cloudy_windy",
                                 Weather == "partly cloudy" ~ "partly_cloudy",
                                 TRUE ~ Weather)) %>%
      # add coords
      left_join(coords, by = c("Gradient" , "Site", "PlotID")) %>%
      select(Year, Date, Gradient, Site, PlotID, Taxon, Cover, Fertile, Weather, Elevation_m:Latitude_N)
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
    command =  community_gradient_raw %>%
      select(Day, Gradient = Site, Site = Elevation, PlotID = Plot, MedianHeight_cm, MaxHeight_cm = Max_height_cm, Vascular:Litter) %>%
      filter(!is.na(Site)) %>%
      mutate(Date = dmy(paste(Day, "07", "18", sep = "-")),
             Year = 2018) %>%
      # Fix Lichen_rock col
      mutate(Lichen_rock = if_else(Lichen_rock == "0_1", "0.1", Lichen_rock),
             Lichen_rock = as.numeric(Lichen_rock)) %>%
      left_join(coords, by = c("Gradient", "Site", "PlotID")) %>%
      pivot_longer(cols = MedianHeight_cm:Litter, names_to = "Variable", values_to = "Value") %>%
      filter(!is.na(Value)) %>%
      select(Year, Date, Gradient, Site, PlotID, Variable, Value, Elevation_m:Longitude_E)
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
    command = community_itex_raw %>%
      pivot_longer(cols = -c(SUBSITE:YEAR, CRUST, `TOTAL-L`:SOIL), names_to = "Spp", values_to = "Abundance") %>%
      # remove non occurrence
      filter(Abundance > 0) %>%
      rename(Site = SUBSITE, Treatment = TREATMENT, PlotID = PLOT, Year = YEAR) %>%
      mutate(Site2 = substr(Site, 5, 5),
             Site = substr(Site, 1, 3),
             PlotID = gsub("L", "", PlotID)) %>%
      # Select for site L. Site H is the northern site
      filter(Site2 == "L") %>%
      select(-Site2, -`TOTAL-L`, -LITTER, -REINDRO, -BIRDRO, -ROCK, -SOIL, -CRUST) %>%
      left_join(sp_itex, by = c("Spp")) %>%
      # Genus, species and taxon
      mutate(Genus = tolower(Genus),

             Species = tolower(Species),
             Species = if_else(is.na(Species), "sp", Species),

             Taxon = paste(Genus, Species, sep = " ")) %>%
      mutate(Taxon = ifelse(Taxon == "NA oppositifolia", "saxifraga oppositifolia", Taxon),
             Taxon = ifelse(Taxon == "festuca richardsonii", "festuca rubra", Taxon),
             Taxon = ifelse(Taxon == "pedicularis hisuta", "pedicularis hirsuta", Taxon),
             Taxon = ifelse(Taxon == "alopecurus boreale", "alopecurus ovatus", Taxon),
             Taxon = ifelse(Taxon == "stellaria crassipes", "stellaria longipes", Taxon),
             Taxon = ifelse(Taxon == "aulocomnium turgidum", "aulacomnium turgidum", Taxon),
             Taxon = ifelse(Taxon == "oncophorus whalenbergii", "oncophorus wahlenbergii", Taxon),
             Taxon = ifelse(Taxon == "racomitrium canescence", "niphotrichum canescens", Taxon),
             Taxon = ifelse(Taxon == "pedicularis dashyantha", "pedicularis dasyantha", Taxon),
             Taxon = ifelse(Taxon == "ptilidium ciliare ciliare", "ptilidium ciliare", Taxon),
             Taxon = ifelse(Taxon == "moss unidentified sp", "unidentified moss sp", Taxon),
             Taxon = ifelse(Taxon == "pleurocarp moss unidentified sp", "unidentified pleurocarp moss sp", Taxon),
             Taxon = ifelse(Taxon == "polytrichum/polytrichastrum sp", "polytrichum_polytrichastrum sp", Taxon),

             FunctionalGroup = if_else(Taxon == "ochrolechia frigida", "fungi", FunctionalGroup),
             FunctionalGroup = if_else(FunctionalGroup == "forbsv", "forb", FunctionalGroup)) %>%
      # add coords
      left_join(coords_itex %>% select(-Project), by = c("Treatment" , "Site")) %>%

      select(Year, Site:PlotID, Taxon, Abundance, FunctionalGroup, Elevation_m:Longitude_E) %>%
      # rename site and plot names
      mutate(Site = case_when(Site == "BIS" ~ "SB",
                              Site == "CAS" ~ "CH",
                              Site == "DRY" ~ "DH"),
             PlotID = str_replace(PlotID, "BIS", "SB"),
             PlotID = str_replace(PlotID, "CAS", "CH"),
             PlotID = str_replace(PlotID, "DRY", "DH")) %>%
      # flag iced Cassiope plots
      mutate(Flag = if_else(PlotID %in% c("CH-4", "CH-6", "CH-9", "CH-10"), "Iced", NA_character_))
  ),

  tar_target(
    name = community_itex_output,
    command =  save_csv(community_itex_clean,
                        name = "PFTC4_Svalbard_2003_2015_ITEX_Community.csv"),
    format = "file"
  )

)
