#### Make a species list ####
# all species per study area and data type
make_sp_list <- function(tnrs, sp_raw, community_itex_clean, traits_itex_clean, community_gradient_clean, traits_gradient_clean){

  # get all species from trait and comm data
  sp_list <- bind_rows(ITEX_comm = community_itex_clean |>
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
    arrange(FunctionalGroup, Taxon) |>
    # make new columne without sp
    mutate(Taxon2 = str_remove(Taxon, " sp"))

  # Check species with TNRS
  # save file
  # sp_list |>
  #   select(Taxon, Taxon2) |>
  #   write_csv("sp_list.csv")

  tnrs_accept <- tnrs |>
    filter(Taxonomic_status == "Accepted") |>
    select(Name_submitted, Accepted_species, Accepted_family, Accepted_name_author) |>
    mutate(Accepted_species = tolower(Accepted_species)) |>
    group_by(Name_submitted) |>
    mutate(n = 1:n()) |>
    tidylog::filter(n == 1) |>
    filter(Name_submitted != "cladina sp")

  # make species list
  sp_list |>
    tidylog::left_join(tnrs_accept, by = c("Taxon2" = "Name_submitted")) |>
    # replace Taxon and family with accepted taxon and family
    mutate(Accepted_species = if_else(is.na(Accepted_species), Taxon, Accepted_species),
           Accepted_family = if_else(is.na(Accepted_family), Family, Accepted_family)) |>
    select(FunctionalGroup, Taxon = Accepted_species, Family= Accepted_family, Authority = Accepted_name_author, ITEX_comm, ITEX_trait, Gradient_comm, Gradient_trait)

}


