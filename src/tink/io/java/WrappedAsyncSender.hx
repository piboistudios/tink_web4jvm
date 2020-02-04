package tink.io.java;

import io.undertow.io.Sender;
import io.undertow.io.AsyncSenderImpl;
import io.undertow.server.HttpServerExchange;

using tink.CoreApi;
using tink.io.PipeResult;

import tink.io.Sink;
import tink.streams.Stream;

class IOCallbackHandler implements io.undertow.io.IoCallback {
	var done:Callback<Outcome<Bool, Error>>;

	public function new(done) {
		this.done = done;
	}

	public function onComplete(exchange:HttpServerExchange, sender:Sender) {
		done.invoke(Success(true));
	}

	public function onException(exchange:HttpServerExchange, sender:Sender, exception:java.io.IOException) {}
}

class WrappedAsyncSender {
	var ended:Promise<Bool>;
	var name:String;
	var native:Sender;

	public function new(name, native) {
		this.name = name;
		this.native = native;
	}

	public function end():Promise<Bool> {
		var didEnd = false;

		ended.handle(function() didEnd = true).dissolve();

		if (didEnd)
			return false;

		native.close();

		return ended.next(function(_) return true);
	}

	public function write(chunk:Chunk):Promise<Bool>
		return Future.async(cb -> {
			if (chunk.length == 0) {
				cb(Success(true));
				return;
			}
			this.native.send(java.nio.ByteBuffer.wrap(chunk.toBytes().getData()), new IOCallbackHandler(cb));
		});
}
