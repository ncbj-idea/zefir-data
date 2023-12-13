# General -----------------------------------------------------------------

library(tidyverse)
options(dplyr.summarise.inform = FALSE) # musi być, bo będzie printować wiele, wiele wiadomości
source("equipment_dimension.R")

path_to_load <- "/home/pstapyra/Documents/Forum Energii/Data/Włocławek/Merged_data/New_merged_ceeb/nowy_ceeb.xlsx"
path_to_save <- "/home/pstapyra/Downloads/ceeb_ready_to_go.xlsx"
trash_treshold <- 0.25
extrapolate_build_threshold <- 0.8
required_colnames <- 
  c("ulica", "numer_porzadkowy", "Klasa_5", "Ekoprojekt", "Klasa_4", "Klasa_3",
    "Poniżej_klasy_3_lub_brak_informacji", "C.O.", "C.W.U.", "Typ_deklaracji",
    "Liczba_zainstalowanych_źródeł_ciepła", "Liczba_eksploatowanych_źródeł_ciepła",
    "Źródło_ciepła", "Rodzaj_budynku_A", "Dotyczy_wszystkich_lokali")
source_translation <- 
  list(
    "Miejska sieć ciepłownicza / ciepło systemowe / lokalna sieć ciepłownicza" = "Miejska sieć ciepłownicza",
    "Kocioł gazowy / bojler gazowy / podgrzewacz gazowy przepływowy / kominek gazowy" = "Kocioł gazowy",
    "Trzon kuchenny / piecokuchnia / kuchnia węglowa" = "Trzon kuchenny" ,
    "Piec kaflowy na paliwo stałe (węgiel, drewno, pellet lub inny rodzaj biomasy)" = "Piec kaflowy",
    "Kominek / koza / ogrzewacz powietrza na paliwo stałe (drewno, pellet lub inny rodzaj biomasy, węgiel)" = "Kominek",
    "Ogrzewanie elektryczne / bojler elektryczny" = "Ogrzewanie elektryczne" ,
    "Kolektory słoneczne do ciepłej wody użytkowej lub z funkcją wspomagania ogrzewania"= "Ogrzewanie elektryczne" ,
    "Pompa ciepła" = "Pompa ciepła", 
    "Kocioł olejowy" = "Kocioł olejowy",
    "Kocioł na paliwo stałe (węgiel, drewno, pellet lub inny rodzaj biomasy) z ręcznym podawaniem paliwa / zasypowy" = 
      "Kocioł na paliwo stałe - pod. ręczne",
    "Kocioł na paliwo stałe (węgiel, drewno, pellet lub inny rodzaj biomasy) z automatycznym podawaniem paliwa / z podajnikiem" = 
      "Kocioł na paliwo stałe - pod. automatyczne"
  )


ceeb <- 
  readxl::read_xlsx(path_to_load, guess_max = 10^5)
if(!all(required_colnames %in% colnames(ceeb))) {
  stop(
    paste("W pliku CEEB brakuje następujących kolumn: ",
          paste(required_colnames[!required_colnames %in% colnames(ceeb)], collapse = ", "), 
          ". W związku z tym użycie parsera nie jest możliwe.", sep = "")
  )
}

# Prepare ceeb data -------------------------------------------------------

# zastąpienie spacji za pomocą podkreślnika w nazwach kolumn
# colnames(ceeb) <- gsub(pattern = " ", replacement = "_", colnames(ceeb))

# niektóre deklaracje ceeb nie mają w ogóle podanego źródła ciepła
# z takimi deklaracjami nie można nic zrobić
# podobnie jak z brakiem numeru
ceeb <- 
  subset(ceeb, !is.na(Źródło_ciepła))
ceeb <- 
  translate_names(ceeb, "Źródło_ciepła",source_translation)

# w ceeb, niektóre nazwy ulic mają w sobie pl., ul. albo os.
# w bdot nie mamy tych skrótów
# nie wiedzieć czemu nie można tego usunąć w jednym kroku (do testu na niewyczyszczonym ceeb)
# ceeb$Ulica <- gsub(pattern = "^ul\\.|^pl\\.|^os\\.", replacement = "", ceeb$Ulica,
#                    ignore.case = TRUE)
# ceeb$Ulica <- gsub(pattern = "^\\s", replacement = "", ceeb$Ulica)


# dodanie nowej zmiennej, która określająca adres danej deklaracji oraz 
# próba ujednolicenia zapisu numerów mieszkań
ceeb$split_var <- ceeb$bdot_key


# Split data --------------------------------------------------------------

# Podział na deklaracje A i B (mieszkalne i niemieszkalne)
Aceeb <- subset(ceeb, Typ_deklaracji == "A")
Bceeb <- subset(ceeb, Typ_deklaracji != "A")
tempA <- split(Aceeb, Aceeb$split_var)

