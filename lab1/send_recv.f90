program send_recv

implicit none

include "mpif.h"

integer :: rank, value, comm_size, ierr
integer :: istatus(MPI_STATUS_SIZE)

!Add call to mpi init
!Add call to get rank
!Add call to get size of communicator

value = 0
!Replace the commented lines with MPI calls
if (rank == 0) then
   value = 5 ! we set this value directly for rank 0 process
   !Insert MPI command to send value to the next rank
   print *, "Process ", rank, " sent ", value
else
   !Insert MPI command to receive value from the previous rank
   print *, "Process ", rank, " got ", value
   if (rank < comm_size-1) then
      !Insert MPI command to send value to the next rank
      print *, "Process ", rank, " sent ", value
   end if
end if

call MPI_Barrier(MPI_COMM_WORLD, ierr)
call MPI_Finalize(ierr)

end program
