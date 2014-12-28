must.be <- function(x, type)
{
  Rstuff <- c("character", "numeric", "integer", "double", "logical", "matrix", "data.frame", "vector")
  type <- match.arg(type, Rstuff)
  
  nm <- deparse(substitute(x))
  fun <- eval(parse(text=paste("is.", type, sep="")))
  
  if (!fun(x))
    stop(paste0("argument '", nm, "' must be of type ", type), call.=FALSE)
  
  return(invisible(TRUE))
}



stress.opts <- function(backoff=3600, verbose=TRUE, dryrun=FALSE, debug=FALSE)
{
  must.be(verbose, "logical")
  must.be(dryrun, "logical")
  
  backoff <- as.integer(backoff)
  if (backoff < 0) stop(paste0("argument 'backoff' must be >= 0; have backoff=", backoff))
  
  if (debug)
    verbose <- 3L
  else if (verbose)
    verbose <- 2L
  else
    verbose <- 0L
  
  ret <- list(backoff=backoff, verbose=verbose, dryrun=dryrun)
  class(ret) <- "stress_opts"
  
  return(ret)
}



vm.opts <- function(bytes=256*1024*1024, stride=4096, hang=0, keep=FALSE)
{
  must.be(keep, "logical")
  
  if (bytes < 0) stop(paste0("argument 'bytes' must be >= 0; have bytes=", bytes))
  if (stride < 0) stop(paste0("argument 'stride' must be >= 0; have stride=", stride))
  if (hang < 0) stop(paste0("argument 'hang' must be >= 0; have hang=", hang))
  
  if (hang == 0) hang <- -1L
  else if (hang == Inf) hang <- 0L
  else hang <- as.integer(hang)
  
  bytes <- as.integer(bytes)
  stride <- as.integer(stride)
  
  
  
  ret <- list(bytes=bytes, stride=stride, hang=hang, keep=keep)
  class(ret) <- "vm_opts"
  
  return(ret)
}



#print.stress <- function(x, ...)
#{
#  stress <- stress[1:(length(stress)-1)]
#  cat(paste(stress, collapse="\n"))
#  cat("\n")
#  
#  invisible()
#}



stress <- function(timeout=1, cpu=0, io=0, vm=0, hdd=0, vmopts=vm.opts(), opts=stress.opts())
{
  timeout <- as.integer(timeout)
  if (timeout < 0) stop(paste0("argument 'timeout' must be >= 0; have timeout=", timeout))
  
  if (class(vmopts) != "vm_opts")
    stop("argument ''")
  if (class(opts) != "stress_opts")
    stop("")
  
  cpu <- as.integer(cpu)
  io <- as.integer(io)
  vm <- as.integer(vm)
  hdd <- as.integer(hdd)
  
  hdd_bytes = 1024L * 1024L * 1024L
  
  ret <- .Call(stress_main, 
        opts$verbose, opts$dryrun, opts$backoff, timeout, 
        cpu, io, vm, vmopts$bytes, vmopts$stride,
        vmopts$hang, vmopts$keep, hdd, hdd_bytes)
  
  class(ret) <- "stress"
  return(ret)
}



stress.cpu <- function(timeout=1, cpu=1, opts=stress.opts())
{
  stress(timeout=timeout, cpu=cpu, io=0, vm=0, hdd=0, opts=stress.opts())
}



stress.io <- function(timeout=1, io=1, opts=stress.opts())
{
  stress(timeout=timeout, cpu=0, io=io, vm=0, hdd=0, opts=stress.opts())
}



stress.vm <- function(timeout=1, vm=1, vmopts=vm.opts(), opts=stress.opts())
{
  stress(timeout=timeout, cpu=0, io=0, vm=vm, hdd=0, vmopts=vm.opts, opts=stress.opts)
}



stress.hdd <- function()
{
  
}

