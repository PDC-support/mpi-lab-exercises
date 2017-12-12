!------------------------------
!     Conway Game of Life
!
!     One sided communication
!     
!     Domain is split vertically (left/right) so that data
!     to be transfered is contiguous     
!
!     leftmost rank is rank 0
!------------------------------

program life
  implicit none
  include 'mpif.h'
  
  integer, parameter :: ni=200, nj=200, nsteps = 500
  integer :: i, j, n, im, ip, jm, jp, nsum, isum, isum1, &
       ierr, myid, nprocs, i1, i2, j1, j2, i1p, i2m, j1p, j2m, &
       i1n, i2n, ninom, njnom, niproc, njproc, nitot, isumloc, &
       j1n,j2n
  integer, allocatable, dimension(:,:) :: old, new
  real :: arand

  integer :: left_rank, right_rank
  integer(kind=MPI_ADDRESS_KIND) :: size,target_disp
  integer disp_unit,left_win,right_win
  
  ! initialize MPI

  call mpi_init(ierr)
  call mpi_comm_rank(mpi_comm_world, myid, ierr)
  call mpi_comm_size(mpi_comm_world, nprocs, ierr)

  ! domain decomposition

  ! nominal number of points per proc., without ghost cells,
  ! assume numbers divide evenly; niproc and njproc are the
  ! numbers of procs in the i and j directions.
  niproc = 1
  njproc = nprocs
  ninom  = ni/niproc
  njnom  = nj/njproc

  if(njnom*njproc.ne.nj) then
     if(myid.eq.0) then
        write(*,*) "Need to be able to divide the j grid exactly between the processes"
        write(*,*) "grid points in j",nj," nprocs=",nprocs
        write(*,*) "grid points per cell",njnom
        write(*,*) "cells that would be used",njnom*njproc
     endif
     call mpi_abort(mpi_comm_world,1,ierr)
  endif


  ! nominal starting and ending indices, without ghost cells
  i1n = 1
  i2n = ninom 
  j1n = myid*njnom + 1
  j2n = j1n + njnom - 1

  ! local starting and ending index, including 2 ghost cells
  ! in each direction (at beginning and end)
  i1  = i1n - 1
  i1p = i1 + 1
  i2  = i2n + 1
  i2m = i2 - 1
  j1  = j1n-1
  j1p = j1 + 1
  j2  = j2n + 1
  j2m = j2 - 1
  nitot = i2 - i1 + 1

  ! allocate arrays
  allocate( old(i1:i2,j1:j2), new(i1:i2,j1:j2) )

  ! FIXME
  ! Create the memory window

  

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
        if(j > j1 .and. j < j2) old(i,j) = nint(arand)
     enddo
  enddo

  !  iterate

  

  time_iteration: do n = 1, nsteps

     ! transfer data to ghost cells

     if(nprocs == 1) then

        ! left and right boundary conditions

        old(i1p:i2m,0)  = old(i1p:i2m,j2m)
        old(i1p:i2m,j2) = old(i1p:i2m,1)

        ! top and bottom boundary conditions

        old(i1,:) = old(i2m,:)
        old(i2,:) = old(i1p,:)

        ! corners

        old(i1,j1) = old(i2m,j2m)
        old(i1,j2) = old(i2m,j1p)
        old(i2,j2) = old(i1p,j1p)
        old(i2,j1) = old(i1p,j2m)

     else

        if(myid.eq.0) then
           left_rank=nprocs-1
        else
           left_rank=myid-1
        endif

         if(myid.eq.nprocs-1) then
           right_rank=0
        else
           right_rank=myid+1
        endif


        ! use one sided communication to move row from left and 
        ! right into ghost cells

        ! read row from the left into the left row of ghost cells
        ! remember a fence call is needed before and after the get
        ! make sure you use a variable of type
        ! integer(kind=MPI_ADDRESS_KIND) for the target displacement
        ! FIXME

        
        ! read row from the right into the right row of ghost cells
        ! remember a fence call is needed before and after the get


        ! top and bottom including corners
        ! will not work with 2d distribution of cells

        old(i1,:) = old(i2n,:)
        old(i2,:) = old(i1n,:)

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

  ! FIXME
  ! free the windows


  deallocate(old, new)
  call mpi_finalize(ierr)

end program life


