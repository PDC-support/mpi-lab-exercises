/**********************************************************************
 * FILE: mpi_pi_send.c
 * OTHER FILES: dboard.c
 * DESCRIPTION:  
 *   MPI pi Calculation Example - C Version 
 *   Point-to-Point communications example
 *   This program calculates pi using a "dartboard" algorithm.  See
 *   Fox et al.(1988) Solving Problems on Concurrent Processors, vol.1
 *   page 207.  All processes contribute to the calculation, with the
 *   master averaging the values for pi. This version uses non-blocking
 *   sends and receives to collect results.
 * AUTHOR: Blaise Barney. Adapted from Ros Leibensperger, Cornell Theory
 *   Center. Converted to MPI: George L. Gusciora, MHPCC (1/95) 
 * LAST REVISED: 04/13/05
 **********************************************************************/
#include "mpi.h"
#include <stdio.h>
#include <stdlib.h>

void srandom (unsigned seed);
double dboard (int darts);
#define DARTS 50000     /* number of throws at dartboard */
#define ROUNDS 10       /* number of times "darts" is iterated */
#define MASTER 0        /* task ID of master task */

int main (int argc, char *argv[])
{
  double homepi,         /* value of pi calculated by current task */
    sendpi,         /* copy of value of pi calculated by current task */
    pi,             /* average of pi after "darts" is thrown */
    avepi,          /* average pi value for all iterations */
    pirecv,         /* pi received from worker */
    pisum;          /* sum of workers pi values */
  int taskid,         /* task ID - also used as seed number */
    numtasks,       /* number of tasks */
    source,         /* source of incoming message */ 
    mtype,          /* message type */
    rc,             /* return code */
    i, n;
  MPI_Status status;
  MPI_Request request;

  /* Obtain number of tasks and task ID */
  MPI_Init(&argc,&argv);
  MPI_Comm_size(MPI_COMM_WORLD,&numtasks);
  MPI_Comm_rank(MPI_COMM_WORLD,&taskid);
  printf ("MPI task %d has started...\n", taskid);
  if (taskid == MASTER)
    printf ("Using %d tasks to compute pi (3.1415926535)\n",numtasks);

  /* Set seed for random number generator equal to task ID */
  srandom (taskid);

  avepi = 0;
  for (i = 0; i < ROUNDS; i++) {
    /* All tasks calculate pi using dartboard algorithm */
    homepi = dboard(DARTS);

    /* Workers send homepi to master */
    /* - Message type will be set to the iteration count */
    if (taskid != MASTER) {
      if(i!=0) {
	/* wait for previous message to finish */
	MPI_Wait(&request,&status);
      }

      mtype = i;
      sendpi=homepi;
      rc = MPI_Isend(&sendpi, 1, MPI_DOUBLE,
		     MASTER, mtype, MPI_COMM_WORLD,&request);
      if (rc != MPI_SUCCESS)
	printf("%d: Send failure on round %d\n", taskid, mtype);
     
      if(i==ROUNDS-1) {
	/* This is the very last message, so wait now */
	MPI_Wait(&request,&status);
      }

    } else {
      /* Master receives messages from all workers */
      /* - Message type will be set to the iteration count */
      /* - Message source will be set to the wildcard DONTCARE: */
      /*   a message can be received from any task, as long as the */
      /*   message types match */
      /* - The return code will be checked, and a message displayed */
      /*   if a problem occurred */
      mtype = i;
      pisum = 0;
      for (n = 1; n < numtasks; n++) {
	rc = MPI_Recv(&pirecv, 1, MPI_DOUBLE, MPI_ANY_SOURCE,
		      mtype, MPI_COMM_WORLD, &status);
	if (rc != MPI_SUCCESS) 
	  printf("%d: Receive failure on round %d\n", taskid, mtype);
	/* keep running total of pi */
	pisum = pisum + pirecv;
      }
      /* Master calculates the average value of pi for this iteration */
      pi = (pisum + homepi)/numtasks;
      /* Master calculates the average value of pi over all iterations */
      avepi = ((avepi * i) + pi)/(i + 1); 
      printf("   After %8d throws, average value of pi = %10.8f\n",
	     (DARTS * (i + 1)),avepi);
    }    
  } 

  MPI_Finalize();
  return 0;
}

/******************************************************************************
 * FILE: dboard.c
 * DESCRIPTION:
 *   Used in pi calculation example codes. 
 *   See mpi_pi_send.c and mpi_pi_reduce.c  
 *   Throw darts at board.  Done by generating random numbers 
 *   between 0 and 1 and converting them to values for x and y 
 *   coordinates and then testing to see if they "land" in 
 *   the circle."  If so, score is incremented.  After throwing the 
 *   specified number of darts, pi is calculated.  The computed value 
 *   of pi is returned as the value of this function, dboard. 
 *   Note:  the seed value for rand() is set in pi_send.f or pi_reduce.f. 
 * AUTHOR: unknown
 * LAST REVISED: 04/14/05 Blaise Barney
 ****************************************************************************/
/*
Explanation of constants and variables used in this function:
  darts       = number of throws at dartboard
  score       = number of darts that hit circle
  n           = index variable
  r           = random number between 0 and 1
  x_coord     = x coordinate, between -1 and 1
  x_sqr       = square of x coordinate
  y_coord     = y coordinate, between -1 and 1
  y_sqr       = square of y coordinate
  pi          = computed value of pi
*/


#include <stdio.h>
#include <stdlib.h>
#define sqr(x)((x)*(x))
long random(void);

double dboard(int darts)
{
  double x_coord, y_coord, pi, r; 
  int score, n;
  unsigned int cconst;  /* must be 4-bytes in size */
  /*************************************************************************
   * The cconst variable must be 4 bytes. We check this and bail if it is
   * not the right size
   ************************************************************************/
  if (sizeof(cconst) != 4) {
    printf("Wrong data size for cconst variable in dboard routine!\n");
    printf("See comments in source file. Quitting.\n");
    exit(1);
  }
  cconst = 2 << (31 - 1);
  score = 0;

  /* "throw darts at board" */
  for (n = 1; n <= darts; n++)  {
    /* generate random numbers for x and y coordinates */
    r = (double)random()/cconst;
    x_coord = (2.0 * r) - 1.0;
    r = (double)random()/cconst;
    y_coord = (2.0 * r) - 1.0;

    /* if dart lands in circle, increment score */
    if ((sqr(x_coord) + sqr(y_coord)) <= 1.0)
      score++;
  }

  /* calculate pi */
  pi = 4.0 * (double)score/(double)darts;
  return(pi);
}
