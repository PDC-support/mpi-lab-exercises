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

  integer :: MPI_STL_TRI
  
contains

  subroutine stl_read(fname, model)
    character(len=*), intent(in) :: fname
    type(stl_model_t), intent(inout) :: model
    integer(kind=MPI_OFFSET_KIND) :: byte_offset
    integer :: fh, ierr, pe_size, pe_rank, stl_offset, n_tri
    integer :: csize, isize, tsize

    call MPI_Comm_size(MPI_COMM_WORLD, pe_size, ierr)
    call MPI_Comm_rank(MPI_COMM_WORLD, pe_rank, ierr)

    call MPI_Type_size(MPI_CHARACTER, csize, ierr)
    call MPI_Type_size(MPI_INTEGER, isize, ierr)
    call MPI_Type_size(MPI_STL_TRI, tsize, ierr)

    call MPI_File_open(MPI_COMM_WORLD, fname, &
         MPI_MODE_RDONLY, MPI_INFO_NULL, fh, ierr)
    
    if (pe_rank .eq. 0) write(*,*) 'Reading STL file: ', fname
    ! Read STL header
    call MPI_File_read_all(fh, model%hdr, 80, MPI_CHARACTER, &
         MPI_STATUS_IGNORE, ierr)
    
    ! Make sure it's a binary STL file 
    if (model%hdr(1:6) .eq. 'solid') then
       write(*,*) 'ASCII STL files not supported!'
       stop 
    end if
    
    ! Read how many triangles the file contains 
    call MPI_File_read_all(fh, n_tri, 1, MPI_INTEGER, &
         MPI_STATUS_IGNORE, ierr)
    if (pe_rank .eq. 0) write(*,*) 'Found: ', n_tri,' triangles'

    ! Compute how many triangles this rank should read
    model%n_tri = (n_tri + pe_size - pe_rank - 1) / pe_size

    ! Allocate memory for triangles, and read them
    allocate(model%tri(model%n_tri))    

    ! Compute the offset into the list of triangles
    stl_offset = 0
    call MPI_Exscan(model%n_tri, stl_offset, 1, MPI_INTEGER, &
         MPI_SUM, MPI_COMM_WORLD, ierr)

    ! Compute offset into the file
    byte_offset = 80 * csize + isize + stl_offset * tsize

    call MPI_File_read_at_all(fh, byte_offset, model%tri, model%n_tri, MPI_STL_TRI, &
         MPI_STATUS_IGNORE, ierr)

    call MPI_File_close(fh, ierr)
    if (pe_rank .eq. 0) write(*,*) 'Done'

  end subroutine stl_read

  subroutine stl_write(fname, model)
    character(len=*), intent(in) :: fname
    type(stl_model_t), intent(in) :: model
    integer(kind=MPI_OFFSET_KIND) :: byte_offset
    integer :: fh, ierr, pe_size, pe_rank, stl_offset, n_tri
    integer :: csize, isize, tsize
    
    call MPI_Comm_size(MPI_COMM_WORLD, pe_size, ierr)
    call MPI_Comm_rank(MPI_COMM_WORLD, pe_rank, ierr)

    call MPI_Type_size(MPI_CHARACTER, csize, ierr)
    call MPI_Type_size(MPI_INTEGER, isize, ierr)
    call MPI_Type_size(MPI_STL_TRI, tsize, ierr)
    
    call MPI_File_open(MPI_COMM_WORLD, fname, &
         MPI_MODE_WRONLY + MPI_MODE_CREATE, MPI_INFO_NULL, fh, ierr)
    
    if (pe_rank .eq. 0) write(*,*) 'Writing STL file: ', fname

    ! Write STL header
    call MPI_File_write_all(fh, model%hdr, 80, MPI_CHARACTER, &
         MPI_STATUS_IGNORE, ierr)

    ! Compute the total number of triangles 
    call MPI_Allreduce(model%n_tri, n_tri, 1, MPI_INTEGER, &
         MPI_SUM, MPI_COMM_WORLD, ierr)

    ! Write number of triangles
    call MPI_File_write_all(fh, n_tri, 1, MPI_INTEGER, &
         MPI_STATUS_IGNORE, ierr)

    ! Compute the offset into the list of triangles
    stl_offset = 0
    call MPI_Exscan(model%n_tri, stl_offset, 1, MPI_INTEGER, &
         MPI_SUM, MPI_COMM_WORLD, ierr)

    ! Compute the offset into the file
    byte_offset = 80 * csize + isize + stl_offset * tsize
    
    ! Write all triangles
    call MPI_File_write_at_all(fh, byte_offset, model%tri, model%n_tri, MPI_STL_TRI, &
         MPI_STATUS_IGNORE, ierr)

    call MPI_File_close(fh, ierr)
    if (pe_rank .eq. 0) write(*,*) 'Done'

  end subroutine stl_write
end module stl

program mpi_derived_types
  use stl
  use mpi
  implicit none
  type(stl_model_t) :: model
  type(stl_triangle_t) :: triangle
  integer(kind=MPI_ADDRESS_KIND) :: disp(5), base
  integer :: type(5), len(5), ierr

  call MPI_Init(ierr)

  ! Setup displacement of each block in the struct
  call MPI_Get_address(triangle%n, disp(1), ierr)
  call MPI_Get_address(triangle%v1, disp(2), ierr)
  call MPI_Get_address(triangle%v2, disp(3), ierr)
  call MPI_Get_address(triangle%v3, disp(4), ierr)
  call MPI_Get_address(triangle%attrib, disp(5), ierr)
  
  base = disp(1) 
  disp(1) = disp(1) - base 
  disp(2) = disp(2) - base 
  disp(3) = disp(3) - base 
  disp(4) = disp(4) - base 
  disp(5) = disp(5) - base 
  
  len = 3
  len(5) = 1
  
  type(1:4) = MPI_REAL
  type(5) = MPI_INTEGER2
  
  ! Create dervied MPI type
  call MPI_Type_create_struct(5, len, disp, type, MPI_STL_TRI, ierr)
  call MPI_Type_commit(MPI_STL_TRI, ierr)

  call stl_read("./data/sphere.stl", model)
  call stl_write("out.stl", model)
  deallocate(model%tri)

  call MPI_Finalize(ierr)

end program mpi_derived_types
