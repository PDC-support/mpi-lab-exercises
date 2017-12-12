#include <stdio.h>
#include "mpi.h"

int main( argc, argv )
     int argc;
     char **argv;
{
  int rank, value, size;
  MPI_Status status;
  MPI_Request request,request2;

  MPI_Init( &argc, &argv );

  MPI_Comm_rank( MPI_COMM_WORLD, &rank );
  MPI_Comm_size( MPI_COMM_WORLD, &size );

  value=0;
  if (rank == 0) {
    MPI_Isend( &value, 1, MPI_INT, rank + 1, 0, MPI_COMM_WORLD,&request );
  }
  else {
    MPI_Irecv( &value, 1, MPI_INT, rank - 1, 0, MPI_COMM_WORLD,&request);
    value+=1;
    if (rank < size - 1) 
      MPI_Isend( &value, 1, MPI_INT, rank + 1, 0, MPI_COMM_WORLD,&request2);
  }
  printf( "Process %d got %d\n", rank, value );
   
  MPI_Finalize( );
  return 0;
}
