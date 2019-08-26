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
  FILE *fp;
  int pe_size, pe_rank;

  MPI_Comm_size(MPI_COMM_WORLD, &pe_size);
  MPI_Comm_rank(MPI_COMM_WORLD, &pe_rank);  

  fp = fopen(fname, "r");

  if (pe_rank == 0) printf("Reading STL file: %s\n", fname);

  /* Read STL header */
  fread(model->hdr, sizeof(char), STL_HDR_SIZE, fp);

  /* Make sure it's a binary STL file */
  if (strncmp(model->hdr, "solid", 5) == 0) {
    fprintf(stderr, "ASCII STL files not supported!\n");
    exit(-1);
  }

  /* Read how many triangles the file contains */
  fread(&model->n_tri, sizeof(uint32_t), 1, fp);
  if (pe_rank == 0) printf("Found: %d triangles\n", model->n_tri);

  /* Allocate memory for triangles, and read them */
  model->tri = malloc(model->n_tri * sizeof(stl_triangle_t));
  fread(model->tri, sizeof(stl_triangle_t), model->n_tri, fp);

  fclose(fp);
  if (pe_rank == 0) printf("Done\n");

}

void stl_write(const char *fname, stl_model_t *model) {
  FILE *fp;
  int pe_size, pe_rank;

  MPI_Comm_size(MPI_COMM_WORLD, &pe_size);
  MPI_Comm_rank(MPI_COMM_WORLD, &pe_rank);
  
  fp = fopen(fname, "w");
  if (pe_rank == 0) printf("Writing STL file: %s\n", fname);

  /* Write STL header */
  fwrite(model->hdr, sizeof(char), STL_HDR_SIZE, fp);

  /* Write number of triangles */
  fwrite(&model->n_tri, sizeof(uint32_t), 1, fp);

  /* Write all triangles */
  fwrite(model->tri, sizeof(stl_triangle_t), model->n_tri, fp);

  fclose(fp);
  if (pe_rank == 0) printf("Done\n");
}

int main(int argc, char **argv) {
  stl_model_t model;
  
  MPI_Init(&argc, &argv);
  
  stl_read("./data/sphere.stl", &model);
  stl_write("out.stl", &model);
  free(model.tri);

  MPI_Finalize();
  
  return 0;
}


