library(shiny)
library(readxl)
library(sf)
library(tmap, quietly = TRUE)
sf_use_s2(FALSE)
### ZMIANA ŚCIEŻKI
# build_data <- read_xlsx("/home/pstapyra/Documents/Zefir/Inwentaryzacja_wizualna/Inw_app_v4/wylosowane.xlsx",
#                         guess_max = 20000) ####
# build_data$ulica <- ifelse(is.na(build_data$ulica), build_data$miejscowosc, build_data$ulica)


counter <- function() {
  i <- 0
  
  function() {
    i <<- i + 1
    i
  }
}

counter_one <- counter()

ui <- fluidPage(
  tabsetPanel(
    tabPanel("Informacje",
             fileInput("file_load", "Data", buttonLabel = "Plik xlsx", accept = ".xlsx"),
             selectInput("user_assig", label = "Wybierz użytkownika", choices = NULL),
             selectInput("city", label = "Wybierz nazwę miasta", 
                         choices = c("Czempiń", "Ustka", "Suwałki", "Sztum", "Olsztyn", "warszawa","włocławek"), 
                                     selected = "warszawa")
    ),
    tabPanel("Inwentaryzacja",
      sidebarLayout(
        sidebarPanel(
          selectInput("street_name", label = "Wybierz ulicę", choices = NULL),
          selectInput("order_number", label = "Wybierz numer porządkowy", choices = NULL),
          selectInput("id_number", label = "Wybierz numer ID", choices = NULL),
          # selectInput("ogrzewany", label = "Czy jest ogrzewany", choices = c("Tak", "Nie", ""), selected = ""),
          selectInput("dach", label = "Dach", choices = c("STARY", "PO REMONCIE", "NOWY", ""), selected = ""),
          # selectInput("rodzaj_dachu", label = "Rodzaj dachu", 
          #             choices = c("płaski","kopertowy do 30st","dwuspadowy 30-50st",
          #                         "wielospadowy","mansarda","nie widać", ""), 
          #             selected = ""),
      # selectInput("poddasze", label = "Czy poddasze ogrzewane", choices = c("Tak", "Nie", "Brak", ""), 
      #             selected = ""),
      selectInput("wiek", label = "Wiek budynku przed modernizacją ", 
                  choices = c("stary","po 1950r.","po 1990r.","Nowy po 2010r", ""), 
                  selected = ""),
      selectInput("okna", label = "Rodzaj okien", 
                  choices = c("STARE","LATA 90-TE","PO 2000 ","NOWE WT21", ""), 
                  selected = ""),
      selectInput("ocieplenie", label = "Ocieplenie ścian", 
                  choices = c("BRAK", "0-8CM","8-15 CM","15 CM >", ""), 
                  selected = ""),
      # selectInput("wentylacja", label = "Rodzaj wentylacji", 
      #             choices = c("GRAWITACYJNA", "MECHANICZNA","NIE WIADOMO", ""), 
      #             selected = ""),
      textInput("uwagi", label = "Uwagi"),
      textInput("stret_view", label = "Google street view"),
      textOutput("build_info"),
      actionButton("small_cleaner", "Wyczyść uwagi i streetview", icon = icon("broom")),
      actionButton("save_data", "Zapisz", class = "btn-lg btn-success"),
    ),
    mainPanel(
      tmapOutput("my_map", width = "100%", height = 850),
      tableOutput("table_info"),
      actionButton("big_cleaner", "Wyczyść wszystko", class = "btn-danger"),
      )
    ))))


