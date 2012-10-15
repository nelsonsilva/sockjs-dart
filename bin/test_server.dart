#library("test_server");

#import("dart:io");
#import("dart:json");
#import('dart:math');
#import('dart:isolate');

#import('package:args/args.dart');
#import("package:sockjs/sockjs.dart", prefix:"sockjs");

void main() {
  var parser = new ArgParser();

  parser
    ..addOption('help', abbr: 'h')
    ..addOption('port', defaultsTo: 8081.toString())
    ..addOption('host', defaultsTo: '0.0.0.0')
    ..addOption('prefix', defaultsTo: '')
    ..addOption('responseLimit', defaultsTo: (128*1024).toString() )
    ..addOption('origins', defaultsTo: '*:*')
    ..addOption('websocket', defaultsTo: "true")
    ..addOption('jsessionid', defaultsTo: "false")
    ..addOption('heartbeatDelay', defaultsTo: 25000.toString())
    ..addOption('disconnectDelay', defaultsTo: 5000.toString())
    ..addOption('sockjsUrl', defaultsTo: 'http://localhost:8080/lib/sockjs.js');
  
  List<String> argv = (new Options()).arguments;
  
  var opts = parser.parse(argv);
  
  if (opts['help'] != null) {
    print(parser.getUsage());
    exit(0);
  }
  
  HttpServer server = new HttpServer();
    
  server.defaultRequestHandler = (HttpRequest req, HttpResponse res) {
    res.headers.set(HttpHeaders.CONTENT_TYPE, "text/plain");
    res.statusCode = 404;
    res.outputStream.writeString('404 - Nothing here (via sockjs-dart test_server)');
    res.outputStream.close();
  };
  
  // INSTALL 
     
  var sjs_echo = sockjs.createServer( 
      prefix: opts["prefix"],
      responseLimit: parseInt(opts["responseLimit"]),
      origins: opts["origins"].split(","),
      websocket: opts["websocket"] == "true",
      jsessionid: opts["jsessionid"] == "true",
      heartbeatDelay: parseInt(opts["heartbeatDelay"]),
      disconnectDelay: parseInt(opts["disconnectDelay"]),
      sockjsUrl: opts["sockjsUrl"]);
  
  sjs_echo.on.connection.add( (conn) {
    print("    [+] echo open    $conn");
    conn.on.close.add( (_) => print("    [-] echo close   $conn") );
    conn.on.data.add( (m) {
      var d  = JSON.stringify(m);
      var max = min(d.length, 64);
      print('    [ ] echo message $conn ${d.substring(0,max)}${((d.length > max) ? '...' : '')}');
      conn.write(m);
    });
  });

  
  var sjs_close = sockjs.createServer(
      prefix: opts["prefix"],
      responseLimit: parseInt(opts["responseLimit"]),
      origins: opts["origins"].split(","),
      websocket: opts["websocket"] == "true",
      jsessionid: opts["jsessionid"] == "true",
      heartbeatDelay: parseInt(opts["heartbeatDelay"]),
      disconnectDelay: parseInt(opts["disconnectDelay"]),
      sockjsUrl: opts["sockjsUrl"]);
  sjs_close.on.connection.add( (conn) {
    print('    [+] clos open    $conn');
    conn.close(3000, "Go away!");
    conn.on.close.add((_) => print('    [-] clos close   $conn'));
  });

  var sjs_ticker = sockjs.createServer(
      prefix: opts["prefix"],
      responseLimit: parseInt(opts["responseLimit"]),
      origins: opts["origins"].split(","),
      websocket: opts["websocket"] == "true",
      jsessionid: opts["jsessionid"] == "true",
      heartbeatDelay: parseInt(opts["heartbeatDelay"]),
      disconnectDelay: parseInt(opts["disconnectDelay"]),
      sockjsUrl: opts["sockjsUrl"]);
  sjs_ticker.on.connection.add((conn) {
    print('    [+] ticker open   $conn');
    var tref;
    var schedule;
    schedule = (_) {
      conn.write('tick!');
      tref = new Timer(1000, schedule);
    };
    tref = new Timer(1000, schedule);
    conn.on.close.add( (_) {
      tref.cancel();
      print('    [-] ticker close   $conn');
    });
  });

  var broadcast = {};
  var sjs_broadcast = sockjs.createServer(
      prefix: opts["prefix"],
      responseLimit: parseInt(opts["responseLimit"]),
      origins: opts["origins"].split(","),
      websocket: opts["websocket"] == "true",
      jsessionid: opts["jsessionid"] == "true",
      heartbeatDelay: parseInt(opts["heartbeatDelay"]),
      disconnectDelay: parseInt(opts["disconnectDelay"]),
      sockjsUrl: opts["sockjsUrl"]);
  sjs_broadcast.on.connection.add( (conn) {
    print('    [+] broadcast open $conn');
    broadcast[conn.id] = conn;
    conn.on.close.add( (_) {
      broadcast.remove(conn.id);
      print('    [-] broadcast close $conn');
    });
    conn.on.data.add( (m) {
      print('    [-] broadcast message $m');
      broadcast.forEach((k, conn) => conn.write(m));
    });
  });

  var sjs_amplify = sockjs.createServer(
      prefix: opts["prefix"],
      responseLimit: parseInt(opts["responseLimit"]),
      origins: opts["origins"].split(","),
      websocket: opts["websocket"] == "true",
      jsessionid: opts["jsessionid"] == "true",
      heartbeatDelay: parseInt(opts["heartbeatDelay"]),
      disconnectDelay: parseInt(opts["disconnectDelay"]));
  sjs_amplify.on.connection.add((conn) {
    print('    [+] amp open    $conn');
    conn.on.close.add( (_) => print('    [-] amp close   $conn'));
  
    conn.on.data.add( (m) {
      var n = parseInt(m);
      n = (n > 0 && n < 19) ? n : 1;
      print('    [ ] amp message: 2^$n');
      print(Strings.join(new List(pow(2, n)+1),'x'));
    });
  });

  
  sjs_echo
    ..installHandlers(server, prefix:'/echo', responseLimit: 4096)
    ..installHandlers(server, prefix:'/disabled_websocket_echo', websocket: false)
    ..installHandlers(server, prefix:'/cookie_needed_echo', jsessionid: true);
  
  sjs_close.installHandlers(server, prefix:'/close');
  sjs_ticker.installHandlers(server, prefix:'/ticker');
  sjs_amplify.installHandlers(server, prefix:'/amplify');
  sjs_broadcast.installHandlers(server, prefix:'/broadcast');
  
  server.listen(opts["host"], parseInt(opts["port"]));
  
  print("Server listening on ${opts["host"]}:${server.port}");
}