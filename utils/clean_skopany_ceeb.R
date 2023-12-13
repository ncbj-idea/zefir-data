library(tidyverse)
library(stringr)

### prototyp doprowadzenia pliku csv do formatu tabelarycznego z csv (historia 
## związana z błędnym kodowanie symboli) oraz później z tabelarycznego
## na wymiar urządzeń


ceeb <- readr::read_file("/home/pstapyra/Downloads/202303_CEEB.csv")
# ceeb_vector1 <- str_split_1(ceeb, pattern = ";;;;;;") # czasem też jest 5 :)
# ceeb <- str_remove_all(ceeb, pattern = ";")
ceeb <- str_remove_all(ceeb, pattern = '"')
ceeb_vector <- str_split_1(ceeb, pattern = "\\r\\n")
ceeb_names <- str_split_1(ceeb_vector[1], pattern = ",")
ceeb_names <- str_split(ceeb_names, pattern = ";")

# pierwszy wiersz to nazwy cech, a ostatni jest pusty
ceeb_record <- ceeb_vector[-1]
ceeb_record <- ceeb_record[-length(ceeb_record)]
#ceeb_record <- str_remove_all(ceeb_record, pattern = "\\r\\n")
#ceeb_record <- str_remove_all(ceeb_record, pattern = '"')
# zastąpienie przecinków w nawiasach średnikiem
ceeb_record <- str_replace_all(ceeb_record, pattern = ";", replacement = ",")
ceeb_record <- gsub("(?:\\G(?!^)|\\()[^()]*?\\K,", ";", ceeb_record, perl=TRUE)

## Wydobycie poszczególnych informacji - tam gdzie jest różna ilość przecinków
# wydobycie informacji o numerach lokali objętych deklaracją wtedy i tylko wtedy
# gdy deklaracja nie dotyczy wszystkich lokali
gsub(".+nie,\\d,(.+),\\d{4}-\\d{2}-\\d{2}.+", "\\1", ceeb_record[2])
gsub(".+nie;\\d;(.+);\\d{4}\\.\\d{2}\\.\\d{2}.+", "\\1", ceeb_record[979])
# wydobycie informacji o źródle ciepła, klasie oraz paliwie
gsub(".+deklaracja CEEB;(.+);(nie|tak);(nie|tak);(nie|tak);(nie|tak).+", "\\1", ceeb_record[979])
gsub(".+deklaracja CEEB,(.+),tak,+", "\\1", ceeb_record[847])
# wydobycie adresu
gsub("^(.+),Tak.+", "\\1", ceeb_record[1])

address <- gsub("^(.+),(Tak|Nie),.+", "\\1", ceeb_record, ignore.case = FALSE)
fuel_source <- gsub(".+(deklaracja CEEB|z urzędu),(.+),(nie|tak),(nie|tak),(nie|tak),(nie|tak).+", "\\2", ceeb_record)
#fuel_source <- gsub(".+deklaracja CEEB,(.+),(nie|tak),(nie|tak),(nie|tak),(nie|tak).+", "\\1", ceeb_record)
nmb_resid <- gsub(".+nie,\\d+,(.+),\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}.+", "\\1", ceeb_record)
from_data <- str_extract("\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}.+", string = ceeb_record)
unknown_data <- str_extract("(Tak|Nie).+(deklaracja CEEB|z urzędu)", string = ceeb_record)
unknown_data2 <- str_extract(pattern = "(nie\\b|tak\\b),.+(nie\\b|tak\\b)", string = ceeb_record)
liczba_lokali <- str_extract(pattern = "nie,(\\d+)", string = ceeb_record, group = 1)
#liczba_lokali <- str_extract(pattern = "\\d+", string = liczba_lokali)

### Create empty data frame
ceeb_names
df_ceeb <- matrix(NA, nrow = length(ceeb_record), ncol = length(ceeb_names))
df_ceeb <- as.data.frame(df_ceeb)
ceeb_names <- str_replace_all(ceeb_names, pattern = " ", replacement = "_")
colnames(df_ceeb) <- ceeb_names


