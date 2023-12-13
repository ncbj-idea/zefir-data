
load_zefir_data <- function(baseline_path, heat_folder, position) {
  stopifnot("baseline_path should be character to zefir excel baseline" = is.character(baseline_path))
  stopifnot("baseline_path should be character to folder which contain zefir scenarios" = is.character(heat_folder))
  stopifnot("position should be numeric, which refers to position in alphabetical order" = is.numeric(position))
  
  heat_files <- list.files(heat_folder)
  target_path <- paste(heat_folder, heat_files[position], sep = "")
  
  heat_target <- 
    readxl::read_xlsx(target_path, sheet = 1)
  heat_baseline <- 
    readxl::read_xlsx(baseline_path, sheet = 1)
  cwu_target <- 
    readxl::read_xlsx(target_path, sheet = 2)
  cwu_baseline <- 
    readxl::read_xlsx(baseline_path, sheet = 2)
  
  list("baseline_heat" = heat_baseline,
       "target_heat" = heat_target,
       "baseline_cwu" = cwu_baseline,
       "target_cwu" = cwu_target)
}

# 
# create_strefa_names <- function(external_file = NULL) {
#   if(is.character(external_file)) {
#     kk <- readxl::read_xlsx(external_file, col_names = FALSE)
#     kk <- kk[[1]]
#     kk
#   } else {
#     "Strefa"
#   }
# }
# 
# 
# replace_strefa_names <- function(data, named_labels) {
#   colnames(data)[-1] <- paste(named_labels, colnames(data)[-1], sep = "_")
#   data
# }
# 
# essential_modification <- 
#   function(base_heat, base_cwu, target_cwu, target_co, labels_path = NULL) {
#     stopifnot("All loaded data should be data.frames" = 
#                 all(is.data.frame(base_heat),
#                     is.data.frame(base_cwu),
#                     is.data.frame(target_cwu),
#                     is.data.frame(target_co)))
#     stopifnot("Labels should be character string or NULL" = 
#                 is.character(labels_path)|is.null(labels_path))
#     
#     zones_labels <- create_strefa_names(external_file = labels_path)
#     
#     base_heat <- replace_strefa_names(base_heat, named_labels = zones_labels)
#     base_cwu <- replace_strefa_names(base_cwu, named_labels = zones_labels)
#     target_cwu <- replace_strefa_names(target_cwu, named_labels = zones_labels)
#     target_heat <- replace_strefa_names(target_co, named_labels = zones_labels)
#     
#     
#     base_heat <- 
#       tidyr::pivot_longer(base_heat, cols = -1, names_to = "target", values_to = "value")%>%
#       filter(value > 0)
#     target_heat <- 
#       tidyr::pivot_longer(target_heat, cols = -1, names_to = "source", values_to = "value")%>%
#       filter(value > 0)
#     base_cwu <- 
#       tidyr::pivot_longer(base_cwu, cols = -1, names_to = "target", values_to = "value") %>%
#       filter(value > 0)
#     target_cwu <- 
#       tidyr::pivot_longer(target_cwu, cols = -1, names_to = "source", values_to = "value") %>%
#       filter(value > 0)
#     
#     target_heat$type <- 
#       "co"
#     base_heat$type <- 
#       "co"
#     target_cwu$type <- 
#       "cwu"
#     base_cwu$type <- 
#       "cwu"
#     
#     colnames(base_heat)[1] <- "source"
#     colnames(base_cwu)[1] <- "source"
#     colnames(target_heat)[1] <- "target"
#     colnames(target_cwu)[1] <- "target"
#     
#     
#     target_heat$target <- paste("_", target_heat$target, sep = "")
#     target_cwu$target <- paste("_", target_cwu$target, sep = "")
#     target_heat <- target_heat[c("source", "target", "value", "type")]
#     target_cwu <- target_cwu[c("source", "target", "value", "type")]
#     
#     list("baseline_heat" = base_heat,
#          "target_heat" = target_heat,
#          "baseline_cwu" = base_cwu,
#          "target_cwu" = target_cwu)
#   }
# 
# 
# prepare_termo_savings <- function(target_data, baseline_data) {
#   savings <- 
#     target_data[c("source", "value")]
#   savings <- 
#     aggregate(savings$value, by = list(savings$source), FUN = sum)
#   colnames(savings) <- c("source", "target_value")
#   
#   aggr_baseline <- 
#     aggregate(baseline_data$value, by = list(baseline_data$target), FUN = sum)
#   colnames(aggr_baseline) <- c("target", "value")
#   
#   savings <- 
#     dplyr::left_join(savings, aggr_baseline, by = dplyr::join_by(source == target))
#   savings$value <- 
#     savings$value - savings$target_value
#   savings$target <- "savings"
#   savings <- savings[c("target", "value","source")]
#   savings <- subset(savings, value > 0)
#   savings$type <- "co"
#   savings <- as_tibble(savings)
#   savings
# }


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
    # browser()
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

