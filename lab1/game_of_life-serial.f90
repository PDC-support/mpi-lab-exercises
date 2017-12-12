!----------------------
!  Conway Game of Life
!    serial version
!----------------------

program life
  
  implicit none
  integer, parameter :: ni=200, nj=200, nsteps = 500
  integer :: i, j, n, im, ip, jm, jp, nsum, isum
  integer, allocatable, dimension(:,:) :: old, new
  real :: arand

  ! allocate arrays, including room for ghost cells

  allocate(old(0:ni+1,0:nj+1), new(0:ni+1,0:nj+1))

  ! initialize elements of old to 0 or 1

  do j = 1, nj
     do i = 1, ni
        call random_number(arand)
        old(i,j) = nint(arand)
     enddo
  enddo

  !  iterate

  time_iteration: do n = 1, nsteps

     ! corner boundary conditions

     old(0,0) = old(ni,nj)
     old(0,nj+1) = old(ni,1)
     old(ni+1,nj+1) = old(1,1)
     old(ni+1,0) = old(1,nj)

     ! left-right boundary conditions

     old(1:ni,0) = old(1:ni,nj)
     old(1:ni,nj+1) = old(1:ni,1)

     ! top-bottom boundary conditions

     old(0,1:nj) = old(ni,1:nj)
     old(ni+1,1:nj) = old(1,1:nj)

     do j = 1, nj
        do i = 1, ni

           im = i - 1
           ip = i + 1
           jm = j - 1
           jp = j + 1
           nsum = old(im,jp) + old(i,jp) + old(ip,jp) &
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

     old = new

  enddo time_iteration

  ! Iterations are done; sum the number of live cells
  
  isum = sum(new(1:ni,1:nj))
  
  ! Print final number of live cells.

  write(*,*)"Number of live cells = ",isum

  deallocate(old, new)

end program life

