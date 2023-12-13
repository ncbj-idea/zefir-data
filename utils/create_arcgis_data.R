library(tidyverse)

path_to_bdot <- "/home/pstapyra/Documents/Forum Energii/Data/Rybnik/BDOT_raw/20230821_buildings_report_Rybnik.xlsx"
path_to_operat <- "/home/pstapyra/Documents/Forum Energii/Data/Rybnik/Preprocessing/NEW_data_to_arcgis_script.xlsx"


bdot <- readxl::read_xlsx(path_to_bdot)
arcgis <- readxl::read_xlsx(path_to_operat)
arcgis$Typ_deklaracji <- 
  ifelse(!is.na(arcgis$centralne) & is.na(arcgis$Typ_deklaracji),
         "B", arcgis$Typ_deklaracji)
arcgis <- subset(arcgis, !is.na(latent_area))
arcgis$gosp_dom <- NULL
arcgis$weight <- NULL

arcgis_prec <- arcgis %>% filter(!is.na(Typ_deklaracji))



drop_B_from_AB <- function(data, col) {
  state_to_modify <- 
    ifelse(length(unique(data[[col]])) > 1, TRUE, FALSE)
  if(state_to_modify) {
    data <- subset(data, data[col] == "A")
  }
  data[c(col)] <- NULL
  data
}

create_arcgis_data <- function(data, centralne, cwu, area) {
  
  centralne_data <- 
    data %>% 
    group_by({{centralne}}) %>% 
    summarise(suma = sum({{area}})) %>%
    pivot_wider(names_from = centralne, values_from = suma)
  main_central <- as.numeric(centralne_data[1,])
  names(main_central) <- colnames(centralne_data)
  main_central <- sort(main_central, decreasing = TRUE)
  
  
  colnames(centralne_data) <- paste(colnames(centralne_data), "centralne", sep = "_")
  colnames(centralne_data) <- str_replace_all(colnames(centralne_data), pattern = "\\s", "_")
  centralne_data$powierzchnia_ogrzewana_arcgis <- sum(centralne_data)
  centralne_data$glowne_centralne <- names(main_central)[1]
  

  cwu_data <- 
    data %>% 
    group_by({{cwu}}) %>% 
    summarise(suma = sum({{area}})) %>%
    pivot_wider(names_from = cwu, values_from = suma)
  
  main_cwu <- as.numeric(cwu_data[1,])
  names(main_cwu) <- colnames(cwu_data)
  
  main_cwu <- sort(main_cwu, decreasing = TRUE)
  centralne_data$glowne_cwu <- names(main_cwu)[1]
  
  colnames(cwu_data) <- paste(colnames(cwu_data), "co", sep = "_")
  colnames(cwu_data) <- str_replace_all(colnames(cwu_data), pattern = "\\s", "_")
  
  new_data <- bind_cols(centralne_data, cwu_data)
  new_data$id <- unique(data$id)
  new_data
}

finalize_arcgis_data <- function(data_list) {
  new_data <- do.call("bind_rows", data_list)
  
  
  
}

create_arcgis_data(arcgis_list[["316"]], centralne, cwu, latent_area)

arcgis_list <- split(arcgis_prec, arcgis_prec$id)
arcgis_list <- map(arcgis_list, drop_B_from_AB, "Typ_deklaracji")
x <- map(arcgis_list, create_arcgis_data, centralne, cwu, latent_area)
x <- do.call("bind_rows", x)
x[is.na(x)] <- 0

razem <- 
  bdot %>%
  left_join(x, by = "id")

razem$glowne_centralne <- 
  ifelse(is.na(razem$glowne_centralne), "Brak CEEB/nieogrzewany", razem$glowne_centralne)
razem$glowne_cwu <- 
  ifelse(is.na(razem$glowne_cwu), "Brak CEEB/nieogrzewany", razem$glowne_cwu)
razem$powierzchnia_ogrzewana_arcgis <- 
  ifelse(is.na(razem$powierzchnia_ogrzewana_arcgis) & razem$kategoria_funkcjonalna_top_down == "Budynki publiczne",
         razem$pow_uzytkowa_m2 * razem$wspolczynnik_powierzchni_uzytkowej_do_powierzchni_zabudowy,
         ifelse(is.na(razem$powierzchnia_ogrzewana_arcgis),
                razem$pow_uzytkowa_m2 * razem$wspolczynnik_powierzchni_uzytkowej_do_powierzchni_zabudowy * 0.7062,
                razem$powierzchnia_ogrzewana_arcgis))


openxlsx::write.xlsx(razem, "/home/pstapyra/Downloads/data_to_arcgis.xlsx")