# create_sunkey_zefir <- 
#   function(base_heat,
#            base_cwu,
#            target_cwu,
#            target_co,
#            labels = NULL,
#            aggr = c(TRUE, FALSE), 
#            cwu_plus_co = TRUE,
#            link_colour = c("source", "target", "type", "building", "termo"),
#            type_to_keep = c("co", "cwu"),
#            keep_termo = c("AB", "C", "D", "EF"),
#            keep_building = c("SINGLE", "MULTI", "PUBLIC"),
#            save_sunkey = NULL,
#            width_pixels = NULL,
#            height_pixels = NULL) {
# 
#     stopifnot("You can't color links by type of heat when heat is summed up" = !(link_colour == "type" & cwu_plus_co))
#     stopifnot("You can't color links by type of heat when only one type of heat is filtered out " = !(link_colour == "type" & length(type_to_keep) == 1))
#     stopifnot("The only allowed values od type_to_keep are 'co' or/and 'cwu" = all(type_to_keep %in% c("co", "cwu")))
#     stopifnot(is.logical(cwu_plus_co))
#     stopifnot(is.logical(aggr))
#     stopifnot("Link_color need to be one word" = length(link_colour) == 1)
#     stopifnot("The only allowed values od link_colour are: 'building' 'termo' 'type' 'building' 'source'"= all(link_colour %in% c("source", "target", "type", "building", "termo")))
#     stopifnot("You can't filter one type of heat when heat is summed up" = !(cwu_plus_co & length(type_to_keep) == 1))
#     stopifnot(any(is.numeric(height_pixels), is.null(height_pixels)))
#     stopifnot(any(is.numeric(width_pixels), is.null(width_pixels)))
#     stopifnot("It should be proper path (character string)" = is.character(save_sunkey))
#     stopifnot("The only allowed values od keep_termo are 'AB', 'C', 'D', 'EF'" = all(keep_termo %in% c("AB", "C", "D", "EF")))
#     stopifnot("The only allowed values od keep_building are 'SINGLE', 'MULTI', 'PUBLIC'" = all(keep_building %in% c("SINGLE", "MULTI", "PUBLIC")))
#     stopifnot("You can't color links by building or termo when heat is summed up" = !(aggr & link_colour %in% c("building", "termo")))
# 
#     essential_data <-
#       essential_modification(base_heat = base_heat,
#                              base_cwu = base_cwu,
#                              target_cwu = target_cwu,
#                              target_co = target_co,
#                              labels_path = labels)
# 
#     savings_data <-
#       prepare_termo_savings(target_data = essential_data$target_heat,
#                             baseline_data = essential_data$baseline_heat)
#     
#     
# 
# 
#     if(!aggr) {
#       dir_graph <-
#         rbind(essential_data$baseline_heat,
#               essential_data$target_heat,
#               essential_data$baseline_cwu,
#               essential_data$target_cwu,
#               savings_data)
#       dir_graph <-
#         subset(dir_graph, type %in% type_to_keep)
#     } else {
#       temp1 <-
#         essential_data$baseline_heat %>%
#         select(source, target) %>%
#         left_join(essential_data$target_heat %>% rename(temp = target),
#                   by = join_by(target == source)) %>%
#         select(!target) %>%
#         rename(target = temp)
#       temp2 <-
#         essential_data$baseline_cwu %>%
#         select(source, target) %>%
#         left_join(essential_data$target_cwu %>% rename(temp = target),
#                   by = join_by(target == source)) %>%
#         select(!target) %>%
#         rename(target = temp)
#       temp3 <-
#         essential_data$baseline_heat %>%
#         select(source, target) %>%
#         inner_join(savings_data %>% rename(temp = target), by = join_by(target == source)) %>%
#         select(!target) %>%
#         rename(target = temp)
# 
#       dir_graph <-
#         rbind(temp1,temp2,temp3)
# 
#     }
# 
#     dir_graph <-
#       subset(dir_graph, type %in% type_to_keep)
# 
#     if(cwu_plus_co | (length(type_to_keep) == 1 & !cwu_plus_co)) {
#       dir_graph <-
#         aggregate(dir_graph$value,
#                   by = list(dir_graph$source, dir_graph$target), FUN = sum)
#       colnames(dir_graph) <- c("source", "target", "value")
# 
#     } else {
#       dir_graph <-
#         aggregate(dir_graph$value,
#                   by = list(dir_graph$source, dir_graph$target, dir_graph$type), FUN = sum)
#       colnames(dir_graph) <- c("source", "target", "type","value")
#     }
# 
# 
# 
#     origin_path <-
#       dir_graph$source[match(dir_graph$source, dir_graph$target)]
#     building_type <-
#       ifelse(is.na(origin_path), dir_graph$target, dir_graph$source)
#     termo <-
#       str_extract(pattern = "_(AB|C|D|EF)_", string = building_type, group = 1)
#     building <-
#       str_extract(pattern = "SINGLE_FAMILY|MULTI_FAMILY|PUBLIC", string = building_type)
# 
#     dir_graph$building <- building
#     dir_graph$termo <- termo
#     dir_graph <-
#       subset(dir_graph, building %in% keep_building)
#     dir_graph <-
#       subset(dir_graph, termo %in% keep_termo)
# 
#     if(link_colour == "building") {
#       dir_graph$type <- dir_graph$building
#     }
# 
#     if(link_colour == "termo") {
#       dir_graph$type <- dir_graph$termo
#     }
# 
#     origin_path <-
#       dir_graph$source[match(dir_graph$source, dir_graph$target)]
# 
#     if(link_colour == "source") {
#       col <-
#         ifelse(is.na(origin_path), dir_graph$source, origin_path)
#     } else if(link_colour == "target") {
#       target_path <-
#         dir_graph$target[match(dir_graph$target, dir_graph$source)]
#       col <-
#         ifelse(is.na(target_path), dir_graph$target, target_path)
#     } else {
#       col <- dir_graph$type
#     }
#     origin_path <-
#       ifelse(is.na(origin_path), dir_graph$source, origin_path)
# 
# 
#     nodes_names <- unique(c(unique(dir_graph$source), unique(dir_graph$target)))
#     nodes <- data.frame(node = seq_along(nodes_names)-1,
#                         name = nodes_names)
#     links2 <-
#       data.frame(
#         source = nodes$node[match(dir_graph$source, nodes$name)],
#         target = nodes$node[match(dir_graph$target, nodes$name)],
#         value = dir_graph$value,
#         type = col
#       )
# 
# 
# 
#     sn <- networkD3::sankeyNetwork(Links = links2,
#                                    Nodes = nodes,
#                                    Source = 'source',
#                                    Target = 'target',
#                                    Value = 'value',
#                                    NodeID = 'name',
#                                    LinkGroup = "type",
#                                    iterations = 100000,
#                                    fontSize = 20,
#                                    height = height_pixels,
#                                    width = width_pixels)
#     sn$x$links$origin <- origin_path
# 
# 
# 
#     ml <- htmlwidgets::onRender(
#       sn,
#       '
#   function(el, x) {
#     var nodes = d3.selectAll(".node");
#     var links = d3.selectAll(".link");
#     nodes.on("mousedown.drag", null); // remove the drag because it conflicts
#     nodes.on("click", clicked);
#     function clicked(d, i) {
#       links
#         .style("stroke-opacity", function(d1) {
#             return d1.origin == d.name ? 0.7 : 0.005;
#           });
#     }
#   }
#   '
#     )
# 
#   networkD3::saveNetwork(ml,
#                          save_sunkey,
#                          selfcontained = TRUE)
#     
#   }

