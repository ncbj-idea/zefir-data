
# Functions ---------------------------------------------------------------


# search for street_var with number in set A and if that names isn't in set B
# than move that pat to numer_var and in street_var remove
clean_street_name <- function(data, street_var, numer_var, bdot_var) {
  bdot_var <- str_to_lower(bdot_var)
  cond_test <- ifelse(str_detect(data[[street_var]], pattern = "^\\w(.)+\\d") & 
                        !str_to_lower(data[[street_var]]) %in% bdot_var & !is.na(data[[street_var]]), 
                      TRUE, FALSE)
  
  data[cond_test, numer_var] <-
    ifelse(is.na(data[cond_test, numer_var, drop = TRUE]),
           str_trim(str_extract(data[cond_test, numer_var],  pattern = regex("(\\s+\\d+(.)*$|\\s$)"))),
           data[cond_test, numer_var, drop = TRUE])
  data[cond_test, street_var] <-
    str_remove(data[cond_test, street_var, drop = TRUE],  pattern = regex("(\\s+\\d+(.)*$|\\s$)"))
  data
  
}

### Remove from numer information about oficyna and change typ_deklaracji 
### to B
oficyna_remover <- function(data, numer_var, deklaracja) {
  data[[deklaracja]] <-
    ifelse(str_detect(str_to_lower(data[[numer_var]]), pattern = "oficyna"),
           "B", data[[deklaracja]])
  data[[numer_var]] <- 
    str_trim(gsub("oficyna.*", x = data[[numer_var]], ignore.case = TRUE, replacement = ""))
  data
}


## remove records which include rod's or other problematic cases
dzialka_remover <- function(data, numer_var) {
  to_remove <- str_detect(str_to_lower(data[[numer_var]]), pattern = "dzialka|dz|działka|rod|altanka|altana|garaż|-$")
  data <- data[!to_remove,]
  data
}
### remove records, which dont have digits in numer variable
with_number <- function(data, numer_var) {
  to_remove <- str_detect(data[[numer_var]], "[\\d]", negate = TRUE)
  data <- data[!to_remove,]
  data
}

### remove from numer variable additional info
remove_add_info <- function(data, numer_var) {
  replacement_var <- gsub(x = data[[numer_var]], 
                          pattern = "lokal.*|\\s*-*\\s*front.*|lokal.*|lok.*|bud.*|paw.*|pawilon.*|", 
                          ignore.case = TRUE,
                          replacement = "")
  replacement_var <- str_trim(replacement_var)
  data[[numer_var]] <- replacement_var
  data
}
### remove paranthesis and its contents
paranthesis_remover <- function(data, numer_var) {
  data[[numer_var]] <- str_remove(data[[numer_var]], "\\(.*")
  data
}


### divide records by  too many letters in numer_var
records_too_many_letter <- function(data, numer_var) {
  to_remove <- str_detect(data[[numer_var]], pattern = "[a-zA-Z]{3,}")
  list(normal_data = data[!to_remove,],
       trash_data = data[to_remove,])
}

# divide address into ulica and numer (rather no need to use with ceeb data, used for zabytki and other data from city)
divide_address <- function(data, address_var, new_street_var, new_number_var) {
  data[[new_number_var]] <-  str_extract(data[[address_var]], pattern = regex("(\\s+\\d+(.)*$|\\s$)"))
  data[[new_street_var]] <- str_extract(data[[address_var]], pattern = regex("(.)*\\w(?=\\s+\\d+(.*)?$)", ignore_case = TRUE))
  data
}



####### remove slasher and numbers after it, if it isn't present in bdot numer data
# (assumptions: it is number of flat in multifamily house or just wrong number)
# and that part of string is moved to variable "Numery_lokali_mieszkalnych_objętych_deklaracją"
# if it is empty

slasher_case <- function(data, numer_var, lokal_var, bdot_slasher) {
  numer_addr <- data[[numer_var]]
  state_to_modify <- 
    str_detect(numer_addr, pattern = "/") & 
    !(numer_addr %in% bdot_slasher)
  data[[lokal_var]] <- 
    ifelse(state_to_modify & is.na(data[[lokal_var]]),
           str_extract(still_messy[[numer_var]], pattern = "/((.)+)$", group = 1),
           still_messy[[lokal_var]])
  data[[numer_var]] <- 
    ifelse(state_to_modify,
           str_remove(data[[numer_var]], pattern = "/(.)+$"), data[[numer_var]])
  data
  
}


