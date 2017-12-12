PROGRAM search  
  implicit none
  integer, parameter ::  N=300
  integer i, target ! local variables
  integer b(N)      ! the entire array of integers

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

  ! Search the b array and output the target locations

  do i=1,N
     if (b(i) == target) then
        write(11,*) i
     end if
  end do

END PROGRAM search 
