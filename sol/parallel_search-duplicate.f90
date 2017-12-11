PROGRAM search  
  implicit none
  include "mpif.h"
  integer, parameter ::  N=300
  integer i, target ! local variables
  integer b(N)      ! the entire array of integers
  integer myrank,size,ierr
  character*15 outfilename
  character*4 rankchar

  call MPI_Init(ierr)
  call MPI_Comm_rank(MPI_COMM_WORLD,myrank,ierr)
  call MPI_Comm_size(MPI_COMM_WORLD,size,ierr)

  ! generate the name of the output file
  ! all mpi tasks must write to a different file
  write(rankchar,'(i4.4)') myrank
  outfilename="found.data_" // rankchar
 
  ! File b.data has the target value on the first line
  ! The remaining 300 lines of b.data have the values for the b array
  open(unit=10,file="b.data")     

  ! File found.data will contain the indices of b where the target is
  open(unit=11,file=outfilename)

  ! Read in the target
  read(10,*) target

  ! Read in b array 

  do i=1,N
     read(10,*) b(i)
  end do

  ! Search the b array and output the target locations

  do i=1,N
     if (b(i) == target) then
        write(11,*) i
     end if
  end do

  write(*,*) "Processor ",myrank," of ",size,": Finished!"

  call MPI_Finalize(ierr)

END PROGRAM search
