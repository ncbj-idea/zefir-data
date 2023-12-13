library(tidyverse)


# Global variables --------------------------------------------------------

path_to_operat <- 
  "/home/pstapyra/Documents/Forum Energii/Data/Rybnik/Preprocessing/Operaty losowania/full_non_living_operat_losowania.xlsx"
path_to_operat <- 
  "/home/pstapyra/Documents/Forum Energii/Data/Rybnik/Preprocessing/Operaty losowania/NEW_operat_losowania.xlsx"
path_to_bdot2 <- 
  "/home/pstapyra/Documents/Forum Energii/Data/Rybnik/BDOT_raw/20230821_buildings_report_Rybnik.xlsx"
path_to_bdot <- 
  "/home/pstapyra/Documents/Forum Energii/Data/Rybnik/Preprocessing/bdot_without_public + zabytki.xlsx"
  

# Processing data ---------------------------------------------------------

operat <- readxl::read_xlsx(path_to_operat)
bdot <- readxl::read_xlsx(path_to_bdot)
bdot2 <- readxl::read_xlsx(path_to_bdot2)

# Usable area in living buildings
operat %>%
  filter(kategoria_funkcjonalna_top_down != "Budynki publiczne") %>% .$latent_area %>% sum()
  group_by(kategoria_funkcjonalna_top_down_ver2, gas_connected) %>%
  summarise(suma = sum(latent_area))

# Count living building by type
bdot %>% count(kategoria_funkcjonalna_top_down)
bdot %>% count(funkcja_szczegolowa_budynku) %>% View()
bdot %>% count(kategoria_funkcjonalna_top_down,funkcja_szczegolowa_budynku) %>% View()

bdot %>% filter(kategoria_funkcjonalna_top_down != "Budynki publiczne" & 
                  !funkcja_szczegolowa_budynku %in% c("budynek jednorodzinny", "budynek o dwóch mieszkaniach", 
                                                      "budynek wielorodzinny")) %>% View()

bdot %>% group_by(kategoria_funkcjonalna_top_down) %>%
  summarise(suma = sum(pow_obrysu_m2, na.rm = TRUE))

operat %>% filter(kategoria_funkcjonalna_top_down == "Budynki publiczne") %>% 
  summarise(suma  = sum(latent_area))


