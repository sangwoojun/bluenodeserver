import FIFO::*;
import FIFOF::*;
import Vector::*;
import Defines::*;

interface MemServer;
	method Action req(MemReq32 data);
	method ActionValue#(Word) resp;
endinterface
interface MemClient;
	method Bool reqExist;
	method ActionValue#(MemReq32) memReq;
	method Action memResp(Word data);
endinterface
interface CacheIfc;
	interface MemServer server;
	interface MemClient client;
endinterface

module mkCacheNull (CacheIfc);
	FIFOF#(MemReq32) reqQ <- mkFIFOF;
	FIFO#(Word) respQ <- mkFIFO;

	interface MemServer server;
		method Action req(MemReq32 data);
			reqQ.enq(data);
		endmethod
		method ActionValue#(Word) resp;
			respQ.deq;
			return respQ.first;
		endmethod
	endinterface
	interface MemClient client;
		method Bool reqExist;
			return reqQ.notEmpty;
		endmethod
		method ActionValue#(MemReq32) memReq;
			reqQ.deq;
			return reqQ.first;
		endmethod
		method Action memResp(Word data);
			respQ.enq(data);
		endmethod
	endinterface
endmodule


interface MemorySystemIfc;
	interface MemServer iMem;
	interface MemServer dMem;
	interface MemClient client;
endinterface

module mkMemorySystem (MemorySystemIfc);
	CacheIfc im <- mkCacheNull;
	CacheIfc dm <- mkCacheNull;
	
	FIFOF#(MemReq32) reqQ <- mkFIFOF;
	FIFO#(Word) respQ <- mkFIFO;

	FIFO#(Bool) reqTargetIsIMemQ <- mkSizedFIFO(32);
	rule relayReq;
		if ( im.client.reqExist ) begin
			let r <- im.client.memReq;
			reqQ.enq(r);
			if ( r.write == False ) reqTargetIsIMemQ.enq(True);
		end else if ( dm.client.reqExist ) begin
			let r <- dm.client.memReq;
			reqQ.enq(r);
			if ( r.write == False ) reqTargetIsIMemQ.enq(False);
		end
	endrule

	rule relayResp;
		reqTargetIsIMemQ.deq;
		let t = reqTargetIsIMemQ.first;
		respQ.deq;
		let r = respQ.first;
		if ( t ) im.client.memResp(r);
		else dm.client.memResp(r);
	endrule


	interface MemServer iMem;
		method Action req(MemReq32 data);
			im.server.req(data);
		endmethod
		method ActionValue#(Word) resp;
			let r <- im.server.resp;
			return r;
		endmethod
	endinterface
	interface MemServer dMem;
		method Action req(MemReq32 data);
			dm.server.req(data);
		endmethod
		method ActionValue#(Word) resp;
			let r <- dm.server.resp;
			return r;
		endmethod
	endinterface
	interface MemClient client;
		method Bool reqExist;
			return reqQ.notEmpty;
		endmethod
		method ActionValue#(MemReq32) memReq;
			reqQ.deq;
			return reqQ.first;
		endmethod
		method Action memResp(Word data);
			respQ.enq(data);
		endmethod
	endinterface
endmodule
