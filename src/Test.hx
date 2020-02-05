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
typedef CXMLCredential = {
    @:tag("Credential") var credential:{

        @:attr("domain") var domain:String;
        @:tag("Identity") var identity:String;
        @:optional @:tag("SharedSecret") var sharedSecret:String;
    };
    @:optional @:tag("UserAgent") var userAgent:String;
}
typedef CXMLHeader = {
    @:tag("To") var to:CXMLCredential;
    @:tag("Sender") var sender:CXMLCredential;
    @:tag("From") var from:CXMLCredential;   
}
typedef CXMLProfileRequest = {
    @:attr var payloadID:String;
    @:attr("xml:lang") var lang:String;
    @:attr var timestamp:String;
    @:tag("Header") var header:CXMLHeader;
    @:tag("Request") var request: {
        @:tag("ProfileRequest") var request:String;
    };
}
class Root {
	public function new() {}

    @:post("/payload") // want to parse an arbitrary data structure?
    @:consumes("application/json") // you can register other mime-type parsers/serializers
    public function payload(body:{name:String, age:Int, job:String}) {
        return '${body.name} is a ${body.age} year old ${body.job}';
    }
    @:post("/xml") // parse arbitrary XML
    @:consumes("application/xml")
    @:produces("application/json")
    public function xml(body:{name:String, age:Int, job:String}) {
        return haxe.Json.stringify(body);
    }

    @:post("/xml-complex") // parse complex arbitrary XML
    // this particular complex anonymous structure models a ProfileRequest
    // see: http://xml.CXml.org/current/cXMLReferenceGuide.pdf
    @:consumes("application/xml") 
    @:produces("application/json")
    public function xmlComplex(body:CXMLProfileRequest) {
        return haxe.Json.stringify(body);
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
