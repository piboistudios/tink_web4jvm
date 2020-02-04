package tink.io.java;

import tink.streams.Stream;
import io.undertow.io.Receiver;
import io.undertow.io.AsyncReceiverImpl;
import io.undertow.server.HttpServerExchange;
import tink.Chunk;

using tink.CoreApi;
class UndertowSource extends Generator<Chunk, Error> {
	public var index:Int;
	var target:WrappedAsyncReceiver;
	function new(index = 0, target:WrappedAsyncReceiver) {
		this.index = index;
		this.target = target;
		super(Future.async(function (cb) {
			target.read(index).handle(function (o) cb(switch o {
			  case Success(null): End;
			  case Success(chunk): Link(chunk, new UndertowSource(index+1, target));
			  case Failure(e): Fail(e);
			}));
		  } #if !tink_core_2 , true #end));
	}
	public function up() 
		return this.upcoming;

	static public function wrap(name, native:AsyncReceiverImpl, onEnd) {
		return new UndertowSource(@:privateAccess new WrappedAsyncReceiver(name, native, onEnd));
	}
}
