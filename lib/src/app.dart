typedef EmitFn(evt, data);

class App extends web.App {
  
  var jsessionid;
  var websocket;
  var origins;
  num responseLimit;
  
  num heartbeatDelay;
  num disconnectDelay;
  String prefix;
  
  EmitFn emit;
  
  App({ this.jsessionid: false, 
        this.websocket: true, 
        this.origins: const ["*:*"], 
        this.responseLimit,
        this.heartbeatDelay,
        this.disconnectDelay,
        this.prefix}) : super();
   
  welcome_screen(HttpRequest req, HttpResponse res, [data, nextFilter]) {
    res.headers.set(HttpHeaders.CONTENT_TYPE, "text/plain; charset=UTF-8");
    res.statusCode = 200;
    res.outputStream.writeString('Welcome to SockJS!\n');
    res.outputStream.close();
    return true;
  }
  
  handle404(HttpRequest req, HttpResponse res, [data, nextFilter]) {

    res.headers.add(HttpHeaders.CONTENT_TYPE, "text/plain; charset=UTF-8");
   
    res.statusCode = 404;
    res.outputStream.writeString('404 Error: Page not found\n');
    res.outputStream.close();

    return true;
  }

  disabled_transport(HttpRequest req, HttpResponse res, [data, nextFilter])
      => handle404(req, res, data);

  h_sid(HttpRequest req, HttpResponse res, [data, nextFilter]) {
      // Some load balancers do sticky sessions, but only if there is
      // a JSESSIONID cookie. If this cookie isn't yet set, we shall
      // set it to a dummy value. It doesn't really matter what, as
      // session information is usually added by the load balancer.
    var cookies = utils.parseCookies(req.cookies);
      if (jsessionid is Function) {
          // Users can supply a function
          jsessionid(req, res);
      } else if (jsessionid) { // && res.setHeader)
          // We need to set it every time, to give the loadbalancer
          // opportunity to attach its own cookies.
          var jsid = cookies['JSESSIONID'];
          // jsid ||= 'dummy';
          var cookie = new Cookie('JSESSIONID');
          cookie.path = '/';
          res.cookies.add(cookie);
      return data;
     }
  }

  log(severity, line) => print("[$severity] - $line");
  
  // TRANSPORTS
  
  // WebSocket Transport
  var _wsHandler = new WebSocketHandler();
  
  _websocketCheck(HttpRequest req) {

    String upgrade = req.headers.value("upgrade");

    if ( (upgrade == null) || (upgrade.toLowerCase() != 'websocket')) {
      throw new web.AppException(
        status: 400,
        message: 'Can "Upgrade" only to "WebSocket".'
      );
    }
    
    var origin = req.headers.value("origin");
    if (!utils.verify_origin(origin, origins)) {
        throw new web.AppException(
          status: 400,
          message: 'Unverified origin.');
    }
  }
  
  raw_websocket(HttpRequest req, HttpResponse res, [data, nextFilter]) {
    _websocketCheck(req);

    _wsHandler.onOpen = (WebSocketConnection conn) {
      new RawWebsocketSessionReceiver(req, res, this, conn);
    };
    _wsHandler.onRequest(req, res);
  }
  
  sockjs_websocket(HttpRequest req, HttpResponse res, [data, nextFilter]) {
    _websocketCheck(req);
    var info = req.connectionInfo;

    _wsHandler.onOpen = (WebSocketConnection conn) {
      Transport.registerNoSession(req, this, new WebSocketReceiver(conn, info) );
    };
    _wsHandler.onRequest(req, res);
    
  }
  
  // XHR Transport
  
  xhr_options(HttpRequest req, HttpResponse res, [data, nextFilter]) {
    res.statusCode = 204;   // No content
    res.headers.add('Access-Control-Allow-Methods', 'OPTIONS, POST');
    res.headers.add('Access-Control-Max-Age', _cacheFor(res));
    return '';
  }
      
  xhr_send(HttpRequest req, HttpResponse res, [data, nextFilter]) {
    
    var d = null;

    if (!?data) {
      throw new web.AppException(
        status: 500,
        message: 'Payload expected.'
      );
    }
    try {
      d = JSON.parse(data);
    } catch (e) {
      throw new web.AppException(
        status: 500,
        message: 'Broken JSON encoding.'
      );
    }
  
    if ((d == null) || (d is! List)) {
      throw new web.AppException(
        status: 500,
        message: 'Payload expected.'
      );
    }
    
    var sessionId = new web.AppRequest(req).session;
    
    var jsonp = Session.bySessionId(sessionId);
    
    if (jsonp == null) {
      throw new web.AppException(status: 404);
    } 

    d.forEach((message) => jsonp.didMessage(message));

    // FF assumes that the response is XML.
    res.headers.add(HttpHeaders.CONTENT_TYPE, 'text/plain; charset=UTF-8');
    res.statusCode = 204;
    res.outputStream.close();
    return true;
  }

      
  xhr_cors(HttpRequest req, HttpResponse res, [content, nextFilter]) {
    
    var origin = req.headers.value('origin');
   
    if ( origin == null || origin == 'null') {
      origin = '*';
    }

    res.headers.add('Access-Control-Allow-Origin', origin);
    var headers = req.headers.value('access-control-request-headers');
    if (headers != null) {
      res.headers.add('Access-Control-Allow-Headers', headers);
    }
    res.headers.add('Access-Control-Allow-Credentials', 'true');
    return content;
  }
  
  xhr_streaming(HttpRequest req, HttpResponse res, [content, nextFilter]) {
   
    res.headers.add(HttpHeaders.CONTENT_TYPE, 'application/javascript; charset=UTF-8');
    res.statusCode = 200;

    // IE requires 2KB prefix:
    //  http://blogs.msdn.com/b/ieinternals/archive/2010/04/06/comet-streaming-in-internet-explorer-with-xmlhttprequest-and-xdomainrequest.aspx
    var s = new StringBuffer();
    for ( int i = 0; i < 2048; i++) {
      s.add('h');
    }
    s.add('\n');
    
    res.outputStream.writeString(s.toString());
    
    Transport.register(req, this, new XhrStreamingReceiver(res, responseLimit: responseLimit) );
    
    return true;
  }
       
  xhr_poll(HttpRequest req, HttpResponse res, [content, nextFilter]) {
    res.headers.add(HttpHeaders.CONTENT_TYPE, 'application/javascript; charset=UTF-8');
    res.statusCode = 200;
  
    Transport.register(req, this, new XhrPollingReceiver(res)); //,responseLimit: responseLimit));
    return true;
  }
      
  // Chunking Test
  info(HttpRequest req, HttpResponse res, [data, nextFilter]) {
    var info = {
            "websocket": websocket,
            "origins": origins,
            "cookie_needed": jsessionid,
            "entropy": utils.random32(),
    };
    res.headers.add(HttpHeaders.CONTENT_TYPE, 'application/json; charset=UTF-8');
    res.statusCode = 200;
    res.outputStream.writeString(JSON.stringify(info));
  }
  
  info_options(HttpRequest req, HttpResponse res, [data, nextFilter]) {
    res.headers.add('Access-Control-Allow-Methods', 'OPTIONS, GET');
    res.headers.add('Access-Control-Max-Age', _cacheFor(res));
    res.statusCode = 204;
    return '';
  }
  
  _cacheFor(HttpResponse res) {
    String cacheFor = res.headers.value(HttpHeaders.CACHE_CONTROL);
    cacheFor = cacheFor.substring("public, max-age=".length);
    return Math.parseInt(cacheFor);
  }
}