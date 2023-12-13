

cieplownia <-data.frame(a=c(432.883,	429.911365,	426.9397,	423.9681,	420.9965,	418.0248,	415.0532,	412.0816,	413.9346,	415.788,	417.6408,	419.4938,	421.3469,	423.2,	425.0531,	426.9061,	428.7592,	430.6123,	432.4653,	434.3184,	436.1715,	438.0246,	439.8776,	441.7307,	443.5838))

zefir_weighted_mean <- function(x, period, type = c("linear", "harmonic", "square")) {
  stopifnot(is.data.frame(x))
  stopifnot(is.numeric(period) & period > 1 & period <= nrow(x))
  stopifnot(type %in% c("linear", "harmonic", "square"))
  truncated_forecast <- x[1:period,,drop = FALSE]
  if(type == "linear") {
    period_weight <- seq(1,period, by = 1)
    period_weight <- period_weight/sum(period_weight)
    period_weight <- rev(period_weight)
    apply(truncated_forecast, MARGIN = 2, weighted.mean, w = period_weight)
    
  } else if(type == "harmonic") {
    
    period_weight <- numeric(period+1)
    period_weight[1] <- 0
    for(i in 2:(period+1)) {
      period_weight[i] <- period_weight[i-1]+1/(period*(period+2-i))
    }
    period_weight <- rev(period_weight[-1])
    apply(truncated_forecast, MARGIN = 2, weighted.mean, w = period_weight)
  } else {
    
    period_weight <- seq(1,period, by = 1)
    period_weight <- 6*period_weight^2/(period*(period+1)*(2*period+1))
    period_weight <- rev(period_weight)
    apply(truncated_forecast, MARGIN = 2, weighted.mean, w = period_weight)
  }
  
}

zefir_weighted_mean(x, period = 10, type = "square")
zefir_weighted_mean(cieplownia, period = 2, type = "linear")



