#include <stdio.h>
#include "mpi.h"

int main(int argc, char *argv[] )
{
  int rank, value, size;
  MPI_Status status;

  //Add call to mpi init
  //Add call to get rank
  //Add call to get size of communicator

  //Replace the commented lines with MPI calls
  if (rank == 0) {
    value = 5;
    printf( "Process %d sending %d\n", rank, value );
    //Insert MPI command to send value to the next rank
  } else {
    //Insert MPI command to receive value from the previous rank
    printf( "Process %d got %d\n", rank, value );
    if (rank < size - 1)
      //Insert MPI command to send value to the next rank
  }

  MPI_Finalize( );
  return 0;
}
