// import Common::*;
import Defines::*;
//import ALU::*;


// ALU
///////////////////////////////////////////////////////////////////////////


function Word alu(Word a, Word b, AluFunc func);
    //return fastAlu(a,b,func);
    Word res = case (func)
                  Add:    (a + b);
                  Sub:    (a - b);
                  And:    (a & b);
                  Or:     (a | b);
                  Xor:    (a ^ b);
                  Slt:    (signedLT(a, b) ? 1 : 0);
                  Sltu:   ((a < b) ? 1 : 0);
                  Sll:    (a << b[4:0]);
                  Srl:    (a >> b[4:0]);
                  Sra:    signedShiftRight(a, b[4:0]);
				  Mul:    (a * b);
               endcase;
    return res;
endfunction


function Bool aluBr(Word a, Word b, BrFunc brFunc);
    Bool res = case (brFunc)
        Eq:     (a == b);
        Neq:    (a != b);
        Lt:     signedLT(a, b);
        Ltu:    (a < b);
        Ge:     signedGE(a, b);
        Geu:    (a >= b);
        AT:     True;
        NT:     False;
    endcase;
    return res;
endfunction


function ExecInst exec( DecodedInst dInst, Word rVal1, Word rVal2, Word pc );
    let imm = dInst.imm;
    let brFunc = dInst.brFunc;
    let aluFunc = dInst.aluFunc;
    Word data = ?;
    Word nextPc = ?;
    Word addr = ?;
    case (dInst.iType) matches
        OP: begin data = alu(rVal1, rVal2, aluFunc); nextPc = pc+4; end
        OPIMM: begin data = alu(rVal1, imm, aluFunc); nextPc = pc+4; end
        BRANCH: begin nextPc = aluBr(rVal1, rVal2, brFunc) ? pc+imm : pc+4; end
        LUI: begin data = imm; nextPc = pc+4; end
        JAL: begin data = pc+4; nextPc = pc+imm; end
        JALR: begin data = pc+4; nextPc = (rVal1+imm) & ~1; end
        LOAD: begin addr = rVal1+imm; nextPc = pc+4; end
        STORE: begin data = rVal2; addr = rVal1+imm; nextPc = pc+4; end
        AUIPC: begin data = pc+imm; nextPc = pc+4; end
    endcase
    ExecInst eInst = ?;
    eInst.iType = dInst.iType;
    eInst.dst = dInst.dst;
    eInst.data = data;
    eInst.addr = addr;
    eInst.nextPC = nextPc;
    return eInst;
endfunction




// // Branch Address Calculation
// ///////////////////////////////////////////////////////////////////////////

// Bit#(32) errorValue = 32'hAAAAAAAA;

// function Word brAddrCalc(Word pc, Word val, IType iType, Word imm);
//     Word targetAddr = case (iType)
//         J:  (pc + imm);
//         Jr: {truncateLSB(val + imm), 1'b0};
//         Br: (pc + imm);
//         default: errorValue; // 32'hAAAAAAAA
//     endcase;
//     return targetAddr;
// endfunction

// // Execute Function
// ///////////////////////////////////////////////////////////////////////////

// function ExecInst exec(DecodedInst dInst, Word rVal1, Word rVal2, Word pc);
//     ExecInst eInst  = ?;
//     let aluVal2     = fromMaybe(rVal2, dInst.imm);
//     let aluRes      = alu(rVal1, aluVal2, dInst.aluFunc);
//     eInst.iType     = dInst.iType;
//     eInst.data      = dInst.iType == St ? rVal2 :
//                       (dInst.iType == J || dInst.iType == Jr) ? (pc + 4) :
//                       dInst.iType == Lui ? fromMaybe(?, dInst.imm) : dInst.iType == Auipc ? pc+fromMaybe(?, dInst.imm) : aluRes;
//     let brTaken     = aluBr(rVal1, rVal2, dInst.brFunc);
//     let brAddr      = brAddrCalc(pc, rVal1, dInst.iType, fromMaybe(?, dInst.imm));
//     eInst.nextPC    = brTaken ? brAddr : pc + 4;
//     eInst.addr      = aluRes;
//     eInst.dst       = dInst.dst;
//     return eInst;
// endfunction

