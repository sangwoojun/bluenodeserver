import FIFO::*;
import FIFOF::*;

import RFile::*;
import MemorySystem::*;
import Defines::*;
import Decode::*;
import Execute::*;

typedef enum {Fetch, Decode, Execute, Mem} ProcStage deriving (Eq,Bits);

interface ProcessorIfc;
	method ActionValue#(MemReq32) memReq;
	method Action memResp(Word data);
endinterface

(* synthesize *)
module mkProcessor(ProcessorIfc);

	FIFOF#(F2D) f2d <- mkSizedFIFOF(2);
    FIFOF#(D2E) d2e <- mkSizedFIFOF(2);
	FIFOF#(E2M) e2m <- mkSizedFIFOF(2);

	Reg#(ProcStage) stage <- mkReg(Fetch);
	
	RFile2R1W   rf <- mkRFile2R1W;
	MemorySystemIfc mem <- mkMemorySystem;



	FIFOF#(Word) redirectPcQ <- mkSizedFIFOF(2);
	Reg#(Word)  pc <- mkReg(0);
	rule doFetch (stage == Fetch);
		let next_pc = pc + 4;
		if ( redirectPcQ.notEmpty ) begin
			redirectPcQ.deq;
			next_pc = redirectPcQ.first;
			$write( "Fetch jumping to %x\n", pc );
		end 

		mem.iMem.req(MemReq32{write:False,addr:pc,data:?,size:Word});
		f2d.enq(F2D {pc: pc, ppc: pppc, epoch: next_epochF});
		pc <= next_pc;
		$write( "Fetching %x\n", pc );
		stage <= Decode;
	endrule





	rule doDecode (stage == Decode);
		Word inst <- mem.iMem.resp;
		let x = f2d.first;
		let dInst = decode(inst); // rs1, rs2 are Maybe types
		let rVal1 = rf.rd1(fromMaybe(?, dInst.src1));
		let rVal2 = rf.rd2(fromMaybe(?, dInst.src2));
		d2e.enq(D2E {pc: x.pc, ppc: x.ppc, epoch: x.epoch, 
				dInst: dInst, rVal1: rVal1, rVal2: rVal2});
		f2d.deq;

		stage <= Execute;
		$display( "Decoding %x %x", x.pc, inst );
	endrule

	Reg#(Bool)  epoch <- mkReg(False);
    //Reg#(RIndx) dstLoad <- mkReg(0);
	rule doExecute (stage == Execute);
		let x = d2e.first;          
		let pcE = x.pc; let ppc = x.ppc; let epochE = x.epoch; 
		let rVal1 = x.rVal1; let rVal2 = x.rVal2; 
		let dInst = x.dInst;
		d2e.deq;

		let eInst = exec(dInst, rVal1, rVal2, pcE);
		
		if (epochE == epoch) begin  // right-path instruction
			if (eInst.iType == Unsupported) begin
				$display("Reached unsupported instruction");
				//$display("Total Clock Cycles = %d\nTotal Instruction Count = %d", cycles, instCnt);
				$display("Dumping the state of the processor");
				$display("pc = 0x%x", x.pc);
				//rf.displayRFileInSimulation;
				$display("Quitting simulation.");
				$finish;
			end
			let misprediction = eInst.nextPC != ppc;
			if ( misprediction ) begin
				epoch <= !epoch;
				redirectPcQ.enq(eInst.nextPC);
			end

			if (eInst.iType == LOAD) begin
				mem.dMem.req(MemReq32{write:False,addr:eInst.addr,data:?,size:dInst.size});
				//dstLoad <= fromMaybe(?, eInst.dst); // FIXME to FIFO
				e2m.enq(E2M{dst:fromMaybe(?, eInst.dst),extendSigned:dInst.extendSigned,size:dInst.size});
				stage <= Mem;
				$write( "mem read from%x\n", eInst.addr);
			end 
			else if (eInst.iType == STORE) begin
				//if ( eInst.addr == 'h4000_1000)
					//$display("Total Clock Cycles = %d\nTotal Instruction Count = %d", cycles, instCnt);
				mem.dMem.req(MemReq32{write:True,addr:eInst.addr,data:eInst.data,size:dInst.size});
				stage <= Fetch;
				$write( "mem write %x to %x\n", eInst.data, eInst.addr);
			end
			else begin
				if(isValid(eInst.dst)) begin
					rf.wr(fromMaybe(?, eInst.dst), eInst.data);
					$write( "rf writing %x to %d\n", fromMaybe(?,eInst.dst), eInst.data );
				end
				stage <= Fetch;
			end
		end
		$display( "Executing %x", x.pc );
	endrule

	rule doWriteback (stage == Mem);
		let data <- mem.dMem.resp;
		e2m.deq;
		let r = e2m.first;

		Word dw = data;
		if ( r.size == Byte ) begin
			if ( r.extendSigned ) begin
				Int#(8) id = unpack(data[7:0]);
				Int#(32) ide = signExtend(id);
				dw = pack(ide);
			end else begin
				dw = zeroExtend(data[7:0]);
			end
		end else if ( r.size == Half ) begin
			if ( r.extendSigned ) begin
				Int#(16) id = unpack(data[15:0]);
				Int#(32) ide = signExtend(id);
				dw = pack(ide);
			end else begin
				dw = zeroExtend(data[15:0]);
			end
		end
		rf.wr(r.dst, dw);
		
		stage <= Fetch;
		$display( "doing Mem %x", data );
	endrule








	method ActionValue#(MemReq32) memReq;
		let r <- mem.client.memReq;
		return r;
	endmethod
	method Action memResp(Word data);
		mem.client.memResp(data);
	endmethod
endmodule
