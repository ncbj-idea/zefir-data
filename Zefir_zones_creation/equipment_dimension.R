# Global object -----------------------------------------------------------

# piorytetowe urządzenie centralne
central_hierarchy <- 
  c("Miejska sieć ciepłownicza",
    "Pompa ciepła",
    "Kocioł gazowy",
    "Ekoprojekt",
    "Klasa_5",
    "Klasa_4",
    "Klasa_3",
    "Poniżej_klasy_3_lub_brak_informacji",
    "Kocioł olejowy",
    "Trzon kuchenny",
    "Piec kaflowy",
    "Kominek",
    "Ogrzewanie elektryczne")
cwu_hierarchy <- 
  c("Miejska sieć ciepłownicza",
    "Pompa ciepła",
    "Kocioł gazowy",
    "Ekoprojekt",
    "Klasa 5",
    "Klasa 4",
    "Klasa 3",
    "Poniżej klasy 3 lub brak informacji",
    "Ogrzewanie elektryczne",
    "Kolektory słoneczne",
    "Kocioł olejowy"
  )

# lista z wagami
central_list <- 
  list(
    # 'Pompa ciepła' = c("Kocioł gazowy", "Ekoprojekt","Klasa 5"),
    # 'Kocioł gazowy' = c("Ekoprojekt","Klasa 5", "Klasa 4")
    # 'Poniżej klasy 3 lub brak informacji' =  "Kocioł olejowy",
    # 'Kocioł olejowy' = c("Trzon kuchenny", "Piec kaflowy","Kominek")
  )
cwu_list <- 
  list(
    # 'Pompa ciepła' = c("Kolektory słoneczne", "Ogrzewanie elektryczne", 
    #                    "Kocioł gazowy", "Ekoprojekt","Klasa 5"),
    # 'Kocioł gazowy' = c("Kolektory słoneczne", "Ogrzewanie elektryczne", 
    #                     "Ekoprojekt","Klasa 5", "Klasa 4"),
    # 'Klasa 5' = c("Kolektory słoneczne", "Ogrzewanie elektryczne"),
    # 'Klasa 4' = c("Kolektory słoneczne", "Ogrzewanie elektryczne"),
    # 'Klasa 3' = c("Kolektory słoneczne", "Ogrzewanie elektryczne"),
    # 'Poniżej klasy 3 lub brak informacji' = c("Kolektory słoneczne", "Ogrzewanie elektryczne"),
    # 'Kocioł olejowy' = c("Kolektory słoneczne", "Ogrzewanie elektryczne")
  )


# Split Data --------------------------------------------------------------

translate_names <- function(data, modified_var,  var_list) {
  position <- match(data[[modified_var]], names(var_list))
  new_value <- unname(unlist(var_list)[position])
  data[[modified_var]] <- new_value 
  data
}


## dodanie informacji o liczbie mieszkań na bazie średniej powierzchni mieszkania w danym mieście
add_liczba_lokali <- function(x,cond, var_cond, divider, gus_multiplicator) {
  stopifnot(is.numeric(divider))
  stopifnot(is.numeric(gus_multiplicator))
  if(all(x[[cond]] == var_cond)) {
    x$Liczba_lokali_mieszkalnych <- 1
  } else {
    x$Liczba_lokali_mieszkalnych <- 
      floor(x$pow_uzytkowa_m2*gus_multiplicator*x$wspolczynnik_powierzchni_uzytkowej_do_powierzchni_zabudowy/divider)
    
  }
  x
}



# Deklaracja A i B -----------------------------------------------------------


# w zależoności od liczby deklaracji na dany adres
# oraz tego co jest w nich
# jest nieco inaczej liczona maksymalna liczba urządzeń
# oraz maksymalna waga, gdzie waga = 1 oznacza cały budynek
max_number_equipment <- function(x, liczba_lokali_var){
      c("eq_number" = x[1,liczba_lokali_var, drop = TRUE],
        "flats_number" = x[1,liczba_lokali_var, drop = TRUE],
        "max_weight" = 1,
        "zbiorowy" = "nie"
      )
  }

###
impute_missing_data <- function(x, equipment_var1, equipment_var2) {
  x[[equipment_var1]] <- 
    ifelse(is.na(x[[equipment_var1]]), 1, x[[equipment_var1]])
  x[[equipment_var2]] <- 
    ifelse(is.na(x[[equipment_var2]])|x[[equipment_var2]] == 0, 1, x[[equipment_var2]])
  x[[equipment_var2]] <- 
    ifelse(x[[equipment_var2]] < x[[equipment_var1]],
           x[[equipment_var1]], x[[equipment_var2]])
  
  x
  
}


# wydobycie informacji o urządzeniach
# wynikiem jest lista zawierająca dwa data frame
# jedna z nazwami urządzeń, ich statusie oraz do czego są używane
# druga z informacjami o klasie kotła
# pod koniec funkcji korekta na błędne deklaracje lub pustostany
# (nie przewidujemy pustostanów)

