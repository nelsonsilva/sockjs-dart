part of sockjs;

class ServerEvents extends event.Events {
  get connection => this["connection"];
}

class Server implements event.Emitter<ServerEvents> {

  ServerEvents on = new ServerEvents();

  // Options
  String prefix;
  num responseLimit;
  List<String> origins;
  bool websocket;
  bool jsessionid;
  num heartbeatDelay;
  num disconnectDelay;
  LogFn log;
  String sockjsUrl;

  Server([  this.prefix,
            this.responseLimit,
            this.origins,
            this.websocket,
            this.jsessionid,
            this.heartbeatDelay,
            this.disconnectDelay,
            this.log,
            this.sockjsUrl]);

  installHandlers(HttpServer httpServer, {
        String prefix: '',
        num responseLimit: 128*1024,
        List<String >origins: const ['*:*'],
        bool websocket: true,
        bool jsessionid: false}) {

      var app = new App(
          jsessionid: jsessionid,
          websocket: websocket,
          origins: origins,
          responseLimit: responseLimit,
          heartbeatDelay: heartbeatDelay,
          disconnectDelay: disconnectDelay,
          prefix: prefix,
          sockjsUrl: sockjsUrl);
      app.emit = (evt, data) => on[evt].dispatch(data);

      var dispatcher = app.generateDispatcher(prefix),
          appHandler = app.generateHandler(dispatcher),
          pathRegexp = new RegExp('^${prefix}([/].+|[/]?)\$'),
          matcher = (HttpRequest request) => pathRegexp.hasMatch(request.uri),
          handler = (HttpRequest request, HttpResponse response) => appHandler(request, response);

      httpServer.addRequestHandler(matcher, handler);

      return true;
  }

}