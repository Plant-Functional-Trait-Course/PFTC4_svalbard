# make trait figure

fancy_trait_name_dictionary <- function(dat){

  dat <- dat |>
    mutate(trait_fancy = recode(Trait,
                                C_percent = "C %",
                                CN_ratio = "CN",
                                dC13_permil = "δC13 ‰",
                                dN15_permil = "δN15 ‰",
                                Plant_Height_cm = "Height cm",
                                Wet_Mass_g = "Wet mass g",
                                Dry_Mass_g = "Dry mass g",
                                LDMC = "LDMC",
                                Leaf_Area_cm2 = "Area cm2",
                                N_percent = "N %",
                                NP_ratio = "NP",
                                P_percent = "P %",
                                SLA_cm2_g = "SLA cm2/g",
                                Leaf_Thickness_mm = "Thickness mm"))

  return(dat)
}

make_trait_figure <- function(traits_itex_clean, traits_gradient_clean){

  itex_trait <- traits_itex_clean |>
    filter(!is.na(Site)) |>
    mutate(Value = if_else(Trait %in% c("Dry_Mass_g", "Wet_Mass_g", "Leaf_Area_cm2", "Plant_Height_cm"),
                           log(Value), Value),
           Trait = factor(Trait, levels = c("Plant_Height_cm", "Shoot_Length_cm", "Shoot_Length_Green_cm", "Wet_Mass_g", "Dry_Mass_g", "Leaf_Area_cm2", "Leaf_Thickness_mm", "SLA_cm2_g", "LDMC", "C_percent", "N_percent", "P_percent", "CN_ratio", "NP_ratio", "dC13_permil", "dN15_permil")),
           Habitat = factor(Site, levels = c("DH", "CH", "SB"))) |>
    fancy_trait_name_dictionary() |>
    ggplot(aes(x = Value, fill = Habitat, colour = Habitat)) +
    geom_density(alpha = 0.5) +
    scale_fill_manual(values = c("red","pink3", "lightblue"), labels = c("Dryas", "Cassiope", "Snowbed")) +
    scale_colour_manual(values = c("red","pink3", "lightblue"), labels = c("Dryas", "Cassiope", "Snowbed")) +
    labs(x = "Trait values", y = "Density", tag = "a)") +
    facet_wrap(~trait_fancy, scales = "free") +
    theme_minimal() +
    theme(text = element_text(size = 14),
          legend.position = "top")


  traits_gradient_trans <- traits_gradient_clean |>
    filter(!is.na(Site),
           Functional_group == "vascular") |>
    mutate(Value = if_else(Trait %in% c("Dry_Mass_g", "Wet_Mass_g", "Leaf_Area_cm2", "Plant_Height_cm"),
                           log(Value), Value),
           Trait = factor(Trait, levels = c("Plant_Height_cm", "Shoot_Length_cm", "Shoot_Length_Green_cm", "Wet_Mass_g", "Dry_Mass_g", "Leaf_Area_cm2", "Leaf_Thickness_mm", "SLA_cm2_g", "LDMC", "C_percent", "N_percent", "P_percent", "CN_ratio", "NP_ratio", "dC13_permil", "dN15_permil"))) |>
    # remove very high NP values
    tidylog::mutate(Value = if_else(Trait == "NP_ratio" & Value > 100, NA_real_, Value)) |>
    fancy_trait_name_dictionary()

  gradient_trait <- ggplot(traits_gradient_trans, aes(x = Value, fill = Gradient, colour = Gradient)) +
    geom_density(alpha = 0.5) +
    scale_fill_manual(name = "",
                      values = c("green4", "grey50"),
                      labels = c("Nutrient input", "Reference")) +
    scale_colour_manual(name = "",
                        values = c("green4", "grey50"),
                        labels = c("Nutrient input", "Reference")) +
    labs(x = "Trait values", y = "Density", tag = "b)") +
    facet_wrap(~trait_fancy, scales = "free") +
    theme_minimal() +
    theme(text = element_text(size = 14),
          legend.position = "top")

  itex_trait/gradient_trait
}
