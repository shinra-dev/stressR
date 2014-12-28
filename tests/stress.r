library(stressR)

opts <- stress.opts(debug=TRUE)

stress.cpu(cpu=1, opts=opts)
#stress.io(io=1)
#stress.vm(vm=1)
#stress.hdd(hdd=1)
