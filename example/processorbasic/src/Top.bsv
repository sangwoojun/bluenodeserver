import FIFO::*;

import Defines::*;
import Processor::*;

import "BDPI" function Word memRead(Bit#(32) addr, Bit#(32) bytes);
import "BDPI" function Action memWrite(Bit#(32) idx, Bit#(32) bytes, Word data);

interface TopIfc;
endinterface

module mkTop(TopIfc);
	ProcessorIfc proc <- mkProcessor;

	rule relaymem;
		let r <- proc.memReq;
		Bit#(32) bytes = case (r.size)
			Byte: 1;
			Half: 2;
			Word: 4;
		endcase;
		if ( r.write ) begin
			memWrite(r.addr, bytes, r.data);
		end else begin
			Bit#(32) data = memRead(r.addr, bytes);
			proc.memResp(data);
		end
	endrule
endmodule
