library(tidyverse)
library(openxlsx)
# requirment library: tidymodels and VIM


# Path_to_files -----------------------------------------------------------
path_to_model <- "/home/pstapyra/Documents/Zefir/zones_area_creation/Data/new_tree_model.RDS"
path_to_termo <- "/home/pstapyra/Documents/Zefir/zones_area_creation/Data/termo_class.xlsx"

path_to_folder <- "/home/pstapyra/Documents/Forum Energii/Data/Rybnik/inwentaryzacja"
path_to_operat_losowania <- "/home/pstapyra/Documents/Forum Energii/Data/Rybnik/Preprocessing/Operaty losowania/NEW_operat_losowania.xlsx"
path_to_operat_arcgis <- "/home/pstapyra/Documents/Forum Energii/Data/Rybnik/Preprocessing/Operaty losowania/full_non_living_operat_losowania.xlsx"
path_to_wylosowane <- "/home/pstapyra/Documents/Forum Energii/Data/Rybnik/Preprocessing/wylosowane_Rybnik.xlsx"

path_to_save_data <- "/home/pstapyra/Downloads/data_with_termo_class2.xlsx"


# Global variables --------------------------------------------------------

distinct_var <-
  c("pow_uzytkowa_m2","longitude_centroid","latitude_centroid","funkcja_ogolna")
impute_var <-
  c(distinct_var, "Dach", "Okna", "Wiek_budynku_p_modern", "Ocieplenie_ścian", "nazwa_funkcji_ogolnej")
inw_var <-
  c("id", "ulica", "numer_porzadkowy", "Dach", "Okna", "Wiek_budynku_p_modern",
    "Ocieplenie_ścian", "Uwagi", "street_view", "energy_class")
estimation_var <-
  c("id", "Wiek_budynku_p_modern","energy_class")
path_os <- 
  if(Sys.info()[["sysname"]] == "Linux") {
    "/"
  } else{
    "\\"
  }
personal_inwentaryzacja <- 
  list.files(path_to_folder)
inwentaryzacja <- data.frame()

# Load data and joining ---------------------------------------------------


tree_model <- readRDS(path_to_model)
termo <- readxl::read_xlsx(path_to_termo)
for(i in personal_inwentaryzacja) {
  temp <- readxl::read_xlsx(paste(path_to_folder, path_os, i, sep = ""))
  temp <- subset(temp, !is.na(Zrobione))
  inwentaryzacja <- rbind(inwentaryzacja, temp)
  
}
operat <-
  readxl::read_xlsx(path_to_operat_losowania)
operat_arcgis <- 
  readxl::read_xlsx(path_to_operat_arcgis)
operat_arcgis <- 
  operat_arcgis %>% 
  filter(!id %in% operat$id)
wylosowane <- 
  readxl::read_xlsx(path_to_wylosowane)


operat_to_join <- operat[c("id",distinct_var)]
operat_to_join <- distinct(operat_to_join, id, .keep_all = TRUE)
inwentaryzacja <-
  inwentaryzacja %>% left_join(operat_to_join, by = "id")
inwentaryzacja[impute_var] <- VIM::kNN(inwentaryzacja[impute_var], k = 10, imp_var = FALSE)
inw_termo <- 
  inwentaryzacja %>% 
  left_join(termo, by = colnames(termo)[-5])


if(sum(is.na(inw_termo$energy_class)) > 0) {
  inw_termo[is.na(inw_termo$energy_class),"energy_class"] <- 
    as.character(workflows:::predict.workflow(tree_model, subset(inw_termo, is.na(energy_class)))[,1,drop = TRUE])
}


### Przygotowanie danych i ich zapis
inw_with_termo <- 
  inw_termo[c(inw_var)]
operat <- 
  left_join(operat, inw_with_termo[c(estimation_var)], by = "id")
wylosowane <- 
  wylosowane %>%
  left_join(inw_with_termo %>% select(!c(ulica, numer_porzadkowy)),
            by = "id")

operat_to_arcgis <- 
  dplyr::bind_rows(operat, operat_arcgis)

operat_to_arcgis <- 
  operat_to_arcgis %>%
  mutate(
    centralne = case_when(
      centralne == "boiler_new" ~ "Kocioł na paliwo stałe nowego typu",
      centralne == "boiler_old" ~ "Kocioł na paliwo stałe starego typu",
      centralne == "Pompa ciepła" ~ "Pompa ciepła",
      centralne == "Ogrzewanie elektryczne" ~ "Ogrzewanie elektryczne",
      centralne == "Kocioł gazowy" ~ "Kocioł gazowy",
      centralne == "Miejska sieć ciepłownicza" ~ "Miejska sieć ciepłownicza",
      TRUE ~ NA_character_
    )
  ) %>%
  mutate(
    cwu = case_when(
      cwu == "boiler_new" ~ "Kocioł na paliwo stałe nowego typu",
      cwu == "boiler_old" ~ "Kocioł na paliwo stałe starego typu",
      cwu == "Pompa ciepła" ~ "Pompa ciepła",
      cwu == "Ogrzewanie elektryczne" ~ "Ogrzewanie elektryczne",
      cwu == "Kocioł gazowy" ~ "Kocioł gazowy",
      cwu == "Miejska sieć ciepłownicza" ~ "Miejska sieć ciepłownicza",
      TRUE ~ NA_character_
    )
  )



pow_operat_losowania <- 
  ifelse(is.na(wylosowane$weight),
         wylosowane$pow_uzytkowa_m2 * wylosowane$wspolczynnik_powierzchni_uzytkowej_do_powierzchni_zabudowy,
         wylosowane$pow_uzytkowa_m2 * wylosowane$weight* wylosowane$wspolczynnik_powierzchni_uzytkowej_do_powierzchni_zabudowy)
wylosowane$latent_area <- 
  ifelse(wylosowane$kategoria_funkcjonalna_top_down != "Budynki publiczne",
         pow_operat_losowania * 0.706, pow_operat_losowania)

wb <- createWorkbook("Klasy_termo")
addWorksheet(wb, "Inwentaryzacja")
writeData(wb, 1, inw_with_termo)
addWorksheet(wb, "data_to_arcgis")
writeData(wb, 2, operat_to_arcgis)
addWorksheet(wb, "data_to_estimation")
writeData(wb, 3, wylosowane)

openxlsx::saveWorkbook(wb, path_to_save_data)
  












