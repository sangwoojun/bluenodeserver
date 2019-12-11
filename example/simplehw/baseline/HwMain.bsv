import FIFO::*;
import Defines::*;

interface HwMainIfc;
	method ActionValue#(MemReq32) memReq;
	method Action memResp(Bit#(32) data);
endinterface

module mkHwMain (HwMainIfc);
	FIFO#(MemReq32) memReqQ <- mkFIFO;
	Reg#(Bool) init <- mkReg(0);
	rule initr(!init);
		init <= True;
		$display( "Hello World!" );
	endrule

	method ActionValue#(MemReq32) memReq;
		memReqQ.deq;
		return memReqQ.first;
	endmethod
	method Action memResp(Bit#(32) data);
	endmethod
endmodule
