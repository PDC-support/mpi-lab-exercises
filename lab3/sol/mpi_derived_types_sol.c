/*
  STL file format 

  UINT8[80] – Header
  UINT32 – Number of triangles

  foreach triangle
  REAL32[3] – Normal vector
  REAL32[3] – Vertex 1
  REAL32[3] – Vertex 2
  REAL32[3] – Vertex 3
  UINT16 – Attribute byte count
  end

  (see https://en.wikipedia.org/wiki/STL_(file_format)
  
*/

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <mpi.h>

#define STL_HDR_SIZE 80
MPI_Datatype MPI_STL_TRI;

typedef struct {
  float n[3];			/* Normal vector */
  float v1[3];			/* Vertex 1 */
  float v2[3];			/* Vertex 2 */
  float v3[3];			/* Vertex 3 */
  uint16_t attrib;		/* Attribute byte count */
} __attribute__((packed)) stl_triangle_t;

typedef struct {
  char hdr[STL_HDR_SIZE];	/* Header */
  uint32_t n_tri;		/* Number of triangles */
  stl_triangle_t *tri;		/* Triangles */
} stl_model_t;


void stl_read(const char *fname, stl_model_t *model) {
  MPI_File fh;
  int pe_size, pe_rank;
  uint n_tri, stl_offset;
  MPI_Offset byte_offset;

  MPI_Comm_size(MPI_COMM_WORLD, &pe_size);
  MPI_Comm_rank(MPI_COMM_WORLD, &pe_rank);

  MPI_File_open(MPI_COMM_WORLD, fname, MPI_MODE_RDONLY, MPI_INFO_NULL, &fh);
  if (pe_rank == 0) printf("Reading STL file: %s\n", fname);

  /* Read STL header */
  MPI_File_read_all(fh, model->hdr, STL_HDR_SIZE, MPI_CHAR, MPI_STATUS_IGNORE);

  /* Make sure it's a binary STL file */
  if (strncmp(model->hdr, "solid", 5) == 0) {
    fprintf(stderr, "ASCII STL files not supported!\n");
    exit(-1);
  }

  /* Read how many triangles the file contains */
  MPI_File_read_all(fh, &n_tri, 1, MPI_UNSIGNED, MPI_STATUS_IGNORE);
  if (pe_rank == 0) printf("Found: %d triangles\n", n_tri);

  /* Compute how many triangles this rank should read */
  model->n_tri = (n_tri + pe_size - pe_rank - 1) / pe_size;

  /* Allocate memory for triangles, and read them */
  model->tri = malloc(model->n_tri * sizeof(stl_triangle_t));

  /* Compute the offset into the list of triangles */
  stl_offset = 0;
  MPI_Exscan(&model->n_tri, &stl_offset, 1, 
	     MPI_UNSIGNED, MPI_SUM, MPI_COMM_WORLD);

  /* Compute offset into the file */
  byte_offset = STL_HDR_SIZE * sizeof(char) + sizeof(uint32_t) + 
    stl_offset * sizeof(stl_triangle_t);

  MPI_File_read_at_all(fh, byte_offset, model->tri, model->n_tri,
		       MPI_STL_TRI, MPI_STATUS_IGNORE);

  MPI_File_close(&fh);
  if (pe_rank == 0) printf("Done\n");

}

void stl_write(const char *fname, stl_model_t *model) {
  MPI_File fh;
  int pe_size, pe_rank;
  uint n_tri, stl_offset;
  MPI_Offset byte_offset;

  MPI_Comm_size(MPI_COMM_WORLD, &pe_size);
  MPI_Comm_rank(MPI_COMM_WORLD, &pe_rank);
  
  MPI_File_open(MPI_COMM_WORLD, fname,
		MPI_MODE_WRONLY | MPI_MODE_CREATE, MPI_INFO_NULL, &fh);
  if (pe_rank == 0) printf("Writing STL file: %s\n", fname);

  /* Write STL header */
  MPI_File_write_all(fh, model->hdr, STL_HDR_SIZE, MPI_CHAR, MPI_STATUS_IGNORE);

  /* Compute the total number of triangles */
  MPI_Allreduce(&model->n_tri, &n_tri, 1,
		MPI_UNSIGNED, MPI_SUM, MPI_COMM_WORLD);

  /* Write number of triangles */
  MPI_File_write_all(fh, &n_tri, 1, MPI_UNSIGNED, MPI_STATUS_IGNORE);


  /* Compute the offset into the list of triangles */
  stl_offset = 0;
  MPI_Exscan(&model->n_tri, &stl_offset, 1, 
	     MPI_UNSIGNED, MPI_SUM, MPI_COMM_WORLD);

  /* Compute offset into the file */
  byte_offset = STL_HDR_SIZE * sizeof(char) + sizeof(uint32_t) + 
    stl_offset * sizeof(stl_triangle_t);
  
  /* Write all triangles */
  MPI_File_write_at_all(fh, byte_offset, model->tri, model->n_tri, 
  			MPI_STL_TRI, MPI_STATUS_IGNORE);

  MPI_File_close(&fh);
  if (pe_rank == 0) printf("Done\n");
}

int main(int argc, char **argv) {
  int i;
  stl_model_t model;
  stl_triangle_t triangle;

  const int len[5] = {3, 3, 3, 3, 1};
  const MPI_Datatype type[5] = {MPI_FLOAT, MPI_FLOAT, 
				MPI_FLOAT, MPI_FLOAT, MPI_UNSIGNED_SHORT};
  MPI_Datatype MPI_STL_TRI_STRUCT;
  MPI_Aint base, disp[5], sizeofstruct;

  MPI_Init(&argc, &argv);

  /* Setup displacement of each block in the struct */
  MPI_Get_address(&triangle.n[0], disp); 
  MPI_Get_address(&triangle.v1[0], disp + 1); 
  MPI_Get_address(&triangle.v2[0], disp + 2); 
  MPI_Get_address(&triangle.v3[0], disp + 3); 
  MPI_Get_address(&triangle.attrib, disp + 4); 

  base = disp[0]; 
  for (i=0; i < 5; i++) disp[i] = MPI_Aint_diff(disp[i], base); 
  MPI_Type_create_struct(5, len, disp, type, &MPI_STL_TRI_STRUCT);

  /* Resize the dervied type to account for padding by the compiler */
  MPI_Get_address(&triangle+1, &sizeofstruct); 
  sizeofstruct = MPI_Aint_diff(sizeofstruct, base); 
  MPI_Type_create_resized(MPI_STL_TRI_STRUCT, 0, sizeofstruct, &MPI_STL_TRI);
 
  /* Create dervied MPI type */
  MPI_Type_commit(&MPI_STL_TRI);


  stl_read("./data/sphere.stl", &model);
  stl_write("out.stl", &model);
  free(model.tri);

  MPI_Finalize();
  
  return 0;
}


