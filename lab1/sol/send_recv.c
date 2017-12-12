#include <stdio.h>
#include "mpi.h"

int main(int argc, char *argv[] )
{
  int rank, value, size;
  MPI_Status status;

  MPI_Init( &argc, &argv );

  MPI_Comm_rank( MPI_COMM_WORLD, &rank );
  MPI_Comm_size( MPI_COMM_WORLD, &size );

  if (rank == 0) {
    value = 5;
    printf( "Process %d sending %d\n", rank, value );
    MPI_Send( &value, 1, MPI_INT, rank + 1, 0, MPI_COMM_WORLD );
  } else {
    MPI_Recv( &value, 1, MPI_INT, rank - 1, 0, MPI_COMM_WORLD, &status );
    printf( "Process %d got %d\n", rank, value );
    if (rank < size - 1)
      MPI_Send( &value, 1, MPI_INT, rank + 1, 0, MPI_COMM_WORLD );
  }

  MPI_Finalize( );
  return 0;
}
