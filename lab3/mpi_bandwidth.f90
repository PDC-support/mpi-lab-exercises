Program bandwidth
implicit none
include "mpif.h"

integer, parameter :: MaxTasks=8192,StartSize=100000
integer, parameter :: EndSize=1000000, Increment=100000, RoundTrips = 100

integer numtasks,rank,n,i,j,rndtrps,nbytes,start,end,incr
integer src,dest,rc,tag,taskpairs(MaxTasks),namelength

double precision thistime, bw, bestbw, worstbw, totalbw, avgbw
double precision bestall, avgall, worstall
double precision timings(MaxTasks/2,3),tmptimes(3)
double precision resolution, t1, t2

character (len=EndSize) ::  msgbuf
character (len=MPI_MAX_PROCESSOR_NAME) ::  host,hostmap(MaxTasks)

integer status(MPI_STATUS_SIZE),ierr

tag=1

call MPI_Init(ierr)
call MPI_Comm_size(MPI_COMM_WORLD,numtasks,ierr)
if( mod(numtasks,2).ne.0) then
   write(*,*) "ERROR : Must be an even number of tasks! Quiting..."
   call MPI_Abort(MPI_COMM_WORLD,1,ierr)
   stop
endif

call MPI_Comm_rank(MPI_COMM_WORLD,rank,ierr)

start = StartSize
end = EndSize
incr = Increment
rndtrps = RoundTrips

msgbuf=repeat("x",end)

! All tasks send their host name to task 0
call MPI_Get_processor_name(host,namelength,ierr)
call MPI_Gather(host,MPI_MAX_PROCESSOR_NAME,MPI_CHARACTER,hostmap, &
     MPI_MAX_PROCESSOR_NAME,MPI_CHARACTER,0,MPI_COMM_WORLD,ierr)

! Determine who my send/receive partner is and tell task 0
if(rank.lt.numtasks/2) then
   dest = numtasks/2 + rank
   src = dest
endif
if(rank.ge.numtasks/2) then
   dest = rank - numtasks/2
   src = dest
endif
call MPI_Gather(dest,1,MPI_INTEGER,taskpairs,1,MPI_INTEGER,0,  &
     MPI_COMM_WORLD,ierr)

if(rank.eq.0) then
   resolution=MPI_Wtick()

   write(*,*) "******************** MPI Bandwidth Test ********************"
   write(*,*) "Message start size= ",start," bytes"
   write(*,*) "Message finish size= ",end," bytes"
   write(*,*) "Incremented by ",incr," bytes per iteration"
   write(*,*) "Roundtrips per iteration= ",rndtrps
   write(*,*) "MPI_Wtick resolution = ",resolution
   write(*,*) "************************************************************"

   do i=1,numtasks
!       write(*,*) "task ",i," is on ",len_trim(hostmap(i)),  &
      write(*,*) "task ",i," is on ",trim(hostmap(i)),  &
            " partner=",taskpairs(i)
   enddo
endif

!*************************** first half of tasks *****************************
!* These tasks send/receive messages with their partner task, and then do a  *
!* few bandwidth calculations based upon message size and timings.           *

if(rank.lt.numtasks/2) then
   do n=start,end,incr
      bestbw  = 0.0d0
      worstbw = 0.99d99
      totalbw = 0.0d0
      nbytes=n
      do i=1,rndtrps
         t1 = MPI_Wtime()
         call MPI_Send(msgbuf,n,MPI_CHARACTER,dest,tag,MPI_COMM_WORLD,ierr)
         call MPI_Recv(msgbuf,n,MPI_CHARACTER,src,tag,MPI_COMM_WORLD,status,ierr)
         t2 = MPI_Wtime()
         thistime=t2-t1
         bw = nbytes*2/thistime
         totalbw = totalbw + bw
         if (bw.gt.bestbw) bestbw = bw
         if(bw.lt.worstbw) worstbw = bw
      enddo
      ! Convert to megabytes per second
      bestbw = bestbw/1000000.0d0
      avgbw = totalbw/(1000000.0d0*rndtrps)
      worstbw = worstbw/1000000.0;

      !Task 0 collects timings from all relevant tasks
      if(rank.eq.0) then
         ! Keep track of my own timings first
         timings(1,1) = bestbw
         timings(1,2) = avgbw
         timings(1,3) = worstbw
         ! Initialize overall averages
         bestall = 0.0;
         avgall = 0.0;
         worstall = 0.0;
      ! Now receive timings from other tasks and print results. Note
      ! that this loop will be appropriately skipped if there are
      ! only two tasks.
         do j=1,numtasks/2-1
            call MPI_Recv(timings(j+1,1),3,MPI_DOUBLE_PRECISION,j,tag, &
                 MPI_COMM_WORLD,status,ierr)
         enddo
         write(*,*) "***Message size: ",n, &
                 " *** best  /  avg  / worst (MB/sec)"
         do j=0,numtasks/2-1

            write(*,'(A,I4,A,I4,3(A,F10.4))') "task pair: ",j," - ",taskpairs(j+1),"   :   ", &
                 timings(j+1,1)," / ",timings(j+1,2)," / ",timings(j+1,3)
            bestall = bestall + timings(j+1,1)
            avgall = avgall + timings(j+1,2)
            worstall = worstall + timings(j+1,3)
         enddo
         write(*,'(3(A, F10.4))') "OVERALL AVERAGES:            ", &
              2*bestall/numtasks," / ",2*avgall/numtasks," / ", &
              2*worstall/numtasks
         write(*,*)
      else
         !Other tasks send their timings to task 0
         tmptimes(0) = bestbw;
         tmptimes(1) = avgbw;
         tmptimes(2) = worstbw;
         call MPI_Send(tmptimes, 3, MPI_DOUBLE_PRECISION, 0, tag, &
              MPI_COMM_WORLD,ierr)
      endif
   enddo
endif


!**************************** second half of tasks ***************************
!* These tasks do nothing more than send and receive with their partner task *

if(rank.ge.numtasks/2) then
   do n=start,end,incr
      do i=1,rndtrps
         call MPI_Recv(msgbuf,n,MPI_CHARACTER,src,tag,MPI_COMM_WORLD,status,ierr)
         call MPI_Send(msgbuf,n,MPI_CHARACTER,dest,tag,MPI_COMM_WORLD,ierr)
      enddo
   enddo
endif



call MPI_Finalize(ierr)

end program