### liczba oraz numery lokai objętych deklaracją, gdy deklaracja nie dotyczy całego
# budynku
df_ceeb[ceeb_names[20]] <- as.numeric(liczba_lokali)
# gdy długość stringa jest większa niż 20 to wykrywa zły wzorzec i powinno być NA
df_ceeb[which(unlist(map(nmb_resid, str_length)) < 20),21] <- 
  nmb_resid[which(unlist(map(nmb_resid, str_length)) < 20)]


### address
address_list <- str_split(address, ",")
df_ceeb[ceeb_names[1]] <- address
df_ceeb[ceeb_names[2]] <- str_extract(address, "Czempiń - obszar wiejski|Czempiń - miasto")
df_ceeb[ceeb_names[3]] <- str_extract("(Czempiń - obszar wiejski|Czempiń - miasto),([^,]+).+", group = 2, string = address)
df_ceeb[ceeb_names[4]] <- str_extract("(Czempiń - obszar wiejski|Czempiń - miasto),([^,]+),([^,]+),.+", group = 3, string = address)
df_ceeb[ceeb_names[5]] <- unlist(map2(.x = unlist(map(address_list, length)), .y = str_split(address, ","), ~.y[[.x]]))


### unknown data
temp_ud <- str_split(unknown_data, ",")
df_ceeb[ceeb_names[6]] <- unlist(map(temp_ud,1))
df_ceeb[ceeb_names[7]] <- unlist(map(temp_ud,2))
df_ceeb[ceeb_names[8]] <- unlist(map(temp_ud,3))



### after data - jest więcej niż jeden numer telefonu
df_ceeb[ceeb_names[26]] <- str_extract("\\d{9}.*", string = from_data)
temp_ad <- str_split(from_data, ",")
df_ceeb[ceeb_names[22]] <- unlist(map(temp_ad,1))
df_ceeb[ceeb_names[23]] <- unlist(map(temp_ad,2))
df_ceeb[ceeb_names[24]] <- unlist(map(temp_ad,3))
df_ceeb[ceeb_names[25]] <- unlist(map(temp_ad,4))


### unknown_data2 - uwaga deklaracja B ma inną strukturę - trzeba wyciągnąć wszystko poza tak/nie/,
# split, żeby wydobyć tak.nie reszta za pomocą wyrażenia
tamp_ud2 <- str_split(unknown_data2, ",")
df_ceeb[ceeb_names[12]] <- unlist(map(tamp_ud2,1))
df_ceeb[ceeb_names[13]] <- unlist(map(tamp_ud2,2))
df_ceeb[ceeb_names[14]] <- unlist(map(tamp_ud2,3))
df_ceeb[ceeb_names[15]] <- unlist(map(tamp_ud2,4))
df_ceeb[ceeb_names[19]] <- unlist(map(tamp_ud2,-1))
df_ceeb[ceeb_names[18]] <- unlist(map(tamp_ud2,-2))
df_ceeb[ceeb_names[17]] <- unlist(map(tamp_ud2,-3))
# deklaracje typu B mają opis budynku, który może zawierać przecinki
str_extract(string = unknown_data2[441], pattern = "(\\bnie\\b|\\btak\\b|,)+(.+),(.+),(\\bnie\\b|\\btak\\b)", group = 2)
df_ceeb[ceeb_names[16]] <- 
  str_extract(string = unknown_data2, pattern = "(\\bnie\\b|\\btak\\b|,)+(.+),(.+),(\\bnie\\b|\\btak\\b)", group = 2)
