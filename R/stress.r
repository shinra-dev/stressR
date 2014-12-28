stress.opts <- function(backoff=3600, verbose=TRUE, dryrun=FALSE, debug=FALSE)
{
  assert.wholenum(backoff)
  assert.type(verbose, "logical")
  assert.type(dryrun, "logical")
  assert.type(debug, "logical")
  
  backoff <- as.integer(backoff)
  assert.nonneg(backoff)
  
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
  assert.wholenum(bytes)
  assert.wholenum(stride)
  if (hang != Inf) assert.wholenum(hang)
  assert.type(keep, "logical")
  
  assert.nonneg(bytes)
  assert.nonneg(stride)
  assert.nonneg(hang)
  
  if (hang == 0) hang <- -1L
  else if (hang == Inf) hang <- 0L
  else hang <- as.integer(hang)
  
  bytes <- as.integer(bytes)
  stride <- as.integer(stride)
  
  
  ret <- list(bytes=bytes, stride=stride, hang=hang, keep=keep)
  class(ret) <- "vm_opts"
  
  return(ret)
}



stress <- function(timeout=1, cpu=0, io=0, vm=0, hdd=0, hdd_bytes=1024*1024*1024, vmopts=vm.opts(), opts=stress.opts())
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
  
  hdd_bytes <- as.integer(hdd_bytes)
  
  .Call(stress_main, 
        opts$verbose, opts$dryrun, opts$backoff, timeout, 
        cpu, io, vm, vmopts$bytes, vmopts$stride,
        vmopts$hang, vmopts$keep, hdd, hdd_bytes)
  
  return(invisible())
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



stress.hdd <- function(timeout=1, hdd=1, hdd_bytes=1024*1024*1024, opts=stress.opts())
{
  stress(timeout=timeout, cpu=0, io=0, vm=0, hdd=hdd, hdd_bytes=hdd_bytes, opts=stress.opts())
}

