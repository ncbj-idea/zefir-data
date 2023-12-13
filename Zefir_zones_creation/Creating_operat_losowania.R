library(tidyverse)


# Global variable ---------------------------------------------------------

path_to_data <- "/home/pstapyra/Downloads/ceeb_ready_to_go.xlsx"
path_to_bdot <- "/home/pstapyra/Downloads//bdot_without_public + zabytki.xlsx"

# Processing --------------------------------------------------------------


zrewidowany <- 
  readxl::read_xlsx(path_to_data, guess_max = 20000)
bdot <- readxl::read_xlsx(path_to_bdot)
zrewidowany <- 
  subset(zrewidowany, !is.na(bdot_key) & !is.na(pow_uzytkowa_m2))

# tam gdzie są urządzenia sieciowe to jest możliwość przyłączenia
zrewidowany$heat_connected <- 
  ifelse(!is.na(zrewidowany$centralne) & 
           (zrewidowany$centralne == "Miejska sieć ciepłownicza" | zrewidowany$cwu == "Miejska sieć ciepłownicza"),
         TRUE, zrewidowany$heat_connected)
zrewidowany$gas_connected <- 
  ifelse(!is.na(zrewidowany$centralne) & 
           (zrewidowany$centralne == "Kocioł gazowy" | zrewidowany$cwu == "Kocioł gazowy"),
         TRUE, zrewidowany$gas_connected)


# wszyscy mają możliwość podłączenia do gazu, ale nie wszyscy do sieci ceipłowniczej
# niestety nie można oograniczyć heat_connected tylko do tych co mają teraz sieć ciepłowniczą
sum(zrewidowany$heat_connected)/nrow(zrewidowany)
zrewidowany %>%
  group_by(heat_connected) %>%
  summarise(prop = sum(pow_uzytkowa_m2)/sum(zrewidowany$pow_uzytkowa_m2))

sum(zrewidowany$gas_connected)/nrow(zrewidowany)
zrewidowany %>%
  group_by(gas_connected) %>%
  summarise(prop = sum(pow_uzytkowa_m2)/sum(zrewidowany$pow_uzytkowa_m2))
bdot %>%
  filter(!is.na(pow_uzytkowa_m2)) %>%
  group_by(gas_connected) %>%
  summarise(prop = sum(pow_uzytkowa_m2)/sum(bdot$pow_uzytkowa_m2, na.rm = TRUE))


# Remove_trash_zones ------------------------------------------------------

ceeb_A <- 
  zrewidowany %>% 
  filter(
    is.na(Typ_deklaracji), 
    kategoria_funkcjonalna_top_down != "Budynki publiczne")
A_wtih_trash <- 
  zrewidowany %>% 
  filter(
    Typ_deklaracji == "A", 
    kategoria_funkcjonalna_top_down != "Budynki publiczne")


x <- 
  A_wtih_trash %>%
  group_by(centralne, cwu, gas_connected,kategoria_funkcjonalna_top_down) %>%
  summarise(suma_wag = sum(weight))

# opcjonalnie zmiana kolektory słoneczne na ogrzewanie elektryczne
A_wtih_trash$centralne <- 
  ifelse(A_wtih_trash$centralne == "Kolektory słoneczne", 
         "Ogrzewanie elektryczne", A_wtih_trash$centralne)
A_wtih_trash$cwu <- 
  ifelse(A_wtih_trash$cwu == "Kolektory słoneczne", 
         "Ogrzewanie elektryczne", A_wtih_trash$cwu)
x <- 
  A_wtih_trash %>%
  group_by(centralne, cwu, gas_connected,kategoria_funkcjonalna_top_down) %>%
  summarise(suma_wag = sum(weight))

# Zmiana cwu na co jeżeli spełnia warunki (warunek trzeba zmienić na procent, żeby było
# skalowalne)
trash_zones <- 
  A_wtih_trash %>% 
  group_by(centralne, cwu, gas_connected, kategoria_funkcjonalna_top_down) %>% 
  summarise(suma_wag = sum(weight)) %>%
  filter(suma_wag <= 100) %>% 
  mutate(new_cwu = centralne)

A_wtih_trash <- 
  A_wtih_trash %>%
  left_join(trash_zones, 
            by = c("centralne", "cwu", "gas_connected",
                   "kategoria_funkcjonalna_top_down")) %>%
  mutate(cwu = ifelse(!is.na(new_cwu), new_cwu, cwu)) %>%
  select(!c(new_cwu, suma_wag))

x <- 
  A_wtih_trash %>%
  group_by(centralne, cwu, gas_connected,kategoria_funkcjonalna_top_down) %>%
  summarise(suma_wag = sum(weight))



