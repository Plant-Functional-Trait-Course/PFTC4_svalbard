# make ordination

make_ordination <- function(community_itex_clean, community_gradient_clean){

  # merge community data
  all_comm <- bind_rows(ITEX = community_itex_clean %>%
                          filter(Year == 2015) %>%
                          rename(Cover = Abundance),
                        Gradient = community_gradient_clean %>%
                          mutate(Site = as.character(Site)),
                        .id = "Project") %>%
    mutate(Location = if_else(Project == "ITEX", Site, Gradient),
           Elevation_m = if_else(Project == "ITEX", 238, Elevation_m),
           # make first letter capital
           Taxon = str_to_sentence(Taxon))

  # make data fat
  comm_fat = all_comm %>%
    select(-c(Project, Year, FunctionalGroup, Latitude_N:Flag, Date, Fertile, Weather, Gradient)) %>%
    distinct() %>%
    spread(key = Taxon, value = Cover, fill = 0) |>
    mutate(Treatment = if_else(Treatment == "OTC", "warm", "control"),
           Treatment = if_else(is.na(Treatment), "control", Treatment))

  # species
  comm_fat_spp = comm_fat %>% select(-(Site:Location))

  # NMDS
  NMDS_1 <-  metaMDS(comm_fat_spp, noshare = TRUE, try = 30, k = 1)
  NMDS_2 <-  metaMDS(comm_fat_spp, noshare = TRUE, try = 30, k = 2)
  NMDS_3 <-  metaMDS(comm_fat_spp, noshare = TRUE, try = 30, k = 3)
  NMDS_4 <-  metaMDS(comm_fat_spp, noshare = TRUE, try = 30, k = 4)
  NMDS_5 <-  metaMDS(comm_fat_spp, noshare = TRUE, try = 30, k = 5)
  NMDS_6 <-  metaMDS(comm_fat_spp, noshare = TRUE, try = 30, k = 6)

  stress_plot <- tibble(
    stress = c(NMDS_1$stress, NMDS_2$stress, NMDS_3$stress, NMDS_4$stress, NMDS_5$stress, NMDS_6$stress),
    dimensions = c(1:6)) %>%
    ggplot(aes(x = dimensions, y = stress)) +
    geom_point()

  set.seed(32)
  NMDS <- metaMDS(comm_fat_spp, noshare = TRUE, try = 30)

  species <- envfit(NMDS, comm_fat_spp, permutations = 999)
  spp.scrs <- as.data.frame(scores(species, display = "vectors")) |>
    rownames_to_column(var = "Taxon") |>
    mutate(pval = species$vectors$pvals) #|>
    #filter(pval <= 0.05)

  fNMDS <- fortify(NMDS) %>%
    filter(Score == "sites") %>%
    bind_cols(comm_fat %>% select(Site:Location)) |>
    mutate(Elevation_m = if_else(!Location %in% c("C", "B"), 238, Elevation_m))

  Ordination <- ggplot(fNMDS, aes(x = NMDS1, y = NMDS2, group = PlotID, shape = Treatment, colour = Location, alpha = Elevation_m)) +
    geom_point(size = 2.5) +
    coord_equal() +
    scale_shape_manual(name = "Treatment",
                       values = c(16, 1)) +
    scale_colour_manual(name = "Habitat",
                        values = c("green4", "grey50", "pink3", "red","lightblue"),
                        labels = c("Nutrient input", "Reference", "Cassiope", "Dryas", "Snowbed")) +
    scale_alpha_continuous(name = "Elevation m a.s.l.",
                           range = c(0.4, 1)) +
    labs(x = "NMDS axis 1", y = "NMDS axis 2", tag = "a)") +
    theme_bw()

  arrows <- ggplot(fNMDS, aes(x = NMDS1, y = NMDS2)) +
    coord_equal() +
    geom_segment(data = spp.scrs, aes(x = 0, xend = NMDS1, y = 0, yend = NMDS2),
                 arrow = arrow(length = unit(0.25, "cm")),
                 colour = "grey60", linewith = 0.3) +
    ggrepel::geom_text_repel(data = spp.scrs,
                             aes(x = NMDS1, y = NMDS2, label = Taxon),
                             colour = "grey20",
                             cex = 3, direction = "both", segment.size = 0.25) +
    labs(x = "NMDS axis 1", y = "NMDS axis 2", tag = "b)")  +
    theme_bw()

  ordination_plot <- Ordination / arrows + plot_layout(guides = "collect") & theme(text = element_text(size = 17))

}
#ggsave("Ordination.png", ordination_plot, width = 8, height = 14)

