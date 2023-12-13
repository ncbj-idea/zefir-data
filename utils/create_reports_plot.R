library(tidyverse)
library(ggthemes)

mpec <- readxl::read_excel("/home/pstapyra/Downloads/mpec_merged_bdot_poprawiony.xlsx",
                           sheet = 2)
bei <- readxl::read_excel("/home/pstapyra/Downloads/STREFY_bei_join_bdot.xlsx",
                          sheet = 2)
bei_source <-
  readxl::read_excel("/home/pstapyra/Downloads/STREFY_bei_join_bdot.xlsx",
                     sheet = 1)
public <- readxl::read_excel("/home/pstapyra/Downloads/public_estimation.xlsx")
living <- readxl::read_excel("/home/pstapyra/Documents/Forum Energii/Data/Włocławek/Oszacowanie_stref/OszacowanieA.xlsx",
                             sheet = 2)

bei_source <-
  bei_source %>%
  filter(usable_area != 0) %>%
  mutate(Zefir_termo = str_remove(building_type, "PUBLIC_")) %>% 
  group_by(now_tech.heat, Zefir_termo) %>%
  summarise(Powierzchnia = sum(usable_area))

mpec <- 
  mpec %>%
  select(Powierzchnia, Building_type, Klasa_termo) %>% 
  filter(Klasa_termo != "BRAK" & !is.na(Building_type)) %>%
  mutate(Rodzaj_budynku = ifelse(Building_type == "Budynki mieszkalne jednorodzinne",
                                 "Jednorodzinne",
                                 ifelse(Building_type == "Budynki publiczne",
                                        "Niemieszkalne", "Wielorodzinne"))) %>%
  mutate(Zefir_termo = case_when(
    Klasa_termo == "A" ~ "AB",
    Klasa_termo == "B" ~ "AB",
    Klasa_termo == "C" ~ "C",
    Klasa_termo == "D" ~ "D",
    Klasa_termo == "E" ~ "EF",
    Klasa_termo == "F" ~ "EF",
    TRUE ~ NA_character_
  ))



bei <- 
  bei %>%
  filter(!is.na(Powierzchnia)) %>%
  select(Klasa_termo, Powierzchnia) %>%
  mutate(Rodzaj_budynku = "Niemieszkalne") %>%
  mutate(Zefir_termo = case_when(
    Klasa_termo == "A" ~ "AB",
    Klasa_termo == "B" ~ "AB",
    Klasa_termo == "C" ~ "C",
    Klasa_termo == "D" ~ "D",
    Klasa_termo == "E" ~ "EF",
    Klasa_termo == "F" ~ "EF",
    TRUE ~ NA_character_
  ))

public$Rodzaj_budynku <- "Niemieszkalne"
public <- 
  public %>%
  mutate(Zefir_termo = case_when(
    energy_class == "A" ~ "AB",
    energy_class == "B" ~ "AB",
    energy_class == "C" ~ "C",
    energy_class == "D" ~ "D",
    energy_class == "E" ~ "EF",
    energy_class == "F" ~ "EF",
    TRUE ~ NA_character_
  ))

living <- 
  living %>%
  mutate(Rodzaj_budynku = ifelse(str_detect(Rodzaj_budynku, pattern = "jednorodzinne"), "Jednorodzinne", "Wielorodzinne")) %>%
  mutate(Zefir_termo = case_when(
    energy_class == "A" ~ "AB",
    energy_class == "B" ~ "AB",
    energy_class == "C" ~ "C",
    energy_class == "D" ~ "D",
    energy_class == "E" ~ "EF",
    energy_class == "F" ~ "EF",
    TRUE ~ NA_character_
  ))


termo <- 
  rbind(
    bei %>% group_by(Klasa_termo, Rodzaj_budynku) %>% summarise(Powierzchnia = sum(Powierzchnia)) %>% mutate(Rodzaj = "Dane UM"),
    living %>% rename(Klasa_termo = energy_class) %>% group_by(Klasa_termo, Rodzaj_budynku) %>% summarise(Powierzchnia = sum(Freq)) %>% mutate(Rodzaj = "Inwentaryzacja"),
    mpec %>% group_by(Klasa_termo, Rodzaj_budynku) %>% summarise(Powierzchnia = sum(Powierzchnia)) %>% mutate(Rodzaj = "MPEC"),
    public %>% rename(Klasa_termo = energy_class) %>%  group_by(Klasa_termo, Rodzaj_budynku) %>% summarise(Powierzchnia = sum(Powierzchnia)) %>% mutate(Rodzaj = "Inwentaryzacja")
  )

