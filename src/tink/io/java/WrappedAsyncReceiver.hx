package tink.io.java;

import tink.streams.Stream;
import io.undertow.io.Receiver;
import io.undertow.io.AsyncReceiverImpl;
import io.undertow.server.HttpServerExchange;
import tink.Chunk;

using tink.CoreApi;

class PartialBytesHandler implements io.undertow.io.Receiver_PartialBytesCallback {
	var ended:FutureTrigger<Outcome<Null<Chunk>, Error>>;
	var data:SignalTrigger<tink.Chunk>;

	public function new(ended, data) {
		this.ended = ended;
		this.data = data;
	}

	public function handle(exchange:HttpServerExchange, message:haxe.io.BytesData, last:Bool) {
		if (last || message.length == 0) {
			this.ended.trigger(Success(null));
			this.data.trigger(null);
		} else {
			this.data.trigger(haxe.io.Bytes.ofData(message));
		}
	}
}

class WrappedAsyncReceiver {
	var native:AsyncReceiverImpl;
	var name:String;
	var end:Promise<Null<Chunk>>;
	var handler:PartialBytesHandler;
	// var data:Array<tink.Chunk> = [];
	var onData:Signal<Null<Chunk>>;

	function new(name, native, onEnd) {
		this.name = name;
		this.native = native;
		var endTrigger = Future.trigger();
		var dataTrigger = Signal.trigger();
		this.end = endTrigger.asFuture();
		this.onData = dataTrigger.asSignal();
		this.handler = new PartialBytesHandler(endTrigger, dataTrigger);
		this.native.pause();
		if (onEnd != null) {
			this.end.handle(onEnd);
		}
	}

	public function read():Promise<Null<Chunk>>
		return Future.async(cb -> {
			this.native.resume();
			this.native.receivePartialBytes(this.handler);
			this.onData.next().handle(c -> {
				cb(Success(c));
				this.native.pause();
			});
		}).first(this.end);
}
