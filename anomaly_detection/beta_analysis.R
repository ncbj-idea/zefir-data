library(fitdistrplus)
library(dygraphs)


# Wczytanie danych --------------------------------------------------------

path_folder_beta <- "/home/pstapyra/Documents/Chronos/Anomaly_detection/Data/indywidualne_obiekty/beta"
ts_beta_path <- list.files(path_folder_beta)
beta_olsztyn <- vector(mode = "list", length = length(ts_beta_path))
names(beta_olsztyn) <- gsub(pattern = "\\.csv", replacement = "", x = ts_beta_path) 

for(i in seq_along(beta_olsztyn)) {
  path_to_load <- paste(path_folder_beta, "/", ts_beta_path[i], sep = "")
  x <- read.csv(path_to_load)
  x <- subset(x, !is.na(imported))
  x$scaled_imported <- (x$imported-min(x$imported))/(max(x$imported)-min(x$imported))
  beta_olsztyn[[i]] <- x
}



# Estymacja parametrów rozkładu beta --------------------------------------

par_list <- vector(mode = "list", length = length(beta_olsztyn))
for(i in seq_along(par_list)) {
  x <- fitdist(beta_olsztyn[[i]]$scaled_imported, "beta", method = "mme")
  par_list[[i]] <- unname(x$estimate)
}
rm(x,i)

bayes_prob <- function(x, var_A, event_A, 
                       threshold_type = c("mean","median","quantile"), 
                       shape1, shape2) {
  if(threshold_type == "mean") {
    threshold <- mean(x$scaled_imported[x[[var_A]] != event_A])
  } else if(threshold_type == "median") {
    threshold <- median(x$scaled_imported[x[[var_A]] != event_A])
  } else {
    threshold <- 
      unname(quantile(x$scaled_imported[x[[var_A]] != event_A], probs = 0.75))
  }
  
  prob_A <- table(x[var_A])/nrow(x)
  prob_A <- prob_A[[event_A]]
  
  cond_prob <- subset(x, scaled_imported > threshold)
  cond_prob <- table(cond_prob[var_A])/nrow(cond_prob)
  cond_prob <- cond_prob[event_A]
  if(is.na(cond_prob)) {
    cond_prob <- 0
  }
  cond_prob <- unname(cond_prob)
  
  prob_y <- pbeta(q = threshold, shape1 = shape1, shape2 = shape2, lower.tail = FALSE)
  cond_prob*prob_y/prob_A
}



# Conditional probability -------------------------------------------------


roboczy_olsztyn <- purrr::map(beta_olsztyn, subset, cykl_tygodnia == "roboczy")
roboczy_prob <- vector(mode = "list", length = length(roboczy_olsztyn))
tygodniowy_prob <- vector(mode = "list", length = length(roboczy_olsztyn))
names(roboczy_prob) <- names(beta_olsztyn)
names(tygodniowy_prob) <- names(beta_olsztyn)

for(i in seq_along(roboczy_prob)) {
  roboczy_prob[[i]] <- 
    bayes_prob(x = roboczy_olsztyn[[i]], 
               var_A ="cykl_roboczy_4", 
               event_A = "noc_robocza", 
               threshold_type = "quantile", 
               shape1 = par_list[[i]][1],
               shape2 = par_list[[i]][2])
  
}

for(i in seq_along(tygodniowy_prob)) {
  tygodniowy_prob[[i]] <- 
    bayes_prob(x = beta_olsztyn[[i]], 
               var_A ="cykl_tygodnia", 
               event_A = "weekend", 
               threshold_type = "quantile", 
               shape1 = par_list[[i]][1],
               shape2 = par_list[[i]][2])
  
}


# Analiza wybranych szeregów ----------------------------------------------

sort(unlist(roboczy_prob))
sort(unlist(tygodniowy_prob))


anomalie_nocne <- 
  names(roboczy_prob)[unlist(roboczy_prob) > 0.05]
anomalie_tygodniowe <- 
  names(tygodniowy_prob)[unlist(tygodniowy_prob) > 0.05]
anomalie_tygodniowe <-
  anomalie_tygodniowe[-1] # muzeum jest czynne w weekend

# anomalie nocne
ts_night_anomaly <- 
  roboczy_olsztyn[anomalie_nocne]
x <- 
  ts_night_anomaly[[5]]
threshold_day <- 
  subset(x, cykl_roboczy_4 == "dzień roboczy")
threshold_day <- 
  quantile(threshold_day$scaled_imported, probs = 0.75)
x$anomaly <- 
  ifelse(x$cykl_roboczy_4 == "noc_robocza" & x$scaled_import > threshold_day, x$imported, 0)
x$anomaly_indicator <- 
  ifelse(x$cykl_roboczy_4 == "noc_robocza" & x$scaled_import > threshold_day, "anomalia", "norma")

y <- table(subset(x, cykl_roboczy_4 == "noc_robocza")$anomaly_indicator,
      subset(x, cykl_roboczy_4 == "noc_robocza")$godzina)
y/colSums(y)

y <- x
y$bucket <- lubridate::as_datetime(y$bucket, tz = "Europe/Warsaw")
y <- xts::as.xts(y[c("bucket", "imported", "anomaly")])

dygraph(y) %>% dyRangeSelector() %>%
  dyOptions(useDataTimezone = TRUE) %>% 
  dySeries("imported", drawPoints = FALSE) %>%
  dySeries("anomaly", drawPoints = TRUE,  pointSize = 5, pointShape = "star") %>% 
  dyHighlight(highlightSeriesBackgroundAlpha = 0.3,
              hideOnMouseOut = FALSE)

# anomalie tygodniowe
ts_weekly_anomaly <- 
  beta_olsztyn[anomalie_tygodniowe]
x <- 
  ts_weekly_anomaly[[3]]
threshold <- 
  subset(x, cykl_tygodnia == "roboczy")
threshold <- 
  quantile(threshold$scaled_imported, probs = 0.75)
x$anomaly <- 
  ifelse(x$cykl_tygodnia == "weekend" & x$scaled_import > threshold, x$imported, 0)
x$anomaly_indicator <- 
  ifelse(x$cykl_tygodnia == "weekend" & x$scaled_import > threshold, "anomalia", "norma")


y <- x
y$bucket <- lubridate::as_datetime(y$bucket, tz = "Europe/Warsaw")
y <- xts::as.xts(y[c("bucket", "imported", "anomaly")])

dygraph(y) %>% dyRangeSelector() %>%
  dyOptions(useDataTimezone = TRUE) %>% 
  dySeries("imported", drawPoints = FALSE) %>%
  dySeries("anomaly", drawPoints = TRUE,  pointSize = 5, pointShape = "star") %>% 
  dyHighlight(highlightSeriesBackgroundAlpha = 0.3,
              hideOnMouseOut = FALSE)


# do przetestowania
kruskal.test()
pairwise.wilcox.test(PlantGrowth$weight, PlantGrowth$group,
                     p.adjust.method = "BH")





