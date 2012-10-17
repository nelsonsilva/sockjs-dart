#library("websocket");

#import("dart:io");
#import("dart:json");
#import("package:sockjs/sockjs.dart");
#import("package:sockjs/src/web.dart", prefix:'web');
#import("package:sockjs/src/utils.dart", prefix:'utils');

class WebSocketReceiver extends GenericReceiver {
    get protocol => "websocket";

    WebSocketConnection ws;
    
    WebSocketReceiver(this.ws, HttpConnectionInfo info) {

      //this.response = response;
      
      // this is null for a detached socket!
      this.connectionInfo = info;
      

        ws.onMessage = (m) => didMessage(m);
        
        setUp();
    }

    setUp() {
        super.setUp();
        ws.onClosed = (int status, String reason) => thingy_end_cb();
    }

    tearDown() {
        ws.onClosed = (int status, String reason) => thingy_end_cb();
        super.tearDown();
    }

    didMessage(payload) {

        if (ws != null && session != null && !payload.isEmpty()) {
          var message;
            try {
                message = JSON.parse(payload);
            } catch (_) {
                return didClose(1002, 'Broken framing.');
            }
            if (payload[0] == '[') {
              message.forEach( (msg) => session.didMessage(msg));
            } else {
                session.didMessage(message);
            }
        }
    }

    doSendFrame(payload) {
        if (ws != null) {
            try {
                ws.send(payload);
                return true;
            } catch (_) {}
        }
        return false;
    }

    didClose([int status, String reason]) {
        super.didClose();
        try {
            ws.close();
        } catch (_) {}
        ws = null;
        connection = null;
    }
}

        
class RawWebsocketSessionReceiver extends SockJSSession {
  WebSocketConnection ws;
  
  var _end_cb;
  var _message_cb;
  
  RawWebsocketSessionReceiver(HttpRequest req, HttpResponse conn, App server, this.ws) {
        
    print("[RawWebsocketSessionReceiver]");
    prefix = server.prefix;
    readyState = Transport.OPEN;

    connection = new SockJSConnection(this);
    decorateConnection(req);
    
    server.emit('connection',connection);
    
    _end_cb = () => didClose();
    
    ws.onClosed = (int status, String reason) {
      //if (status == WebSocketStatus.NO_STATUS_RECEIVED) {
      //  return;
      //}
      print("[RawWebsocketSessionReceiver] onClosed($status): $reason");
      _end_cb();
    };
    
    _message_cb = (m) => didMessage(m);
    
    ws.onMessage = (m) => _message_cb(m);
    
    print("[RawWebsocketSessionReceiver] HERE");
  }

  didMessage(m) {
      print("[RawWebsocketSessionReceiver] got $m");
      if (readyState == Transport.OPEN) {
          connection.on.data.dispatch(m.data);
      }
      return;
  }

  send(payload) {
      print("[RawWebsocketSessionReceiver] send $payload");
      if (readyState != Transport.OPEN) {
          return false;
      }
      ws.send(payload);
      return true;
  }

  close([status=1000, reason="Normal closure"]) {
      if (readyState != Transport.OPEN) {
          return false;
      }
      readyState = Transport.CLOSING;
      ws.close(status, reason);
      return true;
  }
  
  didClose() {
      if (ws == null) {
          return;
      }
      ws.onMessage = null;
      ws.onClosed = null;
      
      try {
          ws.close();
      } catch (_) { }
      
      ws = null;

      readyState = Transport.CLOSED;
      connection.on.end.dispatch();
      connection.on.close.dispatch();
      connection = null;
  }
    
  // copied from Session to remove ugly inheritance
  decorateConnection(HttpRequest req) {

    // Store the last known address.
    var socket = connection;
    
    connection.remoteHost = socket.remoteHost;
    connection.remotePort = socket.remotePort;
    try {
        connection.address = socket.address();
    } catch (e) {
        connection.address = {};
    }

    connection.url = req.uri;
    connection.pathname = req.path;
    connection.protocol = connection.protocol;

    var headers = {};
    for (var key in ['referer', 'x-client-ip', 'x-forwarded-for', 
                'x-cluster-client-ip', 'via', 'x-real-ip']) {
      if (req.headers.value(key) != null) {
        headers[key] = req.headers.value(key);
      }
    }
    if (!headers.isEmpty()) {
        connection.headers = headers;
    }
  }
}

// WebSocket Transport
var _wsHandler = new WebSocketHandler();

_websocketCheck(HttpRequest req, List<String> origins) {

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
  
  raw(web.App app, List<String> origins) => (HttpRequest req, HttpResponse res, [data, nextFilter]) {
  _websocketCheck(req, origins);
    
  _wsHandler.onOpen = (WebSocketConnection conn) {
    new RawWebsocketSessionReceiver(req, res, app, conn);
  };
  _wsHandler.onRequest(req, res);
};
  
sockjs(web.App app, List<String> origins) => (HttpRequest req, HttpResponse res, [data, nextFilter]) {
  _websocketCheck(req, origins);
  var info = req.connectionInfo;

  _wsHandler.onOpen = (WebSocketConnection conn) {
    Transport.registerNoSession(req, app, new WebSocketReceiver(conn, info) );
  };
  _wsHandler.onRequest(req, res);
};
  