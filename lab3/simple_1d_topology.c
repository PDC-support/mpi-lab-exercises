#include "mpi.h"
#include <stdio.h>
#include <stdlib.h>
int main(int argc, char *argv[]){

  int nprocs,myid,period,cart_id;
  int plus_one,minus_one,cart_position;

  MPI_Comm cart_comm ;

 /* initialize MPI */

  MPI_Init(&argc,&argv);
  MPI_Comm_size(MPI_COMM_WORLD,&nprocs);
  MPI_Comm_rank(MPI_COMM_WORLD,&myid);

  period=1;
  
  MPI_Cart_create(MPI_COMM_WORLD,1,&nprocs,&period,0,&cart_comm);
  MPI_Comm_rank(cart_comm,&cart_id);
  MPI_Cart_coords(cart_comm,myid,1,&cart_position);
  
  MPI_Cart_shift(cart_comm,0,1,&cart_id,&plus_one);
  MPI_Cart_shift(cart_comm,0,-1,&cart_id,&minus_one);

  printf("myid = %d cart_id=%d cart_position=%d plus_one=%d minus_one=%d\n",myid,cart_id,cart_position,plus_one,minus_one);
  
  MPI_Finalize();
}
 