# Liczba_eksploatowanych_źródeł_ciepła
# C.O.
# C.W.U.

simple_equipment <- function(x, freq, co, cwu, nazwa_urzadz, col_id_klasa) {
  df_eq <- 
    x %>% group_by({{co}}, {{cwu}}, {{nazwa_urzadz}}) %>%
    summarise(liczba = sum({{freq}}))
  df_eq <- eq_multiply(df_eq, "liczba")
  
  df_klasa <- 
    x[,col_id_klasa] %>% pivot_longer(cols = 1:5, values_drop_na = TRUE, 
                                      values_to = "liczba", names_to = "klasa")

  if(nrow(df_klasa) == 0){
    df_klasa
  } else {
    df_klasa <- eq_multiply(df_klasa, "liczba")
  }
  
  
  if(all(df_eq[rlang::as_name(enquo(co))] == "Nie")) {
    df_eq[rlang::as_name(enquo(co))] <- "Tak"
  }
  
  if(all(df_eq[rlang::as_name(enquo(cwu))] == "Nie")) {
    df_eq[rlang::as_name(enquo(cwu))] <- "Tak"
  }
  

  list(equipment = df_eq, klasy = df_klasa)
}

# Tyle replikacji rekordu ile wynosi wartość cechy liczba
# używane w simple_equipment
# funkcja używana w simple_equipment
eq_multiply <- function(x, col_liczba) {
  multiplication <- x[[col_liczba]]
  id <- 1:nrow(x)
  new_x <- x[unlist(map2(multiplication, id, replicate)),]
  new_x[[col_liczba]] <- NULL
  new_x
}

# Zastąpienie kotłów na paliwo stałe
# boiler_old oraz boiler_new w zależności od klasy
replace_klasowy_kociol <- function(list_eq, class_sort, var_source, co, cwu) {
  tempx <- list_eq$equipment
  tempy <- list_eq$klasy$klasa
  tempy <- tempy[order(match(tempy, class_sort))]
  cond <- any(is.element(c("Kocioł na paliwo stałe - pod. automatyczne",
                           "Kocioł na paliwo stałe - pod. ręczne"), tempx[[var_source]]))
  # czy w deklaracji w ogóle są kotły na paliwo stałe
  if(cond) {
    # czy w deklaracji nie wpisano klasy kotła warunek length(tempy) == 0
    if(length(tempy) == 0) {
      tempx[[var_source]] <- ifelse(tempx[[var_source]] == "Kocioł na paliwo stałe - pod. automatyczne",
                                "Klasa_4", tempx[[var_source]])
      tempx[[var_source]] <- ifelse(tempx[[var_source]] == "Kocioł na paliwo stałe - pod. ręczne",
                                "Poniżej_klasy_3_lub_brak_informacji", tempx[[var_source]])
      tempx
      
    } else {
      id_boilers <- tempx[[var_source]] %in% 
        c("Kocioł na paliwo stałe - pod. automatyczne",
          "Kocioł na paliwo stałe - pod. ręczne")
      boilers <- tempx[id_boilers,]
      non_boilers <- tempx[!id_boilers,]
      # chcemy mieć pewność, że najlepsza klasa będzie zastępować urządzenia, które
      # ogrzewają jak najwięcej rzeczy
      boilers$control <- (boilers[[co]] == "Tak") + (boilers[[cwu]] == "Tak")
      boilers <- dplyr::arrange(boilers, desc(control))
      
      # zastępowanie bojlerów
      for(i in seq_along(tempy)) {
        boilers[i,var_source] <- tempy[i]
      }
      boilers[[var_source]] <- ifelse(boilers[[var_source]] == "Kocioł na paliwo stałe - pod. automatyczne",
                                  "Klasa_4", boilers[[var_source]])
      boilers[[var_source]] <- ifelse(boilers[[var_source]] == "Kocioł na paliwo stałe - pod. ręczne",
                                  "Poniżej_klasy_3_lub_brak_informacji", boilers[[var_source]])
      boilers$control <- NULL
      rbind(boilers, non_boilers)
    }
    
  } else {
    tempx
  }
}

# funkcja tworząca ramkę danych z urządzeniami CWU oraz CO
finalize_eq_many <- function(class_eq, meta_eq, cwu_hier, cental_hier, co, cwu, var_sort) {
  cwu_eq <- subset(class_eq, class_eq[[cwu]] == "Tak")
  cental_eq <- subset(class_eq, class_eq[[co]] == "Tak")
  
  cwu_eq <- sortowanie_Czarka(cwu_eq, eq_sort = cwu_hier, var_sort)
  cental_eq <- sortowanie_Czarka(cental_eq, eq_sort = cental_hier, var_sort)
  
  max_eq <- meta_eq["eq_number"]
  
  cwu_max <- min(nrow(cwu_eq), max_eq)
  central_max <- min(nrow(cental_eq), max_eq)
  
  cental_eq <- cental_eq[1:central_max,]
  cental_eq$type <- "central"
  cental_eq[[cwu]] <- NULL
  cental_eq[[co]] <- NULL
  cwu_eq <- cwu_eq[1:cwu_max,]
  cwu_eq$type <- "cwu"
  cwu_eq[[cwu]] <- NULL
  cwu_eq[[co]] <- NULL
  
  rbind(cental_eq, cwu_eq)  
}

