/****************************
    Conway Game of Life

       2 processors
  divide domain top-bottom
 (break with horizontal line)
*****************************/

#include "mpi.h"
#include <stdio.h>
#include <stdlib.h>

#define NI 200
#define NJ 200

#define NSTEPS 500

int main(int argc, char *argv[]){

  int i, j, n, im, ip, jm, jp, nsum, isum, isum1, nprocs ,myid, ierr;
  int ig, jg, i1g, i2g, j1g, j2g, ninom, njnom, ninj, i1, i2, i2m,
    j1, j2, j2m, ni, nj, isumloc,igrid;
  int niproc, njproc;
  int **old, **new, *old1d, *new1d;
  MPI_Status status;

  MPI_Win top_win,bottom_win;
  MPI_Aint size;
  int disp_unit,above_rank,below_rank;

  float x;

  /* initialize MPI */

  MPI_Init(&argc,&argv);
  MPI_Comm_size(MPI_COMM_WORLD,&nprocs);
  MPI_Comm_rank(MPI_COMM_WORLD,&myid);

  /* nominal number of points per proc. in each direction,
     without ghost cells, assume numbers divide evenly */ 

  niproc = nprocs;   /* divide domain in i direction only */ 
  njproc = 1;   
  ninom = NI/niproc;
  njnom = NJ/njproc;

  /* NI must be exactly divisble by nprocs */

  if(ninom*niproc!=NI) {
    igrid=NI;
    printf("Need to be able to divide the i grid exactly between the processes\n");
    printf("grid points in i=%d nprocs=%d\n",igrid,nprocs);
    MPI_Abort(MPI_COMM_WORLD, 1);
  }
      
  /* global starting and ending indices (without ghost cells) */

  i1g = (myid*ninom) + 1;
  i2g = i1g + ninom - 1;
  j1g = 1;
  j2g = njnom;

  /* local starting and ending indices, including ghost cells */

  i1  = 0;
  i2  = ninom + 1;
  i2m = i2 - 1;
  j1  = 0;
  j2  = njnom + 1;
  j2m = j2 - 1;

  /* allocate arrays; want elements to be contiguous, so
     allocate 1-D arrays, then set pointer to each row (old
     and new) to allow use of array notation for convenience */

  ni = i2-i1+1;
  nj = j2-j1+1;
  ninj = ni*nj;

  old1d = malloc(ninj*sizeof(int));
  new1d = malloc(ninj*sizeof(int));
  old   = malloc(ni*sizeof(int*));
  new   = malloc(ni*sizeof(int*));

  for(i=0; i<ni; i++){
    old[i] = &old1d[i*nj];
    new[i] = &new1d[i*nj];
  }

  /* create the memory window */

  disp_unit=sizeof(int);
  size=(njnom)*sizeof(int);

  MPI_Win_create(&old[1][1],size,disp_unit,MPI_INFO_NULL,MPI_COMM_WORLD,&top_win);
  MPI_Win_create(&old[ninom][1],size,disp_unit,MPI_INFO_NULL,MPI_COMM_WORLD,&bottom_win);

  /*  Initialize elements of old to 0 or 1.
      We're doing some sleight of hand here to make sure we
      initialize to the same values as in the serial case.
      The rand() function is called for every i and j, even
      if they are not on the current processor, to get the same
      random distribution as the serial case, but they are
      only used if i and j reside on the current procesor. */

  
  for(ig=1; ig<=NI; ig++){
    for(jg=1; jg<=NJ; jg++){
      x = rand()/((float)RAND_MAX + 1);
      
      /* if this i is on the current processor */
      if( ig >= i1g && ig <= i2g ){

        /* local i and j indices, accounting for lower ghost cell */
        i = ig - i1g + 1;
        j = jg ;
	
        if(x<0.5){
          old[i][j] = 0;
        }else{
          old[i][j] = 1;
        }
      }
      
    }
  }
  
   /* iterate */

  for(n=0; n<NSTEPS; n++){

    /* transfer data to ghost cells */

    if(nprocs == 1){

      /* left and right columns */

      for(i=1; i<i2; i++){
        old[i][0]  = old[i][j2m];
        old[i][j2] = old[i][1];
      }

      /* top and bottom */

      for(j=1; j<j2; j++){
        old[0][j]  = old[i2m][j];
        old[i2][j] = old[1][j];
      }

      /* corners */

      old[0][0]   = old[i2m][j2m];
      old[0][j2]  = old[i2m][1];
      old[i2][j2] = old[1][1];
      old[i2][0]  = old[1][j2m];

    }else{

      if(myid==0) {
	above_rank=nprocs-1;
      } else {
	above_rank=myid-1;
      } 

      if(myid==nprocs-1) {
	below_rank=0;
      } else {
	below_rank=myid+1;
      }
	
      /* use one sided communication to move row from above and */
      /* below into ghost cells */  

      /* read row from bottom of above process into top row of ghost cells */
      /* remember a fence call is needed before and after the get */
            
     
      MPI_Win_fence(0 , bottom_win);
      MPI_Get(&old[0][1],njnom,MPI_INT,above_rank,0,njnom,
		MPI_INT,bottom_win);
      MPI_Win_fence(0 , bottom_win); 
     
      /* read row from below into bottom row of ghost cells */
      /* remember a fence call is needed before and after the get */
      
      MPI_Win_fence(0 , top_win);
      MPI_Get(&old[i2][1],njnom,MPI_INT,below_rank,0,njnom,
	      MPI_INT,top_win);
      MPI_Win_fence(0 , top_win); 
      
      /* left and right including corners*/
      /* needs something more complicated if problem split into 2d */

        for(i=i1; i<=i2; i++){
         old[i][0]  = old[i][j2m];
	 old[i][j2] = old[i][1];
        }

    }

    /* update states of cells */

    for(i=1; i<i2; i++){
      for(j=1; j<j2; j++){
                
        im = i-1;
        ip = i+1;
        jm = j-1;
        jp = j+1;
        nsum =  old[im][jp] + old[i][jp] + old[ip][jp]
              + old[im][j ]              + old[ip][j ] 
              + old[im][jm] + old[i][jm] + old[ip][jm];

        switch(nsum){
        case 3:
          new[i][j] = 1;
          break;
        case 2:
          new[i][j] = old[i][j];
          break;
        default:
          new[i][j] = 0;
        }
      }
    }

    /* copy new state into old state */
    
    for(i=1; i<i2; i++){
      for(j=1; j<j2; j++){
        old[i][j] = new[i][j];
      }
    }

  }

  /*  Iterations are done; sum the number of live cells */

  isum = 0;
  for(i=1; i<i2; i++){
    for(j=1; j<j2; j++){
      isum = isum + new[i][j];
    }
  }

  /* Print final number of live cells.  For multiple processors,
     must reduce partial sums */
  
  if(nprocs > 1){
    isumloc = isum;
    MPI_Reduce(&isumloc, &isum, 1, MPI_INT, MPI_SUM, 0, MPI_COMM_WORLD);
  }

  if(myid == 0) printf("Number of live cells = %d\n", isum);
  
   
  /* free the windows */

  MPI_Win_free(&top_win);
  MPI_Win_free(&bottom_win);

  MPI_Finalize();
}
 
