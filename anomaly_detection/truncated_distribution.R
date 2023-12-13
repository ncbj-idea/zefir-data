

### Pareto
dtpareto <- function(x, mu, sigma, upper_bound) {
  pp <- pPARETO2(q = upper_bound, mu = mu, sigma = sigma)
  dPARETO2(x = x, mu = mu, sigma = sigma)/pp
  
}

ptpareto <- function(q, mu, sigma, upper_bound) {
  pp <- pPARETO2(q = upper_bound, mu = mu, sigma = sigma)
  pPARETO2(q = q, mu = mu, sigma = sigma)/pp
  
}

qtpareto <- function(p, mu, sigma, upper_bound) {
  pp <- pPARETO2(q = upper_bound, mu = mu, sigma = sigma)
  mu*((1-p*pp)^-sigma-1)
}

### Dagum
dtdagum <- function(x, scale, shape1.a, shape2.p, upper_bound) {
  pp <- pdagum(q = upper_bound, scale = scale, shape1.a = shape1.a, shape2.p = shape2.p)
  ddagum(x = x,  scale = scale, shape1.a = shape1.a, shape2.p = shape2.p)/pp
  
}

ptdagum <- function(q, scale, shape1.a, shape2.p, upper_bound) {
  pp <- pdagum(q = upper_bound,  scale = scale, shape1.a = shape1.a, shape2.p = shape2.p)
  pdagum(q = q,  scale = scale, shape1.a = shape1.a, shape2.p = shape2.p)/pp
  
}

qtdagum <- function(p, scale, shape1.a, shape2.p, upper_bound) {
  pp <- pdagum(q = upper_bound,  scale = scale, shape1.a = shape1.a, shape2.p = shape2.p)
  scale * (expm1(-log(p*pp)/shape2.p))^(-1/shape1.a)
}


### Frechet
dtfrechet <- function(x, location, scale, shape, upper_bound) {
  pp <- pfrechet(q = upper_bound, location = location, scale = scale, shape = shape)
  dfrechet(x = x,  location = location, scale = scale, shape = shape)/pp
  
}

ptfrechet <- function(q, location, scale, shape, upper_bound) {
  pp <- pfrechet(q = upper_bound,  location = location, scale = scale, shape = shape)
  pfrechet(q = q,  location = location, scale = scale, shape = shape)/pp
  
}

qtfrechet <- function(p, location, scale, shape, upper_bound) {
  pp <- pfrechet(q = upper_bound,  location = location, scale = scale, shape = shape)
  location + scale * (-log(p*pp))^(-1/shape)
}

# Rayleigh
dtrayleigh <- function(x, scale, upper_bound) {
  pp <- prayleigh(q = upper_bound, scale = scale)
  drayleigh(x = x,  scale = scale)/pp
  
}

ptrayleigh <- function(q, scale = scale, upper_bound) {
  pp <- prayleigh(q = upper_bound,  scale = scale)
  prayleigh(q = q,  scale = scale)/pp
  
}

qtrayleigh <- function(p, scale, upper_bound) {
  pp <- prayleigh(q = upper_bound,  scale = scale)
  scale * sqrt(-2 * log1p(-p*pp))
}



bayes_prob <- function(x, 
                       var_A, 
                       event_A, 
                       threshold) {
  
  prob_A <- table(x[var_A])/nrow(x)
  prob_A <- prob_A[[event_A]]
  
  cond_prob <- subset(x, imported > threshold)
  cond_prob <- table(cond_prob[var_A])/nrow(cond_prob)
  cond_prob <- cond_prob[event_A]
  if(is.na(cond_prob)) {
    cond_prob <- 0
  }
  cond_prob <- unname(cond_prob)
  
  cond_prob/prob_A
}





