library(tidyverse)
library(openxlsx)


zones_names <- readxl::read_xlsx("/home/pstapyra/Downloads/zones.xlsx", sheet = 2)
zones_names <- zones_names$`Rodzaj budynku`



create_cost_excel <- function(path_to_excel, buildings_types, path_to_save) {
  
  path_to_excel <- paste(path_to_excel, "/costs.xlsx", sep = "")
  wb <- createWorkbook("Koszty", creator = "IDEA")
  addWorksheet(wb, "Koszty zmienne")
  addWorksheet(wb, "Nakłady inwestycyjne")
  addWorksheet(wb, "Koszty operacyjne")
  
  excel_data <- readxl::read_xlsx(path_to_excel, sheet = 1)
  excel_data <- subset(excel_data, year == 1)
  excel_data[,2] <- NULL
  colnames(excel_data)[1] <- "Numer strefy"
  writeData(wb, sheet = 1, t(colnames(excel_data)), startRow = 1, colNames= FALSE)
  writeData(wb, sheet = 1, t(c("Rodzaj budynku", buildings_types)), startRow = 2, 
            colNames = FALSE)
  writeData(wb, sheet = 1, excel_data, startRow = 3, colNames= FALSE)
  
  
  excel_data <- readxl::read_xlsx(path_to_excel, sheet = 2)
  excel_data <- subset(excel_data, year == 0)
  excel_data[,2] <- NULL
  colnames(excel_data)[1] <- "Numer strefy"
  writeData(wb, sheet = 2, t(colnames(excel_data)), startRow = 1, colNames= FALSE)
  writeData(wb, sheet = 2, t(c("Rodzaj budynku", buildings_types)), startRow = 2, 
            colNames = FALSE)
  writeData(wb, sheet = 2, excel_data, startRow = 3, colNames= FALSE)
  
  excel_data <- readxl::read_xlsx(path_to_excel, sheet = 3)
  excel_data <- subset(excel_data, year == 1)
  excel_data[,2] <- NULL
  colnames(excel_data)[1] <- "Numer strefy"
  writeData(wb, sheet = 3, t(colnames(excel_data)), startRow = 1, colNames= FALSE)
  writeData(wb, sheet = 3, t(c("Rodzaj budynku", buildings_types)), startRow = 2, 
            colNames = FALSE)
  writeData(wb, sheet = 3, excel_data, startRow = 3, colNames= FALSE)
  
  if(length(readxl::excel_sheets(path_to_excel)) == 5) {
    addWorksheet(wb, "Termomodernizacja")
    excel_data <- readxl::read_xlsx(path_to_excel, sheet = 4)
    excel_data <- subset(excel_data, year == 0)
    excel_data[,2] <- NULL
    colnames(excel_data)[1] <- "Numer strefy"
    writeData(wb, sheet = 4, t(colnames(excel_data)), startRow = 1, colNames= FALSE)
    writeData(wb, sheet = 4, t(c("Rodzaj budynku", buildings_types)), startRow = 2, 
              colNames = FALSE)
    writeData(wb, sheet = 4, excel_data, startRow = 3, colNames= FALSE)
  }
  
  path_to_save <- paste(path_to_save, "/", "Koszty.xlsx", sep = "")
  saveWorkbook(wb, path_to_save)
}

create_emission_excel <- function(path_to_excel, buildings_types, path_to_save) {
  
  path_to_excel <- paste(path_to_excel, "/emissions.xlsx", sep = "")
  wb <- createWorkbook("Emisje", creator = "IDEA")
  addWorksheet(wb, "Emisje")
  
  excel_data <- readxl::read_xlsx(path_to_excel, sheet = 1)
  excel_data <- subset(excel_data, year == 1)
  excel_data[,3] <- NULL
  colnames(excel_data)[1:2] <- c("Nazwa technologii", "Rodzaj emisji")
  writeData(wb, sheet = 1, excel_data)
  
  path_to_save <- paste(path_to_save, "/", "Emisje.xlsx",sep = "")
  saveWorkbook(wb, path_to_save)
}

create_nominal_power_excel <- function(path_to_excel, buildings_types, path_to_save) {
  
  path_to_excel <- paste(path_to_excel, "/powers.xlsx", sep = "")
  wb <- createWorkbook("Moc nominalna" , creator = "IDEA")
  addWorksheet(wb, "Planowana moc")
  addWorksheet(wb, "Zainstalowana moc")
  
  excel_data <- readxl::read_xlsx(path_to_excel, sheet = 1)
  excel_data <- subset(excel_data, year == 0)
  excel_data[,2] <- NULL
  colnames(excel_data)[1] <- "Numer strefy"
  writeData(wb, sheet = 1, t(colnames(excel_data)), startRow = 1, colNames= FALSE)
  writeData(wb, sheet = 1, t(c("Rodzaj budynku", buildings_types)), startRow = 2, 
            colNames = FALSE)
  writeData(wb, sheet = 1, excel_data, startRow = 3, colNames= FALSE)
  
  excel_data <- readxl::read_xlsx(path_to_excel, sheet = 2)
  excel_data <- subset(excel_data, year == 1)
  excel_data[,2] <- NULL
  colnames(excel_data)[1] <- "Numer strefy"
  writeData(wb, sheet = 2, t(colnames(excel_data)), startRow = 1, colNames= FALSE)
  writeData(wb, sheet = 2, t(c("Rodzaj budynku", buildings_types)), startRow = 2, 
            colNames = FALSE)
  writeData(wb, sheet = 2, excel_data, startRow = 3, colNames= FALSE)
  
  path_to_save <- paste(path_to_save, "/", "Moc nominalna.xlsx",sep = "")
  saveWorkbook(wb, path_to_save)
}

