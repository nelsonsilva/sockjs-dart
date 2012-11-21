library sockjs;

import "dart:io";
import "dart:json";
import "dart:math" as Math;
import 'dart:isolate';
import 'dart:scalarlist';

import "package:uuid/uuid.dart";

import "src/events.dart" as event;
import "src/web.dart" as web;
import "src/utils.dart" as utils;
import "src/transport/xhr.dart" as xhr;
import "src/transport/websocket.dart" as ws;

part "src/app.dart";
part "src/server.dart";
part "src/transport.dart";
part "src/iframe.dart";
part "src/transport/connection.dart";
part "src/transport/session.dart";
part "src/transport/receiver.dart";

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

/*
listen(httpServer, options) {
    var srv = createServer(options);
    if (httpServer != null) {
        srv.installHandlers(httpServer);
    }
    return srv;
}*/
