package tink.io.java;

import tink.streams.Stream;
import io.undertow.io.Receiver;
import io.undertow.io.AsyncReceiverImpl;
import io.undertow.server.HttpServerExchange;
import tink.Chunk;

using tink.CoreApi;

class PartialBytesHandler implements io.undertow.io.Receiver_PartialBytesCallback {
    var ended:FutureTrigger<Noise>;
    var data:SignalTrigger<tink.Chunk>;
	public function new() {
        this.ended = Future.trigger();
        this.data = Signal.trigger();
    }
    public function onceEnded():Future<Noise> {
        return this.ended;
    }
    public function onData():Signal<tink.Chunk> {
        return this.data;
    }

	public function handle(exchange:HttpServerExchange, message:haxe.io.BytesData, last:Bool) {
		if (last || message.length == 0) {
			this.ended.trigger(Noise);
		} else {
            this.data.trigger(haxe.io.Bytes.ofData(message));
		}
	}


}

class WrappedAsyncReceiver  {
    var native:AsyncReceiverImpl;
    var name:String;
    var end:Surprise<Null<Chunk>, Error>;
    var handler:PartialBytesHandler;
    var data:Array<tink.Chunk> = [];
	function new(name, native, onEnd) {
        this.name = name;
        this.native = native;
        this.handler = new PartialBytesHandler();
        this.end = Future.async(function(cb) {
            this.handler.onceEnded().handle(cb.bind(Success(null)));
            this.handler.onData().handle(chunk -> {
                 this.data.push(chunk);
            });
            this.native.receivePartialBytes(this.handler);
        });
        if(onEnd != null) {
            this.end.handle(onEnd);
        }
    }

    public function read(index:Int):Promise<Null<Chunk>>
        return Future.async(cb -> {
            if(this.data.length > index) {
                var chunk = this.data[index];
                cb(Success(chunk));
            } else this.handler.onData().next().handle(chunk -> {
                cb(Success(chunk));
            });
        }).first(this.end);

	
}
