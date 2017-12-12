**Instructions and hints on how to run for the MPI course**

# Where to run

The exercises will be run on PDC's CRAY XC-40 system [Beskow](https://www.pdc.kth.se/hpc-services/computing-systems):

```
beskow.pdc.kth.se
```

# How to login

To access PDC's cluster you should use your laptop and the Eduroam or KTH Open wireless networks.

[Instructions on how to connect from various operating systems](https://www.pdc.kth.se/support/documents/login/login.html).


# More about the environment on Beskow

The Cray automatically loads several [modules](https://www.pdc.kth.se/support/documents/running/running_jobs/software.html#using-modules) at login.

- Heimdal - [Kerberos commands](https://www.pdc.kth.se/support/documents/login/login.html#general-information-about-kerberos)
- OpenAFS - [AFS commands](https://www.pdc.kth.se/support/documents/running/managing_files/afs.html)
- SLURM -  [queuing system commands](https://www.pdc.kth.se/support/documents/running/running_jobs/job_scheduling.html)


# Running MPI programs on Beskow

First it is necessary to book a node for interactive use:

```
salloc -A <allocation-name> -N 1 -t 1:0:0
```

Then the aprun command is used to launch an MPI application:

```
aprun -n 32 ./example.x
```

In this example we will start 32 MPI tasks (there are 32 cores per node on the Beskow nodes).

If you do not use aprun and try to start your program on the login node then you will get an error similar to

```
Fatal error in MPI_Init: Other MPI error, error stack:
MPIR_Init_thread(408): Initialization failed
MPID_Init(123).......: channel initialization failed
MPID_Init(461).......:  PMI2 init failed: 1
```


# MPI Exercises

- MPI Lab 1: [Program Structure and Point-to-Point Communication in MPI](lab1/instructions_lab1.md)
- MPI Lab 2: [Collective and Non-Blocking] Communication(lab1/instructions_lab1.md)
- MPI Lab 3: [Advanced Topics](lab1/instructions_lab1.md)
