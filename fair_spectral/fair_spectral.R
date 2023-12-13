

# Spectral clustering -----------------------------------------------------

gauss_dist <- function(x, sigma) {
  return(exp(-x^2/sigma))
  
}

full_connected <- function(x, ...) {
  
  gauss_dist(x, ...)
  
}
Tneighborhood <- function(x, epsilon) {
  temp_x <- x * (x < epsilon) # połączone tylko te wierzchołki, gdzie odległość < epsilon
  max_x <- max(temp_x[temp_x != 0])
  min_x <- min(temp_x[temp_x != 0]) # czy tutaj powinno być zero? aktualnie max(temp_x) zmienia się w 0
  return((max_x-temp_x)/(max_x-min_x)* (temp_x != 0))
}

Kneighborhood <- function(x, k = 10) {
  stopifnot(is.matrix(x))
  nrow_x <- nrow(x)
  stopifnot(k <= nrow_x)
  stopifnot(is.numeric(k))

  ordered_x <- apply(x,MARGIN = 2,  FUN = order)
  ordered_x <- ordered_x[2:(1+k),] # zwróć indeksy 10 najbliższych sąsiadóœ (bez 1 pozycji, bo bez relacji zwrotnej)
  

  temp_x <- purrr::map(1:nrow_x, .f = mutual_neighbor, kmatrix = ordered_x)
  temp_x <- lapply(X = temp_x, FUN = true_imputer, list_to_m = nrow_x)
  temp_x <- do.call("cbind", temp_x)
  
  temp_x <- x*temp_x
  
  max_x <- max(temp_x[temp_x != 0])
  min_x <- min(temp_x[temp_x != 0])
  return((max_x-temp_x)/(max_x-min_x)* (temp_x != 0))
  
}

mutual_neighbor <- function(searched, kmatrix) {
  temp <- kmatrix[as.logical(colSums(kmatrix[,kmatrix[,searched]] == searched)),searched]
  temp
}

true_imputer <- function(list_to_m, list_neigbor) {
  f_vector <- logical(list_to_m)
  f_vector[list_neigbor] <- TRUE
  f_vector
}

laplacian_matrix <- function(X, type = c("Kneighborhood", "full_connected", "Tneighborhood"), ...){
  
  stopifnot(type %in% c("Kneighborhood", "full_connected", "Tneighborhood"))
  distance_matrix <- as.matrix(dist(X))
  
  if(type == "Kneighborhood") {
    W_matrix <- Kneighborhood(distance_matrix, ...) 
  } else if(type == "full_connected") {
    W_matrix <- full_connected(distance_matrix, ...)
  } else {
    W_matrix <- Tneighborhood(distance_matrix, ...)
  }
  
  Lmatrix <- diag(colSums(W_matrix))- W_matrix 
  Lmatrix
}

spectral_clustering <- function(data, clusters, ...) {
  col_u <- nrow(data)
  l_matrix <- laplacian_matrix(X = data, ...)
  l_eigen <- eigen(l_matrix)
  u_matrix <- l_eigen$vectors[,(col_u-clusters+1):(col_u) ]
  kmeans(u_matrix, centers = clusters, nstart = 50)$cluster
}

Z_matrix <- function(membership){
  
  mm <- as.data.frame(membership)
  lum <- length(unique(membership))
  colnames(mm) <- "Proportion"
  tmp_f <- as.formula(paste("~", "Proportion-1", sep = ""))
  f_matrix <- model.matrix(tmp_f, data=mm )
  f_matrix <- as.matrix(f_matrix)[,-lum]
  nn <- nrow(f_matrix)
  prop_matrix <- t(colSums(f_matrix)/nn)
  prop_matrix <- prop_matrix[rep(1,nn), ]
  f_matrix <-  f_matrix - prop_matrix
  
  ortho_base <- pracma::nullspace(t(f_matrix))
  ortho_base
}



fair_spectral <- function(data, clusters, membership, ...) {
  
  l_matrix <- laplacian_matrix(X = data,  ...)
  zmx <- Z_matrix(membership)
  
  constr <- t(zmx) %*% l_matrix %*% zmx

  # żeby zlikwidować macierz zespoloną
  #constr <- (constr+t(constr))/2
  
  eig_constr <- eigen(constr)$vectors
  dim_u <- ncol(eig_constr)
  y_matrix <- eig_constr[,(dim_u-clusters+1):dim_u]
  
  h_matrix <- zmx %*% y_matrix
  kmeans(h_matrix, centers = clusters, nstart = 50, iter.max = 30)$cluster
  
}


laplacian_matrix2 <- function(X, type = c("Kneighborhood", "full_connected", "Tneighborhood"), ...){
  
  stopifnot(type %in% c("Kneighborhood", "full_connected", "Tneighborhood"))
  distance_matrix <- as.matrix(dist(X))
  
  if(type == "Kneighborhood") {
    W_matrix <- Kneighborhood(distance_matrix, ...) 
  } else if(type == "full_connected") {
    W_matrix <- full_connected(distance_matrix, ...)
  } else {
    W_matrix <- Tneighborhood(distance_matrix, ...)
  }
  
  diag_matrix <- diag(colSums(W_matrix))
  Lmatrix <- diag_matrix- W_matrix 
  list(diag_matrix, Lmatrix)
}

laplacian_matrix3 <- function(X, type = c("Kneighborhood", "full_connected", "Tneighborhood"), ...){
  
  stopifnot(type %in% c("Kneighborhood", "full_connected", "Tneighborhood"))
  distance_matrix <- as.matrix(dist(X))
  
  if(type == "Kneighborhood") {
    W_matrix <- Kneighborhood(distance_matrix, ...) 
  } else if(type == "full_connected") {
    W_matrix <- full_connected(distance_matrix, ...)
  } else {
    W_matrix <- Tneighborhood(distance_matrix, ...)
  }
  
  diag_matrix <- diag(colSums(W_matrix))
  Lmatrix <- diag_matrix- W_matrix 
  list(colSums(W_matrix), Lmatrix)
}


fair_spectral_norm <- function(data, clusters, membership, ...) {
  
  temp <- laplacian_matrix2(X = data,  ...)
  l_matrix <- temp[[2]]
  diag_matrix <- temp[[1]]
  zmx <- Z_matrix(membership)
  q_matrix <- expm::sqrtm(t(zmx) %*% diag_matrix %*% zmx)
  q_inv <- solve(q_matrix)
  constr <- t(q_inv) %*% t(zmx) %*% l_matrix %*% zmx %*% q_inv
  eig_constr <- eigen(constr)$vectors
  dim_u <- ncol(eig_constr)
  y_matrix <- eig_constr[,(dim_u-clusters+1):dim_u]
  
  h_matrix <- zmx %*% q_inv %*% y_matrix
  kmeans(h_matrix, centers = clusters, nstart = 50, iter.max = 30)$cluster
}



spectral_norm <- function(data, clusters, ...) {
  
  col_u <- nrow(data)
  temp <- laplacian_matrix3(X = data,  ...)
  l_matrix <- temp[[2]]
  diag_inv <- diag(1/sqrt(temp[[1]]))
  
  h_matrix <- diag_inv %*% l_matrix %*% diag_inv
  
  l_eigen <- eigen(h_matrix)
  u_matrix <- l_eigen$vectors[,(col_u-clusters+1):(col_u) ]
  
  kmeans(diag_inv %*% h_matrix, centers = clusters, nstart = 50, iter.max = 30)$cluster
}



