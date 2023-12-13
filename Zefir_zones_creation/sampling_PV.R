library(tidyverse)
library(sampling)

dachy <- 
  readxl::read_xlsx(
    "/home/pstapyra/Documents/Forum Energii/Data/Rybnik/Preprocessing/Operaty losowania/full_non_living_operat_losowania.xlsx")

dachy <- 
  dachy %>% distinct(id, pow_obrysu_m2, kategoria_funkcjonalna_top_down, .keep_all = TRUE)
dachy <- 
  dachy %>% mutate(integer_strata = case_when(
    kategoria_funkcjonalna_top_down == "Budynki o dwóch mieszkaniach i wielomieszkaniowe" ~ 1,
    kategoria_funkcjonalna_top_down == "Budynki mieszkalne jednorodzinne" ~ 2,
    kategoria_funkcjonalna_top_down == "Budynki publiczne" ~ 3,
    TRUE ~ 4
  )) %>%
  left_join(dachy %>% count(kategoria_funkcjonalna_top_down), 
            by = "kategoria_funkcjonalna_top_down")

pik_prob <- inclusionprobastrata(dachy$integer_strata, c(100,100,100))
dachy$prob <- pik_prob
set.seed(123)
sampled_pv <- 
  balancedstratification(
    X = as.matrix(dachy[c("longitude_centroid","latitude_centroid")]),
    strata = dachy$integer_strata,
    pik = pik_prob)
sampled_dachy <- dachy[as.logical(sampled_pv),]



sampled_dachy[c("przydzial", "Dach", "Okna",
                 "Wiek_budynku_p_modern", "Ocieplenie_ścian", 
                 "Uwagi", "Zrobione", "street_view")] <- NA
sampled_dachy$przydzial <- "Gosia"

openxlsx::write.xlsx(sampled_dachy,
                     "/home/pstapyra/Documents/Forum Energii/Data/Rybnik/Preprocessing/Sampling_PV.xlsx")




