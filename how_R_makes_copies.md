How R makes copies
=======

*author*: Srikanth KS

`R` passes by *value*. This leads to multiple copies of `R` objects(objects are in RAM), although lazy evaluation and *copy-on-modify* semantics prevent it to some extent. This makes interactive use seamless but not apt for larger datasets.

The code below investigates, how `R` creates copies(and thereby consume memory). We are typically interested in peak memory utilization (should not be closer to the system's memory limit).

``` r
# # how R makes copies

library("peakRAM")
library("pryr")

# ## Vectors
# We stick to `numeric` vector. There are some savings with `integer` vector.
set.seed(1)
x <- rnorm(1e7)
object_size(x)        # around 76.3 or 80 MB
```

    ## 80 MB

``` r
address(x)
```

    ## [1] "0x7f17c895c010"

``` r
peakRAM(x[1:1e6])     # two copies of subset are present at some time
```

    ##   Function_Call Elapsed_Time_sec Total_RAM_Used_MiB Peak_RAM_Used_MiB
    ## 1    x[1:1e+06]            0.008                7.6              15.2

``` r
set.seed(2)
index <- sample(1:1e7, 1e6)
peakRAM(x[index])     # two copies of subset are present at some time
```

    ##   Function_Call Elapsed_Time_sec Total_RAM_Used_MiB Peak_RAM_Used_MiB
    ## 1      x[index]            0.025                7.7              11.5

``` r
peakRAM(x[1] <- 1)    # makes a copy of the object
```

    ##   Function_Call Elapsed_Time_sec Total_RAM_Used_MiB Peak_RAM_Used_MiB
    ## 1       x[1]<-1            0.029                  0              76.3

``` r
address(x)            # makes an in-place replacement
```

    ## [1] "0x7f17c3d10010"

``` r
peakRAM(x[1:10] <- 1) # makes just one copy
```

    ##   Function_Call Elapsed_Time_sec Total_RAM_Used_MiB Peak_RAM_Used_MiB
    ## 1    x[1:10]<-1                0                  0                 0

``` r
peakRAM(length(x))    # does not make a copy
```

    ##   Function_Call Elapsed_Time_sec Total_RAM_Used_MiB Peak_RAM_Used_MiB
    ## 1     length(x)                0                  0                 0

``` r
peakRAM(class(x))     # does not make a copy
```

    ##   Function_Call Elapsed_Time_sec Total_RAM_Used_MiB Peak_RAM_Used_MiB
    ## 1      class(x)                0                  0                 0

``` r
peakRAM(str(x))       # does not make a copy
```

    ##  num [1:10000000] 1 1 1 1 1 1 1 1 1 1 ...

    ##   Function_Call Elapsed_Time_sec Total_RAM_Used_MiB Peak_RAM_Used_MiB
    ## 1        str(x)                0                  0                 0

``` r
peakRAM(dim(x))       # does not make a copy
```

    ##   Function_Call Elapsed_Time_sec Total_RAM_Used_MiB Peak_RAM_Used_MiB
    ## 1        dim(x)                0                  0                 0

``` r
peakRAM(dim(x) <- c(10L, 1e6L)) # makes a copy
```

    ##             Function_Call Elapsed_Time_sec Total_RAM_Used_MiB
    ## 1 dim(x)<-c(10L,1000000L)            0.028                  0
    ##   Peak_RAM_Used_MiB
    ## 1              76.3

``` r
address(x)                      # at a different address
```

    ## [1] "0x7f17c895c010"

``` r
peakRAM(dim(x) <- NULL) # does not make a copy
```

    ##   Function_Call Elapsed_Time_sec Total_RAM_Used_MiB Peak_RAM_Used_MiB
    ## 1  dim(x)<-NULL                0                  0                 0

``` r
address(x)              # at the same address
```

    ## [1] "0x7f17c895c010"

``` r
rm(x, index)
invisible(gc())

# ## Lists

set.seed(2)
y        <- list(a = rnorm(1e7), b = rpois(1e7, 1L))
object_size(y)        # around 120 MB
```

    ## 120 MB

``` r
address(y)
```

    ## [1] "0x3cf9220"

``` r
peakRAM(z <- y[[2]])  # does not make a copy
```

    ##   Function_Call Elapsed_Time_sec Total_RAM_Used_MiB Peak_RAM_Used_MiB
    ## 1     z<-y[[2]]                0                  0                 0

``` r
address(z)            # pointing to a different address, but no actual copy
```

    ## [1] "0x7f17c6336010"

``` r
peakRAM(length(z))
```

    ##   Function_Call Elapsed_Time_sec Total_RAM_Used_MiB Peak_RAM_Used_MiB
    ## 1     length(z)                0                  0                 0

``` r
rm(z)
peakRAM(z <- y[1:2])                       # does not make a copy
```

    ##   Function_Call Elapsed_Time_sec Total_RAM_Used_MiB Peak_RAM_Used_MiB
    ## 1     z<-y[1:2]                0                  0                 0

``` r
peakRAM(y[["b"]] <- rchisq(1e7, df = 10))  # makes a copy
```

    ##                   Function_Call Elapsed_Time_sec Total_RAM_Used_MiB
    ## 1 y[["b"]]<-rchisq(1e+07,df=10)            0.928               76.3
    ##   Peak_RAM_Used_MiB
    ## 1              76.3

``` r
address(y)
```

    ## [1] "0x3c085a8"

``` r
# On the other hand,
set.seed(3)
z <- as.list(rnorm(1e7))
object_size(z)           # around 560 MB
```

    ## 560 MB

``` r
peakRAM(z[1:1e6])        # around of peak RAM 15.3 MB
```

    ##   Function_Call Elapsed_Time_sec Total_RAM_Used_MiB Peak_RAM_Used_MiB
    ## 1    z[1:1e+06]            0.024                7.6              15.3

``` r
peakRAM(z[[100]] <- 1)   # around a peak RAM(= total) of 76.3 MB
```

    ##   Function_Call Elapsed_Time_sec Total_RAM_Used_MiB Peak_RAM_Used_MiB
    ## 1   z[[100]]<-1            0.205                  0              76.3

``` r
# Does mem decrease if the list size decreases
sz <- as.list(rnorm(1e6/2))
peakRAM(sz[[100]] <- 1)     # around 3.8 MB of peak(=total) RAM 
```

    ##   Function_Call Elapsed_Time_sec Total_RAM_Used_MiB Peak_RAM_Used_MiB
    ## 1  sz[[100]]<-1            0.008                  0               3.8

``` r
peakRAM(length(y))    # does not make a copy
```

    ##   Function_Call Elapsed_Time_sec Total_RAM_Used_MiB Peak_RAM_Used_MiB
    ## 1     length(y)                0                  0                 0

``` r
peakRAM(class(y))     # does not make a copy
```

    ##   Function_Call Elapsed_Time_sec Total_RAM_Used_MiB Peak_RAM_Used_MiB
    ## 1      class(y)                0                  0                 0

``` r
peakRAM(str(y))       # does not make a copy, but some memory is used to print
```

    ## List of 2
    ##  $ a: num [1:10000000] -0.8969 0.1848 1.5878 -1.1304 -0.0803 ...
    ##  $ b: num [1:10000000] 13.5 4.29 6.5 14.26 13.88 ...

    ##   Function_Call Elapsed_Time_sec Total_RAM_Used_MiB Peak_RAM_Used_MiB
    ## 1        str(y)            0.001                  0                 0

``` r
peakRAM(names(y))     # does not make a copy
```

    ##   Function_Call Elapsed_Time_sec Total_RAM_Used_MiB Peak_RAM_Used_MiB
    ## 1      names(y)                0                  0                 0

``` r
invisible(gc())

# ## Environments

names(sz) <- 1:length(sz)
e         <- list2env(sz)
rm(y)
invisible(gc())
object_size(e)       # around 85 MB
```

    ## 84.8 MB

``` r
peakRAM(ls(e))       # around 3.8 MB of peak RAM
```

    ##   Function_Call Elapsed_Time_sec Total_RAM_Used_MiB Peak_RAM_Used_MiB
    ## 1         ls(e)            1.534                3.9               3.9

``` r
peakRAM(e[["101"]] <- 1) # almost no usage, this where significant saving comes
```

    ##   Function_Call Elapsed_Time_sec Total_RAM_Used_MiB Peak_RAM_Used_MiB
    ## 1 e[["101"]]<-1                0                  0                 0

``` r
rm(e, z, sz)

R.version
```

    ##                _                           
    ## platform       x86_64-pc-linux-gnu         
    ## arch           x86_64                      
    ## os             linux-gnu                   
    ## system         x86_64, linux-gnu           
    ## status                                     
    ## major          3                           
    ## minor          3.3                         
    ## year           2017                        
    ## month          03                          
    ## day            06                          
    ## svn rev        72310                       
    ## language       R                           
    ## version.string R version 3.3.3 (2017-03-06)
    ## nickname       Another Canoe

Complete chunk
==============

``` r
# # how R makes copies

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
```
