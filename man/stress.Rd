% Generated by roxygen2 (4.1.0): do not edit by hand
% Please edit documentation in R/stress.r
\name{stress}
\alias{stress}
\alias{stress.cpu}
\alias{stress.hdd}
\alias{stress.io}
\alias{stress.vm}
\title{Stress Tester}
\usage{
stress(timeout = 1, cpu = 0, io = 0, vm = 0, hdd = 0,
  hdd_bytes = 1024 * 1024 * 1024, vmopts = vm.opts(),
  opts = stress.opts())

stress.cpu(timeout = 1, cpu = 1, opts = stress.opts())

stress.io(timeout = 1, io = 1, opts = stress.opts())

stress.vm(timeout = 1, vm = 1, vmopts = vm.opts(), opts = stress.opts())

stress.hdd(timeout = 1, hdd = 1, hdd_bytes = 1024 * 1024 * 1024,
  opts = stress.opts())
}
\arguments{
\item{timeout}{Run time for the test in seconds.  If 0, the test will run
forever (and may be impossible to kill from the R console!).}

\item{cpu}{The number of CPU workers to spawn.}

\item{io}{The number of IO workers to spawn.}

\item{vm}{The number of memory workers to spawn.}

\item{hdd}{The number of writers to spawn.}

\item{hdd_bytes}{The number of bytes written per hdd worker.}

\item{vmopts}{.}

\item{opts}{.}
}
\value{
Each function returns \code{NULL}.
}
\description{
TODO.
}
\details{
TODO

\tabular{ll}{ cpu \tab spins on \code{sqrt} \cr io \tab spins on \code{sync}
\cr vm \tab spins on \code{malloc/free} \cr hdd \tab spins on
\code{write/unlink} \cr }
}
\examples{
\dontrun{
library(stressR)

stress.cpu(cpu=1)
}
}
\seealso{
\code{\link{options}}
}

