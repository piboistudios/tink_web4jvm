import tink.http.containers.*;
import tink.http.Response;
import tink.web.routing.*;
import tink.streams.Stream;

class Test {
	static function main() {
		var container = new tink.http.containers.UndertowContainer(null, null);
		// var container =  PhpContainer.inst; //use PhpContainer instead of NodeContainer when targeting PHP
		var router = new Router<Root>(new Root());
		container.run(function(req) {
			var ctx = Context.ofRequest(req);
			// ctx.allRaw().handle(r -> trace(r));
			// trace('ctx: $ctx');
			// trace('rawBody: ${ctx.rawBody}');
			// ctx.rawBody().all().handle(r -> trace(r));
			// (ctx.rawBody : tink.streams.Stream<tink.Chunk, tink.core.Error>).forEach(c -> {
			//     trace(c);
			//     return Resume;
			// });
			var output = new haxe.io.BytesOutput();
			var outSink = tink.io.Sink.ofOutput("std-sink", output);
			var requestSource = (switch req.body {
				case Plain(s): s;
				default: null;
			});
			trace('requestSource: $requestSource');
			(cast requestSource : Generator<tink.Chunk, tink.core.Error>).forEach(c -> {
				trace('chunk: $c');
				return Resume;
			});
			// requestSource.pipeTo(outSink).handle(() -> {
			// 	trace("Done piping request channel.");
			// 	var text = output.getBytes().toString();
			// 	// trace(text.slice(0, 50));
			// 	sys.io.File.saveContent("./request.out", text);
			// });
			return router.route(ctx).recover(OutgoingResponse.reportError);
		});
	}
}

class Root {
	public function new() {}

	@:post("/streaming")
	public function streaming(body:tink.io.Source.RealSource) {
		trace("Streaming");
		var output = new haxe.io.BytesOutput();
		var outSink = tink.io.Sink.ofOutput("std-sink", output);
		body.pipeTo(outSink).handle(() -> {
			var text = output.getBytes().toString();
			// trace(text.slice(0, 50));
			sys.io.File.saveContent("./request.out", text);
		});
		return "OK";
	}

	@:post("/data")

	// @:consumes("application/json")
	public function data(body:{name:String}) {
		return 'test';
	}

	@:get('/')
	@:get('/$name')
	public function hello(name = 'World')
		return 'Hello, $name!';
}
