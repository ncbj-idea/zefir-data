library(shiny)
library(dplyr)
library(stringr)
library(tidyr)
library(networkD3)




replace_strefa_names <- function(data, named_labels) {
  colnames(data)[-1] <- paste(named_labels, colnames(data)[-1], sep = "_")
  data
}

essential_modification <- 
  function(base_heat, base_cwu, target_cwu, target_co, labelz) {
    base_heat <- replace_strefa_names(base_heat, named_labels = labelz)
    base_cwu <- replace_strefa_names(base_cwu, named_labels = labelz)
    target_cwu <- replace_strefa_names(target_cwu, named_labels = labelz)
    target_heat <- replace_strefa_names(target_co, named_labels = labelz)
    
    
    base_heat <-
      tidyr::pivot_longer(base_heat, cols = -1, names_to = "target", values_to = "value")%>%
      filter(value > 0)
    target_heat <-
      tidyr::pivot_longer(target_heat, cols = -1, names_to = "source", values_to = "value")%>%
      filter(value > 0)
    base_cwu <-
      tidyr::pivot_longer(base_cwu, cols = -1, names_to = "target", values_to = "value") %>%
      filter(value > 0)
    target_cwu <-
      tidyr::pivot_longer(target_cwu, cols = -1, names_to = "source", values_to = "value") %>%
      filter(value > 0)

    target_heat$type <-
      "co"
    base_heat$type <-
      "co"
    target_cwu$type <-
      "cwu"
    base_cwu$type <-
      "cwu"

    colnames(base_heat)[1] <- "source"
    colnames(base_cwu)[1] <- "source"
    colnames(target_heat)[1] <- "target"
    colnames(target_cwu)[1] <- "target"


    target_heat$target <- paste("_", target_heat$target, sep = "")
    target_cwu$target <- paste("_", target_cwu$target, sep = "")
    target_heat <- target_heat[c("source", "target", "value", "type")]
    target_cwu <- target_cwu[c("source", "target", "value", "type")]
    target_cwu

    list("baseline_heat" = base_heat,
         "target_heat" = target_heat,
         "baseline_cwu" = base_cwu,
         "target_cwu" = target_cwu)
  }


prepare_termo_savings <- function(target_data, baseline_data) {
  savings <-
    target_data[c("source", "value")]
  savings <-
    aggregate(savings$value, by = list(savings$source), FUN = sum)
  colnames(savings) <- c("source", "target_value")

  aggr_baseline <-
    aggregate(baseline_data$value, by = list(baseline_data$target), FUN = sum)
  colnames(aggr_baseline) <- c("target", "value")

  savings <-
    dplyr::left_join(savings, aggr_baseline, by = dplyr::join_by(source == target))
  savings$value <-
    savings$value - savings$target_value
  savings$target <- "savings"
  savings <- savings[c("target", "value","source")]
  savings <- subset(savings, value > 0)
  savings$type <- "co"
  savings
}


