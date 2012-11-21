library test_server;

import "dart:io";
import "dart:json";
import "dart:math" as Math;

import "package:sockjs/sockjs.dart" as sockjs;
import 'package:args/args.dart';

HttpServer server;

get echo =>
  sockjs.createServer()
    ..on.connection.add( (conn) {
      print("    [+] echo open    $conn");
      conn.on.close.add( (_) => print("    [-] echo close   $conn") );
      conn.on.data.add( (m) {
        var d  = JSON.stringify(m);
        var max = Math.min(d.length, 64);
        print('    [ ] echo message $conn ${d.substring(0,max)}${((d.length > max) ? '...' : '')}');
        conn.write(m);
      });
    });

get broadcast {
  var participants = [];
  return sockjs.createServer()
    ..on.connection.add( (conn) {
      print('    [+] broadcast open $conn');
      participants.add(conn);
      conn.on.close.add( (conn) {
        var idx = participants.indexOf(conn);
        participants.removeAt(idx);
        print('    [-] broadcast close $conn');
      });
      conn.on.data.add( (m) {
        print('    [-] broadcast message $m');
        participants.forEach((conn) => conn.write(m));
      });
    });
}

get chat => broadcast;

void main() {

  var parser = new ArgParser();

  parser
    ..addOption('port', defaultsTo: '8080')
    ..addOption('host', defaultsTo: '0.0.0.0');

  List<String> argv = (new Options()).arguments;

  var opts = parser.parse(argv);
  
  var host = opts["host"],
      port = int.parse(opts["port"]);
  
  server = new HttpServer();

  server.defaultRequestHandler = (HttpRequest req, HttpResponse res) {

    File script = new File(new Options().script);
    script.directory().then((Directory d) {
      final String basePath = "${d.path}/../example";

      final String path = req.path == '/' ? '/index.html' : req.path;

      final File file = new File('${basePath}${path}');
      file.exists().then((bool found) {

        if (found) {
          file.fullPath().then((String fullPath) {
            file.openInputStream().pipe(res.outputStream);
          });
        } else {
          res.headers.set(HttpHeaders.CONTENT_TYPE, "text/plain");
          res.statusCode = 404;
          res.outputStream.writeString('404 - Nothing here (via sockjs-dart test_server)');
          res.outputStream.close();
        }
      });
    });

  };

  echo.installHandlers(server, prefix:'/echo');
  chat.installHandlers(server, prefix:'/chat');
  broadcast.installHandlers(server, prefix:'/broadcast');

  server.listen(host, port);

  print("Server listening on $host:$port");
}