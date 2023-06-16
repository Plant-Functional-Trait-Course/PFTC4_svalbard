#### Make a species list ####
make_sp_list <- function(sp_raw, community_itex_clean, traits_itex_clean, community_gradient_clean, traits_gradient_clean){

  bind_rows(ITEX_comm = community_itex_clean |>
              distinct(Taxon),
            ITEX_trait = traits_itex_clean |>
              distinct(Taxon),
            Gradient_comm = community_gradient_clean |>
              distinct(Taxon),
            Gradient_trait = traits_gradient_clean |>
              distinct(Taxon),
            .id = "data") |>
    mutate(presence = "x") |>
    tidylog::left_join(sp_raw,
                       by = c("Taxon")) |>
    pivot_wider(names_from = data, values_from = presence) |>
    arrange(FunctionalGroup, Taxon) |> View()

}


# fg_f_sp <- read_csv("raw_data/PFTC4_Svalbard_2018_speciesList.csv")
# library(TNRS)
# author <- TNRS(fg_f_sp$Taxon) %>%
#   select(Name_submitted, Accepted_name_author)

SpeciesList <- bind_rows(ITEX_comm = commITEX %>% distinct(Taxon),
          ITEX_trait = traitITEX %>% distinct(Taxon),
          .id = "data"
          ) %>%
  mutate(presence = "x") %>%
  pivot_wider(names_from = data, values_from = presence) %>%
  full_join(bind_rows(Gradient_comm = commGradient %>% distinct(Taxon),
                      Gradient_trait = traitGradient %>% distinct(Taxon),
                      .id = "data"
  ) %>%
    mutate(presence = "x") %>%
    pivot_wider(names_from = data, values_from = presence),
  by = "Taxon") %>%
  left_join(fg_f_sp, by = "Taxon") %>%
  select(FunctionalGroup, Family, Taxon:Gradient_trait) %>%
  arrange(FunctionalGroup, Family, Taxon) %>%
  left_join(author, by = c("Taxon" = "Name_submitted"))


write_csv(SpeciesList, "clean_data/community/PFTC4_Svalbard_2018_Species_Experiment_list.csv")

