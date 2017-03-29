# how R makes copies
# author: Srikanth KS (talegari)

library("peakRAM")
library("pryr")

# ## Vectors
# We stick to `numeric` vector. There are some savings with `integer` vector.
set.seed(1)
x <- rnorm(1e7)
object_size(x)        # around 76.3 or 80 MB
address(x)

peakRAM(x[1:1e6])     # two copies of subset are present at some time

set.seed(2)
index <- sample(1:1e7, 1e6)
peakRAM(x[index])     # two copies of subset are present at some time

peakRAM(x[1] <- 1)    # makes a copy of the object
address(x)            # makes an in-place replacement

peakRAM(x[1:10] <- 1) # makes just one copy

peakRAM(length(x))    # does not make a copy
peakRAM(class(x))     # does not make a copy
peakRAM(str(x))       # does not make a copy
peakRAM(dim(x))       # does not make a copy

peakRAM(dim(x) <- c(10L, 1e6L)) # makes a copy
address(x)                      # at a different address

peakRAM(dim(x) <- NULL) # does not make a copy
address(x)              # at the same address

rm(x, index)
invisible(gc())

# ## Lists

set.seed(2)
y        <- list(a = rnorm(1e7), b = rpois(1e7, 1L))
object_size(y)        # around 120 MB
address(y)


peakRAM(z <- y[[2]])  # does not make a copy
address(z)            # pointing to a different address, but no actual copy
peakRAM(length(z))
rm(z)
peakRAM(z <- y[1:2])                       # does not make a copy
peakRAM(y[["b"]] <- rchisq(1e7, df = 10))  # makes a copy
address(y)

# On the other hand,
set.seed(3)
z <- as.list(rnorm(1e7))
object_size(z)           # around 560 MB
peakRAM(z[1:1e6])        # around of peak RAM 15.3 MB
peakRAM(z[[100]] <- 1)   # around a peak RAM(= total) of 76.3 MB

# Does mem decrease if the list size decreases
sz <- as.list(rnorm(1e6/2))
peakRAM(sz[[100]] <- 1)     # around 3.8 MB of peak(=total) RAM 

peakRAM(length(y))    # does not make a copy
peakRAM(class(y))     # does not make a copy
peakRAM(str(y))       # does not make a copy, but some memory is used to print
peakRAM(names(y))     # does not make a copy

invisible(gc())

# ## Environments

names(sz) <- 1:length(sz)
e         <- list2env(sz)
rm(y)
invisible(gc())
object_size(e)       # around 85 MB

peakRAM(ls(e))       # around 3.8 MB of peak RAM
peakRAM(e[["101"]] <- 1) # almost no usage, this where significant saving comes
rm(e, z, sz)

R.version
