\name{options}

\alias{stress.opts}
\alias{vm.opts}

\title{Stress Tester Options}

\description{
  .
}
\usage{
  stress.opts(backoff=3600, verbose=TRUE, dryrun=FALSE, debug=FALSE)
  vm.opts(bytes=256*1024*1024, stride=4096, hang=0, keep=FALSE)
}
\arguments{
  \item{backoff}{Wait time in microseconds before starting.}
  \item{verbose}{.}
  \item{dryrun}{.}
  \item{debug}{Show what would have been done without actually doing it.}
  \item{bytes}{The number of bytes allocated by each vm worker.}
  \item{stride}{Touch a byte every \code{stride} bytes.}
  \item{hang}{Time to sleep before calling free.}
  \item{keep}{Option to re-use memory rather than freeing and reallocating.}
}
\details{
  .
}
\value{
  .
}
\seealso{\code{\link{stress}}}


