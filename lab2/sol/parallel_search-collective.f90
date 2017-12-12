PROGRAM search  
  implicit none
  include 'mpif.h'
  integer, parameter ::  N=300
  integer :: N_loc
  integer i, target ! local variables
  integer b(N)      ! the entire array of integers
  integer :: count, full_count
  integer, allocatable :: b_loc(:),res(:),countA(:),displacements(:)
  integer :: full_res(N)
  integer rank,err,nproc
 
  
  CALL MPI_INIT(err)
  CALL MPI_COMM_RANK(MPI_COMM_WORLD, rank, err)
  CALL MPI_COMM_SIZE(MPI_COMM_WORLD, nproc, err)
 
  ! check that N/nproc divides evenly

  if( mod(N,nproc) .ne. 0) then
     if (rank == 0) then
        write(*,*) "Number of points ",N," must divide evenly by"
        write(*,*) "number of processors ",nproc
     endif
      call mpi_abort(mpi_comm_world,1,err)
   endif

   N_loc=N/nproc
   allocate(b_loc(N_loc))
   allocate(res(N_loc))
   allocate(countA(nproc))
   allocate(displacements(nproc))


  if (rank == 0) then
     ! File b.data has the target value on the first line
     ! The remaining 300 lines of b.data have the values for the b array
     open(unit=10,file="b.data")     

     ! File found.data will contain the indices of b where the target is
     open(unit=11,file="found.data")

     ! Read in the target
     read(10,*) target

     ! Read in b array 
     
     do i=1,N
        read(10,*) b(i)
     end do
  endif
  ! send the target (called by all ranks)
  call MPI_BCAST(target,1,MPI_INTEGER,0,MPI_COMM_WORLD,err )

  ! scatter the data array
  call MPI_SCATTER(b,N_loc,MPI_INTEGER,b_loc,N_loc,MPI_INTEGER,  &
       0,MPI_COMM_WORLD,err)


  ! Search the b array and save the target locations, and number
  count=0
  do i=1,N_loc
     if (b_loc(i) == target) then
        count=count+1
        res(count)=i+rank*N_loc ! correct for actual position in array
     end if
  end do

  !gather the partial count from each process

  ! First the number of data points
  call MPI_GATHER(count,1,MPI_INTEGER,countA,1,MPI_INTEGER, &
       0,MPI_COMM_WORLD,err)

  ! calculate the displacements
  if(rank == 0) then
     full_count=0
     do i=1,nproc
        displacements(i)=full_count
        full_count=full_count+countA(i)
     enddo
  endif
  
  ! Now we know the number of data points, we can gather the actual data
  call MPI_GATHERV(res,count,MPI_INTEGER,full_res,countA, &
       displacements,MPI_INTEGER,0,MPI_COMM_WORLD,err)

  ! now output results
  if(rank == 0 ) then
     do i=1,full_count
        write(*,*) full_res(i)
     enddo
  endif

  call MPI_BARRIER(MPI_COMM_WORLD,err)
  call MPI_FINALIZE(err)
    
END PROGRAM search 
