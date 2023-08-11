# community cleaning

# clean community data from gradient
clean_comm_gradient <- function(community_gradient_raw, draba_dic_raw, coords){

  community_gradient_raw %>%
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
    # fix other species (TNRS corrections)
    mutate(Taxon = case_when(Taxon == "Micranthes hieracifolia" ~ "Micranthes hieraciifolia",
                             Taxon == "Cochleria groenlandica" ~ "Cochlearia groenlandica",
                             Taxon == "Calamagrostis neglecta" ~ "Calamagrostis stricta",
                             Taxon == "Huperzia arctica" ~ "Huperzia appressa",
                             Taxon == "Alopecurus ovatus" ~ "Alopecurus magellanicus",
                             Taxon == "Festuca rubra" ~ "Festuca richardsonii",
                             TRUE ~ Taxon)) |>
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

}

clean_comm_structure_grad <- function(community_gradient_raw, coords){

  community_gradient_raw %>%
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
    select(Year, Date, Gradient, Site, PlotID, Variable, Value, Elevation_m:Latitude_N)

}


# clean itex community data
clean_comm_itex <- function(community_itex_raw, sp_itex, coords_itex){

  community_itex_raw %>%
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
           Taxon = ifelse(Taxon == "alopecurus ovatus", "alopecurus magellanicus", Taxon),
           Taxon = ifelse(Taxon == "luzula arctica", "luzula nivalis", Taxon),
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

}



# clean comm structure itex

clean_height_itex <- function(height_itex_raw){

  height_itex_raw |>
    rename(Site = SUBSITE, Treatment = TREATMENT, PlotID = PLOT, Year = YEAR) |>
    group_by(Site, Treatment, PlotID, Year) |>
    summarise(Height = mean(HEIGHT, na.rm = TRUE)) |>
    mutate(Site2 = substr(Site, 5, 5),
           Site = substr(Site, 1, 3),
           PlotID = gsub("L", "", PlotID)) |>
    # Select for site L. Site H is the northern site
    filter(Site2 == "L") %>%
    select(-Site2) |>
    # method for which method was used (2015 100 measurements pinpoint method, 2009 highest individuals per plot)
    mutate(Method = if_else(Year == 2015, "pinpoint", "highest_ind")) |>
    # rename site and plot names
    mutate(Site = case_when(Site == "BIS" ~ "SB",
                            Site == "CAS" ~ "CH",
                            Site == "DRY" ~ "DH"),
           PlotID = str_replace(PlotID, "BIS", "SB"),
           PlotID = str_replace(PlotID, "CAS", "CH"),
           PlotID = str_replace(PlotID, "DRY", "DH")) %>%
    # remove wrong plotID (unsure which it is)
    tidylog::filter(!(Treatment == "OTC" & PlotID == "DH-8")) |>
    # flag iced Cassiope plots
    mutate(Flag = if_else(PlotID %in% c("CH-4", "CH-6", "CH-9", "CH-10"), "Iced", NA_character_))

}




