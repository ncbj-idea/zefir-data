library(tidyverse)


path_to_urzadzenia <- 
  "/home/pstapyra/Documents/Forum Energii/Data/Włocławek/Walidacja_danych/CEEB/Nowy ceeb/urzadzenia.csv"
path_to_klasy <- 
  "/home/pstapyra/Documents/Forum Energii/Data/Włocławek/Walidacja_danych/CEEB/Nowy ceeb/klasy.csv"
path_to_save <- 
  "/home/pstapyra/Documents/Forum Energii/Data/Włocławek/Walidacja_danych/CEEB/Nowy ceeb/klasy_i_urzadzenia.csv"

klasy <- read_csv(path_to_klasy)
urzadzenia <- read_csv(path_to_urzadzenia)

colnames(klasy) <- str_replace_all(colnames(klasy), pattern = " ", replacement = "_")
colnames(urzadzenia) <- str_replace_all(colnames(urzadzenia), pattern = " ", replacement = "_")

colnames(klasy)[which(colnames(klasy) == "Numer_domu")] <- "Numer_budynku"


klasy <- 
  klasy %>% 
  select(Typ_deklaracji, Ulica, Numer_budynku, Klasa_kotła) %>%
  na.omit() %>%
  count(Typ_deklaracji, Ulica, Numer_budynku, Klasa_kotła) %>%
  pivot_wider(names_from = "Klasa_kotła", values_from = "n")

razem <- 
  urzadzenia %>%
  left_join(klasy, join_by(Typ_deklaracji, Ulica, Numer_budynku))

write_csv2(razem, path_to_save)