# jeżeli mocno śmieciowa strefa waga <= 10 to zmiana możliwości przyłączeniowych
# na drugą wartość pod warunkiem, że to coś da, tj. grupa z przeciwną wartością
# występuje - do korekty, w rybniku nie wysępuje 
trash_zones <- 
  A_wtih_trash %>% 
  group_by(centralne, cwu, gas_connected, kategoria_funkcjonalna_top_down) %>% 
  summarise(suma_wag = sum(weight)) %>%
  filter(suma_wag <= 10) %>% 
  mutate(new_connected = ifelse(gas_connected == 1, FALSE, TRUE))

A_wtih_trash <- 
  A_wtih_trash %>%
  left_join(trash_zones, 
            by = c("centralne", "cwu", "gas_connected",
                   "kategoria_funkcjonalna_top_down")) %>%
  mutate(gas_connected = ifelse(!is.na(new_connected), new_connected, gas_connected)) %>%
  select(!c(new_connected,suma_wag))

x <- 
  A_wtih_trash %>%
  group_by(centralne, cwu, gas_connected,kategoria_funkcjonalna_top_down) %>%
  summarise(suma_wag = sum(weight))

# czasmi trzeba ręcznie zmienić edge case
# A_wtih_trash$heat_connected[
#   A_wtih_trash$centralne == "Ogrzewanie elektryczne" & 
#     A_wtih_trash$cwu == "Ogrzewanie elektryczne"
# ] <- TRUE
# A_wtih_trash$kategoria_funkcjonalna_top_down[
#   A_wtih_trash$centralne == "Ogrzewanie elektryczne" & 
#     A_wtih_trash$cwu == "Ogrzewanie elektryczne"
# ] <- "Budynki mieszkalne jednorodzinne"
# 
# x <- 
#   A_wtih_trash %>%
#   group_by(centralne, cwu, heat_connected,kategoria_funkcjonalna_top_down) %>%
#   summarise(suma_wag = sum(weight))


## te wszystkie operacje na końcu wymagają, ze trzeba zrobić podsumowanie 
# w wartstwach, w którcch będzie losowanie
# jeżeli nrow(wyrażenie ponizej) == nrow(A_with_trash) to żadne korekty nie są 
# potrzebne
x <- 
  A_wtih_trash %>%
  group_by(bdot_key, centralne, cwu, heat_connected,kategoria_funkcjonalna_top_down)


operat_losowania_A <- 
  rbind(A_wtih_trash, ceeb_A)


# Budynki typu B ----------------------------------------------------------

ceeb <- 
  zrewidowany %>% filter(!is.na(centralne))

x <- split(ceeb, ceeb$split_var)

# przypadek nr 1 jest tylko deklaracja typu B na dany adres + modyfikacja jeżeli
# budynek jest mieszkalany (wniosek nr 3 -wnioski są w skrypcie get_idea_abaout_non_living-, 
# tj. budynek dostaje tylko jedno piętro albo jeżeli
# ma tylko jedno to połowę budynku)
only_b <- map(x, ~prod(ifelse(unique(.x$Typ_deklaracji) == "B", TRUE, FALSE)))
only_b <- as.logical(unname(unlist(only_b)))

first_part <- do.call("rbind", x[only_b])
first_part <- as_tibble(first_part)
first_part <- 
  first_part %>%
  mutate(pow_uzytkowa_m2 = 
           ifelse(kategoria_funkcjonalna_top_down != "Budynki publiczne",
                  ifelse(liczba_kondygnacji == 1,
                         pow_obrysu_m2*0.5,
                         pow_obrysu_m2),
                  pow_uzytkowa_m2))
first_part <- 
  first_part %>%
  mutate(korekta_wag = 
           ifelse(kategoria_funkcjonalna_top_down != "Budynki publiczne",
                  "tak", "nie"))


# przypadek nr 2 wchodzą budynki z wnioski nr 1
turystyka <- c("dom wypoczynkowy", "hotel", "pensjonat", "sanatorium")
second_part <- 
  ceeb %>%
  filter(funkcja_szczegolowa_budynku %in% turystyka) %>%
  filter(Typ_deklaracji == "A") %>%
  mutate(korekta_wag = "nie")

# przypadek nr 3 wchodzą budynki z wniosku nr 2
a_and_b <- 
  map(x, ~ifelse(length(unique(.x$Typ_deklaracji)) == 2 & 
                   unique(.x$kategoria_funkcjonalna_top_down) !="Budynki publiczne"  ,
                 TRUE,FALSE))
a_and_b <- as.logical(unname(unlist(a_and_b)))
third_part <- do.call("rbind", x[a_and_b])
third_part <- as_tibble(third_part)
third_part <- subset(third_part, Typ_deklaracji == "B")
third_part <- 
  third_part %>%
  mutate(pow_uzytkowa_m2 = ifelse(liczba_kondygnacji == 1,
                                  pow_obrysu_m2*0.5,
                                  pow_obrysu_m2))
