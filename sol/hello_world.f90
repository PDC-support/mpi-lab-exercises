program hello

implicit none

include "mpif.h"

integer :: rank, comm_size, ierr

call MPI_Init(ierr)
call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierr)
call MPI_Comm_size(MPI_COMM_WORLD, comm_size, ierr)

print *, "Hello from rank ", rank, " of ", comm_size

call MPI_Finalize(ierr)

end program
