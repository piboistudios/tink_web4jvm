package tink.io.java;

import tink.streams.Stream;
import io.undertow.io.Receiver;
import io.undertow.io.AsyncReceiverImpl;
import io.undertow.server.HttpServerExchange;
import tink.Chunk;

using tink.CoreApi;

class PartialBytesHandler implements io.undertow.io.Receiver_PartialBytesCallback {
	var cb:CallbackList<Step<Chunk, Error>>;
	var onEnd:Void->Void;
	var receiver:AsyncReceiverImpl;

	public function new(cb:Step<tink.Chunk, Error>->Void, onEnd:Void->Void, receiver) {
		this.cb = new CallbackList<Step<tink.Chunk, Error>>();
		this.cb.add(cb);
		this.onEnd = onEnd;
		this.receiver = receiver;
	}

	public function handle(exchange:HttpServerExchange, message:haxe.io.BytesData, last:Bool) {
		// trace('handling: $message (${message.length})');
		if (last || message.length == 0) {
			this.cb.invoke(End);
			this.cb.clear();
			this.onEnd();
			// trace("end");
		} else {
			var msg = haxe.io.Bytes.ofData(message);
			this.cb.invoke(Link(Chunk.ofBytes(msg), @:privateAccess new UndertowSource(receiver, this, null)));
			this.cb.clear();
			// trace('link: ${msg.toString()}');
		}
	}

	public function replace(cb:Step<tink.Chunk, Error>->Void) {
		this.cb.add(cb);
	}
}

class UndertowSource extends Generator<Chunk, Error> {
	function new(target:AsyncReceiverImpl, handler:PartialBytesHandler, onEnd:Void->Void) {
		var future = Future.async(cb -> {
			
			handler == null ? target.receivePartialBytes(new PartialBytesHandler(cb, onEnd, target)) : handler.replace(cb);
		} #if !tink_core_2, true #end);
		super(future);
		future.eager();
	}

	static public function wrap(native, handler, onEnd) {
		return new UndertowSource(native, handler, onEnd);
	}
}
