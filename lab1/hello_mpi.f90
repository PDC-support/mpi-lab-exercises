program MPI

include "mpif.h"
integer myrank,size,ierr

call MPI_Init(ierr)
call MPI_Comm_rank(MPI_COMM_WORLD,myrank,ierr)
call MPI_Comm_size(MPI_COMM_WORLD,size,ierr)

write(*,*) "Processor ",myrank," of ",size,": Hello World!"

call MPI_Finalize(ierr)
end program