third_part <- 
  third_part %>%
  mutate(korekta_wag = "tak")


# przypadek nr 4 - dwie deklaracje ale budynek jest niemieszkalny
a_and_b_part2 <- 
  map(x, ~ifelse(length(unique(.x$Typ_deklaracji)) == 2 & 
                   unique(.x$kategoria_funkcjonalna_top_down) =="Budynki publiczne"  ,
                 TRUE,FALSE))
a_and_b_part2 <- as.logical(unname(unlist(a_and_b_part2)))
fourth_part <- do.call("rbind", x[a_and_b_part2])
fourth_part <- as_tibble(fourth_part)
fourth_part <- subset(fourth_part, Typ_deklaracji == "B")
fourth_part <- 
  fourth_part %>%
  mutate(korekta_wag = "nie")

### wyłączenie powtarzających się rekordów
sum(first_part$id %in% second_part$id)
sum(first_part$id %in% third_part$id)
sum(first_part$id %in% fourth_part$id)
sum(second_part$id %in% third_part$id)
sum(second_part$id %in% fourth_part$id) 
sum(third_part$id %in% fourth_part$id)


operat_losowania_B <- 
  rbind(first_part, second_part[!second_part$id %in% fourth_part$id,], third_part, fourth_part)

operat_losowania_B$korekta_wag <- NULL


operat_losowania_B$heat_connected <- 
  ifelse(operat_losowania_B$centralne == "Miejska sieć ciepłownicza"|operat_losowania_B$cwu=="Miejska sieć ciepłownicza", 
         TRUE,operat_losowania_B$heat_connected)
operat_losowania_B$gas_connected <- 
  ifelse(operat_losowania_B$centralne == "Kocioł gazowy"|operat_losowania_B$cwu=="Kocioł gazowy", 
         TRUE,operat_losowania_B$gas_connected)

# usunięcie śmieciowych stref jeżeli trzeba
trash_zones <- 
  operat_losowania_B %>% 
  count(centralne, cwu, gas_connected) %>% 
  filter(n <= 40) %>% 
  mutate(new_cwu = centralne)

operat_losowania_B <- 
  operat_losowania_B %>%
  left_join(trash_zones, 
            by = c("centralne", "cwu", "gas_connected")) %>%
  mutate(cwu = ifelse(!is.na(new_cwu), new_cwu, cwu)) %>%
  select(!c(new_cwu, n))
operat_losowania_B$kategoria_funkcjonalna_top_down <- "Budynki publiczne"

x <- 
  operat_losowania_B %>%
  group_by(centralne, cwu, gas_connected) %>%
  count(gas_connected, centralne, cwu)


operat_losowania <- 
  rbind(operat_losowania_A %>% mutate(losowania = "A"), 
        operat_losowania_B%>% mutate(losowania = "B"))

x <- 
  operat_losowania %>%
  group_by(centralne, cwu, gas_connected, kategoria_funkcjonalna_top_down) %>%
  summarise(suma_wag = sum(weight))
## nie wiedzieć czemu mamy jeden przypadek


# Dodanie do operatu losowania bdot mieszkalny ----------------------------


bdot <- 
  bdot %>%
  filter(!id %in% operat_losowania$id & kategoria_funkcjonalna_top_down != "Budynki publiczne") %>%
  mutate(losowania = "A")
operat_losowania <- 
  operat_losowania %>%
  bind_rows(bdot)


### Zabytki
zabytki <- 
  operat_losowania %>% filter(zabytek == 1)
nie_zabytki <- 
  operat_losowania %>% filter(zabytek == 0)
trash_zones <- 
  zabytki %>% 
  group_by(centralne, cwu, gas_connected, kategoria_funkcjonalna_top_down) %>% 
  summarise(suma_wag = sum(weight)) %>%
  filter(suma_wag <= 30) %>% 
  mutate(new_cwu = centralne)

zabytki <- 
  zabytki %>%
  left_join(trash_zones, 
            by = c("centralne", "cwu", "gas_connected",
                   "kategoria_funkcjonalna_top_down")) %>%
  mutate(cwu = ifelse(!is.na(new_cwu), new_cwu, cwu)) %>%
  select(!c(new_cwu, suma_wag))
operat_losowania <- 
  rbind(zabytki, nie_zabytki)

x <- 
  operat_losowania %>%
  group_by(centralne, cwu, gas_connected, kategoria_funkcjonalna_top_down, zabytek) %>%
  summarise(suma_wag = sum(weight))


# Zapisanie danych --------------------------------------------------------


openxlsx::write.xlsx(
  operat_losowania,
  "/home/pstapyra/Downloads/operat_losowania.xlsx"
)








