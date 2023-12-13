library(tidyverse)
source("clean_address_function.R")

# Global variable ---------------------------------------------------------

path_to_load <- "/home/pstapyra/Documents/NCBIR/Walidacja/ceeb.xlsx"
path_to_bdot <- "/home/pstapyra/Documents/NCBIR/bdot/buildings_report_WARSZAWA_Z_SIECIAMI.xlsx"
path_to_save_normal <- "/home/pstapyra/Downloads/ceeb_to_bdot.xlsx"
path_to_save_rewizja <- "/home/pstapyra/Downloads/ceeb_rewizja.xlsx"

adres_col <- NULL
numer_col <- "Numer"
ulica_col <- "Ulica"

# only for ceeb
required_colnames <- 
  c("Numery lokali mieszkalnych objętych deklaracją", "Liczba lokali objętych deklaracją",
    "Dotyczy wszystkich lokali mieszkalnych", "Liczba lokali zbiorowego zamieszkania",
    "Liczba lokali mieszkalnych", "Typy budynków dla deklaracji B", "Budynek zbiorowego zamieszkania",
    "Budynek wielorodzinny", "Budynek jednorodzinny", "Klasa kotłów na paliwo stałe", 
    "Zainstalowane źródło ciepła", "Typ deklaracji", "Numer", "Ulica")


# Load data ---------------------------------------------------------------

ceeb <- readxl::read_xlsx(path_to_load)
bdot <- readxl::read_xlsx(path_to_bdot)

### selection of streets which have numbers in its names (bdot)
bdot <- remove_abb(bdot, "ulica")
ulice <- unique(bdot$ulica)
street_with_number <- ulice[str_detect(ulice, pattern = "\\d")]

### selection of numer_porzadkowy  which have slasher in its names (bdot)
# and has other symbols
slasher_numer <- unique(bdot$numer_porzadkowy)
# numer_with_dash <- slasher_numer[str_detect(slasher_numer, "[^\\p{L}\\d]", negate = FALSE)]
numer_with_dash <- slasher_numer[str_detect(slasher_numer, "[-]", negate = FALSE)]
slasher_numer <- slasher_numer[str_detect(slasher_numer, "/", negate = FALSE)]


# test: do we have all columns
if(!(all(required_colnames %in% colnames(ceeb))|
   all(str_replace_all(required_colnames, pattern = " ", "_") %in% colnames(ceeb)))) {
  stop(
    paste("W pliku CEEB brakuje następujących kolumn: ",
          paste(required_colnames[!required_colnames %in% colnames(ceeb)], collapse = ", "), 
          ". W związku z tym użycie parsera nie jest możliwe.", sep = "")
  )
}


# Cleaning ceeb -----------------------------------------------------------

# Make names synthetic
colnames(ceeb) <- gsub(pattern = " ", replacement = "_", colnames(ceeb))
# we cant use record with no vale in 'Zainstalowane_źródło_ciepła'
ceeb <- 
  subset(ceeb, !is.na(Numer) & !is.na(Zainstalowane_źródło_ciepła) &!is.na(Ulica))

# remove abbreviation in Ulica variable
ceeb <- remove_abb(ceeb, ulica_col)
ceeb$duplication_id <- NA
         
####### (1) Two steps to keep only real street (no number of building or flat) in ulica variable
# (a) move numbers, which arent part of street's names to numer varaible, only if numer is empty
# otherwise delete those nubers 
still_messy <- clean_street_name(data = ceeb, street_var = ulica_col, numer_var = numer_col, bdot_var = street_with_number)


###### (1.5) Oficyna case
still_messy <- oficyna_remover(still_messy, numer_var = numer_col, deklaracja = "Typ_deklaracji")


####### (2) working on numer variable
still_messy <- dzialka_remover(still_messy, numer_var = numer_col)
still_messy <- paranthesis_remover(still_messy, numer_var = numer_col)
still_messy <- with_number(still_messy, numer_var = numer_col)


#### split by " i " in numer variable
still_messy <- duplicated_by_and(still_messy, numer_var = numer_col, duplication_id)

#### (2) c.d.
still_messy <- remove_add_info(still_messy, numer_var = numer_col)

# chceck if there is some missing pattern
records_too_many_letter(still_messy, numer_var = numer_col)$trash_data %>% View()
still_messy <- records_too_many_letter(still_messy, numer_var = numer_col)$normal_data

# in bdot numer_porzadkowy there is no space in numer variable [WARNING: always check bdot]
bdot$numer_porzadkowy[str_detect(bdot$numer_porzadkowy, "\\s")]
still_messy[[numer_col]] <- str_remove_all(still_messy[[numer_col]], pattern = "\\s")

####### slasher_case
close_to_clean <- 
  slasher_case(still_messy, numer_col, "Numery_lokali_mieszkalnych_objętych_deklaracją", slasher_numer)


####### (4) remove some symbols in numer variable (list isnt complete)
close_to_clean[[numer_col]] <- str_remove_all(close_to_clean[[numer_col]], " |_|--|'|^-$|^,|\\s")


####### (5) duplicated by comma
# add new_variable which allow to make correction in liczba urządzeń i liczba mieszkań
# (by human) after duplication
close_to_clean <- duplicated_by_comma(close_to_clean, numer_col, duplication_id)


### Duplicate those records, which have symbol "-" it means the numer variable
# should be all symbols (letters or numbers) between left and right hand including
# bordering symbols only if "-" isn't occures in bdot numer_porzadkowy

