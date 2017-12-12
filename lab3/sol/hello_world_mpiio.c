/***********************
Hello World!

MPI I/O version

************************/

#include <stdio.h>
#include <stdlib.h>
#include "mpi.h"

#define BUF_LENGTH 50					// Max buffer
char FILENAME[]="result.txt";		// Name of file

int main(int argc, char *argv[]) {
  char mytext[BUF_LENGTH];	
  int rank,numtasks;
  MPI_File fp; 
  MPI_Status status;
  MPI_Offset offset;
  

  // Initialize MPI
  MPI_Init(&argc,&argv);
  MPI_Comm_rank(MPI_COMM_WORLD,&rank);
  MPI_Comm_size(MPI_COMM_WORLD,&numtasks);
  /*
  Get the rank number and store in buffer with the same length
  regardless of rank number so that each rank writes in a separate
  file area with exactly the same size.
  Therefore the output from rank, with size=3 bytes, is written to a string
  */   
  sprintf(mytext,"Rank: %3d Hello World!\n",rank);
  offset=rank*strlen(mytext);
  // Open file and write text
  MPI_File_open(MPI_COMM_WORLD,FILENAME,MPI_MODE_CREATE|MPI_MODE_WRONLY,MPI_INFO_NULL,&fp);
  MPI_File_write_at(fp,offset,&mytext,strlen(mytext),MPI_CHAR,&status);
  MPI_File_close(&fp);
  // Finalize MPI
  MPI_Finalize();
  return 0;
  }
