
!------------------------------
!     Hello World

!     MPI-I/O example
!------------------------------

program HelloWorld

  implicit none
  include 'mpif.h'

  integer, parameter :: BUF_LENGTH=50
  integer :: ierr, myid, nprocs, fp
  character( len=BUF_LENGTH) ::  mytext
  integer :: status(mpi_status_size)
  integer(kind=MPI_OFFSET_KIND) offset

  ! initialize MPI
  call mpi_init(ierr)
  call mpi_comm_rank(mpi_comm_world, myid, ierr)
  call mpi_comm_size(mpi_comm_world, nprocs, ierr)

  ! Get the rank number and store in buffer with the same length
  ! regardless of rank number so that each rank writes in a separate
  ! file area with exactly the same size.
  ! Therefore the output from rank, with size=3 bytes, is written to a string
  write(mytext,"(A6,i3,A14)")"Rank: ",myid," Hello World!"
  offset = myid * len(mytext)
  
  ! MPI IO Write to file
  call MPI_FILE_OPEN(MPI_COMM_WORLD, 'result.txt', & 
                       MPI_MODE_WRONLY + MPI_MODE_CREATE, & 
                       MPI_INFO_NULL, fp, ierr)
  call MPI_FILE_WRITE_AT(fp, offset, mytext, len(mytext), MPI_CHARACTER, & 
                        MPI_STATUS_IGNORE, ierr)                       
  call MPI_FILE_CLOSE(fp, ierr) 
  ! Finalize MPI
  call mpi_finalize(ierr)

end program HelloWorld
