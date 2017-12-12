PROGRAM parallel_search   
  implicit none
  include 'mpif.h'
  integer N
  parameter (N=300)
  integer i, target
  integer b(N),a(N/3) ! a is name of the array each slave searches 
  integer rank,err,nproc
  integer status(MPI_STATUS_SIZE)
  integer end_cnt,x,gi

  CALL MPI_INIT(err)
  CALL MPI_COMM_RANK(MPI_COMM_WORLD, rank, err)
  CALL MPI_COMM_SIZE(MPI_COMM_WORLD, nproc, err)
 
  !only 4 MPI tasks supported
  if(nproc.ne.4) then
     write(*,*) "Must be run with 4 MPI tasks"
     write(*,*) "Number of Tasks = ",nproc
     write(*,*) "Aborting..."
     call mpi_abort(mpi_comm_world,1,err)
  endif


  if (rank == 0) then
    open(unit=10,file="b.data")
    read(10,*) target
 
    do i=1,3  !  Notice how i is used as the destination process for each send 
      CALL MPI_SEND(target,1,MPI_INTEGER,i,9,MPI_COMM_WORLD,err)
    end do

    do i=1,300
      read(10,*) b(i)
    end do

    CALL MPI_SEND(b(1),100,MPI_INTEGER,1,11,MPI_COMM_WORLD,err)
    CALL MPI_SEND(b(101),100,MPI_INTEGER,2,11,MPI_COMM_WORLD,err)
    CALL MPI_SEND(b(201),100,MPI_INTEGER,3,11,MPI_COMM_WORLD,err)

    end_cnt=0
    open(unit=11,file="found.data")
    do while (end_cnt .ne. 3 )
      CALL MPI_RECV(x,1,MPI_INTEGER,MPI_ANY_SOURCE,MPI_ANY_TAG, &
                     MPI_COMM_WORLD,status,err)
      if (status(MPI_TAG) == 52 ) then
        end_cnt=end_cnt+1  ! See Comment  
      else
        write(11,*) "P",status(MPI_SOURCE),x
      end if
    end do 

  else 
    CALL MPI_RECV(target,1,MPI_INTEGER,0,9,MPI_COMM_WORLD,status,err) 
    CALL MPI_RECV(a,100,MPI_INTEGER,0,11,MPI_COMM_WORLD,status,err) 

    do i=1,100
      if (a(i) == target) then
        gi=(rank-1)*100+i !  Equation to convert local index to global index 
        CALL MPI_SEND(gi,1,MPI_INTEGER,0,19,MPI_COMM_WORLD,err)
      end if
    end do  

    CALL MPI_SEND(target,1,MPI_INTEGER,0,52,MPI_COMM_WORLD,err) ! See Comment
     
  end if 

  CALL MPI_FINALIZE(err)

END PROGRAM parallel_search
