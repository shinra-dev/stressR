assert.type <- function(x, type)
{
  Rstuff <- c("character", "numeric", "integer", "double", "logical", "matrix", "data.frame", "vector")
  type <- match.arg(type, Rstuff)
  
  nm <- deparse(substitute(x))
  fun <- eval(parse(text=paste("is.", type, sep="")))
  
  if (!fun(x))
    stop(paste0("argument '", nm, "' must be of type ", type), call.=FALSE)
  
  return(invisible(TRUE))
}



assert.nonneg <- function(x)
{
  nm <- deparse(substitute(x))
  
  if (x < 0)
    stop(paste0("argument '", nm, "' must be >= 0; have ", nm, "=", x), call.=FALSE)
  
  return(invisible(TRUE))
}



isint <- function(x)
{
  epsilon <- 1e-8
  
  return(abs(x - round(x)) < epsilon)
}



assert.wholenum <- function(x)
{
  nm <- deparse(substitute(x))
  
  if (x < 0)
    stop(paste0("argument '", nm, "' must be an integer; have ", nm, "=", x), call.=FALSE)
  
  return(invisible(TRUE))
}
