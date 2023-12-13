library(tidyverse)
library(sampling)


# Global variable ---------------------------------------------------------

path_to_operat <- "/home/pstapyra/Documents/Forum Energii/Data/Rybnik/Preprocessing/operat_losowania.xlsx"
path_save_inwentaryzacja <- "/home/pstapyra/Downloads/inwentaryzacja_Rybnik.xlsx"
path_save_wylosowane <- "/home/pstapyra/Downloads/wylosowane_Rybnik.xlsx"
factor_correction <- 0.706

# Load and preprocessing ----------------------------------------------------

operat_losowania <- 
  readxl::read_xlsx(path_to_operat, 
                    guess_max = 2*10^4)
operat_losowania <- 
  subset(operat_losowania, !is.na(pow_uzytkowa_m2))
operat_losowania$kategoria_funkcjonalna_top_down_ver2 <- 
  ifelse(operat_losowania$Typ_deklaracji == "B" & !is.na(operat_losowania$Typ_deklaracji), 
         "Budynki publiczne", operat_losowania$kategoria_funkcjonalna_top_down)

x <- as.numeric(str_extract(operat_losowania$other, "x_datautworzenia': '((\\d{4})-\\d{2}-\\d{2})", group = 2))
operat_losowania$rok_dodania_bdot <- x

x <- operat_losowania %>%
  group_by(centralne, cwu, gas_connected, kategoria_funkcjonalna_top_down) %>%
  summarise(suma_wag = sum(weight))


pow_operat_losowania <- 
  ifelse(is.na(operat_losowania$weight),
         operat_losowania$pow_uzytkowa_m2 * operat_losowania$wspolczynnik_powierzchni_uzytkowej_do_powierzchni_zabudowy,
         operat_losowania$pow_uzytkowa_m2 * operat_losowania$weight* operat_losowania$wspolczynnik_powierzchni_uzytkowej_do_powierzchni_zabudowy)
# używana jest powierzchnia gusowska (mieszkalne)
# założenie, że mnożnik jest taki sam dla każdego budynku
# y_observed = y_latent * g
# multiplicator_area <- 
#   gus_area/sum(pow_operat_losowania[which(operat_losowania$kategoria_funkcjonalna_top_down != "Budynki publiczne")])
operat_losowania$latent_area <- 
  ifelse(operat_losowania$kategoria_funkcjonalna_top_down_ver2 != "Budynki publiczne",
         pow_operat_losowania * factor_correction, pow_operat_losowania)


# Balanced sampling -------------------------------------------------------

operat_losowania$strata <- 
  paste(operat_losowania$kategoria_funkcjonalna_top_down_ver2,
        operat_losowania$centralne,
        operat_losowania$cwu,
        operat_losowania$gas_connected,
        operat_losowania$zabytek)
openxlsx::write.xlsx(operat_losowania, "//home/pstapyra/Documents/Forum Energii/Data/Rybnik/Preprocessing/NEW_operat_losowania.xlsx")
list_strata <- split(operat_losowania, operat_losowania$strata)
x <- unlist(map(list_strata, nrow))

todo_all <- list_strata[x<=30]
todo_sampling <- list_strata[x>30]

todo_all <- do.call("rbind", todo_all)
todo_all <- as_tibble(todo_all)

x <- unlist(map(todo_sampling, nrow))
sample_size_strata <- 
  unname(ifelse(x*0.04 <= 30, 30, x*0.04))
sample_size_strata <- 
  ifelse(x < 30, x, sample_size_strata)
sample_size_strata <- ceiling(sample_size_strata)
unname(sample_size_strata/x)
sum(sample_size_strata)

# ### sprawdzenie na mapie, gdzie są poszczególne warstwy
# # tylko tam gdzie jest wieksza populacja
# which(x > 1000)
# library(tmap)
# tmap_mode("view")
# 
# build_to_map <-  sf::st_as_sf(operat_losowania, wkt = "geom_wkt",crs = "EPSG:2180")
# build_to_map <- build_to_map %>%
#   filter(strata == names(x)[7])
# mapa <- tm_shape(build_to_map) + 
#   tm_basemap(server = "OpenStreetMap.Mapnik") + 
#   tm_fill("grey", legend.show = TRUE, alpha = 0.4, id = "id") + 
#   tm_borders(col = "black", lwd = 2) + 
#   tmap_style("beaver")
# mapa
# ####
# # Korekty co do liczbności
# # unique(operat_losowania$strata)[1] == 

sub_data <- lapply(todo_sampling, FUN = "[[", "latent_area")
prob_vectors <- map2(.x = sub_data, .y =  sample_size_strata,
                     .f = inclusionprobabilities)


build_data <- do.call("rbind", todo_sampling)
build_data$Prob <- unlist(unname(prob_vectors))
build_data <- as_tibble(build_data)
aux_matrix_ls <- 
  build_data %>% select(longitude_centroid, latitude_addr, rok_dodania)
aux_matrix_ls <- 
  split(aux_matrix_ls, build_data$strata)
aux_matrix_ls <- 
  map(aux_matrix_ls, as.matrix)
set.seed(1236) # Rybnik
x <- map2(aux_matrix_ls, prob_vectors, order = 1, .f = samplecube) %>% 
  unlist() %>% unname()