### żródło, klasa i paliwo
# dane oryginalne
df_ceeb$source_fuels_class <- fuel_source
# o paliwo nie ma co się bić
temp_fuel <- str_split(fuel_source, ",")
df_ceeb[ceeb_names[11]] <- unlist(map(temp_fuel,3))
df_ceeb[ceeb_names[10]] <- unlist(map(temp_fuel,2))
# na bazie poprzedniej kolumny powstaną dodatkowe zmienne, które będą miały albo 
# informację, że dana klasa występuje w zgłoszeniu albo liczbę z nawiasu
df_ceeb$klasa3_nd <- ifelse(str_detect(pattern = "Poniżej klasy 3 lub brak informacji", 
                                       string = df_ceeb[[ceeb_names[10]]]), 
                            str_extract(pattern = "Poniżej klasy 3 lub brak informacji \\((\\d)\\)", 
                                        string = df_ceeb[[ceeb_names[10]]],
                                        group = 1), NA)
df_ceeb$klasa3 <- ifelse(str_detect(pattern = "Klasa 3", 
                                    string = df_ceeb[[ceeb_names[10]]]), 
                         str_extract(pattern = "Klasa 3 \\((\\d)\\)", 
                                     string = df_ceeb[[ceeb_names[10]]],
                                     group = 1), NA)
df_ceeb$klasa4 <- ifelse(str_detect(pattern = "Klasa 4", 
                                    string = df_ceeb[[ceeb_names[10]]]), 
                         str_extract(pattern = "Klasa 4 \\((\\d)\\)", 
                                     string = df_ceeb[[ceeb_names[10]]],
                                     group = 1), NA)
df_ceeb$klasa5 <- ifelse(str_detect(pattern = "Klasa 5", 
                                    string = df_ceeb[[ceeb_names[10]]]), 
                         str_extract(pattern = "Klasa 5 \\((\\d)\\)", 
                                     string = df_ceeb[[ceeb_names[10]]],
                                     group = 1), NA)
df_ceeb$klasa_eko <- ifelse(str_detect(pattern = "Ekoprojekt", 
                                       string = df_ceeb[[ceeb_names[10]]]), 
                            str_extract(pattern = "Ekoprojekt \\((\\d)\\)", string = df_ceeb[[ceeb_names[10]]],
                                        group = 1), NA)
# źródło ciepła
df_ceeb[[ceeb_names[9]]] <- unlist( map(temp_fuel, 1))

## id - poóźniej potrzebne do łaczenia danych
df_ceeb$id <- 1:nrow(df_ceeb)


x <- df_ceeb %>% select(2:26,28:33,1,27)
x$orginal_record <- ceeb_record
x <- x %>%
  mutate(across(everything(), \(x) str_replace_all(string = x, pattern = ",", replacement = ";")))
readr::write_csv(x, "/home/pstapyra/Documents/Zefir/ceeb_repair/Results/Czempin/ceeb_koszmar.csv")
### tutaj następuje ręczne poprawka błędnych rekordów


# Wymiar urządzeń ---------------------------------------------------------
half_way_ceeb <- readr::read_csv("/home/pstapyra/Documents/Zefir/ceeb_repair/Results/Czempin/ceeb_koszmar.csv")
x <- half_way_ceeb[c("Zainstalowane_źródło_ciepła","Klasa_kotłów_na_paliwo_stałe", "id")]

list_x <- str_split(x$Zainstalowane_źródło_ciepła, "\\|")
list_x <- lapply(list_x, str_trim)


### Nowa funkcja tworząca data frame - equipment
create_special_df <- function(data, id, nazwa) {
  x <- data.frame(temp = data,"id" = id)
  colnames(x)[1] <- nazwa
  x
}

create_source_df <- function(lista) {
  equipment <- map(lista, str_extract, pattern = "(.+) \\(", group = 1)
  liczba <- map(lista, str_extract, pattern = "liczba: (\\d+)", group = 1)
  state <- map(lista, str_extract, pattern = "w użyciu|nieużywane")
  CWU <- map(lista, str_detect, pattern = "ogrzewanie wody")
  centralne <- map(lista, str_detect, pattern = "ogrzewanie centralne")

  cbind(do.call("rbind", map2(.x = equipment, .y = 1:3437, .f = create_special_df, nazwa = "source")),
        do.call("rbind", map2(.x = liczba, .y = 1:3437, .f = create_special_df, nazwa = "liczba"))[,-2,drop = FALSE], 
        do.call("rbind", map2(.x = state, .y = 1:3437, .f = create_special_df, nazwa = "stan"))[,-2,drop = FALSE],
        do.call("rbind", map2(.x = CWU, .y = 1:3437, .f = create_special_df, nazwa = "ogrzewanie_wody"))[,-2,drop = FALSE],
        do.call("rbind", map2(.x = centralne, .y = 1:3437, .f = create_special_df, nazwa = "ogrzewanie_centralne"))[,-2,drop = FALSE])
  
}

