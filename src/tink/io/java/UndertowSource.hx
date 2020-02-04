package tink.io.java;

import tink.streams.Stream;
import io.undertow.io.Receiver;
import io.undertow.io.AsyncReceiverImpl;
import io.undertow.server.HttpServerExchange;
import tink.Chunk;

using tink.CoreApi;

class UndertowSource extends Generator<Chunk, Error> {
	function new(target:WrappedAsyncReceiver) {
		super(Future.async(function(cb) {
			target.read().handle(function(o) cb(switch o {
				case Success(null): End;
				case Success(chunk): Link(chunk, new UndertowSource(target));
				case Failure(e): Fail(e);
			}));
		} #if !tink_core_2, true #end));
	}

	static public function wrap(name, native:AsyncReceiverImpl, onEnd) {
		return new UndertowSource(@:privateAccess new WrappedAsyncReceiver(name, native, onEnd));
	}
}