# function duplicates record by occurrence of pattern in var_number
# it checks what symbol is in left and right hand than creates 
# natural ordered sequence, e.g. lef_hand = BE, righ_hand = BG,
# sequence is c(BE,BF,BG). Fucntion assumption is that only last symbol
# is changeable. Function mark some recors for review, for example pattern c(63a,b,c)
# is not detected and thus marked.
# var_number is column where value from sequance go
duplicated_by_dash <- function(data, numer_var, bdot_dash, duplication_id) {
  # browser()
  state_to_modify <- 
    str_detect(data[[numer_var]], "^[^-]*-[^-]*$") & 
    !data[[numer_var]] %in% bdot_dash
  
  
  data_to_modify <- 
    data[state_to_modify,]
  data_to_keep <- 
    data[!state_to_modify,]
  
  data_to_modify <- 
    split(data_to_modify, 1:nrow(data_to_modify))
  repaired_data <- map(data_to_modify, dash_duplicator, numer_var)
  
  rewizja_ceeb <- 
    do.call("rbind",map(repaired_data,1)[unlist(map(repaired_data,2))])
  repaired_df <- map(repaired_data,1)[!unlist(map(repaired_data,2))]
  
  label_id <- paste("dash", as.character(1:sum(unlist(map(repaired_data,2))), sep = "_"))
  
  repaired_df <- 
    map2(repaired_df, paste("dash", as.character(1:length(repaired_df), sep = "_")), 
         \(x,y) mutate(x, duplication_id =  y))
  
  clean_ceeb <- rbind(data_to_keep, 
                      do.call("rbind",repaired_df))
  
  list(clean_ceeb = clean_ceeb,
       rewizja_ceeb = rewizja_ceeb)
  
}

dash_duplicator <- function(prob_mixed, var_number) {
  # browser()
  last_symbol <- str_sub(prob_mixed[[var_number]], start = -1, end = -1)
  dec_x <- ifelse(str_detect(last_symbol, "\\d"), "number", "letter")
  left_hand <- ifelse(dec_x == "number",
                      str_extract(prob_mixed[[var_number]], pattern = "(\\d+)-", group = 1),
                      str_extract(prob_mixed[[var_number]], pattern = "([a-zA-Z]+)-", group = 1))
  right_hand <- ifelse(dec_x == "number",
                       str_extract(prob_mixed[[var_number]], pattern = "-(\\d+)", group = 1),
                       str_extract(prob_mixed[[var_number]], pattern = "-\\d*([a-zA-Z]+)", group = 1))
  
  if(dec_x != "number") {
    base_string <- str_extract(prob_mixed[[var_number]], pattern = "\\d+")
    left_length <- str_length(left_hand)
    right_length <- str_length(right_hand)
  }
  
  if(is.na(right_hand)| (is.na(left_hand) & dec_x == "number")) {
    list(df = prob_mixed, review = TRUE)
    } else {
      if(dec_x == "number") {
        left_hand <- as.numeric(left_hand)
        right_hand <- as.numeric(right_hand)
        if(left_hand > right_hand) {
          list(df = prob_mixed, review = TRUE)
          } else {
            numer_var <- seq(from = left_hand, to = right_hand, by = 1)
            prob_mixed <- prob_mixed[replicate(length(numer_var), 1),]
            prob_mixed[[var_number]] <- numer_var
            list(df = prob_mixed, review = FALSE)
          }
        
        } else {
          if(!is.na(left_length) & left_length != right_length & left_length >= 1) {
            list(df = prob_mixed, review = TRUE)
            } else {
              if(!is.na(left_hand)) {
                left_position <- which(str_to_lower(str_sub(left_hand, start = -1, end = -1)) == letters)
                base_case <- NULL
              } else {
                left_position <- 1
                base_case <- base_string
                left_hand <- right_hand
              }
              right_position <- which(str_to_lower(str_sub(right_hand, start = -1, end = -1)) == letters)
              if(left_position > right_position) {
                list(df = prob_mixed, review = TRUE)
              } else {
                letter_var <- seq(from = left_position, to = right_position, by = 1)
                
                if(str_sub(left_hand, start = -1, end = -1) %in% LETTERS) {
                  x <- paste(base_string, str_sub(left_hand,-5,-2), LETTERS[letter_var],sep = "")
                } else {
                  x <- paste(base_string, str_sub(left_hand, -5,-2), letters[letter_var], sep = "")
                }
                
                x <- c(base_case, x)
                prob_mixed <- prob_mixed[replicate(length(x), 1),]
                prob_mixed[[var_number]] <- x
              }
              list(df = prob_mixed, review = FALSE)
            }
          }
      }
  }


# duplicates record by coma separator. Sequance go to var_coma column.
duplicated_by_comma <- function(data, numer_var, duplication_id) {
  
  state_to_modify <- str_detect(data[[numer_var]], ",")
  data_to_modify <- 
    data[state_to_modify,]
  data_to_keep <- 
    data[!state_to_modify,]
  
  data_to_modify <- 
    split(data_to_modify, 1:nrow(data_to_modify))
  data_to_modify <- map(data_to_modify, coma_duplicator, numer_var)
  label_id <- paste("coma", as.character(1:length(data_to_modify), sep = "_"))
  data_to_modify <- 
    map2(data_to_modify,label_id, 
         \(x,y) mutate(x, duplication_id = y ))
  
  rbind(data_to_keep, do.call("rbind", data_to_modify))
}