server <- function(input, output) {
  
  
  path_os <- reactive({
    if(Sys.info()[["sysname"]] == "Linux") {
      paste(miasto(), "/", sep = "")
    } else{
      paste(miasto(), "\\", sep = "")
      
    }
  })
  
  
  build_data <- reactive({
    req(input$file_load)
    
    read_xlsx(input$file_load$datapath)
  })
  
  build_data_to_save <- reactiveVal()
  
  observeEvent(input$file_load, {
    build_data_to_save(build_data())
  })
  
  
  
  
  miasto <- reactive(input$city)
  
  observeEvent(input$city, {
    if(!dir.exists(miasto())) {
      dir.create(miasto())
    }
  })
  
  
  observeEvent(input$small_cleaner, {
    updateTextInput(inputId = "stret_view", value = "")
    updateTextInput(inputId = "uwagi", value = "")
  })
  
  observeEvent(input$big_cleaner, {
    updateTextInput(inputId = "stret_view", value = "")
    updateTextInput(inputId = "uwagi", value = "")
    # updateSelectInput(inputId = "wentylacja", selected = "")
    updateSelectInput(inputId = "ocieplenie", selected = "")
    updateSelectInput(inputId = "okna", selected = "")
    updateSelectInput(inputId = "wiek", selected = "")
    # updateSelectInput(inputId = "rodzaj_dachu", selected = "")
    # updateSelectInput(inputId = "ogrzewany", selected = "")
    updateSelectInput(inputId = "dach", selected = "")
  })
  
  observeEvent(input$file_load, {
    choices <- sort(unique(build_data()[["przydzial"]]))
    updateSelectInput(inputId = "user_assig", choices = choices) 
  })
  
  
  user_name <- reactive({
    req(input$file_load)
    req(input$user_assig)
    input$user_assig
    })
  
  user_streets <- reactive({
    subset(build_data(), przydzial == user_name())
    })
  
  observeEvent(user_name(), {
    choices <- sort(unique(user_streets()$ulica))
    updateSelectInput(inputId = "street_name", choices = choices) 
  })
  
  
  build_numbers <- reactive({
    req(input$street_name)
    subset(user_streets(), ulica == input$street_name)
    
  })
  
  observeEvent(build_numbers(), {
    freezeReactiveValue(input, "order_number")
    temp_choices <- unique(build_numbers()$numer_porzadkowy)
    ordering <- as.numeric(gsub("\\D+","", temp_choices))
    updateSelectInput(inputId = "order_number", 
                      choices = temp_choices[order(ordering)]) 
  })
  
  id_numbers <- reactive({
    req(input$order_number)
    subset(build_numbers(), numer_porzadkowy == input$order_number)
    
  })

  observeEvent(id_numbers(), {
    freezeReactiveValue(input, "id_number")
    temp_choices <- id_numbers()$id
    updateSelectInput(inputId = "id_number",
                      choices = temp_choices)
  })

  
  
  selected_building <- reactive({
    req(input$order_number)
    subset(build_numbers(), numer_porzadkowy == input$order_number)
  })
  
  id_lol <- reactive(input$id_number)
  
  row_number <- reactive({
    req(input$order_number)
    which(build_data()$id == id_lol()) #input$id_number)
  })
  
  # output$testownik <- renderText(row_number())
  
  
  # ogrzewany <- reactive(input$ogrzewany)
  dach <- reactive(input$dach)
  # rodzaj_dachu <- reactive(input$rodzaj_dachu)
  wiek <- reactive(input$wiek)
  okna <- reactive(input$okna)
  ocieplenie <- reactive(input$ocieplenie)
  # wentylacja <- reactive(input$wentylacja)
  uwagi <- reactive(input$uwagi)
  street_view <- reactive(input$stret_view)
  # miasto <- reactive(input$city)
  # path_info <- reactive(input$path_info)
  
  #buil_reactive <- reactiveVal(build_data)
  

  
  observeEvent(input$save_data, {
    # build_data[row_number(),"Wentylacja"] <<- wentylacja()
    # build_data[row_number(),"Czy_budynek_jest_ogrzewany"] <<- ogrzewany()
    # build_data[row_number(),"Rodzaj_dachu"] <<- rodzaj_dachu()
    
    data_to_modify <- build_data_to_save()
    
    data_to_modify[row_number(),"Dach"] <- dach()
    data_to_modify[row_number(),"Wiek_budynku_p_modern"] <- wiek()
    data_to_modify[row_number(),"Okna"] <- okna()
    data_to_modify[row_number(),"Ocieplenie_ścian"] <- ocieplenie()
    data_to_modify[row_number(),"Uwagi"] <- uwagi()
    data_to_modify[row_number(),"street_view"] <- street_view()
    data_to_modify[row_number(),"Zrobione"] <- "Zrobione"

    build_data_to_save(data_to_modify)
    
    tempx <- paste(path_os(), "inwentaryzacja", "_", miasto(), ".xlsx", sep = "")
    openxlsx::write.xlsx(build_data_to_save(),  tempx)
    
  })
  
  observeEvent(input$save_data, {
    
    if(counter_one() %% 15 == 0) {
      naming_file <- paste(miasto(), as.character(Sys.time()), ".xlsx", sep = "")
      naming_file <- gsub(pattern = ":", replacement = "", naming_file)
      naming_file <- gsub(pattern = "-", replacement = "", naming_file)
      naming_file <- gsub(pattern = " ", replacement = "", naming_file)
      

      path_naming <- paste(path_os(), naming_file, sep = "")
      openxlsx::write.xlsx(build_data_to_save(), path_naming)
    }

  })
  
  
  
  
  
  build_street <- reactive({
    if(is.na(build_data_to_save()[row_number(),"Zrobione", drop = TRUE])) {
      paste(miasto(), selected_building()[["ulica"]], " ", selected_building()[["numer_porzadkowy"]], sep = " ")[1]
    } else {
      paste(paste(miasto(), selected_building()[["ulica"]], " ", selected_building()[["numer_porzadkowy"]], sep = " ")[1],
            "ZROBIONE", sep = "---")

    }

  })

  
  output$my_map <- renderTmap({
    req(selected_building())
    req(selected_building())
    build_to_map <- sf::st_as_sf(selected_building(), wkt = "geom_wkt",crs = "EPSG:2180")
    build_to_map <- build_to_map[build_to_map$id == id_lol(),]
    tm_shape(build_to_map) + 
      tm_basemap(server = "OpenStreetMap.Mapnik") + 
      tm_view(set.zoom.limits	= c(15,19), set.view = 17) +
      tm_borders(lwd = 3, col = "green") +
      tm_fill("id", id = "id", alpha = 0, legend.show = FALSE)
  })
  output$build_info <- renderText({
    req(selected_building())
    build_street()
    })
  output$table_info <- renderTable(selected_building()[c("id", "nazwa_funkcji_ogolnej")],
                                   digits = 0)
}



shinyApp(ui = ui, server = server)
