package tink.io.java;

import org.xnio.Xnio;
import org.xnio.XnioWorker;
import java.nio.ByteBuffer;

using tink.CoreApi;

class WriteHandler implements java.lang.Runnable {
	var chunk:tink.Chunk;
	var buffer:Array<java.types.Int8>;
	var trigger:Outcome<Bool, Error>->Void;

	public function new(chunk, buffer, trigger) {
		this.chunk = chunk;
		this.buffer = buffer;
		this.trigger = trigger;
	}

	public function run() {
		try {
			var chunkData = chunk.toBytes().getData();
			for (i in chunkData) {
				this.buffer.push(i);
			}
			trigger(Success(true));
		} catch (e:Dynamic) {
			trigger(Failure(Error.withData("Error writing to stream", e)));
		}
	}
}

class XnioByteBuffer {
	var buffer:Array<java.types.Int8>;
	var worker:org.xnio.XnioWorker;
	var ended:FutureTrigger<Outcome<Bool, Error>>;

	public function new(buffer) {
		this.buffer = buffer != null ? buffer : new Array<java.types.Int8>();
		this.ended = Future.trigger();
	}

	public function end():Promise<Bool> {
		var didEnd = false;

		ended.asFuture().handle(function() didEnd = true).dissolve();

		if (didEnd)
			return false;

		this.ended.trigger(Success(false));
		return (ended.asFuture() : Promise<Bool>).next(_ -> true);
	}

	public function dump() {
		return java.nio.ByteBuffer.wrap(cast java.Lib.nativeArray(buffer, true));
	}

	public function write(bytes:tink.Chunk) {
		var trigger:FutureTrigger<Outcome<Bool, Error>> = Future.trigger();
		var xnio = Xnio.getInstance();
		if (this.worker == null) {
			if (xnio != null)
				this.worker = xnio.createWorker(org.xnio.OptionMap.EMPTY);
			else
				trigger.trigger(Failure(new tink.core.Error("Unable to get XnioWorker")));
		}
		worker.execute(new WriteHandler(bytes, buffer, trigger.trigger));
		return trigger.asFuture().first(ended);
	}
}