create_roczny_bilans_excel <- function(path_to_excel, path_to_save) {
  
  path_to_excel <- paste(path_to_excel, "/scaled_ee_yearly_balance.xlsx", sep = "")
  wb <- createWorkbook("Roczny bilans energii" , creator = "IDEA")
  addWorksheet(wb, "Roczny popyt")
  addWorksheet(wb, "Roczna podaż")
  
  excel_data <- readxl::read_xlsx(path_to_excel, sheet = 1)
  colnames(excel_data) <- c("Nazwa technologii", "Energia w MWh")
  excel_data[nrow(excel_data),1] <- "Popyt bytowy"
  writeData(wb, sheet = 1, excel_data)
  
  excel_data <- readxl::read_xlsx(path_to_excel, sheet = 2)
  colnames(excel_data) <- c("Nazwa technologii", "Energia w MWh")
  writeData(wb, sheet = 2, excel_data)
  
  path_to_save <- paste(path_to_save, "/", "Roczny bilans energii.xlsx",sep = "")
  saveWorkbook(wb, path_to_save)
}

create_roczny_bilans_strefowy_excel <- function(path_to_excel, buildings_types, path_to_save) {
  
  path_to_excel <- paste(path_to_excel, "/scaled_ee_zonal_balance.xlsx", sep = "")
  wb <- createWorkbook("Roczny bilans energii dla stref" , creator = "IDEA")
  addWorksheet(wb, "Roczny popyt")
  addWorksheet(wb, "Roczna podaż")
  
  excel_data <- readxl::read_xlsx(path_to_excel, sheet = 1)
  colnames(excel_data)[1] <- "Numer strefy"
  excel_data[nrow(excel_data),1] <- "Popyt bytowy"
  writeData(wb, sheet = 1, t(colnames(excel_data)), startRow = 1, colNames= FALSE)
  writeData(wb, sheet = 1, t(c("Rodzaj budynku", buildings_types)), startRow = 2, 
            colNames = FALSE)
  writeData(wb, sheet = 1, excel_data, startRow = 3, colNames= FALSE)
  
  excel_data <- readxl::read_xlsx(path_to_excel, sheet = 2)
  colnames(excel_data)[1] <- "Numer strefy"
  writeData(wb, sheet = 2, t(colnames(excel_data)), startRow = 1, colNames= FALSE)
  writeData(wb, sheet = 2, t(c("Rodzaj budynku", buildings_types)), startRow = 2, 
            colNames = FALSE)
  writeData(wb, sheet = 2, excel_data, startRow = 3, colNames= FALSE)
  
  path_to_save <- paste(path_to_save, "/", "Roczny bilans energii dla stref.xlsx",sep = "")
  saveWorkbook(wb, path_to_save)
}

create_thermo_excel <- function(path_to_excel, buildings_types, path_to_save) {
  
  path_to_excel <- paste(path_to_excel, "/thermo.xlsx", sep = "")
  if(file.exists(path_to_excel)) {
    wb <- createWorkbook("Termomodernizacja" , creator = "IDEA")
    addWorksheet(wb, "Procent termomodernizacji")
    addWorksheet(wb, "Redukcja zapotrzebowania")
    
    excel_data <- readxl::read_xlsx(path_to_excel, sheet = 1)
    excel_data <- subset(excel_data, year == 0)
    excel_data[,2] <- NULL
    colnames(excel_data)[1] <- "Numer strefy"
    writeData(wb, sheet = 1, t(colnames(excel_data)), startRow = 1, colNames= FALSE)
    writeData(wb, sheet = 1, t(c("Rodzaj budynku", buildings_types)), startRow = 2, 
              colNames = FALSE)
    writeData(wb, sheet = 1, excel_data, startRow = 3, colNames= FALSE)
    
    excel_data <- readxl::read_xlsx(path_to_excel, sheet = 2)
    excel_data <- subset(excel_data, year == 1)
    excel_data[,2] <- NULL
    colnames(excel_data)[1] <- "Numer strefy"
    writeData(wb, sheet = 2, t(colnames(excel_data)), startRow = 1, colNames= FALSE)
    writeData(wb, sheet = 2, t(c("Rodzaj budynku", buildings_types)), startRow = 2, 
              colNames = FALSE)
    writeData(wb, sheet = 2, excel_data, startRow = 3, colNames= FALSE)
    
    path_to_save <- paste(path_to_save, "/", "Termomodernizacja.xlsx", sep = "")
    saveWorkbook(wb, path_to_save)
  }
}

