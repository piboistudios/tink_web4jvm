# tink_web4jvm

This is a proof of concept for tink_web running on Haxe's JVM target.

It utilizes the Java [Undertow](https://github.com/undertow-io/undertow)/[XNIO](https://github.com/xnio/xnio) libraries by JBOSS to create interfaces usable by tink_io and tink_http to create the: `tink.http.containers.UndertowContainer`:

## Setup
This project requires lix.pm, if you don't have it:
`npm i lix -g`

### Lix Usage:
- After cloning the repo:
 `lix download` will install all of the Haxe dependencies required for this project.



Creating an Undertow Container:
```haxe
import tink.http.containers.*;
import tink.http.Response;
import tink.web.routing.*;

class Test {
    static function main() {
        var container = new tink.http.containers.UndertowContainer("localhost", 8080); 
        var router = new Router<Root>(new Root());
        container.run(function(req) {
            return router.route(Context.ofRequest(req))
                .recover(OutgoingResponse.reportError);
        });
    }
}

class Root {
	public function new() {}

    @:post("/payload") // want to parse an arbitrary data structure?
    @:consumes("application/json") // you can register other mime-type parsers/serializers
    public function payload(body:{name:String, age:Int, job:String}) {
        return '${body.name} is a ${body.age} year old ${job}';
    }
    @:post("/stream-to-disk") // want to stream binary streams over the web? Go ahead!
	public function stream_to_disk(body:tink.io.Source.RealSource) {
        var stdOutput = new haxe.io.BytesOutput();
        var stdSink = tink.io.Sink.ofOutput('std-output', stdOutput);
        body.pipeTo(stdSink).handle(() -> {
            var text = stdOutput.getBytes().toString();
            sys.io.File.saveContent("./request-streamed.out", text);
        });
        return "Streaming request to disk. :) Enjoy your response while we continue processing in the background.";
    }

    @:post("/buffer-to-disk") // want to synchronously read the request? Try it!
    public function buffer_to_disk(body:haxe.io.Bytes) {
        var text = body.toString();
        sys.io.File.saveContent("./request-buffered.out", text);
        return "Data buffered and written to disk; this happened synchronously, so the data was written to disk before this response was sent";
    }
    @:get("/long-running-response") // need to run a long-running task before you can respond? Don't wait!
    public function long_running_response() {
        return tink.core.Future.async(cb -> {
            haxe.Timer.delay(() -> {
                cb("This is the response after one second has elapsed.");
            }, 1000);
        });
    }
	@:get('/')
	@:get('/hello/$name') // basics
	public function hello(name = 'World')
		return 'Hello, $name!';
}

```
