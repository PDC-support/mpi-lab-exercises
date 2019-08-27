!
!  STL file format 
!
!  UINT8[80] – Header
!  UINT32 – Number of triangles
!
!  foreach triangle
!  REAL32[3] – Normal vector
!  REAL32[3] – Vertex 1
!  REAL32[3] – Vertex 2
!  REAL32[3] – Vertex 3
!  UINT16 – Attribute byte count
!  end
!
!  (see https://en.wikipedia.org/wiki/STL_(file_format)
!
module types
  integer, parameter :: dp = kind(0.0d0)
  integer, parameter :: sp = kind(0.0)
end module types

module stl
  use mpi
  use types
  implicit none

  type :: stl_triangle_t
     real(kind=sp) :: n(3)
     real(kind=sp) :: v1(3)
     real(kind=sp) :: v2(3)
     real(kind=sp) :: v3(3)
     integer(kind=2) :: attrib
  end type stl_triangle_t

  type :: stl_model_t
     character(len=80) :: hdr
     integer :: n_tri
     type(stl_triangle_t), allocatable :: tri(:)
  end type stl_model_t
  
contains

  subroutine stl_read(fname, model)
    character(len=*), intent(in) :: fname
    type(stl_model_t), intent(inout) :: model
    integer :: pe_size, pe_rank, ierr

    call MPI_Comm_size(MPI_COMM_WORLD, pe_size, ierr)
    call MPI_Comm_rank(MPI_COMM_WORLD, pe_rank, ierr)

    open(42, file=fname, access='stream', form='unformatted')
    
    if (pe_rank .eq. 0) write(*,*) 'Reading STL file: ', fname
    ! Read STL header
    read(42, pos=1) model%hdr
    
    ! Make sure it's a binary STL file 
    if (model%hdr(1:6) .eq. 'solid') then
       write(*,*) 'ASCII STL files not supported!'
       stop 
    end if
    
    ! Read how many triangles the file contains 
    read(42, pos=81) model%n_tri
    if (pe_rank .eq. 0) write(*,*) 'Found: ', model%n_tri,' triangles'

    ! Allocate memory for triangles, and read them
    allocate(model%tri(model%n_tri))    
    read(42, pos=85) model%tri

    close(42)    
    if (pe_rank .eq. 0) write(*,*) 'Done'

  end subroutine stl_read

  subroutine stl_write(fname, model)
    character(len=*), intent(in) :: fname
    type(stl_model_t), intent(in) :: model
    integer :: pe_size, pe_rank, ierr

    call MPI_Comm_size(MPI_COMM_WORLD, pe_size, ierr)
    call MPI_Comm_rank(MPI_COMM_WORLD, pe_rank, ierr)
    
    open(17, file=fname, access='stream', form='unformatted')
    
    if (pe_rank .eq. 0) write(*,*) 'Writing STL file: ', fname

    ! Write STL header
    write(17, pos=1) model%hdr

    ! Write number of triangles
    write(17, pos=81) model%n_tri
    
    ! Write all triangles
    write(17, pos=85) model%tri

    close(17)
    if (pe_rank .eq. 0) write(*,*) 'Done'

  end subroutine stl_write
end module stl

program mpi_derived_types
  use stl
  use mpi
  implicit none
  type(stl_model_t) :: model
  integer :: ierr
  call MPI_Init(ierr)

  call stl_read("./data/sphere.stl", model)
  call stl_write("out.stl", model)
  deallocate(model%tri)

  call MPI_Finalize(ierr)

end program mpi_derived_types