# customowe sortowanie zgodne z hierarchią urządzeń
# używane w funkcji finalize_eq_many
sortowanie_Czarka <- function(x, eq_sort, var_sort) {
  x[order(match(x[[var_sort]], eq_sort)),]
  
}

# agregacja wielu tych samych urządzeń do jednego urządzenia
weighted_boilers <- function(df_eq, var_source, type_source) {
  char_source <- rlang::as_name(enquo(var_source))
  char_type <- rlang::as_name(enquo(type_source))
  
  # max_weight <- as.numeric(weight_info[["max_weight"]])
  df_eq[[char_source]] <- ifelse(df_eq[[char_source]] %in% c("Ekoprojekt", "Klasa_5"),
                            "boiler_new", df_eq[[char_source]])
  df_eq[[char_source]] <- 
    ifelse(df_eq[[char_source]] %in% 
             c("Klasa_4", "Klasa_3", "Poniżej_klasy_3_lub_brak_informacji",
               "Kocioł olejowy", "Trzon kuchenny", 
               "Piec kaflowy", 
               "Kominek"),
           "boiler_old", df_eq[[char_source]])
  df_eq <- 
    count(df_eq, {{var_source}}, {{type_source}})
  
  df_central <- subset(df_eq, type == "central")
  df_cwu <- subset(df_eq, type == "cwu")
  
  df_central$weight <- df_central$n/sum(df_central$n) #*max_weight
  df_cwu$weight <- df_cwu$n/sum(df_cwu$n)# *max_weight
  df_eq <- rbind(df_central, df_cwu)
  df_eq$n <- NULL
  df_eq
}

# stworzenie par urządzeń, naiwne założenie o niezależności
# tworzona jest każda kombinacja
many_equipment_pairs <- function(df_eq, meta_weights) {
  max_weight <- as.numeric(meta_weights[["max_weight"]])
  centralne_eq <- subset(df_eq, type == "central")
  centralne_eq$type <- NULL
  cwu_eq <- subset(df_eq, type == "cwu")
  cwu_eq$type <- NULL
  colnames(centralne_eq) <- c("centralne", "central_weight")
  colnames(cwu_eq) <- c("cwu", "cwu_weight")
  pairs_eq <- crossing(centralne_eq, cwu_eq)
  pairs_eq$weight <- pairs_eq$central_weight * pairs_eq$cwu_weight*max_weight
  pairs_eq$central_weight <- NULL
  pairs_eq$cwu_weight <- NULL
  pairs_eq
}

# dodanie informacji z o adresie i typie deklaracji
finalize_equipment <- function(pair_eq, list_hshd, distinct_var){
  y <- list_hshd[distinct_var]
  y <- distinct(y, .keep_all = TRUE)
  cbind(pair_eq, y)
}

# testowanie czy występuję edge case opisany w confluence
# uwaga już nie powinien występować
edge_case_tester <- function(x) {
  sum(is.na(x$centralne)) > 0
}

# usuwanie śmieciowych par urządzeń w wielorodzinnych
remove_trash_items <- function(df, threshold, waga) {
  
  if(nrow(df) != 1) {
    
    while(min(df[[waga]]) < threshold & nrow(df) != 1) {
      add_weight <- min(df[[waga]])
      row_to_remove <- df[[waga]] == add_weight
      
      if(sum(row_to_remove) == 1) {
        df <- df[!row_to_remove,]
        df[[waga]] <- df[[waga]] + add_weight/nrow(df)
      } else {
        number_to_remove <- sample(which(row_to_remove), 1)
        df <- df[-number_to_remove,]
        df[[waga]] <- df[[waga]] + add_weight/nrow(df)
      }
    }
    df
  } else {
    df
  }
}

add_wiele_gosp_dom <- function(x,y, co) {
  gosp_number <- as.numeric(y["eq_number"])
  x$gosp_dom_gas <- 
    ifelse(x[[co]] == "Kocioł gazowy" & y["zbiorowy"] == "nie",
           x$weight * gosp_number,0)
  x$gosp_dom_zbior_gas <- 
    ifelse(x$centralne == "Kocioł gazowy" & y["zbiorowy"] == "tak",
           x$weight * gosp_number,0)
  x$gosp_dom_mpc <- 
    ifelse(x$centralne == "Miejska sieć ciepłownicza" & y["zbiorowy"] == "nie",
           x$weight * gosp_number,0)
  x$gosp_dom_zbior_mpc <- 
    ifelse(x$centralne == "Miejska sieć ciepłownicza" & y["zbiorowy"] == "tak",
           x$weight * gosp_number,0)
  x$gosp_dom <- x$weight * gosp_number
  x
  
  
}