create_sunkey_zefir <-
  function(base_heat,
           base_cwu,
           target_cwu,
           target_co,
           labels = NULL,
           aggr = c(TRUE, FALSE),
           cwu_plus_co = TRUE,
           link_colour = c("source", "target", "type", "building", "termo"),
           type_to_keep = c("co", "cwu"),
           keep_termo = c("AB", "C", "D", "EF"),
           keep_building = c("SINGLE", "MULTI", "PUBLIC")){

    stopifnot("You can't color links by type of heat when heat is summed up" = !(link_colour == "type" & cwu_plus_co))
    stopifnot("You can't color links by type of heat when one type of heat is filtered out " = !(link_colour == "type" & length(type_to_keep) == 1))
    stopifnot("You can't filter one type of heat when heat is summed up" = !(cwu_plus_co & length(type_to_keep) == 1))
    stopifnot("You can't color links by building or termo when heat is summed up" = !(aggr & link_colour %in% c("building", "termo")))

    essential_data <-
      essential_modification(base_heat = base_heat,
                             base_cwu = base_cwu,
                             target_cwu = target_cwu,
                             target_co = target_co,
                             labelz = labels)

    savings_data <-
      prepare_termo_savings(target_data = essential_data$target_heat,
                            baseline_data = essential_data$baseline_heat)


    # Filter out termo and building
    savings_data$building <- str_extract(pattern = "SINGLE_FAMILY|MULTI_FAMILY|PUBLIC", string = savings_data$source)
    savings_data$termo <- str_extract(pattern = "_(AB|C|D|EF)_", string = savings_data$source, group = 1)
    savings_data <-
       subset(savings_data, building %in% keep_building)
    savings_data <-
       subset(savings_data, termo %in% keep_termo)

    baseline_heat <- essential_data[["baseline_heat"]]
    baseline_heat$building <- str_extract(pattern = "SINGLE_FAMILY|MULTI_FAMILY|PUBLIC", string = baseline_heat$target)
    baseline_heat$termo <- str_extract(pattern = "_(AB|C|D|EF)_", string = baseline_heat$target, group = 1)
    baseline_heat <-
      subset(baseline_heat, building %in% keep_building)
    baseline_heat <-
      subset(baseline_heat, termo %in% keep_termo)

    target_heat <- essential_data[["target_heat"]]
    target_heat$building <- str_extract(pattern = "SINGLE_FAMILY|MULTI_FAMILY|PUBLIC", string = target_heat$source)
    target_heat$termo <- str_extract(pattern = "_(AB|C|D|EF)_", string = target_heat$source, group = 1)
    target_heat <-
      subset(target_heat, building %in% keep_building)
    target_heat <-
      subset(target_heat, termo %in% keep_termo)


    baseline_cwu <- essential_data[["baseline_cwu"]]
    baseline_cwu$building <- str_extract(pattern = "SINGLE_FAMILY|MULTI_FAMILY|PUBLIC", string = baseline_cwu$target)
    baseline_cwu$termo <- str_extract(pattern = "_(AB|C|D|EF)_", string = baseline_cwu$target, group = 1)
    baseline_cwu <-
      subset(baseline_cwu, building %in% keep_building)
    baseline_cwu <-
      subset(baseline_cwu, termo %in% keep_termo)

    target_cwu <- essential_data[["target_cwu"]]
    target_cwu$building <- str_extract(pattern = "SINGLE_FAMILY|MULTI_FAMILY|PUBLIC", string = target_cwu$source)
    target_cwu$termo <- str_extract(pattern = "_(AB|C|D|EF)_", string = target_cwu$source, group = 1)
    target_cwu <-
      subset(target_cwu, building %in% keep_building)
    target_cwu <-
      subset(target_cwu, termo %in% keep_termo)




    if(aggr) {
      dir_graph <-
        rbind(baseline_heat,
              target_heat,
              baseline_cwu,
              target_cwu,
              savings_data)
      dir_graph <-
        subset(dir_graph, type %in% type_to_keep)
    } else {
      temp1 <-
        baseline_heat %>%
        select(source, target) %>%
        left_join(target_heat %>% rename(temp = target) %>% select(!c(termo, building)),
                  by = join_by(target == source)) %>%
        select(!target) %>%
        rename(target = temp)
      temp2 <-
        baseline_cwu %>%
        select(source, target) %>%
        left_join(target_cwu %>% rename(temp = target) %>% select(!c(termo, building)),
                  by = join_by(target == source)) %>%
        select(!target) %>%
        rename(target = temp)
      temp3 <-
        baseline_heat %>%
        select(source, target) %>%
        inner_join(savings_data %>% rename(temp = target) %>% select(!c(termo, building)),
                   by = join_by(target == source)) %>%
        select(!target) %>%
        rename(target = temp)

      dir_graph <-
        rbind(temp1,temp2,temp3)

    }

    dir_graph <-
      subset(dir_graph, type %in% type_to_keep)

    if(cwu_plus_co | (length(type_to_keep) == 1 & !cwu_plus_co)) {
      dir_graph <-
        aggregate(dir_graph$value,
                  by = list(dir_graph$source, dir_graph$target), FUN = sum)
      colnames(dir_graph) <- c("source", "target", "value")

    } else {
      dir_graph <-
        aggregate(dir_graph$value,
                  by = list(dir_graph$source, dir_graph$target, dir_graph$type), FUN = sum)
      colnames(dir_graph) <- c("source", "target", "type","value")
    }



    origin_path <-
      dir_graph$source[match(dir_graph$source, dir_graph$target)]
    # building_type <-
    #   ifelse(is.na(origin_path), dir_graph$target, dir_graph$source)
    # termo <-
    #   str_extract(pattern = "_(AB|C|D|EF)_", string = building_type, group = 1)
    # building <-
    #   str_extract(pattern = "SINGLE_FAMILY|MULTI_FAMILY|PUBLIC", string = building_type)
    #
    # dir_graph$building <- building
    # dir_graph$termo <- termo
    # dir_graph

    # dir_graph <-
    #   subset(dir_graph, building %in% keep_building)
    # dir_graph <-
    #   subset(dir_graph, termo %in% keep_termo)
    #
    if(link_colour == "building") {
      dir_graph$type <- dir_graph$building
    }

    if(link_colour == "termo") {
      dir_graph$type <- dir_graph$termo
    }

    origin_path <-
      dir_graph$source[match(dir_graph$source, dir_graph$target)]

    if(link_colour == "source") {
      col <-
        ifelse(is.na(origin_path), dir_graph$source, origin_path)
    } else if(link_colour == "target") {
      target_path <-
        dir_graph$target[match(dir_graph$target, dir_graph$source)]
      col <-
        ifelse(is.na(target_path), dir_graph$target, target_path)
    } else {
      col <- dir_graph$type
    }
    origin_path <-
      ifelse(is.na(origin_path), dir_graph$source, origin_path)


    nodes_names <- unique(c(unique(dir_graph$source), unique(dir_graph$target)))
    nodes <- data.frame(node = seq_along(nodes_names)-1,
                        name = nodes_names)
    links2 <-
      data.frame(
        source = nodes$node[match(dir_graph$source, nodes$name)],
        target = nodes$node[match(dir_graph$target, nodes$name)],
        value = dir_graph$value,
        type = col
      )
    links2

    sn <- networkD3::sankeyNetwork(Links = links2,
                                   Nodes = nodes,
                                   Source = 'source',
                                   Target = 'target',
                                   Value = 'value',
                                   NodeID = 'name',
                                   LinkGroup = "type",
                                   iterations = 100000,
                                   fontSize = 20)


    sn$x$links$origin <- origin_path



    ml <- htmlwidgets::onRender(
      sn,
      '
  function(el, x) {
    var nodes = d3.selectAll(".node");
    var links = d3.selectAll(".link");
    nodes.on("mousedown.drag", null); // remove the drag because it conflicts
    nodes.on("click", clicked);
    function clicked(d, i) {
      links
        .style("stroke-opacity", function(d1) {
            return d1.origin == d.name ? 0.7 : 0.005;
          });
    }
  }
  '
    )

    ml
}




