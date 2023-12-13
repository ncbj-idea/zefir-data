library(tidyverse)
library(FactoMineR)
library(factoextra)
rybnik <- 
  readxl::read_xlsx("/home/pstapyra/Documents/Forum Energii/Data/Rybnik/Preprocessing/data_with_termo_class.xlsx",
                    sheet = 3)
wloclawek <- 
  readxl::read_xlsx("/home/pstapyra/Documents/Forum Energii/Data/Włocławek/Estimation/data_with_termo_class.xlsx",
                    sheet = 2)
wloclawek_mpec <- 
  readxl::read_xlsx("/home/pstapyra/Documents/Forum Energii/Data/Włocławek/Merged_data/mpec/mpec_merged_bdot_poprawiony.xlsx",
                    sheet = 2)
wloclawek_mpec <- 
  wloclawek_mpec %>% filter(`Klasa termomodernizacyjna` != "BRAK")
wloclawek_mpec <- 
  data.frame(centralne = "Miejska sieć ciepłownicza",
             energy_class = wloclawek_mpec$`Klasa termomodernizacyjna`)
wloclawek_razem <- 
  rbind(wloclawek %>% select(centralne, energy_class),
        wloclawek_mpec)

x <- table(rybnik$centralne, rybnik$energy_class)
x <- table(wloclawek_razem$centralne, wloclawek_razem$energy_class)
z <- chisq.test(x, simulate.p.value = TRUE)
round(z$residuals,4)
round(z$residuals^2/z$statistic,4)*100

res.ca <- CA(x, graph = FALSE)
fviz_ca_biplot(res.ca, repel = TRUE)
# jakość reprezentacji wiersza i wkład wierszy w wymiary
get_ca_row(res.ca)$cos2[,1:2]
fviz_cos2(res.ca, choice = "row", axes = 1:2)
get_ca_row(res.ca)$contrib
# jakość reprezentacji kolumny i wkład kolumny w wymiary
get_ca_col(res.ca)$cos2[,1:2]
fviz_cos2(res.ca, choice = "col", axes = 1:2)
get_ca_col(res.ca)$contrib

### kolumny w wiersze | wiersze w kolumny
fviz_ca_biplot(res.ca, 
               map ="rowprincipal", arrow = c(TRUE, TRUE),
               repel = TRUE)
fviz_ca_biplot(res.ca, 
               map ="colprincipal", arrow = c(TRUE, TRUE),
               repel = TRUE)
fviz_ca_biplot(res.ca, 
               map ="rowgreen", arrow = c(TRUE, TRUE),
               repel = TRUE)
fviz_ca_biplot(res.ca, 
               map ="colgreen", arrow = c(TRUE, TRUE),
               repel = TRUE)
fviz_ca_biplot(res.ca, 
               map ="rowgab", arrow = c(TRUE, TRUE),
               repel = TRUE)
fviz_ca_biplot(res.ca, 
               map ="colgab", arrow = c(TRUE, TRUE),
               repel = TRUE)
FactoInvestigate::Investigate(res.ca)
# Włocławek
# odrzucenie null
# D i B słaba reprezentacja w 2D
#  boiler_new: +(C,D), -(A,B,F) 
#  boiler_old: +(E), -(A,B)
# Kocioł gazowy: +(C, D), -(A,B,E,F) 
# MPEC: +(A,B,E,F), -(C)
# elektryczne: +(C), -(A,F)
# pompa ciepła +(B,C), -(E,F)

# Rybnik
# odrzucenie null
# A i ogrzewanie elektryczne słaba reprezentacja w 2D
# boiler_new: +(A E), -(B,C) 
# boiler_old: +(E F), -(B,C,D)
# Kocioł gazowy: +(B C), -(E,F) 
# MPEC: +(C), -(E)
# elektryczne: +(A),
# pompa ciepła +(B,C,D), -(E,F)


### Cochran-Mantel-Haenszel Chi-Squared 
razem <- data.frame(x = c(rybnik$centralne, wloclawek_razem$centralne),
                    y = c(rybnik$energy_class, wloclawek_razem$energy_class),
                    z = c(rep("rybnik", nrow(rybnik)), rep("wloclawek", nrow(wloclawek_razem))))
zz <- mantelhaen.test(x = as.factor(razem$x),
                y = as.factor(razem$y),
                z = as.factor(razem$z))
zz



