library(tidyverse)
library(survey)

path_to_pv <- "/home/pstapyra/Documents/Forum Energii/Data/Rybnik/inwentaryzacja_Rybnik_PV.xlsx"

fotowoltaika <- readxl::read_xlsx(path_to_pv)

fotowoltaika$weight_PV <- 1/fotowoltaika$prob
fotowoltaika$base_nominal <- 
  as.numeric(fotowoltaika$Uwagi)/100*fotowoltaika$pow_obrysu_m2*0.00020956
fotowoltaika$fpc_n <- 100/fotowoltaika$n

fotowoltaika <- fotowoltaika %>% filter(kategoria_funkcjonalna_top_down != "Budynki publiczne")
svy_super_area <- svydesign(ids = ~0, 
                            weights = ~weight_PV, 
                            strata = ~kategoria_funkcjonalna_top_down,
                            pps = "brewer",
                            fpc = ~prob,
                            data = fotowoltaika)


svyratio(~I(base_nominal*(kategoria_funkcjonalna_top_down != "Budynki mieszkalne jednorodzinne")), ~base_nominal, svy_super_area)
# 32.8
# 0.8881704
# 0.1118296
32.8*0.8881704
32.8*0.1118296

x <- svytotal(~base_nominal, svy_super_area)
x
confint(x)

zz <- fotowoltaika %>% 
  filter(kategoria_funkcjonalna_top_down == unique(fotowoltaika$kategoria_funkcjonalna_top_down)[3])
svy_super_area <- svydesign(ids = ~0, 
                            weights = ~weight_PV, 
                            strata = ~kategoria_funkcjonalna_top_down,
                            pps = "brewer",
                            fpc = ~prob,
                            data = zz)

x <- svytotal(~base_nominal, svy_super_area)
x
confint(x)

