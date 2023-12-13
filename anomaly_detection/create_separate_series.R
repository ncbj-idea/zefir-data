library(tidyverse)
library(lubridate)



olsztyn <- read_csv("/home/pstapyra/Documents/Chronos/Anomaly_detection/Data/dane_olsztyn.csv")
olsztyn <- 
  olsztyn %>%
  mutate(bucket = as_datetime(bucket, tz = "Europe/Warsaw"),
         godzina = hour(bucket),
         dzien = day(bucket),
         miesac = month(bucket),
         dzien_tygodnia = weekdays(bucket))
olsztyn <- 
  olsztyn %>%
  mutate(cykl_tygodnia = ifelse(dzien_tygodnia %in% c("sobota", "niedziela"), "weekend", "roboczy"),
         cykl_roboczy_1 = ifelse(cykl_tygodnia == "weekend", "nie_dotyczy",
                               ifelse(godzina %in% 8:16, "dzień roboczy", "noc_robocza")),
         cykl_roboczy_2 = ifelse(cykl_tygodnia == "weekend", "nie_dotyczy",
                                 ifelse(godzina %in% 8:20, "dzień roboczy", "noc_robocza")),
         cykl_roboczy_3 = ifelse(cykl_tygodnia == "weekend", "nie_dotyczy",
                                 ifelse(godzina %in% 6:20, "dzień roboczy", "noc_robocza")),
         cykl_roboczy_4 = ifelse(cykl_tygodnia == "weekend", "nie_dotyczy",
                                 ifelse(godzina %in% 6:20, "dzień roboczy", "noc_robocza"))
  )

olsztyn_list <- split(olsztyn, olsztyn$name)
nazwy <- names(olsztyn_list)


# save as separate data frame
for(i in 1:length(nazwy)) {
  csv_name <- paste("/home/pstapyra/Documents/Chronos/Anomaly_detection/Data/indywidualne_obiekty/",
                    nazwy[i], ".csv", sep = "") 
  
  write_csv(x = olsztyn_list[[i]],file = csv_name)
  
}



