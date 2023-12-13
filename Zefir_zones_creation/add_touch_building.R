library(tidyverse)
library(sf)


# Load data ---------------------------------------------------------------

path_to_bdot <- "/home/pstapyra/Documents/Forum Energii/Data/Rybnik/Preprocessing/bdot_without_public + zabytki.xlsx"
path_to_operat_losowania <- "/home/pstapyra/Documents/Forum Energii/Data/Rybnik/Preprocessing/Operaty losowania/NEW_operat_losowania.xlsx"
path_to_save <- "/home/pstapyra/Documents/Forum Energii/Data/Rybnik/Preprocessing/Operaty losowania/full_non_living_operat_losowania.xlsx"
value_exclude <- 
  c("budynek gospodarczy", "garaż", "toaleta publiczna")

bdot <- readxl::read_xlsx(path_to_bdot)
bdot[,1] <- NULL
operat <- readxl::read_xlsx(path_to_operat_losowania)


### wyznaczenie adresów do poprawki (błąd w parserze),
# poprawiane są tylko dane arcgis
x <- operat %>% 
  filter(kategoria_funkcjonalna_top_down == "Budynki publiczne")
x <- 
  x %>% group_by(bdot_key) %>%
  summarise(suma = sum(weight)) %>% filter(suma > 1.1)


# Bdot processing ---------------------------------------------------------

### Things to do:
# (1) exclude from bdot record, which funkcja_szczegolowa_budynku in value_exclude
# and, where pow_uzytkowa_ogrzewana is less or equal 100, also add variables which 
# are present in operat losowania
bdot <- subset(bdot, 
                 !funkcja_szczegolowa_budynku %in% value_exclude & 
                 pow_uzytkowa_ogrzewana > 100)
bdot$latent_area <- bdot$pow_uzytkowa_m2*bdot$wspolczynnik_powierzchni_uzytkowej_do_powierzchni_zabudowy
bdot$rok_dodania_bdot <- as.numeric(str_extract(bdot$other, "x_datautworzenia': '((\\d{4})-\\d{2}-\\d{2})", group = 2))

# (2) split data because of number of buildings in address and in single building
# exclude budynki mieszkalne and id which currently is in operat losowania
bdot <- 
  bdot %>%
  left_join(count(bdot, bdot_key),
            by = "bdot_key") %>%
  mutate(split_count = ifelse(n >1, "wiele", "jeden")) %>%
  select(!n) %>%
  split(.$split_count)

single_building <- bdot[[1]]
many_buildings <- bdot[[2]]

single_building <- 
  single_building %>%
  filter(kategoria_funkcjonalna_top_down == "Budynki publiczne",
         !id %in% operat$id)


# (2) keep in bdot only building, where funkcja_szczegolowa_budynku = funkcja_szczegolowa_budynku
# budynku adresowego

many_buildings <- sf::st_as_sf(many_buildings, wkt = "geom_wkt",crs = "EPSG:2180")
many_buildings_list <- split(many_buildings, many_buildings$bdot_key)

keep_same_type <- function(data, var, sort_var, non_living = TRUE) {
  stopifnot(non_living %in% c(TRUE, FALSE))
  sorted_data <- arrange(data, sort_var)
  inclusion_value <- sorted_data[1,var,drop = TRUE]
  sorted_data <- sorted_data[which(sorted_data[[var]] == inclusion_value),]
  if(non_living){
    sorted_data <- 
      subset(sorted_data, kategoria_funkcjonalna_top_down == "Budynki publiczne")
  }
  sorted_data
}
many_buildings_list <- map(many_buildings_list, .f = keep_same_type,
                           var = "funkcja_szczegolowa_budynku",
                           sort_var = "addr_distance",
                           non_living = TRUE)
# drop empty list
cond_non_empty <- 
  unlist(map(many_buildings_list, nrow)) > 0
many_buildings_list <- 
  many_buildings_list[cond_non_empty]

# create complex buildings, starting from address building, distance beetwen
# each buildings is less than 3
create_complex_building <- function(data, dist_threshold = 3) {
  units(dist_threshold) <- "m"
  dist_matrix <- st_distance(data$geom_wkt, data$geom_wkt)
  diag(dist_matrix) <- 999
  
  final_rows <- c()
  cols_to_inspect <- 1:nrow(data)
  inspected_rows <- 1
  
  while(!is_empty(inspected_rows)) {
    fine_rows <- c()
    for(i in inspected_rows) {
      temp_rows <- which(dist_matrix[,inspected_rows] < dist_threshold)
      fine_rows <- unique(c(temp_rows, fine_rows))
    }
    final_rows <- c(final_rows, inspected_rows)
    cols_to_inspect <- cols_to_inspect[!cols_to_inspect %in% inspected_rows]
    inspected_rows <- cols_to_inspect[cols_to_inspect %in% fine_rows]
  }
  data[final_rows,]
}

final_buildings_list <- map(many_buildings_list, create_complex_building)

# Bind data and join cwu and co -------------------------------------------

final_many_building <- 
  do.call("rbind", final_buildings_list)

final_many_building <- 
  final_many_building %>%
  filter(!id %in% operat$id)

final_many_building <- 
  as.data.frame(final_many_building)
final_many_building$geom_wkt <- st_as_text(final_many_building$geom_wkt)

razem <- 
  rbind(final_many_building, single_building)


razem$strata <- "nielosowany"
razem$losowania <- "nielosowany"
razem$kategoria_funkcjonalna_top_down_ver2 <- razem$kategoria_funkcjonalna_top_down
razem$split_count <- NULL


full_operat <- 
  razem %>%
  left_join(operat %>% filter(kategoria_funkcjonalna_top_down == "Budynki publiczne") %>% 
              select(cwu, centralne, bdot_key),
            by = "bdot_key", relationship = "many-to-many")

razem <- 
  dplyr::bind_rows(operat, full_operat)

openxlsx::write.xlsx(razem, path_to_save)
rm(list = ls()[ls() != "x"])


