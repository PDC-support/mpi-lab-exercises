#include "mpi.h"
#include <stdio.h>
#define NELEMENTS 6

int main(int argc, char *argv[])  {
    int numtasks, rank, source=0, dest, tag=1, i;
    int blocklengths[2], displacements[2];
    float a[16] = 
            {1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 
             9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0};
    float b[NELEMENTS]; 

    MPI_Status stat;
    MPI_Datatype indextype;   // required variable

    MPI_Init(&argc,&argv);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &numtasks);

    /* ===================================================================== */
    /* Step 1. Create an MPI Indexed Type
     *    Summary:
     *      Make a new indexed derived datatype.
     *
     *    Function Call:
     *      int MPI_Type_indexed(int count,
     *                           const int *array_of_blocklengths,
     *                           const int *array_of_displacements,
     *                           MPI_Datatype oldtype,
     *                           MPI_Datatype *newtype);
     *      
     *   Input Parameters:
     *      count
     *          number of blocks -- also number of entries in array_of_displacements and array_of_blocklengths
     *      array_of_blocklengths
     *          number of elements in each block (array of nonnegative integers)
     *      array_of_displacements
     *          displacement of each block in multiples of oldtype (array of integers)
     *      oldtype
     *          old datatype (handle)
     *
     *   Output Parameters
     *      newtype
     *          new datatype (handle)
     */
    // NOTE: We want the the resulting values of b[] to be {6.0 7.0 8.0 9.0 13.0 14.0}.
    // TODO: fill in the values for blocklengths
    blocklengths[0] = //TODO ;
    blocklengths[1] = //TODO ;

    // TODO: fill in the values for the displacements
    displacements[0] = //TODO ;
    displacements[1] = //TODO ;
    
    // TODO: create the indexed data type

    // TODO: commit the new derived datatype 

    /* ===================================================================== */

    if (rank == 0) {
        for (i=0; i<numtasks; i++) {
            // task 0 sends one element of indextype to all tasks
            MPI_Send(a, 1, indextype, i, tag, MPI_COMM_WORLD);
        }
    }

    // all tasks receive indextype data from task 0
    MPI_Recv(b, NELEMENTS, MPI_FLOAT, source, tag, MPI_COMM_WORLD, &stat);
    printf("rank= %d  b= %3.1f %3.1f %3.1f %3.1f %3.1f %3.1f\n",
            rank,b[0],b[1],b[2],b[3],b[4],b[5]);

    // free datatype when done using it
    MPI_Type_free(&indextype);
    MPI_Finalize();
    return 0;
}
