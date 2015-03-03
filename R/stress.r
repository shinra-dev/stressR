#' @name options
#' @rdname options
#' 
#' @title Stress Tester Options
#' 
#' @description
#' TODO.
#' 
#' @details
#' TODO.
#' 
#' @aliases stress.opts vm.opts
#' @param backoff
#' Wait time in microseconds before starting.
#' @param verbose 
#' .
#' @param dryrun 
#' .
#' @param debug 
#' Show what would have been done without actually doing it.
#' @param bytes 
#' The number of bytes allocated by each vm worker.
#' @param stride 
#' Touch a byte every \code{stride} bytes.
#' @param hang 
#' Time to sleep before calling free.
#' @param keep 
#' Option to re-use memory rather than freeing and reallocating.
#' 
#' @return
#' TODO.
#' 
#' @seealso \code{\link{stress}}
#' 
#' @export
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


#' @rdname options
#' 
#' @export
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




#' @name stress
#' @rdname stress
#' 
#' @title Stress Tester
#' 
#' @description 
#' TODO.
#' 
#' @details
#' TODO
#' 
#' \tabular{ll}{ cpu \tab spins on \code{sqrt} \cr io \tab spins on \code{sync}
#' \cr vm \tab spins on \code{malloc/free} \cr hdd \tab spins on
#' \code{write/unlink} \cr }
#' 
#' @aliases stress stress.cpu stress.io stress.vm stress.hdd
#' 
#' @param timeout 
#' Run time for the test in seconds.  If 0, the test will run
#' forever (and may be impossible to kill from the R console!).
#' @param cpu 
#' The number of CPU workers to spawn.
#' @param io 
#' The number of IO workers to spawn.
#' @param vm 
#' The number of memory workers to spawn.
#' @param hdd 
#' The number of writers to spawn.
#' @param hdd_bytes 
#' The number of bytes written per hdd worker.
#' @param vmopts 
#' .
#' @param opts 
#' .
#' 
#' @return Each function returns \code{NULL}.
#' 
#' @seealso \code{\link{options}}
#' 
#' @examples
#' 
#' \dontrun{
#' library(stressR)
#' 
#' stress.cpu(cpu=1)
#' }
#' 
#' @export stress
stress <- function(timeout=1, cpu=0, io=0, vm=0, hdd=0, hdd_bytes=1024*1024*1024, vmopts=vm.opts(), opts=stress.opts())
{
  timeout <- as.integer(timeout)
  assert.nonneg(timeout)
  
  assert.class(vmopts, "vm_opts")
  assert.class(opts, "stress_opts")
  
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


#' @rdname stress
#' 
#' @export
stress.cpu <- function(timeout=1, cpu=1, opts=stress.opts())
{
  stress(timeout=timeout, cpu=cpu, io=0, vm=0, hdd=0, opts=opts)
}


#' @rdname stress
#' 
#' @export
stress.io <- function(timeout=1, io=1, opts=stress.opts())
{
  stress(timeout=timeout, cpu=0, io=io, vm=0, hdd=0, opts=opts)
}


#' @rdname stress
#' 
#' @export
stress.vm <- function(timeout=1, vm=1, vmopts=vm.opts(), opts=stress.opts())
{
  stress(timeout=timeout, cpu=0, io=0, vm=vm, hdd=0, vmopts=vmopts, opts=opts)
}


#' @rdname stress
#' 
#' @export
stress.hdd <- function(timeout=1, hdd=1, hdd_bytes=1024*1024*1024, opts=stress.opts())
{
  stress(timeout=timeout, cpu=0, io=0, vm=0, hdd=hdd, hdd_bytes=hdd_bytes, opts=opts)
}

