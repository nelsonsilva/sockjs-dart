class ServerEvents extends event.Events {
  get connection() => this["connection"];
}
        
class Server implements event.Emitter<ServerEvents> {
  
  ServerEvents on = new ServerEvents();
  
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
    
      var listener = new Listener(
          prefix: prefix,
          responseLimit: responseLimit,
          origins: origins,
          websocket: websocket,
          jsessionid: jsessionid,
          heartbeatDelay: heartbeatDelay,
          disconnectDelay: disconnectDelay,
          emit: (evt, data) => on[evt].dispatch(data)
          );
    
      httpServer.addRequestHandler(listener.matcher, listener.handler);
  
      //utils.overshadowListeners(http_server, 'request', handler)
      //utils.overshadowListeners(http_server, 'upgrade', handler)
      return true;
  }

    //middleware(handler_options) {
    //    handler = @listener(handler_options).getHandler()
    //    handler.upgrade = handler
    //    return handler
    //}
}