copy_thermo_summary <- function(path_to_excel, path_to_copy) {
  
  path_to_excel <- paste(path_to_excel, "/thermo_summarize.xlsx", sep = "")
  if(file.exists(path_to_excel)) {
    file.copy(path_to_excel, to = path_to_copy)
  }
}

create_roczna_produkcja_energii_excel <- function(path_to_excel, buildings_types, path_to_save) {
  
  path_to_excel <- paste(path_to_excel, "/yearly_generation_scaled.xlsx", sep = "")
  wb <- createWorkbook("Roczna produkcja energii" , creator = "IDEA")
  addWorksheet(wb, "Produkcja ciepła")
  # addWorksheet(wb, "Produkcja cwu")
  # addWorksheet(wb, "Produkcja energii elektrycznej")
  
  excel_data <- readxl::read_xlsx(path_to_excel, sheet = 1)
  colnames(excel_data)[1] <- "Numer strefy"
  writeData(wb, sheet = 1, t(colnames(excel_data)), startRow = 1, colNames= FALSE)
  writeData(wb, sheet = 1, t(c("Rodzaj budynku", buildings_types)), startRow = 2, 
            colNames = FALSE)
  writeData(wb, sheet = 1, excel_data, startRow = 3, colNames= FALSE)
  
  # excel_data <- readxl::read_xlsx(path_to_excel, sheet = 2)
  # colnames(excel_data)[1] <- "Numer strefy"
  # writeData(wb, sheet = 2, t(colnames(excel_data)), startRow = 1, colNames= FALSE)
  # writeData(wb, sheet = 2, t(c("Rodzaj budynku", buildings_types)), startRow = 2, 
  #           colNames = FALSE)
  # writeData(wb, sheet = 2, excel_data, startRow = 3, colNames= FALSE)
  
  # excel_data <- readxl::read_xlsx(path_to_excel, sheet = 3)
  # colnames(excel_data)[1] <- "Numer strefy"
  # writeData(wb, sheet = 3, t(colnames(excel_data)), startRow = 1, colNames= FALSE)
  # writeData(wb, sheet = 3, t(c("Rodzaj budynku", buildings_types)), startRow = 2, 
  #           colNames = FALSE)
  # writeData(wb, sheet = 3, excel_data, startRow = 3, colNames= FALSE)
  
  path_to_save <- paste(path_to_save, "/", "Roczna_produkcja_energii.xlsx", sep = "")
  saveWorkbook(wb, path_to_save)
}

listownik <- function(path_to_city) {
  x <- list.files(path_to_city)
  x_list <- as.list(paste(path_to_city, "/", x, sep = ""))
  y <- lapply(x_list, FUN = list.files)
  names(y) <- x
  y
  
}

create_hierarchy_files <- function(city, list_folder_names, path) {
  path_outside <- paste(path, city, sep = "")
  if(!dir.exists(path_outside)) {
    for(i in seq_along(list_folder_names)){
      for(j in seq_along(list_folder_names[[i]])){
        path_inside <- paste(path_outside, "/", names(list_folder_names)[i], "/", list_folder_names[[i]][j], sep = "")
        dir.create(path_inside, recursive = TRUE)
      }
    }
  }
}





iterator_value <- listownik("/home/pstapyra/Downloads/Miasto_olsztyn")
create_hierarchy_files(city = "Olsztyn", list_folder_names = iterator_value, 
                       path = "/home/pstapyra/Documents/")


for(i in seq_along(iterator_value)) {
  for(j in seq_along(iterator_value[[i]])) {
    orginal_excel_path <- 
      paste("/home/pstapyra/Downloads/Miasto_olsztyn", "/", names(iterator_value)[i], "/", iterator_value[[i]][j], sep = "")
    destiny_excel_path <- 
      paste("/home/pstapyra/Documents/Olsztyn", "/", names(iterator_value)[i], "/", iterator_value[[i]][j], sep = "")
    create_cost_excel(orginal_excel_path, buildings_types = zones_names, path_to_save = destiny_excel_path)
    create_emission_excel(orginal_excel_path, buildings_types = zones_names,path_to_save = destiny_excel_path)
    # create_nominal_power_excel(orginal_excel_path, buildings_types = zones_names,path_to_save = destiny_excel_path)
    # create_roczny_bilans_excel(orginal_excel_path,path_to_save = destiny_excel_path)
    # create_roczny_bilans_strefowy_excel(orginal_excel_path, 
    #                                     buildings_types = zones_names,path_to_save = destiny_excel_path)
    create_thermo_excel(orginal_excel_path, buildings_types = zones_names,path_to_save = destiny_excel_path)
    copy_thermo_summary(orginal_excel_path, path_to_copy = destiny_excel_path)
    create_roczna_produkcja_energii_excel(orginal_excel_path,path_to_save = destiny_excel_path,
                                          buildings_types = zones_names)
  }
  
}






