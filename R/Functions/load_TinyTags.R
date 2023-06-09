####################################
#### CLEAN RAW TINYTAG DATA ####
####################################

# needs libraries loaded in "climate/R/Merge_ClimateData.R"
load_tinytag <- function(){

  ColumnNames <- read_excel(path = "raw_data/DATA_ITEX_2015_2018/TinyTag_loggers/2005 Temp Data.xls", sheet = "DATA", col_names = FALSE) %>%
    slice(1:5) %>%
    t() %>%
    as_tibble() %>%
    slice(-52) %>%
    rename("Location" = "V1",
           "Treatment" = "V2",
           "Type" = "V3",
           "Log_June" = "V4",
           "Log_Aug" = "V5") %>%
    mutate(Treatment = recode(Treatment, "Control" = "CTL")) %>%
    fill(Location) %>%
    mutate(Treatment = paste(Location, Treatment, Log_June, Log_Aug, Type, sep = "_")) %>%
    select(Treatment) %>%
    t() %>%
    as_tibble()

  tinytag_raw <- read_excel(path = "raw_data/DATA_ITEX_2015_2018/TinyTag_loggers/2005 Temp Data.xls", sheet = "DATA", col_names = FALSE, skip = 7) %>%
    select(-"...51", -"...52")
  colnames(tinytag_raw) <- ColumnNames

  TinyTag <- tinytag_raw %>%
    rename("DateTime" = "Location_Treatment_Logger (June)_Logger (August)_Soil/Surface") %>%
    # some text in this col, make numeric, warning message ok
    mutate(`BIS L4_OTC_22_22_surface` = as.numeric(`BIS L4_OTC_22_22_surface`)) %>%
    pivot_longer(cols = c(-DateTime), names_to = "Treatment", values_to = "Value") %>%
    filter(!is.na(Value)) %>%
    filter(grepl("OTC|CTL", Treatment)) %>%
    separate(col = Treatment, into = c("Site", "PlotID", "Treatment", "LoggerID_Jun", "LoggerID_Aug", "LoggerLocation"), sep = " |_") %>%
    mutate(PlotID = gsub("L", "", PlotID),
           PlotID = paste(Site, PlotID, sep = "-"),
           Variable = "Temperature") %>%
    # clean data: CAS-9
    mutate(Value = if_else(PlotID == "CAS-9" & DateTime > "2005-06-06 01:00:00" & DateTime < "2005-06-28 23:00:00", NA_real_, Value),
           Value = if_else(PlotID == "CAS-9" & DateTime > "2005-08-08 01:00:00", NA_real_, Value)) %>%
    filter(!is.na(Value)) %>%
    select(DateTime, Site, Treatment, PlotID, LoggerLocation, Variable, Value)

}

# Checks
# TinyTag %>%
#   filter(Type == "soil") %>%
#   ggplot(aes(x = DateTime, y = Value, colour = PlotID)) +
#   geom_point() +
#   facet_grid(Treatment ~ Site)