coma_duplicator <- function(data, numer_var){
  
  if(str_detect(data[[numer_var]], 
                pattern = regex("\\d+[a-zA-Z]+\\s*,[a-zA-Z]"), negate = FALSE)) {
    
    number_to_add <- str_extract(data[[numer_var]], pattern = regex("^\\d+"))
    new_number <- unlist(str_split(data[[numer_var]], pattern = ","))
    new_number <- 
      c(new_number[1], paste(number_to_add, new_number[-1], sep = ""))
    data <- data[replicate(length(new_number), 1),]
    data[[numer_var]] <- new_number
    data
  } else {
    new_number <- unlist(str_split(data[[numer_var]], pattern = ","))
    data <- data[replicate(length(new_number), 1),]
    data[[numer_var]] <- new_number
    data
  }
  
}

## duplicate by " i ", need generalization with coma duplicator
duplicated_by_and <- function(data, numer_var, duplication_id) {
  
  state_to_modify <- str_detect(data[[numer_var]], " i ")
  data_to_modify <- 
    data[state_to_modify,]
  data_to_keep <- 
    data[!state_to_modify,]
  
  data_to_modify <- 
    split(data_to_modify, 1:nrow(data_to_modify))
  data_to_modify <- map(data_to_modify, and_duplicator, numer_var)
  label_id <- paste("and", as.character(1:length(data_to_modify), sep = "_"))
  data_to_modify <- 
    map2(data_to_modify,label_id, 
         \(x,y) mutate(x, duplication_id = y ))
  
  rbind(data_to_keep, do.call("rbind", data_to_modify))
}

and_duplicator <- function(data, numer_var){
  
  new_number <- unlist(str_split(data[[numer_var]], pattern = " i "))
  data <- data[replicate(length(new_number), 1),]
  data[[numer_var]] <- new_number
  data
  
}

### modification of liczba mieszkan
mieszkania_modification <- function(data, duplication_id,
                                    all_in, BorA, 
                                    mieszkania, objete_mieszkania,zbiorowe) {
  state_to_modify <- !is.na(data[[duplication_id]]) & data[[BorA]] == "A"
  data_to_modify <- data[state_to_modify,]
  data_to_keep <- data[!state_to_modify,]
  
  divider <- as.data.frame(table(data_to_modify[[duplication_id]]))
  colnames(divider)[1] <- duplication_id
  
  data_to_modify <- data_to_modify %>% left_join(divider, by = duplication_id)
  data_to_modify[[mieszkania]] <- 
    ifelse(data_to_modify[[all_in]] == "tak"|
             is.na(data_to_modify[[objete_mieszkania]]),
           floor(data_to_modify[[mieszkania]]/data_to_modify[["Freq"]]), 
           data_to_modify[[mieszkania]])
  data_to_modify[[objete_mieszkania]] <- 
    floor(data_to_modify[[objete_mieszkania]]/data_to_modify[["Freq"]])
  data_to_modify[[objete_mieszkania]] <- 
    ifelse(data_to_modify[[objete_mieszkania]] == 0 & !is.na(data_to_modify[[objete_mieszkania]]),
           1, data_to_modify[[objete_mieszkania]])
  data_to_modify[[mieszkania]] <- 
    ifelse(data_to_modify[[mieszkania]] == 0 & !is.na(data_to_modify[[mieszkania]]),
           1, data_to_modify[[mieszkania]])
  data_to_modify[["Freq"]] <- NULL
  
  rbind(data_to_keep,data_to_modify)
  
}


# remove abbreviation (two steps, because one step is problematic)
remove_abb <- function(data, street_var) {
  data[[street_var]] <- 
    gsub(pattern = "^ul\\.|^pl\\.|^os\\.|^ulica|^al\\.", replacement = "", data[[street_var]],
         ignore.case = TRUE)
  data[[street_var]] <- 
    gsub(pattern = "^\\s", replacement = "", data[[street_var]],
         ignore.case = TRUE)
  data
  
}

# duplicated_by_comma <- function(data, var_coma) {
#   if(str_detect(data[[var_coma]], pattern = regex("\\d+[a-zA-Z]+,[a-zA-Z]"), negate = FALSE)) {
#     number_to_add <- str_extract(data[[var_coma]], pattern = regex("^\\d+"))
#     new_number <- unlist(str_split(data[[var_coma]], pattern = ","))
#     new_number <- 
#       c(new_number[1], paste(number_to_add, new_number[-1], sep = ""))
#     data <- data[replicate(length(new_number), 1),]
#     data[[var_coma]] <- new_number
#     data
#   } else {
#     new_number <- unlist(str_split(data[[var_coma]], pattern = ","))
#     data <- data[replicate(length(new_number), 1),]
#     data[[var_coma]] <- new_number
#     data
#   }
# }


# close_to_clean$duplication_id <- NA
# x <- close_to_clean[str_detect(close_to_clean[[numer_col]], ","),]
# # exlude record with coma from data(later on coma split data will join to original data)
# close_to_clean <- close_to_clean[!str_detect(close_to_clean[[numer_col]], ","),]
# x <- split(x, 1:nrow(x))
# x <- map(x, duplicated_by_comma, numer_col)
# temp_var <- paste("coma", as.character(1:length(x), sep = "_"))
# x <- 
#   map2(x,temp_var, 
#        \(x,y) mutate(x, "duplication_id" = y ))
# close_to_clean <- 
#   rbind(close_to_clean,
#         do.call("rbind", x))