# Przygotowanie do inwentaryzacji -----------------------------------------
all_wylosowane <- build_data[as.logical(x),]
all_wylosowane <- rbind(all_wylosowane, todo_all %>%mutate(Prob = NA))
inwentaryzacja <- all_wylosowane %>% distinct(id, .keep_all = TRUE)
inwentaryzacja <- 
  inwentaryzacja[,c("id", "ulica", "numer_porzadkowy", "geom_wkt", "nazwa_funkcji_ogolnej")]
inwentaryzacja <- 
  distinct(inwentaryzacja, id, .keep_all = TRUE)

inwentaryzacja[c("przydzial", "Dach", "Okna",
                 "Wiek_budynku_p_modern", "Ocieplenie_ścian", 
                 "Uwagi", "Zrobione", "street_view")] <- NA

## Przydziały
x <- unname(sort(table(inwentaryzacja$ulica), decreasing = TRUE))
x <- as.numeric(x)
pomocowa_tabelka <- 
  data.frame(ulica = names(sort(table(inwentaryzacja$ulica), decreasing = TRUE)),
             liczba = x,
             przydzial = NA)
nrow(pomocowa_tabelka)
pomocowa_tabelka$przydzial[1:3] <- "Paweł"
pomocowa_tabelka$przydzial[4:51] <- rep(c("Magda", "Gosia", "Inni"))

pomocowa_tabelka <- 
  pomocowa_tabelka %>%
  select(ulica, przydzial)

inwentaryzacja$przydzial <- NULL
inwentaryzacja <- 
  inwentaryzacja %>% 
  left_join(pomocowa_tabelka, by = "ulica")


openxlsx::write.xlsx(inwentaryzacja, path_save_inwentaryzacja)
openxlsx::write.xlsx(all_wylosowane, path_save_wylosowane)

# Losowanie ---------------------------------------------------------------
# 
# operat_losowania$strata <- 
#   paste(operat_losowania$kategoria_funkcjonalna_top_down,
#         operat_losowania$centralne,
#         operat_losowania$cwu,
#         operat_losowania$gas_connected)
# 
# 
# list_strata <- split(operat_losowania, operat_losowania$strata)
# x <- unlist(map(list_strata, nrow))
# y <- ifelse(x <= 30, x, ifelse(x*0.1 < 30, 30, x*0.1))
# 
# 
# todo_all <- list_strata[x<=30]
# todo_sampling <- list_strata[x>30]
# 
# todo_all <- do.call("rbind", todo_all)
# todo_all <- as_tibble(todo_all)
# 
# x <- unlist(map(todo_sampling, nrow))
# sample_size_strata <- unname(ifelse(x*0.1 <= 30, 30, x*0.1))
# sample_size_strata <- ceiling(sample_size_strata)
# 
# 
# sub_data <- lapply(todo_sampling, FUN = "[[", "latent_area")
# prob_vectors <- map2(.x = sub_data, .y =  sample_size_strata,
#                      .f = inclusionprobabilities)
# 
# 
# build_data <- do.call("rbind", todo_sampling)
# build_data$Prob <- unlist(unname(prob_vectors))
# build_data <- as_tibble(build_data)
# 
# 
# 
# set.seed(666) # sztum
# x <- map(.x = prob_vectors, .f = UPbrewer) %>% unlist() %>% unname()
# 
# ### Przygotowanie danych do inwentaryzacji i zapis
# all_wylosowane <- build_data[as.logical(x),]
# all_wylosowane <- rbind(all_wylosowane, todo_all %>%mutate(Prob = NA))
# 
# 
# inwentaryzacja <- all_wylosowane %>% distinct(id, .keep_all = TRUE)
# inwentaryzacja <- 
#   inwentaryzacja[,c("id", "ulica", "numer_porzadkowy", "geom_wkt", "nazwa_funkcji_ogolnej", "Prob")]
# inwentaryzacja <- 
#   distinct(inwentaryzacja, id, .keep_all = TRUE)
# 
# inwentaryzacja[c("przydzial", "Dach", "Okna",
#              "Wiek_budynku_p_modern", "Ocieplenie_ścian", 
#              "Uwagi", "Zrobione", "street_view")] <- NA

### przydzelenie ulic do inwentaryzacjia
# x <- unname(sort(table(inwentaryzacja$ulica), decreasing = TRUE))
# x <- as.numeric(x)
# pomocowa_tabelka <- 
#   data.frame(ulica = names(sort(table(inwentaryzacja$ulica), decreasing = TRUE)),
#              liczba = x,
#              przydzial = NA)
# nrow(pomocowa_tabelka)
# pomocowa_tabelka$przydzial[1:3] <- "Paweł"
# pomocowa_tabelka$przydzial[4:51] <- rep(c("Magda", "Gosia", "Inni"))
# 
# pomocowa_tabelka <- 
#   pomocowa_tabelka %>%
#   select(ulica, przydzial)
# 
# inwentaryzacja$przydzial <- NULL
# inwentaryzacja <- 
#   inwentaryzacja %>% 
#   left_join(pomocowa_tabelka, by = "ulica")
# 
# 
# openxlsx::write.xlsx(inwentaryzacja, "/home/pstapyra/Documents/Zefir/Data_city/Sztum/do_inwentaryzacji_sztum.xlsx")
# openxlsx::write.xlsx(all_wylosowane, "/home/pstapyra/Documents/Zefir/Data_city/Sztum/wylosowane_urzadzenia.xlsx")




