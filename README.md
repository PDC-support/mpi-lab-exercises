
# Where to run

The exercises will be run on Dardel at PDC

```
dardel.pdc.kth.se
```

# How to login

To access PDC's cluster you should use your laptop and the Eduroam or KTH Open wireless networks.

[Instructions on how to connect from various operating systems](https://www.pdc.kth.se/support/documents/login/login.html).

# Compiling MPI programs on Dardel

By default the cray compiler is loaded into your environment. In order to use another compiler you have to swap compiler e.g.

```
module swap PrgEnv-cray PrgEnv-gnu
```

On Beskow one should always use the *compiler wrappers* `cc`, `CC` or 
`ftn` (for C, C++ and Fortran codes, respectively), 
which will automatically link to MPI libraries and linear 
algebra libraries like BLAS, LAPACK, etc.

Examples:

```
# Fortran
ftn [flags] source.f90
# C
cc [flags] source.c
# C++
CC [flags] source.cpp
```

# Running MPI programs on Dardel

First it is necessary to book a node for interactive use:

```
salloc -A <allocation-name> -N 1 -n <number of mpi ranks> -t 1:0:0 -p <partition-name> 
```

On the shared partition you can allocate a part of a node. On the main partition you awlays get the whole node with 2 CPUs with 64 physical cores each.

You might also need to specify a reservation by adding the flag 
`--reservation=<name-of-reservation>`.

Then the srun command is used to launch an MPI application:

```
srun -n <number of mpi ranks> ./example.x
```

In this example we will start 32 MPI tasks (there are 32 cores per node on the Beskow nodes).

If you do not use srun and try to start your program on the login node then you will get an error similar to

```
srun: error: Unable to allocate resources: No partition specified or system default partition
```

# MPI Exercises

The labs will be made available as different topics are covered in the MPI lectures.
