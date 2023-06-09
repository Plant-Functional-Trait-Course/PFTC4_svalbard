# chem trait functions

clean_p_traits <- function(p, all_codes){

  # Check IDs
  load(file = "raw_data/envelope_codes.Rdata", verbose = TRUE)
  setdiff(p$Individual_Nr, all_codes$hashcode)

  p <- p %>%
    rename("ID" = "Individual_Nr", "Country" = "Site") %>%
    filter(!is.na(ID),
           Country == "Svalbard") %>%
    mutate(ID = gsub("BTH8780", "BTH8779", ID),
           ID = gsub("BTH8781", "BTH8779", ID),
           ID = gsub("BTG5954", "BTG5953", ID),
           ID = gsub("BTG5955", "BTG5953", ID),
           ID = gsub("BOG7010", "BOG7009", ID),
           ID = gsub("BOG7011", "BOG7009", ID),
           ID = gsub("ALA6942", "ALA6941", ID),
           ID = gsub("ALA6943", "ALA6941", ID),
           ID = gsub("BWQ3664", "BWQ3663", ID),
           ID = gsub("BWQ3665", "BWQ3663", ID),
           ID = gsub("CCE6412", "CCE6411", ID),
           ID = gsub("CCE6413", "CCE6411", ID),
           ID = gsub("BMG1767", "BGM1767", ID),
           ID = gsub("BMG1768", "BGM1767", ID),
           ID = gsub("BMG1769", "BGM1767", ID),
           ID = gsub("BLL7087", "BLL7086", ID),
           ID = gsub("BLL7088", "BLL7086", ID),
           ID = gsub("BDN0364", "BDN0363", ID),
           ID = gsub("BDN0365", "BDN0363", ID),
           ID = gsub("CBO1252", "CBO1251", ID),
           ID = gsub("CBO1253", "CBO1251", ID),
           ID = gsub("BBC2983", "BBC2982", ID),
           ID = gsub("BBC2984", "BBC2982", ID),
           ID = gsub("BPG0975", "BPG0974", ID),
           ID = gsub("BPG0976", "BPG0974", ID),
           ID = gsub("BHS6705", "BHS6704", ID),
           ID = gsub("BHS6706", "BHS6704", ID),
           ID = gsub("BTJ3153", "BTJ3155", ID),
           ID = gsub("BMP3141", "BPM3141", ID),
           ID = gsub("BNQ3128", "BNG3128", ID),
           ID = gsub("DBM2786", "DBM2768", ID),
           ID = gsub("Dec1935", "DEC0035", ID),
           ID = gsub("DEW9132", "DEN9132", ID),
           ID = gsub("AMK4734", "AMK4737", ID),
           ID = gsub("BLT5062", "BLT5002", ID),
           ID = gsub("1172520.0", "APR5110", ID),
           ID = gsub("CBX63219", "CBX6319", ID),
           ID = gsub("13119.0", "DEC0035", ID),
           ID = gsub("Apr5110", "APR5110", ID))

  # only "Hard Red Spring Wheat Flour", "Standard1" and "Standard2"
  #setdiff(p$ID, all_codes$hashcode)

  # pull of standard, calculate R2, choose standard for absorbance curve, make regression and plot
  standard_concentration <- tibble(Standard = c(0, 2, 4, 8, 12, 16),
                                   Concentration = c(0, 0.061, 0.122, 0.242, 0.364, 0.484))
  Standard <- p %>%
    select(Country, Batch, ID, Sample_Absorbance) %>%
    filter(ID %in% c("Standard1", "Standard2")) %>%
    group_by(Country, Batch, ID) %>%
    nest(standard = c(Sample_Absorbance)) %>%
    mutate(standard = map(standard, bind_cols, standard_concentration),
           # remove batch if Sample_Absorbance is NA; Sample has not been measured
           standard = map(standard, ~ filter(., !is.na(Sample_Absorbance))))

  # Plot 2 Standard curves
  # Standard %>%
  #   unnest() %>%
  #   ggplot(aes(x = Sample_Absorbance, y = Concentration, colour = ID)) +
  #   geom_point() +
  #   geom_smooth(method = "lm", se = FALSE) +
  #   labs(x = "Absorbance", y = expression(paste("Concentration ", mu, "g/ml"))) +
  #   facet_wrap(~ Batch)



  # Choose standard and make model
  ModelResult <- Standard %>%
    mutate(correlation = map_dbl(standard, ~ if(length(.x$Sample_Absorbance > 1))
    {cor(.x$Sample_Absorbance, .x$Concentration, use = "pair")}
    else{NA_real_})) %>%
    group_by(Country, Batch) %>%
    slice(which.max(correlation)) %>%
    mutate(fit = map(standard, ~lm(Concentration ~ Sample_Absorbance, .)))


  # Calculate Mean, sd, coeficiant variability for each leaf and flag data
  p2 <- p %>%
    filter(!ID %in% c("Standard1", "Standard2"),
           # remove samples without mass
           !is.na(Sample_Mass)) %>%
    group_by(Country, Batch) %>%
    nest(data = c(ID:Name_measured)) %>%
    # add estimate from model
    left_join(ModelResult %>% select(-ID), by = c("Country", "Batch"))


  OriginalValues <- p2 %>%
    mutate(data = map2(.x = data, .y = fit, ~ mutate(.x, Sample_yg_ml = predict(.y, newdata = select(.x, Sample_Absorbance))))) %>%
    unnest(data) %>%
    mutate(Pmass = Sample_yg_ml * Volume_of_Sample_ml,
           Pconc = Pmass / Sample_Mass * 100) %>%
    # Calculate mean, sd, coefficient of variation
    group_by(Batch, Country, ID) %>%
    mutate(meanP = mean(Pconc, na.rm = TRUE),
           sdP = sd(Pconc, na.rm = TRUE),
           CoeffVarP = sdP / meanP) %>%
    # flag data
    mutate(Flag_orig = ifelse(CoeffVarP >= 0.2, "flag", ""))


  # wheat: check values, flag/remove, calculate convertion factor
  RedWheatValue <- 0.137
  CorrectionFactor <- OriginalValues %>%
    filter(ID %in% c("Hard Red Spring Wheat Flour")) %>%
    mutate(P_Correction = Pconc / RedWheatValue) %>%
    # Calculate mean, sd, coefficient of variation
    group_by(Batch, Country, ID) %>%
    summarise(Correction_Factor = mean(P_Correction, na.rm = TRUE)) %>%
    select(-ID)


  # Use Correction Factor on data
  CorrectedValues <- OriginalValues %>%
    filter(!ID %in% c("Hard Red Spring Wheat Flour")) %>%
    left_join(CorrectionFactor, by = c("Batch", "Country")) %>%
    mutate(Pconc_Corrected = Pconc * Correction_Factor) %>%
    # Calculate mean, sd, coefficient of variation
    group_by(Country, ID) %>%
    summarise(P_percent = mean(Pconc_Corrected, na.rm = TRUE),
              sdP_Corrected = sd(Pconc_Corrected, na.rm = TRUE),
              CoeffVarP_Corrected = sdP_Corrected / P_percent,
              N_replications = n()) %>%
    # flag data
    mutate(Flag_corrected = ifelse(CoeffVarP_Corrected >= 0.2, "flag", ""))

  CorrectedValues

}



