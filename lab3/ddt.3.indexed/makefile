CXX = mpicxx
CFLAGS = -g
EXEC = mpi_ddt_indexed

all:
	$(CXX) $(CFLAGS) mpi_ddt_indexed.c -o $(EXEC)
clean:
	@echo "*** Clean : removing object files"
	@( $(RM) *.o *.mod *~)
	@( $(RM) $(EXEC))
