library(tidyverse)
# version for old ceeb format

path_new_bdot <- "/home/pstapyra/Documents/NCBIR/Postprocessing/merged_shp_build.xlsx"
path_ceeb_join_bdot <- "/home/pstapyra/Documents/NCBIR/Preprocessing/ceeb_joined_bdot.xlsx"
path_to_save <- "/home/pstapyra/Documents/NCBIR/Postprocessing/new_aggr_ceeb_joined_bdot.xlsx"


# bdot
bdot <- readxl::read_xlsx(path_new_bdot)
zz <- subset(bdot, status != "to_join")
bdot$bdot_key <- str_to_lower(paste(str_remove(bdot$ulica, "^ulica "), bdot$numer_porzadkowy))


# ceeb+bdot
stary_ceeb <- readxl::read_xlsx(path_ceeb_join_bdot, guess_max = 4*10^4)
# important: choose those columns which are from ceeb or column, which contain bdot_key (not ceeb_key)
stary_ceeb <- stary_ceeb[,c(1:18,67)]
stary_ceebA <- stary_ceeb %>% filter(Typ_deklaracji == "A")


special_join <- function(data, bdot_data, key_join, order_type, var_bdot, var_ceeb, value){
  sub_data <- subset(data, data[[var_ceeb]] %in% value)
  razem <- data.frame()
  
  for(i in order_type){
    if(i != "others") {
      temp_bdot <- subset(bdot_data, bdot_data[[var_bdot]] == i) 
      bdot_data <- subset(bdot_data, bdot_data[[var_bdot]] != i) 
    } else {
      temp_bdot <- bdot_data
    }
    temp_ceeb <- inner_join(sub_data, temp_bdot, by = key_join)
    sub_data <- anti_join(sub_data, temp_bdot, by = key_join)
    razem <- rbind(razem, temp_ceeb)
    if(nrow(sub_data) == 0) {
      break()
    }
  }
  razem
}

# order type - first ceeb record is trying join certain type of building
# if not, than next position, if join than break loop
# possible better solution without loop: custom sort and take first position
jednorodzinne <- 
  special_join(data = stary_ceebA, bdot_data = bdot, key_join = "bdot_key",
               order_type = c("Budynki mieszkalne jednorodzinne",
                              "Budynki o dwóch mieszkaniach i wielomieszkaniowe",
                              "Budynki o trzech i więcej mieszkaniach",
                              "Budynki zbiorowego zamieszkania",
                              "others"),
               var_bdot = "nazwa_funkcji_ogolnej",
               var_ceeb = "Budynek_jednorodzinny",
               value = "tak")

wielorodzinne <- 
  special_join(data = stary_ceebA, bdot_data = bdot, key_join = "bdot_key",
               order_type = c("Budynki o dwóch mieszkaniach i wielomieszkaniowe",
                              "Budynki o trzech i więcej mieszkaniach",
                              "Budynki zbiorowego zamieszkania",
                              "Budynki mieszkalne jednorodzinne",
                              "others"),
               var_bdot = "nazwa_funkcji_ogolnej",
               var_ceeb = "Budynek_jednorodzinny",
               value = "nie")

publiczne_type <- 
  unique(bdot$nazwa_funkcji_ogolnej)
publiczne_type <-
  publiczne_type[!publiczne_type %in% c("Budynki o dwóch mieszkaniach i wielomieszkaniowe",
                                        "Budynki o trzech i więcej mieszkaniach",
                                        "Budynki mieszkalne jednorodzinne")]

niemieszkalne <- 
  special_join(data = stary_ceeb, bdot_data = bdot, key_join = "bdot_key",
               order_type = c(publiczne_type, "Budynki zbiorowego zamieszkania", "others"),
               var_bdot = "nazwa_funkcji_ogolnej",
               var_ceeb = "Typ_deklaracji",
               value = "B")



razem <- rbind(jednorodzinne, wielorodzinne,niemieszkalne)
openxlsx::write.xlsx(razem, path_to_save)












