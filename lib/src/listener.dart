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
        var dispatcher = _generateDispatcher(prefix);
        _handler = app.generateHandler(dispatcher);
        _pathRegexp = new RegExp('^${prefix}([/].+|[/]?)\$');
  }

    get matcher => (HttpRequest request) => _pathRegexp.hasMatch(request.uri);
        
    get handler => (HttpRequest request, HttpResponse response) => _handler(request, response);
              
    _generateDispatcher(String prefix, [bool websocket = true]) {
      var p = (s) => new RegExp('^${prefix}$s[/]?\$');
      var t = (s) => [p('/([^/.]+)/([^/.]+)$s'), 'server', 'session'];
      
      var opts_filters = ([options_filter='xhr_options'])
        => ['h_sid', 'xhr_cors', 'cache_for', options_filter, 'expose'];
      
      var dispatcher = [
                    ['GET',     p(''), ['welcome_screen']],
                    //['GET',     p('/iframe[0-9-.a-z_]*.html'), ['iframe', 'cache_for', 'expose']],
                    ['OPTIONS', p('/info'), opts_filters('info_options')],
                    ['GET',     p('/info'), ['xhr_cors', 'h_no_cache', 'info', 'expose']],
                    ['OPTIONS', p('/chunking_test'), opts_filters()],
                    //['POST',    p('/chunking_test'), ['xhr_cors', 'expect_xhr', 'chunking_test']],
                    ['GET',     p('/websocket'),   ['raw_websocket']],
                    //['GET',     t('/jsonp'), ['h_sid', 'h_no_cache', 'jsonp']],
                    //['POST',    t('/jsonp_send'), ['h_sid', 'h_no_cache', 'expect_form', 'jsonp_send']],
                    ['POST',    t('/xhr'), ['h_sid', 'h_no_cache', 'xhr_cors', 'xhr_poll']],
                    ['OPTIONS', t('/xhr'), opts_filters()],
                    ['POST',    t('/xhr_send'), ['h_sid', 'h_no_cache', 'xhr_cors', 'expect_xhr', 'xhr_send']],
                    ['OPTIONS', t('/xhr_send'), opts_filters()],
                    ['POST',    t('/xhr_streaming'), ['h_sid', 'h_no_cache', 'xhr_cors', 'xhr_streaming']],
                    ['OPTIONS', t('/xhr_streaming'), opts_filters()],
                    //['GET',     t('/eventsource'), ['h_sid', 'h_no_cache', 'eventsource']],
                    //['GET',     t('/htmlfile'),    ['h_sid', 'h_no_cache', 'htmlfile']],
                    ];
  
      // TODO: remove this code on next major release
      if (websocket) {
        dispatcher.add(['GET', t('/websocket'), ['sockjs_websocket']]);
      } else {
        // modify urls to return 404
        dispatcher.add(['GET', t('/websocket'), ['cache_for', 'disabled_transport']]);
      }
            
      return dispatcher;
    }
            
}
            
            
  

    
    