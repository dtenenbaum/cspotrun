# to be run like this:
# R CMD BATCH -q --vanilla --no-save --no-restore '--args a="somestr" b=c(2,5,6)' initenv.R log.txt

# arguments expected:
# cmonkey.workdir - the directory where the cmonkey initialization will take place (data/ and progs/ must exist here)
# organism - the three letter organism code
# ratios.file - the name of the file containing the ratios
# k.clust = the number of clusters (default 200)
# n.iter = the number of iterations (default 3000)
# parallel.cores = the number of cores
# out.filename = the file to write the initialized environment to (the environment will be called 'e')

args = (commandArgs(TRUE))
if (length(args) == 0) {
    print("No arguments supplied")
    q('no')
}


if (exists("n.iter")) {
    n.iter.saved <- n.iter
    rm(n.iter)
} else {
    n.iter.saved <- 2001
}


for (i in 1:length(args)) {
    eval(parse(text=args[[i]]))
}


pc <- parallel.cores

if (!exists("k.clust")) {
    k.clust <- 200
}



setwd(cmonkey.workdir)

ratios = read.delim(ratios.file, row.names=1)
#dim(ratios)
#colnames(ratios)
#rownames(ratios)

library(cMonkey)

plot.iters <- 0

cm.func.each.iter = function() {
    # do nothing
}

e = new.env()


e$cm.func.each.iter <- cm.func.each.iter

e <- cmonkey.init(e, organism=organism, plot.iters=0, k.clust=k.clust, parallel.cores=parallel.cores)


e$n.iter <- n.iter.saved

parallel.cores <- pc
e$parallel.cores <- parallel.cores
save.image(out.filename)
