.DEFAULT_GOAL := all
OBJPATH=./obj/
BSCFLAGS = -show-schedule -aggressive-conditions --wait-for-license 
BSCFLAGS_BSIM = -bdir $(OBJPATH) -simdir $(OBJPATH) -info-dir $(OBJPATH) -fdir $(OBJPATH) -D BSIM -RTS
BSVPATH=src/
CPPFILES=src/bdpi/bdpi.cpp

all:
	mkdir -p $(OBJPATH)
	bsc $(BSCFLAGS) $(BSCFLAGS_BSIM) -p +:$(BSVPATH) -sim -u -g mkTop $(BSVPATH)/Top.bsv  
	bsc $(BSCFLAGS) $(BSCFLAGS_BSIM) -sim -e mkTop -o $(OBJPATH)/bsim $(OBJPATH)/*.ba $(CPPFILES)

clean:
	rm -r $(OBJPATH)

