# tink_web4jvm

This is a proof of concept for tink_web running on Haxe's JVM target.

It utilizes the Java Undertow/XNIO libraries by JBOSS to create interfaces usable by tink_io and tink_http to create the: `tink.http.containers.UndertowContainer`:

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
    @:get('/$name')
    public function hello(name = 'World')
        return 'Hello, $name!';
} 
```