
### testowanie tworzenie wielu raportów jednym skryptem rmd z parametrem
### który precyzuje jaki plik wczytać i jak zapisać raport

rmd_path <- "/home/pstapyra/Documents/Chronos/First_impressions/raports_format.Rmd"
tS_files <- list.files("/home/pstapyra/Documents/Chronos/Data/indywidualne_1_minuta")
tS_files <- tS_files[!grepl(pattern = "PV", x = tS_files)]
#tS_files <- tS_files[1:2]


for(i in tS_files){
  file_names <- gsub(i, pattern = "\\.csv", replacement = "\\.html")
   path <- paste("/home/pstapyra/Documents/Chronos/Data/indywidualne_1_minuta/",
                 i,
                 sep = "")
  TS_series <- readr::read_csv(path, col_types = "TddI")
  rmarkdown::render(
  input = "/home/pstapyra/Documents/Chronos/First_impressions/raports_format.Rmd",
  params = list(TS_data = TS_series),
  #output_format = "HTML",
  output_file = file_names,
  output_dir = "/home/pstapyra/Documents/Chronos/Raporty"
)
}


rmarkdown::render(
  input = "/home/pstapyra/Documents/Chronos/First_impressions/raports_format.Rmd",
  #params = list(TS_data = i),
  # output_format = "html",
  output_file = "file_names.html",
  output_dir = "/home/pstapyra/Documents/Chronos/Raporty"
)