ui <- fluidPage(
  tabsetPanel(
    tabPanel("Wczytanie i przygotowanie danych",
             fileInput("base_data", "Baseline data", buttonLabel = "Plik xlsx", accept = ".xlsx"),
             fileInput("target_data", "Target scenario data", buttonLabel = "Plik xlsx", accept = ".xlsx"),
             fileInput("zefir_label", "Etykiety stref", buttonLabel = "Plik xlsx", accept = ".xlsx")
    ),
    tabPanel("Sunkey",
             titlePanel("Customizacja"),
             sidebarLayout(
               sidebarPanel(
                 selectInput("aggr", "Czy pokazać pojedyncze strefy?", c(TRUE,FALSE)),
                 selectInput("link_colour", "Kolor połączeń", c("source", "target", "type", "building", "termo")),
                 selectInput("cwu_plus_co", "Czy ciepło ma zostać zsumowane?", c(TRUE,FALSE)),
                 selectInput("type_to_keep", "Rodzaj ciepła", c("cwu", "co"), multiple = TRUE, selected = c("cwu", "co")),
                 selectInput("keep_termo", "Klasy termomodernizacji", c("AB", "C", "D", "EF"), multiple = TRUE, selected = c("AB", "C", "D", "EF")),
                 selectInput("keep_building", "Rodzaje budynków", c("SINGLE_FAMILY", "MULTI_FAMILY", "PUBLIC"), multiple = TRUE, selected = c("SINGLE_FAMILY", "MULTI_FAMILY", "PUBLIC")),
                 numericInput("width_pixels", "Szerokość", value = 0, min = 0, max = 3000),
                 numericInput("height_pixels", "Wysokość", value = 0, min = 0, max = 4000),
                 actionButton("chart_draw", "Wingardium leviosa", class = "btn-block"),
                 width = 2
                 ),
             mainPanel(
               # sankeyNetworkOutput("Adava_kedavra",  width = 2000, height = 3000),
               uiOutput("Adava_kedavra"),
               width = 10
               # tableOutput("Adava_kedavra")
               )
             )
             )
    )
  )
