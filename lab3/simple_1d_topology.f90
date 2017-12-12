program topology
  implicit none
  include 'mpif.h'

  integer nprocs,myid,ierr,period,cart_id
  integer plus_one,minus_one,cart_position
  integer cart_comm

  call mpi_init(ierr)
  call mpi_comm_rank(mpi_comm_world, myid, ierr)
  call mpi_comm_size(mpi_comm_world, nprocs, ierr)

  period=1

  call mpi_cart_create(MPI_COMM_WORLD,1,nprocs,period,0,cart_comm,ierr)
  call mpi_comm_rank(cart_comm,cart_id,ierr)
  call mpi_cart_coords(cart_comm,myid,1,cart_position,ierr)
  
  call mpi_cart_shift(cart_comm,0,1,cart_id,plus_one,ierr)
  call mpi_cart_shift(cart_comm,0,-1,cart_id,minus_one,ierr)

  write(*,*) "myid=",myid,"cart_id=",cart_id,"cart_position=",cart_position
  write(*,*)  "cart_position=",cart_position,"plus_one=",plus_one,"minus_one=",minus_one

  call mpi_finalize(ierr)

end program topology
