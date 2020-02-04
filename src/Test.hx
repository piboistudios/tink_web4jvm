import tink.http.containers.*;
import tink.http.Response;
import tink.web.routing.*;
import tink.streams.Stream;

class Test {
	static function main() {
		var container = new tink.http.containers.UndertowContainer(null, null);
		var router = new Router<Root>(new Root());
		container.run(function(req) {
			var ctx = Context.ofRequest(req);
			return router.route(ctx).recover(OutgoingResponse.reportError);
		});
	}
}

class Root {
	public function new() {}

    @:post("/payload")
    public function payload(body:{name:String}) {
        return body.name;
    }
	@:post("/stream-to-disk")
	public function stream_to_disk(body:tink.io.Source.RealSource) {
        var stdOutput = new haxe.io.BytesOutput();
        var stdSink = tink.io.Sink.ofOutput('std-output', stdOutput);
        body.pipeTo(stdSink).handle(() -> {
            var text = stdOutput.getBytes().toString();
            sys.io.File.saveContent("./request-streamed.out", text);
            trace('Request: $text, ${(body:Dynamic).index}');
        });
        return "Streaming request to disk. :) Enjoy your response while we continue processing in the background.";
    }
    @:post("/buffer-to-disk")
    public function buffer_to_disk(body:haxe.io.Bytes) {
        var text = body.toString();
        sys.io.File.saveContent("./request-buffered.out", text);
        return "Data buffered and written to disk; this happened synchronously, so the data was written to disk before this response was sent";
    }
	@:get('/')
	@:get('/$name')
	public function hello(name = 'World')
		return 'Hello, $name!';
}
