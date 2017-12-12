#include <stdlib.h>
#include <stdio.h>
#include <mpi.h>

int main (int argc, char *argv[]) {
  const int N=300;
  int i,target;
  int b[N];
  FILE *infile,*outfile;
  int myrank, size;

  char outfilename[16] ;


  MPI_Init(&argc, &argv);                 /* Initialize MPI       */
  MPI_Comm_rank(MPI_COMM_WORLD, &myrank); /* Get my rank          */
  MPI_Comm_size(MPI_COMM_WORLD, &size);   /* Get the total
					     number of processors */

  /* generate the name of the output file
     all mpi tasks must write to a different file */
  sprintf(outfilename,"found.data_%d",myrank);

  /* File b.data has the target value on the first line
     The remaining 300 lines of b.data have the values for the b array */

  infile = fopen("b.data","r" ) ;
  outfile = fopen(outfilename,"w") ;
    
  /* read in target */
  fscanf(infile,"%d", &target);

  /* read in b array */
  for(i=0;i<N;i++) {
    fscanf(infile,"%d", &b[i]);
  }
  fclose(infile);

  /* Search the b array and output the target locations */

  for(i=0;i<N;i++) {
    if( b[i] == target) {
      fprintf(outfile,"%d\n",i+1);
    }
  }
  fclose(outfile);

  printf("Processor %d of %d: finished!\n", myrank, size);
  MPI_Finalize();                         /* Terminate MPI        */

  return 0;
}
