sendmessage <- function(message) {

	message <- gsub("\"", "'", message)
        message <- gsub("\n", " ", message)
        message <- paste("\"", message, "\"", sep="")
	cmd = paste("/home/cmonkey/sendmessage.rb", message, sep=" ")
	cat(paste("Sending message to SQS:",message, sep=" "))
	system(cmd)
}


sendmessage("starting")


install.packages("cMonkey_latest.tar.gz", repos=NULL, type="source", lib="/home/cmonkey/R")
plot.iters <- 0


tmp <- .libPaths()
tmp <- c("/home/cmonkey/R", tmp)
.libPaths(tmp)

load("/home/cmonkey/tmp/env.RData")

msg = "blank message"

if (e$iter <= 1) {

 if (!exists("dont.want.new.rnd.seed")) {
    s <- system("./get_random_seed.rb",T)
    i <- as.integer(s)
    cat(paste("setting random seed to",i,sep=" "))
    e$rnd.seed <- i
    set.seed(e$rnd.seed)
  }

	if (file.exists("/home/cmonkey/tmp/preinit.R")) {
       	        status <- try(source("/home/cmonkey/tmp/preinit.R"))
	        if (inherits(status, "try-error")) {
         	         sendmessage("user preinitialization script failed!")
      		         q("no", status=256)
      	       	} else {
			rm(status)
		}
	}

  print("Starting run from scratch")
  e$time.started = date()

  cat(paste("time is now", date(), "\n", sep=" "))
  msg = "starting_run_from_scratch"
} else {
  cat(paste("We are restarting an unfinished run at iteration",e$iter,sep=" "))
  cat("\n")
  msg = paste("restarting_run_at_iter_",e$iter,sep="")
}

sendmessage(msg)

setwd("/home/cmonkey/working_dir")


cm.func.each.iter <- function() {
  if ( iter %in% c( seq( 101, n.iter, by=100 ), n.iter ) ) {
    cat(paste("at iter", iter, "in cm.func.each.iter()",sep=" "))
    filename = "/home/cmonkey/tmp/partial.RData"
    save.cmonkey.env(e,filename)
    sendcmd = paste("../sendstate.rb", filename, sep=" ")
    system(sendcmd)
    sendmessage(paste("status=working,iters=",iter,sep=""))

  }
}


e$cm.func.each.iter <- cm.func.each.iter
environment( e$cm.func.each.iter ) <- e


e$plot.iters <- 0
result <- try(e$cmonkey(e,dont.init=T,plot.iters=0))
if (inherits(result, "try-error")) {
	e$save.cmonkey.env(e, "/home/cmonkey/tmp/partial.RData")
	errMsg <- paste("error: cmonkey run ended with error message:", result)
	sendmessage(errMsg)
	q("no", status=256)
}

sendmessage("cmonkey run complete")

if (file.exists("/home/cmonkey/tmp/postproc.R")) {
	sendmessage("post-processing script exists, running it...")
	status <- try(source("/home/cmonkey/tmp/postproc.R"))
        if (inherits(status, "try-error")) {
                 sendmessage("user post-processing script failed!")
		 print("user post-processing script failed!")
         } else {
		rm(status)
	}
	sendmessage("postprocessing script completed")
} else {
	sendmessage("no postprocessing script supplied")
}

if (!exists("time.ended",envir=e)) {
  e$time.ended = date()  
}
save.image("/home/cmonkey/tmp/complete.image.RData")
sendmessage("data saved")
