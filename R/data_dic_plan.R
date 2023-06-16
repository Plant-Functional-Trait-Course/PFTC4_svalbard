# data dictionary plan

data_dic_plan <- list(

  # attribute table
  tar_target(
    name = attribute_itex_file,
    command = "clean_data/PFTC4_attribute_table_itex.csv",
    format = "file"
  ),

  tar_target(
    name = attribute_grad_file,
    command = "clean_data/PFTC4_attribute_table_gradient.csv",
    format = "file"
  ),

  tar_target(
    name = attribute_itex,
    command = read_csv(attribute_itex_file)
  ),

  tar_target(
    name = attribute_grad,
    command = read_csv(attribute_grad_file)
  ),

  # community itex
  tar_target(
    name = comm_itex_dic,
    command = make_data_dictionary(data = community_itex_clean,
                                   description_table = attribute_itex,
                                   table_ID = NA_character_)
  ),

  # community gradient
  tar_target(
    name = comm_grad_dic,
    command = make_data_dictionary(data = community_gradient_clean,
                                   description_table = attribute_grad,
                                   table_ID = NA_character_)
  ),

  # height itex
  tar_target(
    name = height_itex_dic,
    command = make_data_dictionary(data = height_itex_clean,
                                   description_table = attribute_itex,
                                   table_ID = NA_character_)
  ),

  # height gradient
  tar_target(
    name = height_grad_dic,
    command = make_data_dictionary(data = comm_structure_gradient_clean,
                                   description_table = attribute_grad,
                                   table_ID = NA_character_)
  ),

  # traits itex
  tar_target(
    name = trait_itex_dic,
    command = make_data_dictionary(data = traits_itex_clean,
                                   description_table = attribute_itex,
                                   table_ID = "trait")
  ),

  # traits gradient
  tar_target(
    name = trait_grad_dic,
    command = make_data_dictionary(data = traits_gradient_clean,
                                   description_table = attribute_grad,
                                   table_ID = "trait")
  ),

  # soil gradient
  tar_target(
    name = soil_grad_dic,
    command = make_data_dictionary(data = soil_gradient_clean,
                                   description_table = attribute_grad,
                                   table_ID = "soil")
  ),

  # climate itex
  tar_target(
    name = climate_itex_dic,
    command = make_data_dictionary(data = climate_itex_clean,
                                   description_table = attribute_itex,
                                   table_ID = "climate")
  ),

  # temperature itex
  tar_target(
    name = temp_itex_dic,
    command = make_data_dictionary(data = temperature_itex_clean,
                                   description_table = attribute_itex,
                                   table_ID = "temperature")
  ),


  # climate gradient
  tar_target(
    name = climate_grad_dic,
    command = make_data_dictionary(data = climate_gradient_clean,
                                   description_table = attribute_grad,
                                   table_ID = "climate")
  ),




  # merge data dictionaries
  tar_target(
    name = data_dic,
    command = write_xlsx(list(comm_itex = comm_itex_dic,
                              comm_grad = comm_grad_dic,
                              height_itex = height_itex_dic,
                              height_grad = height_grad_dic,
                              trait_itex = trait_itex_dic,
                              trait_grad = trait_grad_dic,
                              soil_grad = soil_grad_dic,
                              climate_itex = climate_itex_dic,
                              temp_itex = temp_itex_dic,
                              climate_grad = climate_grad_dic
    ),
    path = "clean_data/PFTC4_data_dictionary.xlsx"),
    format = "file"
  )
)