cieplo <- 
  rbind(
    bei_source %>% rename(Ogrzewanie = now_tech.heat) %>% group_by(Ogrzewanie,Zefir_termo) %>% summarise(Powierzchnia = sum(Powierzchnia)) %>% mutate(Rodzaj = "Dane UM", Rodzaj_budynku = "Niemieszkalne"),
    living %>% rename(Ogrzewanie = centralne) %>% group_by(Ogrzewanie, Rodzaj_budynku,Zefir_termo) %>% summarise(Powierzchnia = sum(Freq)) %>% mutate(Rodzaj = "Inwentaryzacja") %>%
      mutate(Ogrzewanie = ifelse(Ogrzewanie == "Miejska sieć ciepłownicza", "Zazamcze", Ogrzewanie)),
    mpec %>% mutate(Ogrzewanie = "MPEC") %>% group_by(Ogrzewanie, Rodzaj_budynku,Zefir_termo) %>% summarise(Powierzchnia = sum(Powierzchnia)) %>% mutate(Rodzaj = "MPEC"),
    public %>% rename(Ogrzewanie = centralne) %>%  group_by(Ogrzewanie, Rodzaj_budynku,Zefir_termo) %>% summarise(Powierzchnia = sum(Powierzchnia)) %>% mutate(Rodzaj = "Inwentaryzacja") %>% 
      mutate(Ogrzewanie = ifelse(Ogrzewanie == "Miejska sieć ciepłownicza", "Zazamcze", Ogrzewanie))
  )

cieplo <- 
  cieplo %>% 
  mutate(Ogrzewanie = case_when(
    Ogrzewanie == "KOCIOL_GAZOWY" ~ "Kocioł gazowy kondensacyjny",
    Ogrzewanie == "MPEC_WLOCLAWEK" ~ "MPEC",
    Ogrzewanie == "PIEC_WEGLOWY_STAREGO_TYPU" ~ "Kocioł na paliwo stałe starego typu",
    Ogrzewanie == "Kocioł gazowy" ~ "Kocioł gazowy kondensacyjny",
    Ogrzewanie == "Zazamcze" ~ "Zazamcze",
    Ogrzewanie == "Ogrzewanie elektryczne" ~ "Ogrzewanie elektryczne",
    Ogrzewanie == "Pompa ciepła" ~ "Pompa ciepła",
    Ogrzewanie == "boiler_new" ~ "Kocioł na paliwo stałe nowego typu",
    Ogrzewanie == "boiler_old" ~ "Kocioł na paliwo stałe starego typu",
    Ogrzewanie == "MPEC" ~ "MPEC",
    TRUE ~ NA_character_
  ))

########## Wykresy

new_colors <- c("A" = "#1a9850",
                "B" = "#a6d96a",
                "C" = "#ffffbf",
                "D" = "#fdae61",
                "E" = "#f46d43",
                "F" = "#a50026")
termo %>%
  mutate(Powierzchnia = Powierzchnia/1000) %>% 
  ggplot(aes(x = Klasa_termo, y = Powierzchnia, fill = Klasa_termo)) +
  geom_col() +
  scale_fill_manual(values = new_colors)+
  facet_grid(Rodzaj~Rodzaj_budynku, scales = "free") +
  theme_few() +
  scale_y_continuous(expand = expansion(mult=c(0,0.1))) +
  ggtitle("Stan budynków we Włocławku", subtitle = "ze względu na źródło danych") +
  ylab(bquote('Powierzchnia w tys.'~m^2)) +
  guides(fill=guide_legend(title="Klasa termomodernizacji")) +
  xlab("Klasa termomodernizacji")

my_colors <- c("Inwentaryzacja" = "#b2df8a","Dane UM" = "#decbe4",MPEC = "#b3cde3")
termo %>%
  mutate(Powierzchnia = Powierzchnia/1000) %>% 
  ggplot(aes(x = Klasa_termo, y = Powierzchnia, fill = Rodzaj)) +
  geom_col() +
  scale_fill_manual(values = my_colors)+
  scale_y_continuous(expand = expansion(mult=c(0,0.1))) +
  facet_wrap(~Rodzaj_budynku, scales = "fixed") +
  theme_few() +
  guides(fill=guide_legend(title="Źródło danych")) +
  ggtitle("Stan budynków we Włocławku") +
  ylab(bquote('Powierzchnia w tys.'~m^2)) +
  xlab("Klasa termomodernizacji")
  


