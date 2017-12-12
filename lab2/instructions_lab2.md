In this lab, you'll get familiar with MPI's Collection Communication routines, using them on programs you previously wrote with point-to-point calls. You'll also explore non-blocking behavior.

# Overview

**Goals**

Get familar with MPI Collective Communication routines and non-blocking calls

**Duration**

Three hours


# Source Codes

- Calculation of PI: Serial C and Fortran
- Send data across all processes : No source provided
- Game of Life: Serial C and Fortran
- Parallel Search: Serial C and Fortran
- Input file used in the Parallel Search program: b.data
- Output file from the Parallel Search program: reference.found.data

# Preparation

In preparation for this lab, read the [general instructions](../README.md) which will help you get going on Beskow.

# Exercise 1: Calculate PI Using Collectives

Calculates PI using a "dartboard" algorithm. If you're unfamiliar with this algorithm, checkout the Wikipedia page on 
[Monte Carlo Integration](http://en.wikipedia.org/wiki/Monte_Carlo_Integration) or 
*Fox et al.(1988) Solving Problems on Concurrent Processors, vol.1 page 207.*   
**Hint**: all processes should contribute to the calculation, with the master averaging the values for PI. Consider using `mpi_reduce` to collect results.


# Exercise 2: Send data across all processes using Non-Blocking

Take the code for sending data across all processes from the MPI Lab 1, and have each node add one to the number received, print out the result, and send the results on.

### Use Proper Synchronization

For the case where you want to use proper synchronization, you'll want to do a non-blocking receive, add one, print, then a non-blocking send. The result should be `1 - 2 - 3 - 4 - 5 ...`

### Try without Synchronization: Detect Race Conditions

To see what happens without synchronization, leave out the `wait`.

# Exercise 3: Find PI Using Non-Blocking Communications

Use a non-blocking send to try to overlap communication and computation. Take the PI code from Exercise 1 as your starting point.

# Exercise 4: Implement the "Game of Life" and "Parallel Search" Using Collectives

In almost every MPI program there are instances where all the processors in a communicator need to perform some sort of data transfer or calculation. These "collective communication" routines are the subject of this exercise and the "Game of Life" and "Parallel Search" programs are no exception.

### Your First Challenge

Modify your previous "Game of Life" code to use `mpi_reduce` to compute the total number of live cells, rather than individual sends and receives.

### Your Second Challenge

Modify your previous "Parallel Search" code to change how the master first sends out the target and subarray data to the slaves. Use the MPI broadcast routines to give each slave the target. Use the MPI scatter routine to give all processors a section of the array b it will search.

When you use the standard MPI scatter routine you will see that the global array b is now split up into four parts and the master process now has the first fourth of the array to search. So you should add a search loop (similar to the workers') in the master section of code to search for the target and calculate the average and then write the result to the output file. This is actually an improvement in performance since all the processors perform part of the search in parallel.

# Solutions

The solutions can be found in the [sol/ directory](sol/).

# Acknowledgment

The examples in this lab are provided for educational purposes by National Center for Supercomputing Applications, (in particular their Cyberinfrastructure Tutor), Lawrence Livermore National Laboratory and Argonne National Laboratory. Much of the LLNL MPI materials comes from the Cornell Theory Center. We would like to thank them for allowing us to develop the material for machines at PDC. You might find other useful educational materials at these sites.
