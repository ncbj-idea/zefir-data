library(tidyverse)
library(patchwork)
library(stargazer)
library(dygraphs)

# Load data and prepare list of results -----------------------------------


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


names(beta_olsztyn)


# Create table ------------------------------------------------------------

x <- beta_olsztyn[["Zespół Szkół Budowlanych"]]
x$bucket <- lubridate::as_datetime(x$bucket)

threshold <- median(subset(x, cykl_roboczy_4 == "dzień roboczy")$imported)
x$anomaly_indicator <- ifelse(x$cykl_roboczy_4 == "noc_robocza" & 
                                x$imported > threshold, "Anomalia", "Norma")

table(x$anomaly_indicator)
sum(x$cykl_roboczy_4 == "noc_robocza")
1667/3799

zz <- subset(x, anomaly_indicator == "Anomalia")
zz %>% 
  mutate(miesac = as.character(miesac)) %>% 
  group_by(miesac, godzina) %>%
  summarise(liczba = n(),
            mediana = median(imported)) %>% View()

p1 <- zz %>% 
  group_by(miesac) %>%
  summarise(Liczba = n()) %>%
  ggplot(aes(x = miesac, y = Liczba)) +
  geom_line(color = "#feb24c", linewidth = 1.3) +
  geom_point(shape = 1, color = "black", size = 2) +
  theme_bw() +
  xlab("Miesiąc") +
  ylab("Liczba anomalii") +
  ggtitle("Występowanie anomalii w czasie") +
  scale_x_continuous(labels = c("Luty", "Marzec", "Kwiecień", "Maj", "Czerwiec"))

p2 <- zz %>% 
  mutate(miesac = as.character(miesac)) %>% 
  ggplot(aes(x = miesac, y = imported)) +
  geom_boxplot(orientation = "x") +
  theme_bw() +
  xlab("Miesiąc") +
  ylab("Energia") +
  ggtitle("Nietypowy pobór energii z sieci") +
  scale_x_discrete(labels = c("Luty", "Marzec", "Kwiecień", "Maj", "Czerwiec"))

p1 + p2

p1 <- 
  zz %>% 
  group_by(godzina) %>%
  summarise(Liczba = n()) %>% 
  mutate(godzina = c(4:9,1:3)) %>% 
  ggplot(aes(x = godzina, y = Liczba)) +
  geom_line(color = "#feb24c", size = 1.3) +
  geom_point(shape = 1, color = "black", size = 2) +
  theme_bw() +
  xlab("Godzina doby") +
  ylab("Liczba anomalii") +
  ggtitle("Występowanie anomalii w czasie") +
  scale_x_continuous(labels = 
                       c("21","23","1", "3", "5"),
                     breaks = c(1,3,5,7,9))

p2 <- 
  zz %>% 
  mutate(godzina = factor(zz$godzina,
                         levels = c("21", "22","23", as.character(0:5)),
                         ordered = TRUE)) %>% 
  ggplot(aes(x = godzina, y = imported)) +
  geom_boxplot(orientation = "x") +
  theme_bw() +
  xlab("Godzina doby") +
  ylab("Energia") +
  ggtitle("Nietypowy pobór energii z sieci")

p1+p2
kruskal.test(list(zz$imported[zz$miesac == 2],
                  zz$imported[zz$miesac == 3],
                  zz$imported[zz$miesac == 4],
                  zz$imported[zz$miesac == 5],
                  zz$imported[zz$miesac == 6]))

pairwise.wilcox.test(zz$imported, zz$miesac,p.adjust.method = "BH")

kruskal.test(list(zz$imported[zz$godzina == 21],
                  zz$imported[zz$godzina == 22],
                  zz$imported[zz$godzina == 23],
                  zz$imported[zz$godzina == 0],
                  zz$imported[zz$godzina == 1],
                  zz$imported[zz$godzina == 2],
                  zz$imported[zz$godzina == 3],
                  zz$imported[zz$godzina == 4],
                  zz$imported[zz$godzina == 5]))

kk <- pairwise.wilcox.test(zz$imported, zz$godzina,p.adjust.method = "BH")


kk <- x %>% 
  filter(cykl_roboczy_4 == "noc_robocza")
ll <- kk %>% 
  group_by(miesac, dzien, godzina, anomaly_indicator) %>% 
  count(anomaly_indicator) %>% 
  ungroup() %>%
  mutate(n = ifelse(anomaly_indicator == "Anomalia",n,0)) %>%
  group_by(miesac, dzien, godzina, ) %>% 
  summarise(n = sum(n)/4) %>% 
  mutate(bucket = lubridate::make_datetime(year = 2023, month = miesac, day = dzien, hour = godzina))
ll %>% 
  ggplot(aes(x = bucket, y = n)) +
  geom_line() +
  theme_bw()
ll <- xts::as.xts(ll[c("bucket", "n")])
plot(ll, main = "Częstotliwość występowania anomalii w godzinie", lwd = 0.9,
     col = "#bcbddc",
     yaxis.right = FALSE, yaxis.ticks = 3, grid.col = "white",
     ylab = "Proporcja")


xts::plot.xts(ll, col = "black", main = "Częstotliwość anomalii w godzinie", alpha = 0.2)
zoo::plot.zoo(ll)
dygraph(ll) %>% dyRangeSelector() %>%
  dyOptions(useDataTimezone = TRUE) %>% 
  dySeries("n", drawPoints = FALSE) %>%
  dyHighlight(highlightSeriesBackgroundAlpha = 0.3,
              hideOnMouseOut = FALSE)


