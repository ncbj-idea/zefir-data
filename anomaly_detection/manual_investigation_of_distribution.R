library(tidyverse)
library(fitdistrplus)
library(gamlss.dist)
library(VGAM)
library(lubridate)
source("truncated_distribution.R")


# Load data and prepare list of results -----------------------------------


path_folder_beta <- "/home/pstapyra/Documents/Chronos/Anomaly_detection/Data/indywidualne_obiekty/beta"
ts_beta_path <- list.files(path_folder_beta)
beta_olsztyn <- vector(mode = "list", length = length(ts_beta_path))
names(beta_olsztyn) <- gsub(pattern = "\\.csv", replacement = "", x = ts_beta_path) 


for(i in seq_along(beta_olsztyn)) {
  path_to_load <- paste(path_folder_beta, "/", ts_beta_path[i], sep = "")
  x <- read.csv(path_to_load)
  x <- subset(x, !is.na(imported))
  x$bucket <- lubridate::as_datetime(x$bucket)
  x <- 
    x %>%
    mutate(bucket = as_datetime(bucket, tz = "Europe/Warsaw"),
           godzina = hour(bucket),
           dzien = day(bucket),
           miesac = month(bucket),
           dzien_tygodnia = weekdays(bucket))
  x <- 
    x %>%
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
  beta_olsztyn[[i]] <- x
}

list_results <- vector(mode = "list", length = length(beta_olsztyn))

names(beta_olsztyn)


# Analysis of ts ----------------------------------------------------------

# Uwagi

number_list <- 1
x <- subset(beta_olsztyn[[number_list]], cykl_roboczy_4 == "noc_robocza")
x <- x$imported
x <- x[x>0]
plot(density(x))
# sort(x, decreasing = TRUE)[1:30]
# sort(table(x), decreasing = TRUE)[1:10]

kkkk <- max(x)
# kkkk <- 3000
# x <- if(max(x) != kkkk) (x[x <= kkkk]) else (x)
# x <- x/10
# kkkk <- kkkk/10

gg <- fitdist(x, "tdagum", method="mle", 
              start=list(scale = 2, shape1.a = 1, shape2.p = 0.5), 
              fix.arg=list(upper_bound=kkkk),
              lower = 0,
              outer.iterations = 100)
plot(gg)
gg$loglik
gg <- fitdist(x, "tpareto", method="mle",
              start=list(mu = 100, sigma = 0.3),
              fix.arg=list(upper_bound=kkkk),
              lower = 0,
              outer.iterations = 100)
plot(gg)
gg$loglik
gg <- fitdist(x, "tfrechet", method="mle",
              start=list(location = 1, scale = 0.5, shape = 1),
              fix.arg=list(upper_bound=kkkk),
              lower = 0,
              outer.iterations = 100)
plot(gg)
gg$loglik
gg <- fitdist(x, "trayleigh", method="mle",
              start=list(scale = 0.1),
              fix.arg=list(upper_bound=max(x)),
              lower = 0,
              outer.iterations = 100)
plot(gg)



zz <- beta_olsztyn[[number_list]] %>% filter(cykl_roboczy_4 == "dzień roboczy")
daily_threshold <- median(zz$imported)
daily_threshold
1-ptdagum(scale = unname(gg$estimate[1]), 
        shape1.a = unname(gg$estimate[2]), 
        shape2.p = unname(gg$estimate[3]),
        upper_bound = unname(gg$fix.arg$upper_bound),
        q = daily_threshold)
1-ptfrechet(location = unname(gg$estimate[1]), 
          scale = unname(gg$estimate[2]), 
          shape = unname(gg$estimate[3]),
          upper_bound = unname(gg$fix.arg$upper_bound),
          q = daily_threshold)
1-ptrayleigh(scale = unname(gg$estimate[1]), 
            upper_bound = unname(gg$fix.arg$upper_bound),
            q = daily_threshold)