# Czy deklaracja dotyczy domu jednorodzinnego czy wielorodzinnego
# uwaga mamy założenie, że dom jednorodzinny nie może mieć więcej niż 1 mieszkanie
# (budynki, które spełniają ten warunek powstały metodą prób i błędów,
# taki urok rejestrów publicznych wypełnianych samodzielnie)
tempA <- map(tempA, 
                   add_liczba_lokali,
                   var_cond = "kategoria_funkcjonalna_top_down", 
                   cond = "Budynki mieszkalne jednorodzinne",
                   divider = 50, 
                   gus_multiplicator = 0.8987)

# Deklaracje A ------------------------------------------------------------


equipment_meta_info <- map(tempA, .f = max_number_equipment, "Liczba_lokali_mieszkalnych")
tempA <- 
  map(tempA, .f = impute_missing_data,
      "Liczba_zainstalowanych_źródeł_ciepła", "Liczba_eksploatowanych_źródeł_ciepła")
smp_equipment_list <- 
  map(tempA, .f = simple_equipment, Liczba_eksploatowanych_źródeł_ciepła,
      C.O., C.W.U.,Źródło_ciepła, 40:44)
klasowe_kotly_lista <- 
  map(smp_equipment_list, .f = replace_klasowy_kociol, central_hierarchy, "Źródło_ciepła", "C.O.", "C.W.U.")
final_equipment_list <- map2(klasowe_kotly_lista, equipment_meta_info, .f = finalize_eq_many,
                             cwu_hier = cwu_hierarchy, cental_hier = central_hierarchy,
                             "C.O.", "C.W.U.", "Źródło_ciepła")
final_boiler_list <- map(final_equipment_list, .f = weighted_boilers, Źródło_ciepła, type)
final_equipment_pairs <- 
  map2(final_boiler_list,equipment_meta_info, .f = many_equipment_pairs)
finalize_results <- 
  map2(final_equipment_pairs, 
       tempA,
       .f = finalize_equipment,
       distinct_var = c("split_var", "Typ_deklaracji", "merged_id"))


#### UWAGA
# sprawdzenie czy mam w danych wystąpił nie obsługiwany edge case - patrz confluence
edge_case_id <- unlist(map(finalize_results, edge_case_tester))
if(sum(edge_case_id >0)) (stop("Uwaga, wymagana rewizja"))


results_trash_removed<- 
  map(finalize_results, remove_trash_items, threshold = trash_treshold, "weight")
results_trash_removed <- 
  map2(finalize_results, equipment_meta_info, .f = add_wiele_gosp_dom, "centralne")

# gotowe deklaracje typu A
final_ceebA<- 
  do.call("rbind", results_trash_removed)
final_ceebA <- 
  as_tibble(final_ceebA)

# Deklaracje B ------------------------------------------------------------


Bceeb$Liczba_lokali_mieszkalnych <- 1
tempB <- split(Bceeb, Bceeb$split_var)
tempB <- 
  map(tempB, .f = impute_missing_data,
      "Liczba_zainstalowanych_źródeł_ciepła", "Liczba_eksploatowanych_źródeł_ciepła")
smp_equipment_list <- 
  map(tempB, .f = simple_equipment, Liczba_eksploatowanych_źródeł_ciepła,
      C.O., C.W.U.,Źródło_ciepła, 40:44)
equipment_meta_info <- map(tempB, .f = max_number_equipment, "Liczba_lokali_mieszkalnych")
klasowe_kotly_lista <- 
  map(smp_equipment_list, .f = replace_klasowy_kociol, central_hierarchy, "Źródło_ciepła", "C.O.", "C.W.U.")
final_equipment_list <- map2(klasowe_kotly_lista, equipment_meta_info, .f = finalize_eq_many,
                             cwu_hier = cwu_hierarchy, cental_hier = central_hierarchy,
                             "C.O.", "C.W.U.", "Źródło_ciepła")
final_boiler_list <- map(final_equipment_list, .f = weighted_boilers, Źródło_ciepła, type)
final_equipment_pairs <- 
  map2(final_boiler_list,equipment_meta_info, .f = many_equipment_pairs)
results_Btype <- 
  map2(final_equipment_pairs, 
       tempB,
       .f = finalize_equipment,
       distinct_var = c("split_var", "Typ_deklaracji", "merged_id"))

results_Btype <- do.call("rbind", results_Btype)
results_Btype <- as_tibble(results_Btype)
results_Btype <- subset(results_Btype, !is.na(centralne))
# waga dla każdej deklaracji typu B wynosi 1 z automatu
results_Btype$weight <- 1
results_Btype$gosp_dom_mpc <- NA
results_Btype$gosp_dom_zbior_mpc <- NA
results_Btype$gosp_dom_gas <- NA
results_Btype$gosp_dom_zbior_gas <- NA
results_Btype$gosp_dom <- NA



# Łączenie danych i zapis -------------------------------------------------

final_ceeb_df <- rbind(final_ceebA,results_Btype)
final_ceeb_df$split_var <- NULL

join_ceeb <- distinct(ceeb[,c(15,47:67)])

final_ceeb_df <- 
  final_ceeb_df %>%
  left_join(join_ceeb, join_by(merged_id, Typ_deklaracji))
# 
# # pamiętać o zmianie ścieżki
# # pamiętać o sprawdzenie mieszkań
openxlsx::write.xlsx(final_ceeb_df, path_to_save)











