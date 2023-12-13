library(tidyverse)

termo <- 
  readxl::read_xlsx("/home/pstapyra/Documents/Zefir/Data/energy_class/energy_class_rules.xlsx")
termo <- 
  termo[c("Dach", "Wiek_budynku_przed_modernizacją", "Okna", "Ocieplenie_ścian", "energy_class")]
termo$energy_class <- 
  ifelse(termo$energy_class == "Bz", "B", termo$energy_class)
termo$energy_class <- 
  ifelse(termo$energy_class == "Dp", "D", termo$energy_class)
termo$energy_class <- 
  ifelse(termo$energy_class == "DDp", "D", termo$energy_class)
termo <- 
  distinct(termo)

wide <- 
  readxl::read_xlsx("/home/pstapyra/Documents/Zefir/Data/energy_class/filled_missing.xlsx")
wide <- 
  wide[c("Dach", "Wiek_budynku_przed_modernizacją", "Okna", "Ocieplenie_ścian", "energy_class")]
wide$energy_class <- 
  ifelse(wide$energy_class == "Dp", "D", wide$energy_class)
wide$energy_class <- 
  ifelse(wide$energy_class == "Bz", "B", wide$energy_class)
wide <- 
  distinct(wide)

dach <- unique(termo$Dach)
dach <- dach[!is.na(dach)]
wiek <- unique(termo$Wiek_budynku_przed_modernizacją)
wiek <- wiek[!is.na(wiek)]


miss_dach <- subset(termo, is.na(termo$Dach) & !is.na(termo$Wiek_budynku_przed_modernizacją))
miss_wiek <- subset(termo, !is.na(termo$Dach) & is.na(termo$Wiek_budynku_przed_modernizacją))
miss_both <- subset(termo, is.na(termo$Dach) & is.na(termo$Wiek_budynku_przed_modernizacją))
non_miss <- subset(termo, !is.na(termo$Dach) & !is.na(termo$Wiek_budynku_przed_modernizacją))

for(i in 1:nrow(miss_dach)) {
  browser()
  temp_x <- miss_dach[rep(i,3),]
  temp_x$Dach <- dach
  non_miss <- 
    rbind(non_miss,temp_x)
}
unique(non_miss$Okna)
unique(non_miss$Dach)

for(i in 1:nrow(miss_wiek)) {
  temp_x <- miss_wiek[rep(i,4),]
  temp_x$Wiek_budynku_przed_modernizacją <- wiek
  non_miss <- rbind(non_miss,temp_x)
}

comb_cols <- expand_grid(dach, wiek)
for(i in 1:nrow(miss_both)) {
  temp_x <- miss_both[rep(i,12),]
  temp_x[c("Dach","Wiek_budynku_przed_modernizacją")] <- comb_cols
  non_miss <- rbind(non_miss,temp_x)
}


non_miss <- 
  rbind(non_miss, wide)

non_miss <- 
  distinct(non_miss)

which(duplicated(x[,-5], fromLast = TRUE))
which(duplicated(x[,-5], fromLast = FALSE))

openxlsx::write.xlsx(x, "/home/pstapyra/Downloads/temp_class.xlsx")











    



