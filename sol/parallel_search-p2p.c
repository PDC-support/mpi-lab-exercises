#include "mpi.h"
#include <stdio.h>
#include <stdlib.h>

#define N 300

int main(int argc, char *argv[]){
  int i,target;
  int b[N],a[N/3]; /* a is the name of the array each slave searches */
  int rank,err,nproc;
  MPI_Status status;
  int end_cnt,x,gi;
  FILE *infile,*outfile;

  MPI_Init(&argc,&argv);
  MPI_Comm_size(MPI_COMM_WORLD,&nproc);
  MPI_Comm_rank(MPI_COMM_WORLD,&rank);
  
  /* only 4 MPI tasks supported */
  if(nproc!=4) {
    printf("Only 4 mpi tasks supported\n");
    printf("Number of tasks = %d Aborting...\n",nproc);
    MPI_Abort(MPI_COMM_WORLD, 1);
  }

  if(rank==0) {
    infile = fopen("b.data","r" ) ;
    
    fscanf(infile,"%d", &target);

    for(i=1;i<=3;i++) {
      /*  Notice how i is used as the destination process for each send */
      MPI_Send(&target,1,MPI_INT,i,9,MPI_COMM_WORLD);
    }

    /* read in b array */
    for(i=0;i<N;i++) {
      fscanf(infile,"%d", &b[i]);
    }
    fclose(infile);

    MPI_Send(&b[0],100,MPI_INT,1,11,MPI_COMM_WORLD);
    MPI_Send(&b[100],100,MPI_INT,2,11,MPI_COMM_WORLD);
    MPI_Send(&b[200],100,MPI_INT,3,11,MPI_COMM_WORLD);

    end_cnt=0;
    outfile = fopen("found.data","w") ;
    while (end_cnt != 3) {
      MPI_Recv(&x,1,MPI_INTEGER,MPI_ANY_SOURCE,MPI_ANY_TAG,
	       MPI_COMM_WORLD,&status);
      if (status.MPI_TAG == 52 ) {
	end_cnt+=1;  /* See Comment */  
      } else {
	fprintf(outfile,"P%d  %d\n",status.MPI_SOURCE,x+1);
      }
    }
    fclose(outfile);
  } else {
    MPI_Recv(&target,1,MPI_INT,0,9,MPI_COMM_WORLD,&status);
    MPI_Recv(&a,100,MPI_INT,0,11,MPI_COMM_WORLD,&status);

    for(i=0;i<100;i++) {
      if (a[i] == target) {
        gi=(rank-1)*100+i; /* Equation to convert local index to global index*/ 
	MPI_Send(&gi,1,MPI_INT,0,19,MPI_COMM_WORLD);
      }
    }

    MPI_Send(&target,1,MPI_INT,0,52,MPI_COMM_WORLD); /* See Comment */
   
  }

  MPI_Finalize();
  return 0;
}
