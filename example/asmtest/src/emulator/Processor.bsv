import FIFO::*;
import FIFOF::*;

import RFile::*;
import MemorySystem::*;
import Defines::*;
import Decode::*;
import Execute::*;

typedef enum {Fetch, Decode, Execute, Mem, Halt} ProcStage deriving (Eq,Bits);

interface ProcessorIfc;
	method ActionValue#(MemReq32) memReq;
	method Action memResp(Word data);
endinterface

(* synthesize *)
module mkProcessor(ProcessorIfc);
	Reg#(Bit#(32)) fetched_cnt <- mkReg(0);

	FIFOF#(F2D) f2d <- mkSizedFIFOF(2);
    FIFOF#(D2E) d2e <- mkSizedFIFOF(2);
	FIFOF#(E2M) e2m <- mkSizedFIFOF(2);

	Reg#(ProcStage) stage <- mkReg(Fetch);
	
	RFile2R1W   rf <- mkRFile2R1W;
	MemorySystemIfc mem <- mkMemorySystem;



	FIFOF#(Word) redirectPcQ <- mkSizedFIFOF(2);
	Reg#(Word)  pc <- mkReg(0);
	rule doFetch (stage == Fetch);
		let fetch_pc = pc;
		if ( redirectPcQ.notEmpty ) begin
			redirectPcQ.deq;
			fetch_pc = redirectPcQ.first;
		end 

		mem.iMem.req(MemReq32{write:False,addr:fetch_pc,data:?,size:Word});
		let predict_pc = fetch_pc + 4;
		pc <= predict_pc;
		f2d.enq(F2D {pc: fetch_pc, ppc: predict_pc, epoch: ?});
		$write( "Instruction %04d: Fetching from %04x\n", fetched_cnt, fetch_pc );
		stage <= Decode;

		fetched_cnt <= fetched_cnt + 1;
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
		//$display( "Decoding %x %x", x.pc, inst );
	endrule

	//Reg#(Bool)  epoch <- mkReg(False);
    //Reg#(RIndx) dstLoad <- mkReg(0);
	rule doExecute (stage == Execute);
		let x = d2e.first;          
		let pcE = x.pc; let ppc = x.ppc; let epochE = x.epoch; 
		let rVal1 = x.rVal1; let rVal2 = x.rVal2; 
		let dInst = x.dInst;
		d2e.deq;

		let eInst = exec(dInst, rVal1, rVal2, pcE);
		
		//if (epochE == epoch) begin  // right-path instruction

			let misprediction = eInst.nextPC != ppc;
			if ( misprediction ) begin
				//epoch <= !epoch;
				redirectPcQ.enq(eInst.nextPC);
			end

			if (eInst.iType == Unsupported) begin
				$display("Reached unsupported instruction");
				//$display("Total Clock Cycles = %d\nTotal Instruction Count = %d", cycles, instCnt);
				$display("Dumping the state of the processor");
				$display("pc = 0x%x", x.pc);
				rf.displayRFileInSimulation;
				$display("Quitting simulation.");
				stage <= Halt;
			end
			else if (eInst.iType == LOAD) begin
				mem.dMem.req(MemReq32{write:False,addr:eInst.addr,data:?,size:dInst.size});
				//dstLoad <= fromMaybe(?, eInst.dst); // FIXME to FIFO
				e2m.enq(E2M{dst:fromMaybe(?, eInst.dst),extendSigned:dInst.extendSigned,size:dInst.size});
				stage <= Mem;
				$write( "\t mem read from %x\n", eInst.addr);
			end 
			else if (eInst.iType == STORE) begin
				//if ( eInst.addr == 'h4000_1000)
					//$display("Total Clock Cycles = %d\nTotal Instruction Count = %d", cycles, instCnt);
				mem.dMem.req(MemReq32{write:True,addr:eInst.addr,data:eInst.data,size:dInst.size});
				stage <= Fetch;
				$write( "\t mem write %x to %x\n", eInst.data, eInst.addr);
			end
			else begin
				if(isValid(eInst.dst)) begin
					rf.wr(fromMaybe(?, eInst.dst), eInst.data);
					$write( "\t exec result writing %x to reg %d\n", eInst.data, fromMaybe(?,eInst.dst)  );
				end
				stage <= Fetch;
			end
		//end
		//$display( "Executing %x", x.pc );
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
		$display( "\t mem read result %x written to reg %x", data, r.dst );
	endrule

	Reg#(Bit#(32)) haltcycles <- mkReg(0);
	rule haltstate (stage == Halt);
		if ( haltcycles >= 1024 ) $finish;
		else begin
			haltcycles <= haltcycles + 1;
		end
	endrule








	method ActionValue#(MemReq32) memReq;
		let r <- mem.client.memReq;
		return r;
	endmethod
	method Action memResp(Word data);
		mem.client.memResp(data);
	endmethod
endmodule
