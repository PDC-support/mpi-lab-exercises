# Overview

In this lab you will get more familiar with more advanced MPI topics, including one sided communication and MPI I/O.

### Goals

Get experience in MPI one sided communication, MPI I/O and topologies in MPI

### Duration

Three hours

# Source Codes

- MPI I/O. Serial hello world in C and Fortran ([hello_mpi.c](hello_mpi.c) and [hello_mpi.f90](hello_mpi.f90))
- MPI Derived types and I/O. Serial STL file reader in C and Fortran ([mpi_derived_types.c](mpi_derived_types.c) and [mpi_derived_types.f90](mpi_derived_types.f90)
- MPI Latency: C and Fortran ([mpi_latency.c](mpi_latency.c) and [mpi_latency.f90](mpi_latency.f90))
- MPI Bandwidth : C and Fortran ([mpi_bandwidth.c](mpi_bandwidth.c) and [mpi_bandwidth.f90](mpi_bandwidth.f90))
- MPI Bandwidth Non-Blocking: C and Fortran ([mpi_bandwidth-nonblock.c](mpi_bandwidth-nonblock.c) 
  and [mpi_bandwidth-nonblock.f90](mpi_bandwidth-nonblock.f90))
 

# Preparation

In preparation for this lab, read the [general instructions](../README.md) which will help you get going on Beskow.

# Exercise 1 - MPI I/O

MPI I/O is used so that results can be written to the same file in parallel. Take the serial hello world programs and modify them so that instead of writing the output to screen the output is written to a file using MPI I/O.

The simplest solution is likely to be for you to create a character buffer, and then use the MPI_File_write_at function.

# Exercise 2 - MPI I/O and derived types

Take the serial stl reader and modify it such that the stl file is read (and written) in parallel using collective MPI I/O. Use derived types such that the file can be read/written with a maximum of 3 I/O operations per read and write.

The simplest solution is likely to create a derived type for each triangle, and then use the MPI_File_XXXX_at_all function. A correct solution will have the same MD5 hash for both stl models (input and output), unless the order of the triangles has been changed.

```
md5sum out.stl data/sphere.stl
822aba6dc20cc0421f92ad50df95464c  out.stl
822aba6dc20cc0421f92ad50df95464c  data/sphere.stl
```

# Exercises 3 - Bandwidth and latency between nodes

Use `mpi_wtime` to compute latency and bandwidth with the bandwidth and latency codes above

**Note**: In modifying the original exercises provided by LLNL, We had to make a small change to the latency code as the Cray latency is a lot better than the tests were designed for. When the latency is of the order 1 millisecond, writing it out as an integer number of milliseconds did not make much sense.

For this exercise, it is nice to compare running on the same node e.g.

```
salloc -N 1 --ntasks-per-node=2 -A <project> -t 00:05:00
srun -n 2 ./mpi_latency.x
```

with running on separate nodes

```
salloc -N 2 --ntasks-per-node=1 -A <project> -t 00:05:00
srun -n 2 ./mpi_latency.x
```

Similarly for the bandwidth.

As you would expect the latency is much better on a single node than across nodes, but possibly unexpectedly if you just have 2 MPI tasks the bandwidth is better between nodes than across a single node. (probably related to lack of contention for resources, e.g. the gemini chips and the l3 cache etc.)

# Solutions

The solutions will be made available at the end of the lab.

# Acknowledgment

The examples in this lab are provided for educational purposes by 
[National Center for Supercomputing Applications](http://www.ncsa.illinois.edu/), 
(in particular their [Cyberinfrastructure Tutor](http://www.citutor.org/)), 
[Lawrence Livermore National Laboratory](https://computing.llnl.gov/) and 
[Argonne National Laboratory](http://www.mcs.anl.gov/). Much of the LLNL MPI materials comes from the 
[Cornell Theory Center](http://www.cac.cornell.edu/). 
We would like to thank them for allowing us to develop the material for machines at PDC. 
You might find other useful educational materials at these sites.


