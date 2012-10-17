#library("sockjs");

#import("dart:io");
#import("dart:json");
#import("dart:math", prefix:'Math');
#import('dart:isolate');
#import('dart:scalarlist');

#import("package:dart_uuid/Uuid.dart");

#import("src/events.dart", prefix:'event');
#import("src/web.dart", prefix:'web');
#import("src/utils.dart", prefix:'utils');
#import("src/transport/xhr.dart", prefix:'xhr');
#import("src/transport/websocket.dart", prefix:'ws');

#source("src/app.dart");
#source("src/server.dart");
#source("src/transport.dart");
#source("src/iframe.dart");
#source("src/transport/connection.dart");
#source("src/transport/session.dart");
#source("src/transport/receiver.dart");

typedef LogFn(severity, line);

log(severity, line) => print(line);

Server createServer({
  String prefix: '',
  num responseLimit: 128*1024,
  List<String >origins: const ['*:*'],
  bool websocket: true,
  bool jsessionid: false,
  num heartbeatDelay: 25000,
  num disconnectDelay: 5000,
  LogFn log: log,
  String sockjsUrl: 'http://cdn.sockjs.org/sockjs-0.3.min.js'}) 
  => new Server(  prefix,
                  responseLimit,
                  origins,
                  websocket,
                  jsessionid,
                  heartbeatDelay,
                  disconnectDelay,
                  log,
                  sockjsUrl);

listen(httpServer, options) {
    var srv = createServer(options);
    if (httpServer != null) {
        srv.installHandlers(httpServer);
    }
    return srv;
}
