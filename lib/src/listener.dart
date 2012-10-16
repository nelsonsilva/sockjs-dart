class Listener {
  App app;
  RegExp _pathRegexp;
  
  var _handler;
  
  String prefix;
  var emit;
  bool websocket;
  num responseLimit;
  List<String> origins;
  bool jsessionid;
  num heartbeatDelay;
  num disconnectDelay;
  
  Listener({this.prefix, this.websocket, this.emit, this.responseLimit, this.origins, this.jsessionid, this.heartbeatDelay, this.disconnectDelay}) {
        app = new App(
            jsessionid: jsessionid, 
            websocket: websocket, 
            origins: origins,
            responseLimit: responseLimit,
            heartbeatDelay: heartbeatDelay,
            disconnectDelay: disconnectDelay,
            prefix: prefix);
        app.emit = emit;
        //app.log('debug', 'SockJS v' + sockjsVersion() + ' ' +
        //                  'bound to ' + JSON.stringify(options.prefix))
        var dispatcher = app.generateDispatcher(prefix);
        _handler = app.generateHandler(dispatcher);
        _pathRegexp = new RegExp('^${prefix}([/].+|[/]?)\$');
  }

    get matcher => (HttpRequest request) => _pathRegexp.hasMatch(request.uri);
        
    get handler => (HttpRequest request, HttpResponse response) => _handler(request, response);
              
}
            
            
  

    
    