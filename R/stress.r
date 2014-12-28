stress <- function()
{
#  // magic num, bool, natnum, natnum
#  // natnum, natnum, natnum, natnum, natnum
#  // natnum, bool, natnum, natnum
  verbosity <- 3L
  dryrun = 0L
  backoff = 3000L
  timeout = 0L
  cpu = 0L
  io = 0L
  vm = 0L
  vm_bytes = 256L * 1024L * 1024L
  vm_stride = 4096L
  vm_hang = -1L
  vm_keep = 0L
  hdd = 0L
  hdd_bytes = 1024L * 1024L * 1024L
  
  .Call(stress_main, 
        verbosity, dryrun, backoff, timeout, 
        cpu, io, vm, vm_bytes, vm_stride,
        vm_hang, vm_keep, hdd, hdd_bytes)
  
  NULL
}
