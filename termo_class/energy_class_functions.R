

missing_col <- c("Dach", "Rodzaj_dachu", "Czy_poddasze_ogrzewane", 
                 "Wiek_budynku_przed_modernizacją", "Okna", "Ocieplenie_ścian", 
                 "Wentylacja")
# eval_col <- c("pow_obrysu_m2", "liczba_kondygnacji", "ulica", "longitude_addr", 
#               "latitude_addr", "kategoria_funkcjonalna_top_down", "kategoria_funkcjonalna_bottom_up")
eval_col <- c("pow_obrysu_m2", "liczba_kondygnacji", "ulica", "longitude_addr", 
              "latitude_addr")
class_data <- readxl::read_xlsx("/home/pstapyra/Documents/Zefir/Data/energy_class/energy_class_rules.xlsx")
tree_model <- readRDS("/home/pstapyra/Documents/Zefir/Data/energy_class/tree_model.RDS")

##
# Impute data -------------------------------------------------------------

create_kape_model <- function(x, missing = c(FALSE,TRUE), addvar = NULL, imp_seed = 123) {
  stopifnot(is.data.frame(x))
  
  
  if(missing) {
    stopifnot(is.character(addvar))
    set.seed(imp_seed)
    x[addvar] <- VIM::kNN(build_data[addvar], k = 10, imp_var = FALSE)
    before_kape <- x
  } else {
    before_kape <- x
  }
  
  before_kape$komercyjny <- 
    ifelse(before_kape$funkcja_szczegolowa_budynku %in% c("budynek jednorodzinny", "budynek wielorodzinny" ), 
           "nie", "tak")
  
  kape_model <- 
    dplyr::mutate(
      .data = before_kape,
      Model_KAPE = dplyr::case_when(
        # jednorodzinne
        funkcja_szczegolowa_budynku == "budynek jednorodzinny" & 
          Rodzaj_dachu %in% c("dwuspadowy 30-50st", "mansarda", "do 30st dwuspadowy") ~ "jed_skosny",
        funkcja_szczegolowa_budynku == "budynek jednorodzinny" & 
          Rodzaj_dachu %in% c("wielospadowy", "jednospadowy") & 
          Czy_poddasze_ogrzewane == TRUE ~ "jed_skosny",
        funkcja_szczegolowa_budynku == "budynek jednorodzinny" & 
          Rodzaj_dachu == "do 30st  dwuspadowy" ~ "jed_skosny", # jeden przypadek brak standaryzacji
        funkcja_szczegolowa_budynku == "budynek jednorodzinny" & 
          Rodzaj_dachu %in% c("płaski", "kopertowy do 30st") ~ "jed_plaski",
        funkcja_szczegolowa_budynku == "budynek jednorodzinny" & 
          Rodzaj_dachu %in% c("wielospadowy", "jednospadowy") ~ "jed_plaski",
        # komercyjne
        komercyjny == "tak" & 
          Rodzaj_dachu %in% c("dwuspadowy 30-50st", "mansarda", "do 30st dwuspadowy") ~ "kom_skosny",
        komercyjny == "tak" & 
          Rodzaj_dachu %in% c("wielospadowy", "jednospadowy") & 
          Czy_poddasze_ogrzewane == TRUE ~ "kom_skosny",
        komercyjny == "tak" & 
          Rodzaj_dachu %in% c("płaski", "kopertowy do 30st") ~ "kom_plaski",
        komercyjny == "tak" & 
          Rodzaj_dachu %in% c("wielospadowy", "jednospadowy") ~ "kom_plaski",
        # wielorodzinne
        funkcja_szczegolowa_budynku == "budynek wielorodzinny" & 
          Rodzaj_dachu %in% c("dwuspadowy 30-50st", "mansarda", "do 30st dwuspadowy") ~ "wiel_skosny",
        funkcja_szczegolowa_budynku == "budynek wielorodzinny" & 
          Rodzaj_dachu %in% c("wielospadowy", "jednospadowy") & 
          Czy_poddasze_ogrzewane == TRUE ~ "jed_skosny",
        funkcja_szczegolowa_budynku == "budynek wielorodzinny" & 
          Rodzaj_dachu %in% c("płaski", "kopertowy do 30st") ~ "wiel_plaski",
        funkcja_szczegolowa_budynku == "budynek wielorodzinny" & 
          Rodzaj_dachu %in% c("wielospadowy", "jednospadowy") ~ "wiel_plaski",
        TRUE ~ NA_character_
      ))
  kape_model
  
  
}




####  temporary solution - now we don't have energy class for komercyjny and 
# wielorodzinny kape model, so here is created artificial kape model for it 
# same as for jednorodzinny
class_data <- 
  rbind(class_data, 
        dplyr::mutate(class_data, Model_KAPE = ifelse(Model_KAPE == "jed_skosny", "kom_skosny", "kom_plaski")),
        dplyr::mutate(class_data, Model_KAPE = ifelse(Model_KAPE == "jed_skosny", "wiel_skosny", "wiel_plaski"))
  )
list_class <- split(class_data, class_data$Model_KAPE)
####  

# drop na column - always compare one row to one row
drop_column_na <- function(data) {
  log_data <- apply(data, MARGIN = 2, is.na)
  data[!log_data]
}

## compare one row to one row
compare_rows <- function(row_class, data_build) { 
  zzz <- drop_column_na(row_class)
  true_cond <- ncol(zzz) - 2 # two last column have information about energy class and kape model
  # we don't want compare it
  target_names <- colnames(zzz)[1:true_cond]
  sum(zzz[target_names] == data_build[target_names]) == true_cond # TRUE/FALSE
  
}


cond_enrg_class <- function(row_data, class_list) {
  target_kape <- row_data[["Model_KAPE"]]
  class_data <- class_list[[target_kape]]
  
  nn <- nrow(class_data)
  temp <- logical(nn)
  
  # unfortunately all functionals effect's is lost information about class
  # row become character vectors :(
  # solution - split class data into list of length = nrow class data
  sad_enrg_list <- split(class_data, 1:nrow(class_data))
  #lapply(class_data, FUN = compare_rows, data_build = row_data)
  temp <- unname(purrr::map_lgl(sad_enrg_list, .f = compare_rows, data_build = row_data))
  #apply(class_data, MARGIN = 1, FUN = compare_rows, data_build = row_data, drop = FALSE)
  
  ### old loop solution
  # for(i in 1:nn) {
  #   temp[i] <- compare_rows(class_data[i,],row_data)
  #   
  # }
  # list(sanity = temp, energy_class = class_data[temp,"energy_class", drop = TRUE])
  list(sanity = temp, energy_class = class_data[temp,"energy_class", drop = TRUE])
  
}
### need  dot-dot-dot for k in knn
find_enrg_class <- function(data_build, list_enrg) {
  temp_list <- apply(data_build, MARGIN = 1, FUN = cond_enrg_class, class_list = list_class)
  
  # we don't know that conditions are disjoint (in terms of class)
  proper_list <- purrr::transpose(temp_list)
  non_one_class <- lapply(proper_list$energy_class, unique)
  non_one_class <- unlist(lapply(non_one_class, length))
  
  # if more than one class than return transponse list (+need warning)
  # if not return vector of classes. no = mean length of vector equal 0 
  if(length(non_one_class[non_one_class] == 0)) {
    unlist(lapply(proper_list$energy_class, "[", 1))
  } else {
    proper_list
  }
  
  
}


# Model class imputation --------------------------------------------------


tree_impute <- function(data, ml_model) {
  as.character(workflows:::predict.workflow(ml_model, subset(data, is.na(energy_class)))[,1,drop = TRUE])
  
}

  











