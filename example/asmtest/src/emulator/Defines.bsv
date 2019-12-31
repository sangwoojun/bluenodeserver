typedef Bit#(32) Word;
typedef Bit#(5) RIndx;

`ifdef MEM_LAT
typedef `MEM_LAT MemLat;
`else
typedef 1 MemLat;
`endif


typedef enum { OP, OPIMM, BRANCH, LUI, JAL, JALR, LOAD, STORE, AUIPC, Unsupported} IType deriving (Bits, Eq, FShow);
typedef enum {Eq, Neq, Lt, Ltu, Ge, Geu, AT, NT} BrFunc deriving (Bits, Eq, FShow);
typedef enum {Add, Sub, And, Or, Xor, Slt, Sltu, Sll, Srl, Sra, Mul} AluFunc deriving (Bits, Eq, FShow);
typedef enum {ImmI, ImmS, ImmB, ImmU, ImmJ, NoImm} ImmType deriving (Bits, Eq, FShow);

typedef enum { Byte,Half,Word } SizeType deriving (Bits, Eq, FShow);

// Opcode
Bit#(7) opOpImm  = 7'b0010011;
Bit#(7) opOp     = 7'b0110011;
Bit#(7) opLui    = 7'b0110111;
Bit#(7) opJal    = 7'b1101111;
Bit#(7) opJalr   = 7'b1100111;
Bit#(7) opBranch = 7'b1100011;
Bit#(7) opLoad   = 7'b0000011;
Bit#(7) opStore  = 7'b0100011;
Bit#(7) opAuipc  = 7'b0010111;
Bit#(7) opSystem = 7'b1110011;

// funct3 - ALU
Bit#(3) fnADD   = 3'b000;
Bit#(3) fnSLL   = 3'b001;
Bit#(3) fnSLT   = 3'b010;
Bit#(3) fnSLTU  = 3'b011;
Bit#(3) fnXOR   = 3'b100;
Bit#(3) fnSR    = 3'b101;
Bit#(3) fnOR    = 3'b110;
Bit#(3) fnAND   = 3'b111;
// funct3 - Branch
Bit#(3) fnBEQ   = 3'b000;
Bit#(3) fnBNE   = 3'b001;
Bit#(3) fnBLT   = 3'b100;
Bit#(3) fnBGE   = 3'b101;
Bit#(3) fnBLTU  = 3'b110;
Bit#(3) fnBGEU  = 3'b111;
// funct3 - Load
Bit#(3) fnLW    = 3'b010;
Bit#(3) fnLB    = 3'b000;
Bit#(3) fnLH    = 3'b001;
Bit#(3) fnLBU   = 3'b100;
Bit#(3) fnLHU   = 3'b101;
// funct3 - Store
Bit#(3) fnSW    = 3'b010;
Bit#(3) fnSB    = 3'b000;
Bit#(3) fnSH    = 3'b001;
// funct3 - Multiply
Bit#(3) fnMUL   = 3'b000;
// funct3 - CSR
Bit#(3) fnCSRRS = 3'b010;

// funct12 - CSR
//Bit#(12) csrCycle   = 12'hC00;
//Bit#(12) csrInstret = 12'hC02;

// execute

typedef struct {
    IType           iType;
    Maybe#(RIndx)   dst;
    Word            data;
    Word            addr;
    Word            nextPC;
} ExecInst deriving (Bits, Eq, FShow);





typedef struct {
    IType iType;
    AluFunc aluFunc;
    BrFunc brFunc;
    Maybe#(RIndx) dst;
    Maybe#(RIndx) src1;
    Maybe#(RIndx) src2;
    Word imm;
	SizeType size;
	Bool extendSigned;
} DecodedInst deriving (Bits, Eq, FShow);


typedef struct {
   Word pc;
   Word ppc;
   Bool epoch;
} F2D deriving(Bits, Eq);

typedef struct {
   Word pc;
   Word ppc;
   Bool epoch;
   DecodedInst dInst; 
   Word rVal1; 
   Word rVal2;
   } D2E deriving(Bits, Eq);

typedef struct {
	RIndx dst;
	Bool extendSigned;
	SizeType size;
} E2M deriving(Bits,Eq);


typedef struct {
	Bool write;
	Bit#(32) addr;
	Word data;
	SizeType size;
} MemReq32 deriving(Bits,Eq);
