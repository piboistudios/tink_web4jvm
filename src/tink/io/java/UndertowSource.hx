package tink.io.java;

import tink.streams.Stream;
import io.undertow.io.Receiver;
import io.undertow.io.AsyncReceiverImpl;
import io.undertow.server.HttpServerExchange;
import tink.Chunk;

using tink.CoreApi;

class PartialBytesHandler implements io.undertow.io.Receiver_PartialBytesCallback {
	var cb:Step<Chunk, Error>->Void;
	var onEnd:Void->Void;
	var receiver:AsyncReceiverImpl;

	public function new(cb:Step<tink.Chunk, Error>->Void, onEnd:Void->Void, receiver) {
		this.cb = cb;
		this.onEnd = onEnd;
		this.receiver = receiver;
	}

	public function handle(exchange:HttpServerExchange, message:haxe.io.BytesData, last:Bool) {
		if (last || message.length == 0) {
			onEnd();
			cb(End);
		} else {
			cb(Link(Chunk.ofBytes(haxe.io.Bytes.ofData(message)), @:privateAccess new UndertowSource(receiver, this, null)));
		}
	}

	public function replace(cb:Step<tink.Chunk, Error>->Void) {
		this.cb = cb;
	}
}

class UndertowSource extends Generator<Chunk, Error> {
	function new(target:AsyncReceiverImpl, handler:PartialBytesHandler, onEnd:Void->Void) {
		super(Future.async(cb -> {
			handler == null ? target.receivePartialBytes(new PartialBytesHandler(cb, onEnd, target)) : handler.replace(cb);
		} #if !tink_core_2, true #end));
	}

	static public function wrap(native, handler, onEnd) {
		return new UndertowSource(native, handler, onEnd);
	}
}
