import FIFO::*;

import HwMain::*;
import Defines::*;

import "BDPI" function Bit#(32) memRead(Bit#(32) addr, Bit#(32) bytes);
import "BDPI" function Action memWrite(Bit#(32) idx, Bit#(32) bytes, Bit#(32) data);

interface TopIfc;
endinterface

module mkTop(TopIfc);
	HwMainIfc hwmain <- mkHwMain;

	rule relaymem;
		let r <- hwmain.memReq;
		if ( r.write ) begin
			memWrite(r.addr, 4, r.data);
		end else begin
			Bit#(32) data = memRead(r.addr, 4);
			hwmain.memResp(data);
		end
	endrule
endmodule
