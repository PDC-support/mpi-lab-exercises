!------------------------------------
!     Conway Game of Life

! 2 processors, domain decomposition
! in j direction only (divide domain
! with a vertical line)

!------------------------------------
program life

  implicit none
  include 'mpif.h'

  integer, parameter :: ni = 200, nj = 200, nsteps = 500
  integer :: i, j, n, im, ip, jm, jp, nsum, isum, isum1, &
       ierr, myid, nprocs, i1, i2, i1p, i2m, j1, j2, j1p, &
       j2m, i1n, i2n, j1n, j2n, ninom, njnom, &
       niproc, njproc, isumloc, istart, iend
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
  !---------------------

  ! nominal number of points per proc. in each direction
  ! (without ghost cells, assume numbers divide evenly);
  ! niproc and njproc are the numbers of procs in the i
  ! and j directions.

  niproc = 1
  njproc = nprocs
  ninom  = ni/niproc
  njnom  = nj/njproc

  ! nominal starting and ending indices
  ! (nominal means without ghost cells)

  i1n = 1
  i2n = ni
  j1n = mod(myid,2)*njnom + 1
  j2n = j1n + njnom - 1

  ! local starting and ending indices, including 2 ghost cells

  i1  = i1n - 1
  i2  = i2n + 1
  i1p = i1  + 1
  i2m = i2  - 1
  j1  = j1n - 1
  j2  = j2n + 1
  j1p = j1  + 1
  j2m = j2  - 1
  
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
        if( j > j1 .and.j < j2 ) then
           old(i,j) = nint(arand)
        endif
     enddo
  enddo

  !  iterate

  time_iteration: do n = 1, nsteps

     ! transfer data to ghost cells

     if(nprocs == 1) then

        ! left and right
        old(i1p:i2m,j1) = old(i1p:i2m,j2m)
        old(i1p:i2m,j2) = old(i1p:i2m,j1p)

        ! top and bottom
        old(i1,j1:j2) = old(i2m,j1:j2)
        old(i2,j1:j2) = old(i1p,j1:j2)

        ! corners
        old(i1,j1) = old(i2m,j2m)
        old(i1,j2) = old(i2m,j1p)
        old(i2,j1) = old(i1p,j2m)
        old(i2,j2) = old(i1p,j1p)

     else

        if(myid == 0) then

           ! left, right
           call mpi_send(old(i1p,j1p), ninom, mpi_integer,    &
                1, 2, mpi_comm_world, ierr)
           call mpi_recv(old(i1p,j2 ), ninom, mpi_integer,    &
                1, 2, mpi_comm_world, status, ierr)
           call mpi_send(old(i1p,j2m), ninom, mpi_integer,    &
                1, 3, mpi_comm_world, ierr)
           call mpi_recv(old(i1p,j1 ), ninom, mpi_integer,    &
                1, 3, mpi_comm_world, status, ierr)

           ! top and bottom
           old(i1,j1:j2) = old(i2m,j1:j2)
           old(i2,j1:j2) = old(i1p,j1:j2)

           ! corners
           call mpi_send(old(i1p,j1p), 1, mpi_integer, &
                1, 4, mpi_comm_world, ierr)
           call mpi_recv(old(i1, j1 ), 1, mpi_integer, &
                1, 4, mpi_comm_world, status, ierr)
           call mpi_send(old(i2m,j1p), 1, mpi_integer, &
                1, 5, mpi_comm_world, ierr)
           call mpi_recv(old(i2, j1 ), 1, mpi_integer, &
                1, 5, mpi_comm_world, status, ierr)

        else

           ! left, right
           call mpi_recv(old(i1p,j2 ), ninom, mpi_integer,    &
                0, 2, mpi_comm_world, status, ierr)
           call mpi_send(old(i1p,j1p), ninom, mpi_integer,    &
                0, 2, mpi_comm_world, ierr)
           call mpi_recv(old(i1p,j1 ), ninom, mpi_integer,    &
                0, 3, mpi_comm_world, status, ierr)
           call mpi_send(old(i1p,j2m), ninom, mpi_integer,    &
                0, 3, mpi_comm_world, ierr)

           ! top and bottom
           old(i1,j1:j2) = old(i2m,j1:j2)
           old(i2,j1:j2) = old(i1p,j1:j2)

           ! corners
           call mpi_recv(old(i2, j2 ), 1, mpi_integer, &
                0, 4, mpi_comm_world, status, ierr)
           call mpi_send(old(i2m,j2m), 1, mpi_integer, &
                0, 4, mpi_comm_world, ierr)
           call mpi_recv(old(i1, j2 ), 1, mpi_integer, &
                0, 5, mpi_comm_world, status, ierr)
           call mpi_send(old(i1p,j2m), 1, mpi_integer, &
                0, 5, mpi_comm_world, ierr)

        endif  !... myid

     endif  !... nprocs

     ! update states of cells

     do j = j1p, j2m
        do i = i1p, i2m

           ip = i + 1
           im = i - 1
           jp = j + 1
           jm = j - 1
           nsum =  old(im,jp)  + old(i,jp)  + old(ip,jp) &
                     + old(im,j )                   + old(ip,j ) &
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
  
  ! Print final number of live cells.

  if(nprocs > 1) then
     if(myid == 0) then
        call mpi_recv(isum1, 1, mpi_integer, 1, 10, &
             mpi_comm_world, status, ierr)
        isum = isum + isum1
     else
        call mpi_send(isum,  1, mpi_integer, 0, 10, &
             mpi_comm_world, ierr)
     endif
  endif

  if(myid == 0) then
     write(*,"(/'Number of live cells = ', i6/)") isum
  endif

  deallocate(old, new)
  call mpi_finalize(ierr)

end program life

