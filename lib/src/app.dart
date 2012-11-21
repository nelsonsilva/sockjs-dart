part of sockjs;

typedef EmitFn(evt, data);

class App extends web.App {

  var jsessionid;
  var websocket;
  var origins;
  num responseLimit;

  num heartbeatDelay;
  num disconnectDelay;
  String prefix;
  String sockjsUrl;

  EmitFn emit;

  App({ this.jsessionid: false,
        this.websocket: true,
        this.origins: const ["*:*"],
        this.responseLimit,
        this.heartbeatDelay,
        this.disconnectDelay,
        this.prefix,
        this.sockjsUrl}) : super();

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
    res.headers.add('Access-Control-Max-Age', utils.getCacheFor(res));
    res.statusCode = 204;
    return '';
  }


  // DISPATCHER
  web.Dispatcher generateDispatcher(String prefix, [bool websocket = true]) {

    var p = (s) => new RegExp('^${prefix}$s[/]?\$');
    var t = (s) => [p('/([^/.]+)/([^/.]+)$s'), 'server', 'session'];

    var opts_filters = ([options_filter = null])
        => [h_sid, xhr.cors, cache_for, (options_filter != null)?options_filter:xhr.options, expose];

    var route = new web.Dispatcher()
      ..GET(p(''), [welcome_screen])
      ..GET(p('/iframe[0-9-.a-z_]*.html'), [iframe(sockjsUrl), cache_for, expose])
      ..OPTIONS(p('/info'), opts_filters(info_options))
      ..GET(p('/info'), [xhr.cors, h_no_cache, info, expose])
      ..OPTIONS(p('/chunking_test'), opts_filters())
      //..POST(p('/chunking_test'), [xhr_cors, expect_xhr, chunking_test])
      ..GET(p('/websocket'), [ws.raw(this, origins)])
      //..GET(t('/jsonp'), [h_sid, h_no_cache, jsonp])
      //POST(t('/jsonp_send'), [h_sid, h_no_cache, expect_form, jsonp_send])
      ..POST(t('/xhr'), [h_sid, h_no_cache, xhr.cors, xhr.poll(this, responseLimit)])
      ..OPTIONS(t('/xhr'), opts_filters())
      ..POST(t('/xhr_send'), [h_sid, h_no_cache, xhr.cors, expect_xhr, xhr.send])
      ..OPTIONS(t('/xhr_send'), opts_filters())
      ..POST(t('/xhr_streaming'), [h_sid, h_no_cache, xhr.cors, xhr.streaming(this, responseLimit)])
      ..OPTIONS(t('/xhr_streaming'), opts_filters());
      //..GET(t('/eventsource'), [h_sid, h_no_cache, eventsource])
      //..GET(t('/htmlfile'),    [h_sid, h_no_cache, htmlfile])


    // TODO: remove this code on next major release
    if (websocket) {
      route.GET(t('/websocket'), [ws.sockjs(this, origins)]);
    } else {
      // modify urls to return 404
      route.GET(t('/websocket'), [cache_for, disabled_transport]);
    }

    return route;
  }
}