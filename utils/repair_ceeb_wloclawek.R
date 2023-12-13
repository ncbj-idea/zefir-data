library(tidyverse)


# Modify as text ----------------------------------------------------------

ceeb <- read_lines("/home/pstapyra/Downloads/202303_CEEB.csv")
ceeb <- str_remove_all(ceeb,";\\d{2}\\.\\d{2}\\.\\d{4}(.)+")
ceeb <- c(
  str_remove_all(ceeb[1], ";Data utworzenia deklaracji(.)+"),
  ceeb[-1])

ceeb_record <- 
  gsub("(?:\\G(?!^)|Włocławek; )(?:(?!Włocławek; |;Włocławek).)*?\\K;(?=.*;Włocławek)", 
       " ", ceeb, perl=TRUE)

ceeb_adresy <- 
  str_extract(ceeb_record[-1], pattern = "(.+);(Tak|Nie);(A|B)", group = 1)
ceeb_nie_adresy <- 
  str_extract(ceeb_record[-1], pattern = "(Tak|Nie);(A|B).+")

ceeb_adresy <- 
  c(
  c("Adres;Gmina;Miejscowość;Ulica;Numer;"),
  ceeb_adresy
  )
ceeb_nie_adresy <- 
  c(
    str_remove_all(ceeb[1], "Adres;Gmina;Miejscowość;Ulica;Numer;"),
    ceeb_nie_adresy
  )

write(ceeb_adresy, "/home/pstapyra/Downloads/ceeb_adresy.csv")
write(ceeb_nie_adresy, "/home/pstapyra/Downloads/ceeb_nie_adresy.csv")


# Modify as pandas --------------------------------------------------------

ceeb_adresy <- read_csv2("/home/pstapyra/Documents/Forum Energii/Data/Włocławek/Walidacja_danych/CEEB/Stary ceeb/ceeb_adresy.csv")
ceeb_nie_adresy <- read_csv2("/home/pstapyra/Documents/Forum Energii/Data/Włocławek/Walidacja_danych/CEEB/Stary ceeb/ceeb_nie_adresy.csv")


colnames(ceeb_adresy) <- str_replace_all(colnames(ceeb_adresy), pattern = " ",
                                     replacement = "_")
colnames(ceeb_nie_adresy) <- str_replace_all(colnames(ceeb_nie_adresy), pattern = " ",
                                         replacement = "_")

rows_remover <- 
  which(!is.na(ceeb_nie_adresy$Zainstalowane_źródło_ciepła) &
          ceeb_nie_adresy$Typ_deklaracji == "A")
ceeb_nie_adresy <- ceeb_nie_adresy[rows_remover,]
ceeb_adresy <- ceeb_adresy[rows_remover,]


# Clean nie_adres ---------------------------------------------------------


move_cols_A <- function(data) {
  if(data$Zainstalowane_źródło_ciepła == "nie") {
    data[,5:16] <- data[,4:15]
    data$Zainstalowane_źródło_ciepła <- NA
  }
  if(str_detect(data$Klasa_kotłów_na_paliwo_stałe, pattern = "Drewno|Węgiel")
     & !is.na(data$Klasa_kotłów_na_paliwo_stałe)){
    data[,6:16] <- data[,5:15]
    data$Klasa_kotłów_na_paliwo_stałe <- NA
  }
  if(data$Klasa_kotłów_na_paliwo_stałe %in% c("tak","nie")) {
    data[,7:16] <- data[,5:14]
    data$Klasa_kotłów_na_paliwo_stałe <- NA
    data$Rodzaj_stosowanych_paliw_w_kotłach_na_paliwo_stałe <- NA
  }
  if(data$Rodzaj_stosowanych_paliw_w_kotłach_na_paliwo_stałe %in% c("tak","nie")) {
    data[,7:16] <- data[,6:15]
    data$Rodzaj_stosowanych_paliw_w_kotłach_na_paliwo_stałe <- NA
  
  }
  if(data$Typy_budynków_dla_deklaracji_B %in% c("tak","nie")) {
    data[,14:16] <- data[,11:13]
    data$Typy_budynków_dla_deklaracji_B <- NA
    data$Liczba_lokali_mieszkalnych <- NA
    data$Liczba_lokali_zbiorowego_zamieszkania <- NA
  }
  if(!is.na(data$Typy_budynków_dla_deklaracji_B)) {
    data[,12:16] <- data[,11:15]
    data$Typy_budynków_dla_deklaracji_B <- NA
  }
  if(data$Liczba_lokali_mieszkalnych %in% c("tak","nie")) {
    data[,14:16] <- data[,12:14]
    data$Liczba_lokali_mieszkalnych <- NA
  }
  if(data$Liczba_lokali_zbiorowego_zamieszkania %in% c("tak","nie")) {
    data[,14:16] <- data[,13:15]
    data$Liczba_lokali_zbiorowego_zamieszkania <- NA
  }
  if(str_detect(data$Liczba_lokali_objętych_deklaracją, pattern = "[^\\d]", negate = FALSE) & 
     !is.na(data$Liczba_lokali_objętych_deklaracją)) {
    data[,16] <- data[,15]
    data$Liczba_lokali_objętych_deklaracją <- NA
  }
  data
}

ceeb_nie_adresy2 <- map_df(ceeb_nie_adresy, str_remove_all, ";{3,}")
ceeb_list <- split(ceeb_nie_adresy2, 1:nrow(ceeb_nie_adresy2))
ceeb_list <- map(ceeb_list, move_cols_A)
ceeb <- do.call("rbind", ceeb_list)


# Merge data -------------------------------------------------------------


ceeb_adresy$...6 <- NULL

razem <- cbind(ceeb_adresy, ceeb)
razem <- subset(razem, Adres == "Włocławek")

write_csv2(razem, "/home/pstapyra/Documents/Forum Energii/Data/Włocławek/Walidacja_danych/CEEB/ceebA_naprawiony.csv")