# duplicated_by_dash(close_to_clean %>% filter(Numer== "107W-ZE"), numer_col, numer_with_dash, duplication_id)
ceeb_list <- duplicated_by_dash(close_to_clean, numer_col, numer_with_dash, duplication_id)
clean_ceeb <- 
  mieszkania_modification(ceeb_list$clean_ceeb, 
                          duplication_id = "duplication_id", 
                          all_in = "Dotyczy_wszystkich_lokali_mieszkalnych", 
                          BorA = "Typ_deklaracji", 
                          mieszkania = "Liczba_lokali_mieszkalnych", 
                          zbiorowe = "Liczba_lokali_zbiorowego_zamieszkania",
                          objete_mieszkania = "Liczba_lokali_objętych_deklaracją") 



openxlsx::write.xlsx(clean_ceeb, path_to_save_normal)
openxlsx::write.xlsx(ceeb_list$rewizja_ceeb, path_to_save_rewizja)



# Zabytki -----------------------------------------------------------------

zabytki <- readxl::read_xlsx("/home/pstapyra/Downloads/zabytki.xlsx")
zabytki_nowe <- divide_address(zabytki, "Adres (ulica, plac)", "Ulica", "Numer")
zabytki_nowe <- subset(zabytki_nowe, !is.na(Ulica))

# requirments for letter_or_number functions
zabytki_nowe$Numer <- str_replace_all(zabytki_nowe$Numer, pattern = "–", "-")
zabytki_nowe$Numer <- str_remove_all(zabytki_nowe$Numer, " |_|--|'|^-$|\\)|\\(")

### Review by human, edge case which is not worth to detect by regex
rewizja <- str_detect(zabytki_nowe$Numer, "[^\\w\\d-,]|kościół")
rewizja_df <- zabytki_nowe[rewizja,]
zabytki_nowe <- zabytki_nowe[!rewizja,]



zabytki_df <- zabytki_nowe[str_detect(zabytki_nowe$Numer, "-|,", negate = TRUE),]
zabytki_to_duplicated <- zabytki_nowe[str_detect(zabytki_nowe$Numer, "-", negate = FALSE),]
zabytki_to_duplicated_2 <- zabytki_nowe[str_detect(zabytki_nowe$Numer, ",", negate = FALSE),]

# Case "-"
list_to_duplicated <- split(zabytki_to_duplicated, 1:nrow(zabytki_to_duplicated))
repaired_df <- map(list_to_duplicated, .f = number_or_letter, "Numer")

# Case ","
list_to_duplicated_2 <- split(zabytki_to_duplicated_2, 1:nrow(zabytki_to_duplicated_2))
repaired_df_2 <- map(list_to_duplicated_2, .f = duplicated_by_comma, var_colon = "Numer")


clean_zabytki <- rbind(zabytki_df, 
                    do.call("rbind",
                            map(repaired_df,1)[!unlist(map(repaired_df,2))]),
                    do.call("rbind", repaired_df_2))
rewizja_zabytki <- 
  rbind(rewizja_df, 
        do.call("rbind",
                map(repaired_df,1)[unlist(map(repaired_df,2))]))

openxlsx::write.xlsx(rewizja_zabytki, "/home/pstapyra/Documents/Forum Energii/Data/Rybnik/zabytki_rewizja.xlsx")
openxlsx::write.xlsx(zabytki_nowe, "/home/pstapyra/Documents/Forum Energii/Data/Włocławek/zabytki.xlsx")



# Budynki dane od miasta :( -----------------------------------------------

budynki <- readxl::read_xlsx("/home/pstapyra/Downloads/BEI_Włocławek.xlsx", sheet = 1)
colnames(budynki) <- gsub(pattern = " ", replacement = "_", colnames(budynki))

budynki <- 
  subset(budynki, !is.na(adres))
budynki$Adres <- 
  str_remove(budynki$Adres, pattern = "\\d{2,}-\\d{2,}")
budynki$Adres <- 
  str_remove_all(budynki$Adres, pattern = ",|ul\\.")
budynki$Adres <- 
  str_remove(budynki$Adres, pattern = "Włocławek")
budynki$Adres <- 
  str_trim(budynki$Adres)

rewizja <- str_detect(budynki$Adres, pattern = regex("^[\\p{L}\\d\\s\\o.]+$", ignore_case = TRUE), negate = FALSE)
df_rewizja <- budynki[!rewizja,]
df_rewizja$Ulica <- NA
df_rewizja$Numer <- NA
df_budynki <- budynki[rewizja,]
df_budynki <- divide_address(df_budynki, "Adres", "Ulica", "Numer")
df_rewizja <- rbind(df_rewizja, subset(df_budynki, is.na(Numer)))
df_budynki <- subset(df_budynki, !is.na(Numer))

openxlsx::write.xlsx(df_budynki, "/home/pstapyra/Downloads/bei_need_bdot")
openxlsx::write.xlsx(df_rewizja, "/home/pstapyra/Downloads/rewizja.xlsx")



### Dla stary ceeb włocławek z powodu wczytania danych jako daty
# które zostały zapisane jako daty
# ceeb$Numer <- 
#   ifelse(str_detect(ceeb$Numer, pattern = "\\."),
#          str_extract(ceeb$Gmina, pattern = "\\d.+"),
#          ceeb$Numer)
###


# tylko włocławek
# still_messy <- 
#   still_messy %>% filter(Typ_deklaracji != "B")
# still_messy$Numer <- 
#   str_remove(still_messy$Numer, pattern = "3 Maja ")
# ###


