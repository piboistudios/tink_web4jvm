package tink.io.java;

import tink.streams.Stream;
import io.undertow.io.Receiver;
import io.undertow.io.AsyncReceiverImpl;
import io.undertow.server.HttpServerExchange;
import tink.Chunk;

using tink.CoreApi;

class PartialBytesHandler implements io.undertow.io.Receiver_PartialBytesCallback {
	public var receiver:WrappedAsyncReceiver;

	public function new(receiver) {
		this.receiver = receiver;
	}

	public function handle(exchange:HttpServerExchange, message:haxe.io.BytesData, last:Bool) {
		if (last || message.length == 0) {
            this.receiver.end();
			this.receiver.emit(Success(null));
		} else {
			this.receiver.emit(Success(haxe.io.Bytes.ofData(message)));
		}
		this.receiver.pause();
	}
}

class WrappedAsyncReceiver {
	var native:AsyncReceiverImpl;
	var name:String;

	var handler:PartialBytesHandler;
    var emitter:FutureTrigger<Outcome<tink.Chunk, Error>>;
    var ended:FutureTrigger<Outcome<tink.Chunk, Error>>;

	function new(name, native, onEnd) {
		this.name = name;
		this.native = native;
		this.emitter = Future.trigger();
		this.handler = new PartialBytesHandler(this);
		this.native.pause();
		if (onEnd != null) {
            this.ended = Future.trigger();
            this.ended.asFuture().handle(() -> {
                onEnd();
            });
		}
	}

	public function pause() {
		this.native.pause();
	}

	public function emit(c:Outcome<Null<tink.Chunk>, Error>) {
		this.emitter.trigger(c);
    }
    public function end() {
        this.ended.trigger(Success(null));
    }

	public function read():Promise<Null<Chunk>> {
		// trace(haxe.CallStack.toString(haxe.CallStack.callStack()));
		return Future.async(cb -> {
			this.native.resume();
			this.native.receivePartialBytes(this.handler);
			this.emitter.asFuture().handle(c -> {
				cb(c);
				this.emitter = Future.trigger();
			});
		}).first(this.ended);
	}
}
