#include <stdio.h>
#include <mpi.h>

int main (int argc, char *argv[]) {
  const int N=300;
  int N_loc;
  int i,target;
  int b[N];
  int count,full_count;

  int *b_loc, *res, *countA, *displacements;
  int full_res[N];
  int rank, err, nproc ;

  FILE *infile,*outfile;



  MPI_Init(&argc, &argv);                 /* Initialize MPI       */
  MPI_Comm_rank(MPI_COMM_WORLD, &rank); /* Get my rank          */
  MPI_Comm_size(MPI_COMM_WORLD, &nproc);   /* Get the total
                                              number of processors */

  /* check that N/nproc divides evenly */

  if( N % nproc != 0 ) {
    if (rank == 0) {
      printf ("number of points %d must divide evenly\n",N);
      printf ("by number of processors %d\n",nproc);
    }
    MPI_Abort(MPI_COMM_WORLD,1);
  }

  N_loc=N/nproc;

  b_loc = malloc( N_loc * sizeof(int) );
  res = malloc( N_loc * sizeof(int) );
  countA = malloc( nproc * sizeof(int) );
  displacements = malloc( nproc * sizeof(int) );


  if (rank == 0 ) {
    /* File b.data has the target value on the first line
       The remaining 300 lines of b.data have the values for the b array */
    infile = fopen("b.data","r" ) ;
    outfile = fopen("found.data","w") ;
    
    /* read in target */
    fscanf(infile,"%d", &target);

    /* read in b array */
    for(i=0;i<N;i++) {
      fscanf(infile,"%d", &b[i]);
    }
    fclose(infile);
  }
 
  /* send the target (called by all ranks) */
  MPI_Bcast(&target,1,MPI_INTEGER,0,MPI_COMM_WORLD);

  /* scatter the data array */
  MPI_Scatter(b,N_loc,MPI_INTEGER,b_loc,N_loc,MPI_INTEGER,  
	      0,MPI_COMM_WORLD);
 


  /* Search the b array and save the target locations and number*/

  count=0;
  for(i=0;i<N_loc;i++) {
    if( b_loc[i] == target) {
      res[count]=i+1+rank*N_loc; /* correct for actual position in array*/
      count++;
    }
  }

  /* gather the partial count from each process */

  /* First the number of data points */
  MPI_Gather(&count,1,MPI_INTEGER,countA,1,MPI_INTEGER, 
	     0,MPI_COMM_WORLD);

  /* calculate the displacements */
  if(rank == 0) {
    full_count=0;
    for(i=0;i<nproc;i++) {
      displacements[i]=full_count;
      full_count=full_count+countA[i];
    }
  }
   
  /* Now we know the number of data points, we can gather the actual data */
  MPI_Gatherv(res,count,MPI_INTEGER,full_res,countA, 
	      displacements,MPI_INTEGER,0,MPI_COMM_WORLD);

  /* now output results */
 if (rank == 0) {
   for(i=0;i<full_count;i++) {  
      fprintf(outfile,"%d\n",full_res[i]);
   }
  fclose(outfile);
 }

 MPI_Barrier(MPI_COMM_WORLD);
 MPI_Finalize();

 return 0;
}