df_together <- create_source_df(list_x)


# # funkcja do tworzenia data framu
# equipment <- map(list_x, str_extract, pattern = "(.+) \\(", group = 1)
# df_equipment <- 
#   do.call("rbind", map2(.x = equipment, .y = 1:3437, .f = create_special_df, nazwa = "source"))
# liczba <- map(list_x, str_extract, pattern = "liczba: (\\d+)", group = 1)
# df_liczba <- 
#   do.call("rbind", map2(.x = liczba, .y = 1:3437, .f = create_special_df, nazwa = "liczba"))
# state <- map(list_x, str_extract, pattern = "w użyciu|nieużywane")
# df_state <- 
#   do.call("rbind", map2(.x = state, .y = 1:3437, .f = create_special_df, nazwa = "stan"))
# CWU <- map(list_x, str_detect, pattern = "ogrzewanie wody")
# df_CWU <- 
#   do.call("rbind", map2(.x = CWU, .y = 1:3437, .f = create_special_df, nazwa = "ogrzewanie_wody"))
# centralne <- map(list_x, str_detect, pattern = "ogrzewanie centralne")
# df_centralne <- 
#   do.call("rbind", map2(.x = centralne, .y = 1:3437, .f = create_special_df, nazwa = "ogrzewanie_centralne"))
# 
# 
# df_together <- 
#   cbind(df_equipment,
#         df_liczba[,-2,drop = FALSE], 
#         df_state[,-2,drop = FALSE],
#         df_CWU[,-2,drop = FALSE],
#         df_centralne[,-2,drop = FALSE])


df_together <- 
  df_together %>%
  left_join(half_way_ceeb, by = "id", multiple = "all")
df_together$Typy_budynków_dla_deklaracji_B <- 
  ifelse(df_together$Typy_budynków_dla_deklaracji_B == ";", NA,df_together$Typy_budynków_dla_deklaracji_B)
df_together <- df_together %>% select(!(32:39))
df_together <- 
  df_together %>% 
  mutate(Klasa_kotłów_na_paliwo_stałe = 
           ifelse(source %in% c("Kocioł na paliwo stałe - pod. automatyczne",
                                                      "Kocioł na paliwo stałe - pod. ręczne"),
                  Klasa_kotłów_na_paliwo_stałe, NA))




##########
readr::write_csv(df_together, file = "/home/pstapyra/Documents/Zefir/ceeb_repair/Results/koszmarne_urzadzenia.csv")
# openxlsx::write.xlsx(df_together, file = "/home/pstapyra/Documents/Zefir/ceeb_repair/Results/urządzenia.xlsx")
# openxlsx::write.xlsx(half_way_ceeb, file = "/home/pstapyra/Documents/Zefir/ceeb_repair/Results/deklaracje.xlsx")

### Są dwa adresy, które mają dwa numery porządkowe 
# 792 (nowa liczba urządzeń = połowa) oraz 2714 (tutaj sprawa bardziej skomplikowana, bo jest jedno urządzenie)




# Ręczna korekta - wartości zmiennych są pomieszane (to są rekordy bez żródła?)
# 379  380  382  383  398  408  412  423  427  459  466  467  483  565  571  624  627  637  644  667  673  677
# 678  688  693  698  699  700  704  709  710  718  721  778  779  839  840  846  858  865  869  882 1557 2575
# 2583 3181 3435



