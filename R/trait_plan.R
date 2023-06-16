#### Download and import meta data from OSF ####

trait_plan <- list(

  # download leaf area
  tar_target(
    name = leaf_area_download,
    command = get_file(node = "smbqh",
                       file = "PFTC4_Svalbard_2018_Raw_LeafArea.csv",
                       path = "raw_data",
                       remote_path = "RawData/RawData_Traits"),
    format = "file"
  ),

  tar_target(
    name = leaf_area_raw,
    command = read_csv(file = leaf_area_download)
  ),

  # download phosphor data
  tar_target(
    name = p_download,
    command = get_file(node = "smbqh",
                       file = "PFTC_All_Phosphor.csv",
                       path = "raw_data",
                       remote_path = "RawData/RawData_Traits"),
    format = "file"
  ),

  # clean phosphor
  tar_target(
    name = p_raw,
    command = read_csv(p_download) %>%
      select(-Rack_Number, -Row, -Column)
  ),


  # download cn data
  tar_target(
    name = cn_download,
    command = {
      get_file(node = "smbqh",
               file = "PFTC_All_IsotopeData.zip",
               path = "raw_data",
               remote_path = "RawData/RawData_Traits")
      # unzip file
      unzip("raw_data/PFTC_All_IsotopeData.zip",
            exdir = "raw_data")
    },
    format = "file"
  ),

  # remote sensing ids
  tar_target(
    name = rs_id_raw,
    command = "raw_data/remote_senseing_ids.txt",
    format = "file"
  ),

  tar_target(
    name = rm_ids,
    command = read_delim(rs_id_raw, delim = ",")
  ),

  # merge CNP
  tar_target(
    name = chem_traits_clean,
    command = {

      p_clean = clean_p_traits(p_raw)

      cn_clean = clean_cn_traits(cn_download)

      #setdiff(cn_data$ID, CorrectedValues$ID)
      cnp_clean <- cn_clean %>%
        full_join(p_clean, by = c("ID", "Country")) %>%
        select(ID, Country, C_percent:dC13_permil, P_percent, Remark_CN, filename, Flag_corrected) %>%
        # filter unrealistic values
        mutate(P_percent = if_else(P_percent > 5, NA_real_, P_percent),
               C_percent = if_else(C_percent > 60, NA_real_, C_percent),
               C_percent = if_else(C_percent < 20, NA_real_, C_percent)) %>%
        mutate(Country = "SV",
               NP_ratio = N_percent / P_percent) %>%
        # remove duplicate rows
        filter(!c(ID == "AWP5107" & is.na(C_percent)),
               !c(ID == "AZR3297" & is.na(C_percent))) %>%
        #remove remote sensing ids
        anti_join(rm_ids, by = "ID")

    }
  ),

  # download traits
  tar_target(
    name = traits_download,
    command = get_file(node = "smbqh",
                       file = "PFTC4_Svalbard_2018_LeafTrait_with_DM.csv",
                       path = "raw_data",
                       remote_path = "RawData/RawData_Traits"),
    format = "file"
  ),

  # import
  tar_target(
    name = traits_raw,
    command = read_csv(file = traits_download)
  ),

  # clean traits
  tar_target(
    name = leaf_traits_clean,
    command = clean_traits(traits_raw, leaf_area_raw, metaItex, coords)
  ),

  # merge traits and chem traits
  tar_target(
    name = traits_all,
    command = finalize_traits(leaf_traits_clean, chem_traits_clean)
  ),

  # gradient traits
  tar_target(
    name = traits_gradient_clean,
    command = traits_all %>%
        filter(Project %in% c("Gradient", "Bryophytes")) %>%
        select(-Treatment)
  ),

  tar_target(
    name = traits_gradient_output,
    command = save_csv(traits_gradient_clean,
               name = "PFTC4_Svalbard_2018_Gradient_Traits.csv"),
    format = "file"
  ),

  # itex traits
  tar_target(
    name = traits_itex_clean,
    command = traits_all %>%
      filter(Project == "ITEX") %>%
      select(-Gradient)
  ),

  tar_target(
    name = traits_itex_output,
    command = save_csv(traits_itex_clean,
                       name = "PFTC4_Svalbard_2018_ITEX_Traits.csv"),
    format = "file"
  ),

  tar_target(
    name = traits_saxy_clean,
    command = traits_all %>%
      filter(Project == "Polyploidy") %>%
      select(-Gradient, -Site, -Treatment)
  ),

  tar_target(
    name = traits_saxy_output,
    command = save_csv(traits_saxy_clean,
                       name = "PFTC4_Svalbard_2018_Polyploidy_Traits.csv"),
    format = "file"
  )
)
