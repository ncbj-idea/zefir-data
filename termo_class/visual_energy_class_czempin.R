
### czempiń
# build_data <-
#   readxl::read_xlsx("/home/pstapyra/Documents/Zefir/Data/Czempin/need_energy_class.xlsx")

### USTKA:
# mieszkalne
# build_data <-
#   readxl::read_xlsx("/home/pstapyra/Documents/Zefir/Data_raw_inventory/Ustka/inwentaryzacja_ustka.xlsx")
# niemieszkalne
build_data <-
  readxl::read_xlsx("/home/pstapyra/Documents/Zefir/Data_raw_inventory/Ustka/inwentaryzacja_B.xlsx")
build_data$Rodzaj_dachu <- "płaski"
build_data$Czy_poddasze_ogrzewane <- "BRAK" 
build_data$Wentylacja <- "GRAWITACYJNA"

build_data$Klimatyzacja <- FALSE
build_data$funkcja_szczegolowa_budynku <- "budynek jednorodzinny"
build_data$Rodzaj_dachu <- ifelse(build_data$Rodzaj_dachu == "nie widać", NA, build_data$Rodzaj_dachu)
build_data$Czy_poddasze_ogrzewane <-
  ifelse(build_data$Rodzaj_dachu == "płaski", "BRAK", "TRUE")

colnames(build_data)[11] <- "Wiek_budynku_przed_modernizacją"
build_data$Wentylacja <- ifelse(build_data$Wentylacja == "NIE WIADOMO", "GRAWITACYJNA", build_data$Wentylacja)
bdot <-
  readxl::read_xlsx("/home/pstapyra/Documents/Zefir/Ceeb_bdot_magic/Results/Ustka/ceeb_join_bdot.xlsx")
bdot <-
  bdot[c("id","pow_obrysu_m2", "liczba_kondygnacji", "longitude_addr", "latitude_addr")]
bdot <-
  dplyr::distinct(bdot)
build_data <-
  dplyr::left_join(build_data, bdot, by = "id")
rm(bdot)
source("/home/pstapyra/Documents/Zefir/energy_class/energy_class_functions.R")


# w czempiniu był używany rodzaj dachu mansardowy
# w kolejnych miastach mansarda
x <- create_kape_model(build_data, missing = TRUE, addvar = c(eval_col,missing_col))
table(x$Model_KAPE)
first_stage_class <- find_enrg_class(x, list_class)
table(first_stage_class)

build_data$energy_class <- first_stage_class
table(build_data$energy_class )


build_data[is.na(build_data$energy_class),"energy_class"] <- 
  as.character(predict(tree_model, subset(build_data, is.na(energy_class)))[,1,drop = TRUE])
build_data$energy_class <- 
  ifelse(build_data$energy_class %in% c("Dp", "DDp"), "D", build_data$energy_class)
# mieszkalne
# openxlsx::write.xlsx(build_data, "/home/pstapyra/Documents/Zefir/Ceeb_bdot_magic/Results/Ustka/do_oszacowania.xlsx")
openxlsx::write.xlsx(build_data, "/home/pstapyra/Documents/Zefir/Ceeb_bdot_magic/Results/Ustka/inwentaryzacja_B.xlsx")

