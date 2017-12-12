program send_recv

implicit none

include "mpif.h"

integer :: rank, value, comm_size, ierr
integer :: istatus(MPI_STATUS_SIZE)
integer :: request

call MPI_Init(ierr)
call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierr)
call MPI_Comm_size(MPI_COMM_WORLD, comm_size, ierr)

value = 0

if (rank == 0) then
   value = 5 ! we set this value directly for rank 0 process
   call MPI_ISend(value, 1, MPI_INTEGER, rank+1, 0, MPI_COMM_WORLD, request, ierr)
   print *, "Process ", rank, " sent ", value
else
   call MPI_IRecv(value, 1, MPI_INTEGER, rank-1, 0, MPI_COMM_WORLD, request, ierr)
   if (rank < comm_size-1) then
      call MPI_ISend(value, 1, MPI_INTEGER, rank+1, 0, MPI_COMM_WORLD, request, ierr)
      print *, "Process ", rank, " sent ", value
   end if
   print *, "Process ", rank, " got ", value
end if

call MPI_Barrier(MPI_COMM_WORLD, ierr)
call MPI_Finalize(ierr)

end program
