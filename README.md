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

    @:get('/')
    @:get('/hello/$name')
    public function hello(name = 'World')
        return 'Hello, $name!';

    @:post("/stream-to-disk")
    public function stream_to_disk(body:tink.io.Source.RealSource) {
        var stdOutput = new haxe.io.BytesOutput();
        var stdSink = tink.io.Sink.ofOutput('std-output', stdOutput);
        body.pipeTo(stdSink).handle(() -> {
            var text = stdOutput.getBytes().toString();
            sys.io.File.saveContent("./request-streamed.out", text);
        });
        return "Streaming request to disk. :) Enjoy your response while we continue processing in the background.";
    }
    @:post("/buffer-to-disk")
    public function buffer_to_disk(body:haxe.io.Bytes) {
        var text = body.toString();
        sys.io.File.saveContent("./request-buffered.out", text);
        return "Data buffered and written to disk; this happened synchronously, so the data was written to disk before this response was sent";
    }
} 
```


# Latest Addition
 - XML Parsing:
    ```haxe
    typedef CXMLCredential = {
        @:tag("Credential") var credential:{

            @:attr("domain") var domain:String;
            @:tag("Identity") var identity:String;
            @:optional @:tag("SharedSecret") var sharedSecret:String;
        };
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

    class CXML() {
        public function new() {}
         @:post("/cxml/profile-request") // parse complex arbitrary XML
        // this particular complex anonymous structure models a ProfileRequest
        // see: http://xml.CXml.org/current/cXMLReferenceGuide.pdf
        @:consumes("application/xml") 
        @:produces("application/json")
        public function profileRequest(body:CXMLProfileRequest) {
            return haxe.Json.stringify(body);
        }

    }
    ```

    Example payload:
    ```xml
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE cXML SYSTEM "http://xml.cXML.org/schemas/cXML/1.2.014/cXML.dtd">
    <cXML payloadID="456778-199@acme.com" xml:lang="en-US" timestamp="2001-03-12T18:39:09-08:00">
        <Header>
            <From>
                <Credential domain="OSN">
                    <Identity>TEST</Identity>
                </Credential>
            </From>
            <To>
                <Credential domain="DUNS">
                    <Identity>1111111111</Identity>
                </Credential>
            </To>
            <Sender>
                <Credential domain="OSN">
                    <Identity>TEST</Identity>
                    <SharedSecret>VERY SECRET, MUCH UNGUESSABLE</SharedSecret>
                </Credential>
                <UserAgent>Oracle Fusion Self Service Procurement</UserAgent>
            </Sender>
        </Header>
       <Request>
          <ProfileRequest />
       </Request>
    </cXML>
    ```
    Response:
    ```json
    {
        "lang": "en-US",
        "header": {
            "from": {
                "credential": {
                    "domain": "OSN",
                    "identity": "TEST"
                }
            },
            "sender": {
                "credential": {
                    "domain": "OSN",
                    "identity": "TEST",
                    "sharedSecret": "VERY SECRET, MUCH UNGUESSABLE"
                }
            },
            "to": {
                "credential": {
                    "domain": "DUNS",
                    "identity": "1111111111"
                }
            }
        },
        "timestamp": "2001-03-12T18:39:09-08:00",
        "request": {
            "request": ""
        },
        "payloadID": "456778-199@acme.com"
    }
    ```