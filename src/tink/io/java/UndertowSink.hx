package tink.io.java;

import io.undertow.io.Sender;
import io.undertow.io.AsyncSenderImpl;
import io.undertow.server.HttpServerExchange;

using tink.CoreApi;
using tink.io.PipeResult;

import tink.io.Sink;
import tink.streams.Stream;

class UndertowSink extends SinkBase<Error, Noise> {
	var target:WrappedAsyncSender;

	function new(target) {
		this.target = target;
	}

	override public function consume<EIn>(source:Stream<Chunk, EIn>, options:PipeOptions):Future<PipeResult<EIn, Error, Noise>> {
		var ret = source.forEach(c -> {
			return target.write(c).map(w -> switch w {
				case Success(true): Resume;
				case Success(false): BackOff;
				case Failure(e): Clog(e);
			});
		});
		if (options.end) {
			ret.handle(end -> target.end());
		}
		return ret.map(c -> c.toResult(Noise));
	}

	static public function wrap(name, native) {
		return new UndertowSink(new WrappedAsyncSender(name, native));
	}
}
