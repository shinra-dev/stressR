/* A program to put stress on a POSIX system(stress).
 *
 * Copyright(C) 2001,2002,2003,2004,2005,2006,2007,2008,2009,2010
 * Amos Waterland <apw@rossby.metr.ou.edu>
 *
 * Modified 2014 by Drew Schmidt to be integrated into R
 * 
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation; either version 2 of the License, or(at your option)
 * any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc., 59
 * Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#include <ctype.h>
#include <errno.h>
#include <libgen.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>
#include <time.h>
#include <unistd.h>
#include <sys/wait.h>

#include <R.h>
#include <Rinternals.h>

#define INT(x) INTEGER(x)[0]


/* By default, print all messages of severity info and above.  */
int global_debug = 2;

/* Name of this program */
static char *global_progname = "stressR";

/* Implemention of runtime-selectable severity message printing.  */
#define dbg(STR, ARGS...) if (global_debug >= 3) \
	Rprintf("%s: dbug: [%lli] ", \
		global_progname,(long long)getpid()), \
		Rprintf(STR, ##ARGS)
#define out(STR, ARGS...) if (global_debug >= 2) \
	Rprintf("%s: info: [%lli] ", \
		global_progname,(long long)getpid()), \
		Rprintf(STR, ##ARGS)
#define wrn(STR, ARGS...) if (global_debug >= 1) \
	Rprintf("%s: WARN: [%lli](%d) ", \
		global_progname,(long long)getpid(), __LINE__), \
		Rprintf(STR, ##ARGS)
#define err(STR, ARGS...) if (global_debug >= 0) \
	Rprintf("%s: FAIL: [%lli](%d) ", \
		global_progname,(long long)getpid(), __LINE__), \
		Rprintf(STR, ##ARGS)



static int hogcpu(void)
{
  while (1)
    sqrt(unif_rand());
  
  return 0;
}

static int hogio()
{
  while (1)
    sync();
  
  return 0;
}

static int hogvm(long long bytes, long long stride, long long hang, int keep)
{
  long long i;
  char *ptr = 0;
  char c;
  int do_malloc = 1;
  
  while (1)
  {
    if (do_malloc)
    {
      dbg("allocating %lli bytes ...\n", bytes);
      if (!(ptr =(char *) malloc(bytes * sizeof(char))))
      {
        err("hogvm malloc failed: %s\n", strerror(errno));
        return 1;
      }
      if (keep)
        do_malloc = 0;
    }
    
    dbg("touching bytes in strides of %lli bytes ...\n", stride);
    for(i = 0; i < bytes; i += stride)
      ptr[i] = 'Z';           /* Ensure that COW happens.  */
    
    if (hang == 0)
    {
      dbg("sleeping forever with allocated memory\n");
      while (1)
        sleep(1024);
    }
    else if (hang > 0)
    {
      dbg("sleeping for %llis with allocated memory\n", hang);
      sleep(hang);
    }
    
    for(i = 0; i < bytes; i += stride)
    {
      c = ptr[i];
      if (c != 'Z')
      {
        err("memory corruption at: %p\n", ptr + i);
        return 1;
      }
    }
    
    if (do_malloc)
    {
      free(ptr);
      dbg("freed %lli bytes\n", bytes);
    }
  }
  
  return 0;
}

static int hoghdd(long long bytes)
{
  long long i, j;
  int fd;
  int chunk =(1024 * 1024) - 1;        /* Minimize slow writing.  */
  char buff[chunk];
  
  /* Initialize buffer with some random ASCII data.  */
  dbg("seeding %d byte buffer with random data\n", chunk);
  for(i = 0; i < chunk - 1; i++)
  {
    j = unif_rand();
    j =(j < 0) ? -j : j;
    j %= 95;
    j += 32;
    buff[i] = j;
  }
  buff[i] = '\n';

  while (1)
  {
    char name[] = "./stress.XXXXXX";
    
    if ((fd = mkstemp(name)) == -1)
    {
      err("mkstemp failed: %s\n", strerror(errno));
      return 1;
    }
    
    dbg("opened %s for writing %lli bytes\n", name, bytes);
    
    dbg("unlinking %s\n", name);
    if (unlink(name) == -1)
    {
      err("unlink of %s failed: %s\n", name, strerror(errno));
      return 1;
    }
    
    dbg("fast writing to %s\n", name);
    for(j = 0; bytes == 0 || j + chunk < bytes; j += chunk)
    {
      if (write(fd, buff, chunk) == -1)
        {
          err("write failed: %s\n", strerror(errno));
          return 1;
        }
    }
    
    dbg("slow writing to %s\n", name);
    for(; bytes == 0 || j < bytes - 1; j++)
    {
      if (write(fd, &buff[j % chunk], 1) == -1)
        {
          err("write failed: %s\n", strerror(errno));
          return 1;
        }
    }
    if (write(fd, "\n", 1) == -1)
    {
      err("write failed: %s\n", strerror(errno));
      return 1;
    }
    ++j;
    
    dbg("closing %s after %lli bytes\n", name, j);
    close(fd);
  }
  
  return 0;
}



SEXP stress_main(
  SEXP R_verbosity, SEXP R_dryrun, SEXP R_backoff, SEXP R_timeout,
  SEXP R_cpu, SEXP R_io, SEXP R_vm, SEXP R_vm_bytes, SEXP R_vm_stride,
  SEXP R_vm_hang, SEXP R_vm_keep, SEXP R_hdd, SEXP R_hdd_bytes)
{
  SEXP ret;
  PROTECT(ret = allocVector(INTSXP, 1));
  
  int pid, children = 0, retval = 0;
  long starttime, stoptime, runtime, forks;
  
  int do_dryrun;
  long long do_backoff, do_timeout, do_cpu, do_io;
  long long do_vm, do_vm_bytes, do_vm_stride, do_vm_hang, do_vm_keep;
  long long do_hdd, do_hdd_bytes;
  
  /* Record our start time.  */
  if ((starttime = time(NULL)) == -1)
    {
      err("failed to acquire current time: %s\n", strerror(errno));
      
      INT(ret) = 1;
      goto finish;
    }
  
  global_debug = INT(R_verbosity);
  do_dryrun = INT(R_dryrun);
  do_backoff = INT(R_backoff);
  if (do_backoff)
    dbg("setting backoff coeffient to %llius\n", do_backoff);
  
  do_timeout = INT(R_timeout);
  do_cpu = INT(R_cpu);
  do_io = INT(R_io);
  do_vm = INT(R_vm);
  do_vm_bytes = INT(R_vm_bytes);
  do_vm_stride = INT(R_vm_stride);
  do_vm_hang = INT(R_vm_hang);
  do_vm_keep = INT(R_vm_keep);
  do_hdd = INT(R_hdd);
  do_hdd_bytes = INT(R_hdd_bytes);
  
  
  /* Print startup message if we have work to do, bail otherwise.  */
  if (do_cpu + do_io + do_vm + do_hdd)
  {
    out("dispatching hogs: %lli cpu, %lli io, %lli vm, %lli hdd\n",
         do_cpu, do_io, do_vm, do_hdd);
  }
/*  else*/ // FIXME
/*    usage(0);*/
  
  /* Round robin dispatch our worker processes.  */
  while ((forks = (do_cpu + do_io + do_vm + do_hdd)))
  {
    long long backoff, timeout = 0;
    
    /* Calculate the backoff value so we get good fork throughput.  */
    backoff = do_backoff * forks;
    dbg("using backoff sleep of %llius\n", backoff);
    
    /* If we are supposed to respect a timeout, calculate it.  */
    if (do_timeout)
    {
      long long currenttime;
      
      /* Acquire current time.  */
      if ((currenttime = time(NULL)) == -1)
      {
        perror("error acquiring current time");
        INT(ret) = 1;
        goto finish;
      }
      
      /* Calculate timeout based on current time.  */
      timeout = do_timeout -(currenttime - starttime);
      
      if (timeout > 0)
      {
        dbg("setting timeout to %llis\n", timeout);
      }
      else
      {
        wrn("used up time before all workers dispatched\n");
        break;
      }
    }
    
    if (do_cpu)
    {
      switch (pid = fork())
      {
      case 0:            /* child */
        alarm(timeout);
        usleep(backoff);
        if (do_dryrun)
          INT(ret) = 0;
        else
          INT(ret) = hogcpu();
        
        goto finish;
      
      case -1:           /* error */
        err("fork failed: %s\n", strerror(errno));
        break;
      default:           /* parent */
        dbg("--> hogcpu worker %lli [%i] forked\n",
             do_cpu, pid);
        ++children;
      }
    --do_cpu;
    }
    
    if (do_io)
    {
      switch (pid = fork())
      {
      case 0:            /* child */
        alarm(timeout);
        usleep(backoff);
        if (do_dryrun)
          INT(ret) = 0;
        else
          INT(ret) = hogio();
        
        goto finish;
        
      case -1:           /* error */
        err("fork failed: %s\n", strerror(errno));
        break;
      default:           /* parent */
        dbg("--> hogio worker %lli [%i] forked\n", do_io, pid);
        ++children;
      }
      
      --do_io;
    }
    
    if (do_vm)
    {
      switch (pid = fork())
      {
      case 0:            /* child */
        alarm(timeout);
        usleep(backoff);
        if (do_dryrun)
          INT(ret) = 0;
        else
          INT(ret) = hogvm(do_vm_bytes, do_vm_stride, do_vm_hang, do_vm_keep);
        
        goto finish;
      
      case -1:           /* error */
        err("fork failed: %s\n", strerror(errno));
        break;
      default:           /* parent */
        dbg("--> hogvm worker %lli [%i] forked\n", do_vm, pid);
        ++children;
      }
      --do_vm;
    }
    
    if (do_hdd)
      {
        switch (pid = fork())
          {
          case 0:            /* child */
            alarm(timeout);
            usleep(backoff);
            if (do_dryrun)
              INT(ret) = 1;
            else
              INT(ret) = hoghdd(do_hdd_bytes);
            
            goto finish;
            
          case -1:           /* error */
            err("fork failed: %s\n", strerror(errno));
            break;
          default:           /* parent */
            dbg("--> hoghdd worker %lli [%i] forked\n",
                 do_hdd, pid);
            ++children;
          }
        --do_hdd;
      }
  }
  
  /* Wait for our children to exit.  */
  while (children)
  {
    int status, ret;
    
    if ((pid = wait(&status)) > 0)
    {
      --children;
      
      if (WIFEXITED(status))
      {
        if ((ret = WEXITSTATUS(status)) == 0)
        {
          dbg("<-- worker %i returned normally\n", pid);
        }
        else
        {
          err("<-- worker %i returned error %i\n", pid, ret);
          ++retval;
          wrn("now reaping child worker processes\n");
          if (signal(SIGUSR1, SIG_IGN) == SIG_ERR)
            err("handler error: %s\n", strerror(errno));
          if (kill(-1 * getpid(), SIGUSR1) == -1)
            err("kill error: %s\n", strerror(errno));
        }
      }
      else if (WIFSIGNALED(status))
      {
        if ((ret = WTERMSIG(status)) == SIGALRM)
        {
          dbg("<-- worker %i signalled normally\n", pid);
        }
        else if ((ret = WTERMSIG(status)) == SIGUSR1)
        {
          dbg("<-- worker %i reaped\n", pid);
        }
        else
        {
          err("<-- worker %i got signal %i\n", pid, ret);
          ++retval;
          wrn("now reaping child worker processes\n");
          if (signal(SIGUSR1, SIG_IGN) == SIG_ERR)
            err("handler error: %s\n", strerror(errno));
          if (kill(-1 * getpid(), SIGUSR1) == -1)
            err("kill error: %s\n", strerror(errno));
        }
      }
      else
      {
        err("<-- worker %i exited abnormally\n", pid);
        ++retval;
      }
    }
    else
    {
      err("error waiting for worker: %s\n", strerror(errno));
      ++retval;
      break;
    }
  }
  
  /* Record our stop time.  */
  if ((stoptime = time(NULL)) == -1)
  {
    err("failed to acquire current time\n");
    INT(ret) = 1;
    goto finish;
  }
  
  /* Calculate our runtime.  */
  runtime = stoptime - starttime;
  
  if (retval)
  {
    error("failed run completed in %lis\n", runtime);
  }
  else
  {
    out("successful run completed in %lis\n", runtime);
  }
  
  INT(ret) = retval;
  
  
  
  finish:
    UNPROTECT(1);
  
  
  return ret;
}

