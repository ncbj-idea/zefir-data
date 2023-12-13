library(readxl)
library(tidymodels)


# Prepare data ------------------------------------------------------------


build_data <- read_xlsx("data/temporary_class.xlsx")
need_class <- build_data[is.na(build_data$energy_class),]
have_class <- build_data[!is.na(build_data$energy_class),]

have_class <- 
  have_class %>% 
  select(energy_class, Wentylacja, Klimatyzacja, Ocieplenie_ścian, Okna, 
         Wiek_budynku_przed_modernizacją, Czy_poddasze_ogrzewane, Dach)
need_class <- 
  need_class %>% 
  select(energy_class, Wentylacja, Klimatyzacja, Ocieplenie_ścian, Okna, 
         Wiek_budynku_przed_modernizacją, Czy_poddasze_ogrzewane, Dach, id)



# Train model -------------------------------------------------------------
# set.seed(123)
set.seed(523)
build_split <- initial_split(have_class, prop = 0.75, strata = energy_class)
build_train <- training(build_split)
build_test <- testing(build_split)


build_folds <- vfold_cv(build_train, v = 10, repeats = 5)
build_recipes <- recipe(energy_class~., build_train)

tree_spec <- 
  decision_tree(
    cost_complexity = tune(),
    tree_depth = tune(),
    min_n = tune()) %>% 
  set_engine("rpart") %>% 
  set_mode("classification")
  
tree_wflow <- 
  workflow() %>% 
  add_model(tree_spec) %>% 
  add_recipe(build_recipes)

tree_param <- extract_parameter_set_dials(tree_spec)
tree_param %>% grid_latin_hypercube(size = 50, original = FALSE)
roc_res <- metric_set(accuracy)


set.seed(666)
build_tune <-
  tree_wflow %>%
  tune_grid(
    build_folds,
    grid = tree_param %>% grid_latin_hypercube(size = 50, original = FALSE),
    metrics = roc_res
  )

autoplot(build_tune) + 
  scale_color_viridis_d(direction = -1) + 
  theme(legend.position = "top")
show_best(build_tune)


# Finalzie ----------------------------------------------------------------

# najlepsze parametry
klkl <- show_best(build_tune, n =10)
tree_param <- tibble(
  cost_complexity = klkl[1,"cost_complexity" ],
  tree_depth = klkl[1,"tree_depth" ],
  min_n = klkl[1,"min_n" ]
  
)

final_tree_wflow <- 
  tree_wflow %>% 
  finalize_workflow(tree_param)

final_tree_fit <- 
  final_tree_wflow %>% 
  fit(build_train)

razem <- cbind(predict(final_tree_fit, build_test), 
               tibble(energy_class = build_test$energy_class))
razem <- razem %>% mutate_all(factor, levels = c("F","E","Dp","C","DDp" ,"D", "B", "Bz"))
accuracy(razem, 
         truth = energy_class, estimate = .pred_class)
tree_fit <- final_tree_fit %>% 
  extract_fit_parsnip()


rpart.plot::rpart.plot(tree_fit$fit,
                       roundint=FALSE,
                       extra = 0,
                       type = 5,
                       varlen = -10,
                       cex = 0.5)


need_class$energy_class <- predict(final_tree_fit, need_class)[,1,drop = TRUE]

x <- build_data[is.na(build_data$energy_class),] %>% arrange(id)
y <- build_data[!is.na(build_data$energy_class),]
x$energy_class <- need_class %>% arrange(id) %>% .$energy_class %>% as.character()
do_losowania <- rbind(x,y)

openxlsx::write.xlsx(do_losowania, "results/tree_data.xlsx")
saveRDS(final_tree_fit, file = "results/tree_model.RDS")





