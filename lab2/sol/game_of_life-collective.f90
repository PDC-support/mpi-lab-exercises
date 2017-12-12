!------------------------------
!     Conway Game of Life

!     reduction operation
!------------------------------

program life

  implicit none
  include 'mpif.h'

  integer, parameter :: ni=200, nj=200, nsteps = 500
  integer :: i, j, n, im, ip, jm, jp, nsum, isum, isum1, &
       ierr, myid, nprocs, i1, i2, j1, j2, i1p, i2m, j1p, j2m, &
       i1n, i2n, ninom, njnom, niproc, njproc, nitot, isumloc
  integer :: status(mpi_status_size), row_type
  integer, allocatable, dimension(:,:) :: old, new
  real :: arand

  ! initialize MPI

  call mpi_init(ierr)
  call mpi_comm_rank(mpi_comm_world, myid, ierr)
  call mpi_comm_size(mpi_comm_world, nprocs, ierr)

  ! only 1 or 2 MPI tasks supported
  if(nprocs.gt.2) then
     write(*,*) "Only 1 or 2 MPI tasks supported"
     write(*,*) "Number of Tasks = ",nprocs
     write(*,*) "Aborting..."
     call mpi_abort(mpi_comm_world,1,ierr)
  endif


  ! domain decomposition

  ! nominal number of points per proc., without ghost cells,
  ! assume numbers divide evenly; niproc and njproc are the
  ! numbers of procs in the i and j directions.
  niproc = nprocs
  njproc = 1
  ninom  = ni/niproc
  njnom  = nj/niproc

  ! nominal starting and ending indices, without ghost cells
  i1n = myid*ninom + 1
  i2n = i1n + ninom - 1

  ! local starting and ending index, including 2 ghost cells
  ! in each direction (at beginning and end)
  i1  = i1n - 1
  i1p = i1 + 1
  i2  = i2n + 1
  i2m = i2 - 1
  j1  = 0
  j1p = j1 + 1
  j2  = nj + 1
  j2m = j2 - 1
  nitot = i2 - i1 + 1

  ! allocate arrays
  allocate( old(i1:i2,j1:j2), new(i1:i2,j1:j2) )

  ! Initialize elements of old to 0 or 1.  We're doing some
  ! sleight of hand here to make sure we initialize to the
  ! same values as in the serial case. The random_number
  ! function is called for every i and j, even if they are
  ! not on the current processor, to get the same random
  ! distribution as the serial case, but they are only used
  ! if this i and j reside on the current procesor.

  do j = 1, nj
     do i = 1, ni
        call random_number(arand)
        if(i > i1 .and. i < i2) old(i,j) = nint(arand)
     enddo
  enddo

  ! Create derived type for single row of array.
  ! There are nj "blocks," each containing 1 element,
  ! with a stride of nitot between the blocks

  call mpi_type_vector(nj+2, 1, nitot, mpi_integer, row_type, ierr);
  call mpi_type_commit(row_type, ierr);

  !  iterate

  time_iteration: do n = 1, nsteps

     ! transfer data to ghost cells

     ! left and right boundary conditions

     old(i1p:i2m,0)  = old(i1p:i2m,j2m)
     old(i1p:i2m,j2) = old(i1p:i2m,1)

     if(nprocs == 1) then

        ! top and bottom boundary conditions

        old(i1,:) = old(i2m,:)
        old(i2,:) = old(i1p,:)

        ! corners

        old(i1,j1) = old(i2m,j2m)
        old(i1,j2) = old(i2m,j1p)
        old(i2,j2) = old(i1p,j1p)
        old(i2,j1) = old(i1p,j2m)

     elseif(myid == 0) then

        ! top and bottom boundary conditions

        call mpi_send(old(i1p,j1), 1, row_type, &
             1, 0, mpi_comm_world, ierr)
        call mpi_recv(old(i1,j1),  1, row_type, &
             1, 0, mpi_comm_world, status, ierr)
        call mpi_send(old(i2m,j1), 1, row_type, &
             1, 1, mpi_comm_world, ierr)
        call mpi_recv(old(i2,j1),  1, row_type, &
             1, 1, mpi_comm_world, status, ierr)

        ! corners

        call mpi_send(old(i1p,j1p), 1, mpi_integer, &
             1, 2, mpi_comm_world, ierr)
        call mpi_recv(old(i1, j1 ), 1, mpi_integer, &
             1, 3, mpi_comm_world, status, ierr)
        call mpi_send(old(i1p,j2m), 1, mpi_integer, &
             1, 4, mpi_comm_world, ierr)
        call mpi_recv(old(i1, j2 ), 1, mpi_integer, &
             1, 5, mpi_comm_world, status, ierr)
     else

        ! top and bottom boundary conditions

        call mpi_recv(old(i2,j1),  1, row_type, &
             0, 0, mpi_comm_world, status, ierr)
        call mpi_send(old(i2m,j1), 1, row_type, &
             0, 0, mpi_comm_world, ierr)
        call mpi_recv(old(i1,j1),  1, row_type, &
             0, 1, mpi_comm_world, status, ierr)
        call mpi_send(old(i1p,j1), 1, row_type, &
             0, 1, mpi_comm_world, ierr)

        ! corners

        call mpi_recv(old(i2, j2 ), 1, mpi_integer, &
             0, 2, mpi_comm_world, status, ierr)
        call mpi_send(old(i2m,j2m), 1, mpi_integer, &
             0, 3, mpi_comm_world, ierr)
        call mpi_recv(old(i2, j1 ), 1, mpi_integer, &
             0, 4, mpi_comm_world, status, ierr)
        call mpi_send(old(i2m,j1p), 1, mpi_integer, &
             0, 5, mpi_comm_world, ierr)
     endif

     do j = j1p, j2m
        do i = i1p, i2m

           im = i - 1
           ip = i + 1
           jm = j - 1
           jp = j + 1
           nsum =  old(im,jp) + old(i,jp) + old(ip,jp) &
                + old(im,j )             + old(ip,j ) &
                + old(im,jm) + old(i,jm) + old(ip,jm)

           select case (nsum)
           case (3)
              new(i,j) = 1
           case (2)
              new(i,j) = old(i,j)
           case default
              new(i,j) = 0
           end select

        enddo
     enddo

     ! copy new state into old state
     old(i1p:i2m,j1p:j2m) = new(i1p:i2m,j1p:j2m)

  enddo time_iteration

  ! Iterations are done; sum the number of live cells

  isum = sum(new(i1p:i2m,j1p:j2m))

  ! Print final number of live cells.  For multiple
  ! processors, must reduce partial sums.

  if(nprocs > 1) then
     isumloc = isum
     call mpi_reduce(isumloc, isum, 1, mpi_integer, &
          mpi_sum, 0, mpi_comm_world, ierr)
  endif

  if(myid == 0) then
     write(*,"(/'Number of live cells = ', i6/)") isum
  endif

  deallocate(old, new)
  call mpi_finalize(ierr)

end program life