clean_cn_traits <- function(cn_download){

  #### ISOTOPE DATA ####
  # import CN and isotope data and merge
  # Read isotope data
  #list_files <- dir(path = "raw_data/IsotopeData/", pattern = "\\.xlsx$", full.names = TRUE)

  cn_isotopes <- cn_download %>%
    set_names() %>%
    map(., ~ {sheetname <- excel_sheets(.x)
    sheetname <- if(length(sheetname) == 1) {
      sheetname
    } else {
      s <- str_subset(sheetname, fixed("REPORT("))
      if(length(s) == 0){s <- sheetname[1]}
      s
    }
    read_excel(.x, skip = 13, sheet = sheetname, na = c("NA", "REPEAT", "small", "See below", "#WERT!", "4X"))}) %>%
    map_df(~ {select(.,-c(...12:...17)) %>%
        slice(1:grep("Analytical precision, 1-sigma", ...1)-1) %>%
        filter(!is.na(...1)) %>% # removing empty rows
        filter(!is.na(C)) %>%
        rename(Samples_Nr = ...1, Individual_Nr = `Sample ID`, Site = ...3, Row = R, Column = C, C_percent = `C%`, N_percent = `N%`, CN_ratio = `C/N`, dN15_permil = `δ15N ‰(ATM)`, dC13_permil = `δ13C ‰(PDB)`, Remark_CN = ...11) %>%
        mutate(Column = as.character(Column))
    }, .id = "filename") %>%
    # remove one row
    filter(!c(Samples_Nr == 2 & filename == "IsotopeData//Enquist_18NORWAY-3_119-REPORT.xlsx")) %>%
    mutate(Samples_Nr = if_else(Samples_Nr == "2*", "2", Samples_Nr)) %>%
    mutate(Site = gsub("Norway|NORWAY", "Svalbard", Site),
           Individual_Nr = gsub("AHN3439", "AHN2439", Individual_Nr)) %>%
    # remove wrong measurements (can remove if C is NA)
    filter(!is.na(C_percent))

  # check duplicates
  # cn_isotopes %>%
  #   group_by(Individual_Nr) %>%
  #   mutate(n = n()) %>%
  #   filter(n > 1) %>%
  #   arrange(Individual_Nr) %>% print(n = Inf)


  # Check ids
  #setdiff(cn_isotopes$Individual_Nr, all_codes$hashcode)

  cn_data <- cn_isotopes %>%
    mutate(Individual_Nr = gsub("CLZ8080", "CLZ8280", Individual_Nr),
           Individual_Nr = gsub("BXE31110", "BXE3110", Individual_Nr),
           Individual_Nr = gsub("BCK00050", "BCK0050", Individual_Nr),
           Individual_Nr = gsub("BBWB9735", "BWB9735", Individual_Nr),
           Individual_Nr = gsub("BW7574", "BWO7574", Individual_Nr),
           Individual_Nr = gsub("BOO4539", "BOO4359", Individual_Nr)) %>%
    rename(ID = Individual_Nr, Country = Site)

  cn_data

}