1-ptpareto(mu = unname(gg$estimate[1]), sigma = unname(gg$estimate[2]),
             upper_bound = unname(gg$fix.arg$upper_bound),
             q = daily_threshold)



#### ANALIZA RYZYKA
data_risk <- beta_olsztyn[[number_list]]
x <- data_risk$imported
x <- x[x>0]
plot(density(x))
# sort(x, decreasing = TRUE)[1:30]
# sort(table(x), decreasing = TRUE)[1:10]
kkkk <- max(x)
# kkkk <- 3000
# x <- if(max(x) != kkkk) (x[x <= kkkk]) else (x)
# x <- x/10
# kkkk <- kkkk/10

gg <- fitdist(x, "tdagum", method="mle", 
              start=list(scale = 2, shape1.a = 1, shape2.p = 0.5), 
              fix.arg=list(upper_bound=kkkk),
              lower = 0,
              outer.iterations = 100)
plot(gg)
gg$loglik
gg <- fitdist(x, "tpareto", method="mle",
              start=list(mu = 100, sigma = 1),
              fix.arg=list(upper_bound=kkkk),
              lower = 0,
              outer.iterations = 100)
plot(gg)
gg$loglik
gg <- fitdist(x, "tfrechet", method="mle",
              start=list(location = 1, scale = 1, shape = 0.1),
              fix.arg=list(upper_bound=kkkk),
              lower = 0,
              outer.iterations = 100)
plot(gg)
gg$loglik
gg <- fitdist(x, "trayleigh", method="mle",
              start=list(scale = 0.1),
              fix.arg=list(upper_bound=kkkk),
              lower = 0,
              outer.iterations = 100)
plot(gg)
qtdagum(scale = unname(gg$estimate[1]), 
        shape1.a = unname(gg$estimate[2]), 
        shape2.p = unname(gg$estimate[3]),
        upper_bound = unname(gg$fix.arg$upper_bound),
        p = 0.99)
qtfrechet(location = unname(gg$estimate[1]), 
          scale = unname(gg$estimate[2]), 
          shape = unname(gg$estimate[3]),
          upper_bound = unname(gg$fix.arg$upper_bound),
          p = 0.99)
qtpareto(mu = unname(gg$estimate[1]), 
          sigma = unname(gg$estimate[2]), 
          upper_bound = unname(gg$fix.arg$upper_bound),
          p = 0.99)

ll <- 
  ptdagum(scale = unname(gg$estimate[1]), 
          shape1.a = unname(gg$estimate[2]), 
          shape2.p = unname(gg$estimate[3]),
          upper_bound = unname(gg$fix.arg$upper_bound),
          q = daily_threshold)
ll <- 
  ptfrechet(location = unname(gg$estimate[1]), 
            scale = unname(gg$estimate[2]), 
            shape = unname(gg$estimate[3]),
            upper_bound = unname(gg$fix.arg$upper_bound),
            q = daily_threshold)
ll <- 
  ptrayleigh(scale = unname(gg$estimate[1]), 
             upper_bound = unname(gg$fix.arg$upper_bound),
             q = daily_threshold)
ll <- ptpareto(mu = unname(gg$estimate[1]), sigma = unname(gg$estimate[2]),
               upper_bound = unname(gg$fix.arg$upper_bound),
               q = daily_threshold)
  


bayes_prob(x = data_risk, 
           var_A = "cykl_roboczy_4", 
           event_A = "noc_robocza", 
           threshold = daily_threshold) * ll
  



beta_olsztyn[[number_list]] %>%
  filter(cykl_roboczy_4 == "noc_robocza") %>% 
  ggplot(aes(x = imported, fill = cykl_roboczy_4)) +
  geom_density(alpha = 0.1) +
  theme_bw()

beta_olsztyn[[number_list]] %>%
  filter(cykl_roboczy_4 == "noc_robocza") %>% 
  mutate(godzina = as.character(godzina)) %>% 
  ggplot(aes(x = imported)) +
  geom_density(alpha = 0.2) +
  facet_grid(dzien_tygodnia~miesac) +
  theme_bw()


