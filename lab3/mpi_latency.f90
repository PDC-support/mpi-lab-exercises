Program latency
implicit none
include "mpif.h"

integer, parameter ::	NUMBER_REPS=1000

integer reps,         &      ! number of samples per test
    tag,              &      ! MPI message tag parameter
    numtasks,         &      ! number of MPI tasks
    rank,             &      ! my MPI task number
    dest, source,     &      ! send/receive task designators
    rc,ierr,          &      ! return code
    n
double precision  T1, T2,  & ! start/end times per rep
    sumT,                  & ! sum of all reps times
    avgT,                  & ! average time per rep in microseconds
    deltaT                   ! time for one rep

character*1 msg              ! buffer containing 1 byte message
integer status(MPI_STATUS_SIZE)    ! MPI receive routine parameter

call MPI_Init(ierr)
call MPI_Comm_size(MPI_COMM_WORLD,numtasks,ierr)
call MPI_Comm_rank(MPI_COMM_WORLD,rank,ierr)

if(rank.eq.0.and.numtasks.ne.2) then
   write(*,*) "Number of tasks =",numtasks
   write(*,*) "Only need 2 tasks - extra will be ignored..."
endif

call MPI_Barrier(MPI_COMM_WORLD,ierr)

sumT = 0
msg = 'x'
tag = 1
reps = NUMBER_REPS

if(rank.eq.0) then
   ! round-trip latency timing test
  write(*,*) "task ",rank," has started..."
  write(*,*)  "Beginning latency timing test. Number of reps = ", reps
  write(*,*) "***************************************************"
  write(*,*) "Rep#       T1               T2            deltaT"
  dest = 1
  source = 1
  do n=1,reps
     T1=MPI_Wtime() ! start time
      ! send message to worker - message tag set to 1.
      ! If return code indicates error quit
     call MPI_Send(msg,1,MPI_BYTE,dest,tag,MPI_COMM_WORLD,ierr)
     if(ierr.ne.MPI_SUCCESS) then
         Write(*,*) "Send error in task 0!"
         call MPI_Abort(MPI_COMM_WORLD, ierr,rc)
         stop
     endif
     ! Now wait to receive the echo reply from the worker
     ! If return code indicates error quit
     call MPI_Recv(msg,1,MPI_BYTE,source,tag,MPI_COMM_WORLD, &
          status,ierr)
     if(ierr.ne.MPI_SUCCESS) then
         Write(*,*) "Receive error in task 0!"
         call MPI_Abort(MPI_COMM_WORLD,ierr,rc)
         stop
     endif
     T2 = MPI_Wtime()      ! end time

     ! calculate round trip time and print
      deltaT = T2 - T1
      sumT = sumT + deltaT
100   format(I4,2F21.8,F12.8)
      write(*,100)  n, T1, T2, deltaT
  enddo

  avgT =  sumT*1000000.0d0/reps;
200 format(A,F8.3,A)
  write(*,*) "***************************************************"
  write(*,200) "*** Avg round trip time = ",avgT," microseconds"
  write(*,200) "*** Avg one way latency = ",avgT/2," microseconds"

else if (rank.eq.1) then
   write(*,*) "task ",rank," has started..."
   dest=0
   source=0
   do n=1,reps
      call MPI_Recv(msg,1,MPI_BYTE,source,tag,MPI_COMM_WORLD,status,ierr)
      if(ierr.ne.MPI_SUCCESS) then
         Write(*,*) "Receive error in task 1!"
         call MPI_Abort(MPI_COMM_WORLD,ierr,rc)
         stop
      endif

      call MPI_Send(msg,1,MPI_BYTE,dest,tag,MPI_COMM_WORLD,ierr)
      if(ierr.ne.MPI_SUCCESS) then
         Write(*,*) "Send error in task 0!"
         call MPI_Abort(MPI_COMM_WORLD, ierr,rc)
         stop
     endif
   enddo
endif


call MPI_Finalize(ierr)

end program
