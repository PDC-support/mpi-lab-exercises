#include <stdio.h>

int main (int argc, char *argv[]) {
  const int N=300;
  int i,target;
  int b[N];
  FILE *infile,*outfile;

  /* File b.data has the target value on the first line
     The remaining 300 lines of b.data have the values for the b array */
  infile = fopen("b.data","r" ) ;
  outfile = fopen("found.data","w") ;
    
  /* read in target */
  fscanf(infile,"%d", &target);

  /* read in b array */
  for(i=0;i<N;i++) {
    fscanf(infile,"%d", &b[i]);
  }
  fclose(infile);

  /* Search the b array and output the target locations */

  for(i=0;i<N;i++) {
    if( b[i] == target) {
      fprintf(outfile,"%d\n",i+1);
    }
  }
  fclose(outfile);
 
 return 0;
}

