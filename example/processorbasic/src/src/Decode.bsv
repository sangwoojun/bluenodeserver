import Defines::*;

function DecodedInst decode(Bit#(32) inst);
    let opcode = inst[6:0];
    let funct3 = inst[14:12];
    let funct7 = inst[31:25];
    let dst     = inst[11:7];
    let src1    = inst[19:15];
    let src2    = inst[24:20];
    let csr    = inst[31:20];

    Word immI = signExtend(inst[31:20]);
    Word immS = signExtend({ inst[31:25], inst[11:7] });
    Word immB = signExtend({ inst[31], inst[7], inst[30:25], inst[11:8], 1'b0});
    Word immU = signExtend({ inst[31:12], 12'b0 });
    Word immJ = signExtend({ inst[31], inst[19:12], inst[20], inst[30:21], 1'b0});

    DecodedInst dInst = ?;
    dInst.iType = Unsupported;
    dInst.dst = tagged Invalid;
    dInst.src1 = tagged Invalid;
    dInst.src2 = tagged Invalid;
    case(opcode)
        opOp: begin
            if (funct7 == 7'b0000000) begin
                case (funct3)
                    fnADD:  dInst = DecodedInst { dst: tagged Valid dst, src1: tagged Valid src1, src2: tagged Valid src2, imm: ?, brFunc: ?, aluFunc: Add,  iType: OP, size: ?, extendSigned: ? };
                    fnSLT:  dInst = DecodedInst { dst: tagged Valid dst, src1: tagged Valid src1, src2: tagged Valid src2, imm: ?, brFunc: ?, aluFunc: Slt,  iType: OP, size: ?, extendSigned: ? };
                    fnSLTU: dInst = DecodedInst { dst: tagged Valid dst, src1: tagged Valid src1, src2: tagged Valid src2, imm: ?, brFunc: ?, aluFunc: Sltu, iType: OP, size: ?, extendSigned: ? };
                    fnXOR:  dInst = DecodedInst { dst: tagged Valid dst, src1: tagged Valid src1, src2: tagged Valid src2, imm: ?, brFunc: ?, aluFunc: Xor,  iType: OP, size: ?, extendSigned: ? };
                    fnOR:   dInst = DecodedInst { dst: tagged Valid dst, src1: tagged Valid src1, src2: tagged Valid src2, imm: ?, brFunc: ?, aluFunc: Or,   iType: OP, size: ?, extendSigned: ? };
                    fnAND:  dInst = DecodedInst { dst: tagged Valid dst, src1: tagged Valid src1, src2: tagged Valid src2, imm: ?, brFunc: ?, aluFunc: And,  iType: OP, size: ?, extendSigned: ? };
                    fnSLL:  dInst = DecodedInst { dst: tagged Valid dst, src1: tagged Valid src1, src2: tagged Valid src2, imm: ?, brFunc: ?, aluFunc: Sll,  iType: OP, size: ?, extendSigned: ? };
                    fnSR:   dInst = DecodedInst { dst: tagged Valid dst, src1: tagged Valid src1, src2: tagged Valid src2, imm: ?, brFunc: ?, aluFunc: Srl,  iType: OP, size: ?, extendSigned: ? };
                endcase
            end else if (funct7 == 7'b0100000) begin
                case (funct3)
                    fnADD:  dInst = DecodedInst { dst: tagged Valid dst, src1: tagged Valid src1, src2: tagged Valid src2, imm: ?, brFunc: ?, aluFunc: Sub,  iType: OP, size: ?, extendSigned: ? };
                    fnSR:   dInst = DecodedInst { dst: tagged Valid dst, src1: tagged Valid src1, src2: tagged Valid src2, imm: ?, brFunc: ?, aluFunc: Sra,  iType: OP, size: ?, extendSigned: ? };
                endcase
            end
		  else if (funct7 == 7'b0000001) begin
                 // Multiply instruction
                 case (funct3)
                     fnMUL:  dInst = DecodedInst { dst: tagged Valid dst, src1: tagged Valid src1, src2: tagged Valid src2, imm: ?, brFunc: ?, aluFunc: Mul,  iType: OP, size: ?, extendSigned: ? };
                 endcase
             end
        end
        opOpImm: begin
            case (funct3)
                fnADD:  dInst = DecodedInst { dst: tagged Valid dst, src1: tagged Valid src1, src2: tagged Invalid, imm: immI, brFunc: ?, aluFunc: Add,  iType: OPIMM, size: ?, extendSigned: ? };
                fnSLT:  dInst = DecodedInst { dst: tagged Valid dst, src1: tagged Valid src1, src2: tagged Invalid, imm: immI, brFunc: ?, aluFunc: Slt,  iType: OPIMM, size: ?, extendSigned: ? };
                fnSLTU: dInst = DecodedInst { dst: tagged Valid dst, src1: tagged Valid src1, src2: tagged Invalid, imm: immI, brFunc: ?, aluFunc: Sltu, iType: OPIMM, size: ?, extendSigned: ? };
                fnXOR:  dInst = DecodedInst { dst: tagged Valid dst, src1: tagged Valid src1, src2: tagged Invalid, imm: immI, brFunc: ?, aluFunc: Xor,  iType: OPIMM, size: ?, extendSigned: ? };
                fnOR:   dInst = DecodedInst { dst: tagged Valid dst, src1: tagged Valid src1, src2: tagged Invalid, imm: immI, brFunc: ?, aluFunc: Or,   iType: OPIMM, size: ?, extendSigned: ? };
                fnAND:  dInst = DecodedInst { dst: tagged Valid dst, src1: tagged Valid src1, src2: tagged Invalid, imm: immI, brFunc: ?, aluFunc: And,  iType: OPIMM, size: ?, extendSigned: ? };
                fnSLL:  begin
                    if (funct7 == 7'b0000000) begin
                        dInst = DecodedInst { dst: tagged Valid dst, src1: tagged Valid src1, src2: tagged Invalid, imm: immI, brFunc: ?, aluFunc: Sll, iType: OPIMM, size: ?, extendSigned: ? };
                    end
                end
                fnSR: begin
                    if (funct7 == 7'b0000000) begin
                        dInst = DecodedInst { dst: tagged Valid dst, src1: tagged Valid src1, src2: tagged Invalid, imm: immI, brFunc: ?, aluFunc: Srl, iType: OPIMM, size: ?, extendSigned: ? };
                    end else if (funct7 == 7'b0100000) begin
                        dInst = DecodedInst { dst: tagged Valid dst, src1: tagged Valid src1, src2: tagged Invalid, imm: immI, brFunc: ?, aluFunc: Sra, iType: OPIMM, size: ?, extendSigned: ? };
                    end
                end
            endcase
        end
        opBranch: begin
            case(funct3)
                fnBEQ:  dInst = DecodedInst { dst: tagged Invalid, src1: tagged Valid src1, src2: tagged Valid src2, imm: immB, brFunc: Eq,  aluFunc: ?, iType: BRANCH, size: ?, extendSigned: ? };
                fnBNE:  dInst = DecodedInst { dst: tagged Invalid, src1: tagged Valid src1, src2: tagged Valid src2, imm: immB, brFunc: Neq, aluFunc: ?, iType: BRANCH, size: ?, extendSigned: ? };
                fnBLT:  dInst = DecodedInst { dst: tagged Invalid, src1: tagged Valid src1, src2: tagged Valid src2, imm: immB, brFunc: Lt,  aluFunc: ?, iType: BRANCH, size: ?, extendSigned: ? };
                fnBGE:  dInst = DecodedInst { dst: tagged Invalid, src1: tagged Valid src1, src2: tagged Valid src2, imm: immB, brFunc: Ge,  aluFunc: ?, iType: BRANCH, size: ?, extendSigned: ? };
                fnBLTU: dInst = DecodedInst { dst: tagged Invalid, src1: tagged Valid src1, src2: tagged Valid src2, imm: immB, brFunc: Ltu, aluFunc: ?, iType: BRANCH, size: ?, extendSigned: ? };
                fnBGEU: dInst = DecodedInst { dst: tagged Invalid, src1: tagged Valid src1, src2: tagged Valid src2, imm: immB, brFunc: Geu, aluFunc: ?, iType: BRANCH, size: ?, extendSigned: ? };
            endcase
        end
        opLui:  dInst = DecodedInst { dst: tagged Valid dst, src1: tagged Invalid,   src2: tagged Invalid, imm: immU, brFunc: ?, aluFunc: ?, iType: LUI, size: ?, extendSigned: ? };
        opJal:  dInst = DecodedInst { dst: tagged Valid dst, src1: tagged Invalid,   src2: tagged Invalid, imm: immJ, brFunc: ?, aluFunc: ?, iType: JAL, size: ?, extendSigned: ? };
        opJalr: dInst = DecodedInst { dst: tagged Valid dst, src1: tagged Valid src1, src2: tagged Invalid, imm: immI, brFunc: ?, aluFunc: ?, iType: JALR, size: ?, extendSigned: ? };
        opLoad: begin
			case (funct3)
			fnLW: dInst = DecodedInst { dst: tagged Valid dst, src1: tagged Valid src1, src2: tagged Invalid, imm: immI, brFunc: ?, aluFunc: ?, iType: LOAD, size:Word, extendSigned: ? };
			fnLH: dInst = DecodedInst { dst: tagged Valid dst, src1: tagged Valid src1, src2: tagged Invalid, imm: immI, brFunc: ?, aluFunc: ?, iType: LOAD, size:Half, extendSigned: True };
			fnLB: dInst = DecodedInst { dst: tagged Valid dst, src1: tagged Valid src1, src2: tagged Invalid, imm: immI, brFunc: ?, aluFunc: ?, iType: LOAD, size:Byte, extendSigned: True };
			fnLHU: dInst = DecodedInst { dst: tagged Valid dst, src1: tagged Valid src1, src2: tagged Invalid, imm: immI, brFunc: ?, aluFunc: ?, iType: LOAD, size:Half, extendSigned: False };
			fnLBU: dInst = DecodedInst { dst: tagged Valid dst, src1: tagged Valid src1, src2: tagged Invalid, imm: immI, brFunc: ?, aluFunc: ?, iType: LOAD, size:Byte, extendSigned: False };
			//FIXME sign extend?!
			endcase
        end
        opStore: begin
			case (funct3)
				fnSW: dInst = DecodedInst { dst: tagged Invalid, src1: tagged Valid src1, src2: tagged Valid src2, imm: immS, brFunc: ?, aluFunc: ?, iType: STORE, size: Word, extendSigned: ? };
				fnSH: dInst = DecodedInst { dst: tagged Invalid, src1: tagged Valid src1, src2: tagged Valid src2, imm: immS, brFunc: ?, aluFunc: ?, iType: STORE, size: Half, extendSigned: ? };
				fnSB: dInst = DecodedInst { dst: tagged Invalid, src1: tagged Valid src1, src2: tagged Valid src2, imm: immS, brFunc: ?, aluFunc: ?, iType: STORE, size: Byte, extendSigned: ? };
			endcase
        end

        opAuipc: dInst = DecodedInst { dst: tagged Valid dst, src1: tagged Invalid,   src2: tagged Invalid, imm: immU, brFunc: ?, aluFunc: ?, iType: AUIPC };
        // opSystem: begin
        //     if (funct3 == fnCSR && src1 == 0) begin
        //         case (csr)
        //             csrCycle:   dInst = DecodedInst { dst: tagged Valid dst, src1: tagged Invalid, src2: tagged Invalid, imm: ?, brFunc: ?, aluFunc: ?, iType: RDCYCLE };
        //             csrInstret: dInst = DecodedInst { dst: tagged Valid dst, src1: tagged Invalid, src2: tagged Invalid, imm: ?, brFunc: ?, aluFunc: ?, iType: RDINSTRET };
        //         endcase
        //     end
        // end
    endcase
    return dInst;
endfunction
