

library(tidyverse)
# trzeba sprawdzić czy w żadnym wypadku przy imputacji nie jest produkowany
# ujemny import energii

# i jest wyjątek Zespół Szkół Budowlanych PV.csv - tylko produkcja brak importu

TS_series <- list.files("/home/pstapyra/Documents/Chronos/Data/indywidualne_1_minuta")
quality_check <- 
  vector(mode = "list", length = length(TS_series))
names(quality_check) <- TS_series

for(i in TS_series) {
path_ts <- paste("/home/pstapyra/Documents/Chronos/Data/indywidualne_1_minuta/", 
                   i, sep = "")
ts_one <- readr::read_csv(path_ts, col_types = "TddI")

xts_one <- xts::as.xts(ts_one[,1:2])
xts_imp_info <-  xts::as.xts(ts_one[,c(1,5)])
ends <- xts::endpoints(ts_one$timestamp,'hours')

xts_one_hour <- xts::period.apply(xts_one, ends ,sum)
xts_imp_hour <- xts::period.apply(xts_imp_info, ends ,sum)


### Weekly imputation + correction
df_qual_imp <- 
  tibble(
    data = zoo::index(xts_one_hour),
    import = c(zoo::coredata(xts_one_hour)),
    flag_imp = ifelse(c(zoo::coredata(xts_imp_hour)) == 60,0, 1),
    lag_weekly = ifelse(flag_imp == 0, lag(import, n = 168), 0),
  ) %>%
  mutate(
    lag_weekly = ifelse(is.na(lag_weekly), 0, lag_weekly),
  )

df_qual_imp$flag_imp[1:168] <- 1
df_qual_imp$flag_imp <- ifelse(df_qual_imp$lag_weekly ==0, 1, df_qual_imp$flag_imp)
df_qual_imp$group_flag <- cumsum(df_qual_imp$flag_imp)

df_correction <- 
  df_qual_imp %>% 
  filter(flag_imp == 0) %>% 
  group_by(group_flag) %>%
  summarise(suma_import = sum(import),
            suma_weekly = sum(lag_weekly),
            count_row = n()) %>%
  ungroup() %>%
  mutate(avg_correction = (suma_import-suma_weekly)/count_row) %>%
  select(group_flag, avg_correction)

df_qual_imp <- 
  df_qual_imp %>% 
  left_join(df_correction, by = "group_flag") %>%
  mutate(import = ifelse(flag_imp == 0, lag_weekly + avg_correction, import))


xts_two <- xts::as.xts(df_qual_imp[,1:2])
quality_check[[i]] <- min(xts_two, na.rm = TRUE)

}
