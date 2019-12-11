typedef struct {
	Bool write;
	Bit#(32) addr;
	Bit#(32) data;
} MemReq32 deriving(Bits,Eq);