# Define server logic required to draw a histogram
server <- function(input, output) {
  
  
  baseline_co <- reactive({
    req(input$base_data)
    readxl::read_xlsx(input$base_data$datapath, sheet = 1)
  })
  
  baseline_cwu <- reactive({
    req(input$base_data)
    readxl::read_xlsx(input$base_data$datapath, sheet = 2)
  })
  
  target_co <- reactive({
    req(input$target_data)
    readxl::read_xlsx(input$target_data$datapath, sheet = 1)
  })
  
  target_cwu <- reactive({
    req(input$target_data)
    readxl::read_xlsx(input$target_data$datapath, sheet = 2)
  })
  
  label_zones <- reactive({
    req(input$zefir_label)
    x <- readxl::read_xlsx(input$zefir_label$datapath, sheet = 1, col_names = FALSE)
    x <- x[[1]]
    x
  })
  
zones_aggr <- reactive(as.logical(input$aggr))
color_links <- reactive(input$link_colour)
sum_co_cwu <- reactive(as.logical(input$cwu_plus_co))
type_filter <- reactive(input$type_to_keep)
termo_filter <- reactive(input$keep_termo)
build_filter <- reactive(input$keep_building)
h_pixel <- eventReactive(input$chart_draw, {
    paste(input$height_pixels, "px", sep = "")

})
w_pixel <- eventReactive(input$chart_draw, {
  paste(input$width_pixels, "px", sep = "")
})


  
  # sunkey_plotting <- 
  #   eventReactive(input$chart_draw, {
  #     create_sunkey_zefir(base_heat = baseline_co(),
  #                         base_cwu = baseline_cwu(),
  #                         target_cwu = target_cwu(),
  #                         target_co = target_co(),
  #                         labels = label_zones(),
  #                         aggr = zones_aggr(), 
  #                         link_colour = color_links(),
  #                         type_to_keep = type_filter(),
  #                         keep_termo = termo_filter(),
  #                         cwu_plus_co = sum_co_cwu(),
  #                         keep_building = build_filter(),
  #                         width_pixels = NULL,
  #                         height_pixels = NULL)
      sunkey_plotting <-
        eventReactive(input$chart_draw, {
          create_sunkey_zefir(base_heat = baseline_co(),
                              base_cwu = baseline_cwu(),
                              target_cwu = target_cwu(),
                              target_co = target_co(),
                              labels = label_zones(),
                              aggr = zones_aggr(),
                              link_colour = color_links(),
                              type_to_keep = type_filter(),
                              keep_termo = termo_filter(),
                              cwu_plus_co = sum_co_cwu(),
                              keep_building = build_filter()
                              )
          })

  output$Sunkey <-
    renderSankeyNetwork(sunkey_plotting())
    #renderTable(sunkey_plotting())

  output$Adava_kedavra <- renderUI({
    sankeyNetworkOutput("Sunkey",  width = w_pixel(), height = h_pixel())
  })
  
  
}


# Run the application 
shinyApp(ui = ui, server = server)