# cieplo %>%
#   mutate(Powierzchnia = Powierzchnia/1000) %>% 
#   ggplot(aes(x = Rodzaj_budynku, y = Powierzchnia)) +
#   geom_col() +
#   facet_wrap(~Ogrzewanie, scales = "free") +
#   theme_few() +
#   ggtitle("Stan budynków we Włocławku") +
#   ylab("Powierzchnia w tys. m2") +
#   xlab("Klasa termomodernizacji")


# new_colors <- c("Kocioł gazowy kondensacyjny" = "#F6EA53",
#                 "MPEC" = "#85599B",
#                 "Kocioł na paliwo stałe starego typu" = "#424242",
#                 "Zazamcze" = "#",
#                 "Ogrzewanie elektryczne" = "#005AAA",
#                 "Pompa ciepła" = "#DDE1F3",
#                 "Kocioł na paliwo stałe nowego typu" = "#606060")

cieplo %>%
  group_by(Ogrzewanie, Zefir_termo,Rodzaj_budynku) %>%
  summarise(Powierzchnia = sum(Powierzchnia)) %>%
  mutate(Powierzchnia = Powierzchnia/1000) %>% 
  ggplot(aes(x = Zefir_termo, y = Powierzchnia, fill = Ogrzewanie)) +
  geom_col() +
  scale_fill_brewer(type = "qual", palette = 7, direction = 1) +
  # scale_fill_brewer(palette = "Paired") + 
  # paletteer::scale_fill_paletteer_d("colorBlindness::PairedColor12Steps")+
  # viridis::scale_fill_viridis(discrete = TRUE, option = "G") +
  facet_wrap(~Rodzaj_budynku, scales = "fixed") +
  theme_few() +
  scale_y_continuous(expand = expansion(mult=c(0,0.05))) +
  ggtitle("Włocławek") +
  ylab(bquote('Powierzchnia w tys.'~m^2)) +
  xlab("Klasa termomodernizacji")



termo %>% 
  group_by(Rodzaj_budynku, Klasa_termo) %>% 
  summarise(Powierzchnia = sum(Powierzchnia)) %>%
  mutate(Powierzchnia = Powierzchnia/10^3) %>% 
  ggplot(aes(x = Rodzaj_budynku, fill = Klasa_termo, y = Powierzchnia)) +
  geom_col() +
  theme_bw() + 
  scale_fill_manual(values = new_colors)+
  scale_y_continuous(expand = expansion(mult=c(0,0.05))) +
  guides(fill=guide_legend(title="Klasa termomodernizacji")) + 
  ggtitle("Termomodernizacja we Włocławku") +
  ylab(bquote('Powierzchnia w tys.'~m^2)) +
  xlab("Rodzaj budynku")

termo %>% 
  group_by(Rodzaj_budynku, Klasa_termo) %>% 
  summarise(Powierzchnia = sum(Powierzchnia)) %>%
  ungroup() %>% 
  mutate(Powierzchnia = Powierzchnia/sum(Powierzchnia)) %>% 
  ggplot(aes(x = Rodzaj_budynku, fill = Klasa_termo, y = Powierzchnia)) +
  geom_col() +
  theme_bw() + 
  scale_fill_manual(values = new_colors)+
  scale_y_continuous(expand = expansion(mult=c(0,0)), labels = scales::percent) +
  guides(fill=guide_legend(title="Klasa termomodernizacji")) + 
  ggtitle("Termomodernizacja we Włocławku") +
  ylab("Powierzchnia użytkowa") +
  xlab("Rodzaj budynku")

termo %>% 
  group_by(Rodzaj_budynku, Klasa_termo) %>% 
  summarise(Powierzchnia = sum(Powierzchnia)) %>%
  ungroup() %>% 
  group_by(Rodzaj_budynku) %>%
  mutate(Powierzchnia = Powierzchnia/sum(Powierzchnia)) %>% 
  ungroup() %>% 
  ggplot(aes(x = Rodzaj_budynku, fill = Klasa_termo, y = Powierzchnia)) +
  geom_col() +
  theme_bw() + 
  scale_fill_manual(values = new_colors)+
  scale_y_continuous(expand = expansion(mult=c(0,0)), labels = scales::percent) +
  guides(fill=guide_legend(title="Klasa termomodernizacji")) + 
  ggtitle("Termomodernizacja we Włocławku") +
  ylab("Powierzchnia użytkowa") +
  xlab("Rodzaj budynku")

