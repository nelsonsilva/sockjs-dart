abstract class SockJSSession {
  String prefix;
  int readyState = Transport.CONNECTING;
  SockJSConnection connection;
  GenericReceiver recv;
  
  send(String msg);
  close([int status, String reason]);
  
  decorateConnection(HttpRequest req) {

    // Store the last known address.
    var socket = recv.connection;
    
    
    if(socket == null) {
      socket = recv.connectionInfo;
    }
    
    connection.remoteHost = socket.remoteHost;
    connection.remotePort = socket.remotePort;
    try {
      connection.address = socket.address();
    } catch (e) {
      connection.address = {};
    }

    connection.url = req.uri;
    connection.pathname = req.path;
    connection.protocol = recv.protocol;

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

class Session extends SockJSSession {
  
    static Map<String, Session> MAP = {};
  
    String sessionId;
    
    num heartbeatDelay;
    num disconnectDelay;
    
    List send_buffer = [];
    
    bool isClosing = false;
    
    var timeout_cb;
    Timer to_tref;
   
    var emit_open;
          
    var close_frame;
    
    static Session bySessionId(session_id) {
      if (session_id == null) { return null; }
      return MAP[session_id];
    }
        
    Session(this.sessionId, App server) {

        heartbeatDelay = server.heartbeatDelay;
        disconnectDelay = server.disconnectDelay;
        prefix = server.prefix;
        
        readyState = Transport.CONNECTING;
        
        if (sessionId != null) {
            MAP[sessionId] = this;
        }
        
        timeout_cb = () => didTimeout();
        to_tref = new Timer(disconnectDelay, (Timer t) => timeout_cb());
        connection = new SockJSConnection(this);
        emit_open = () {
            emit_open = null;
            server.emit('connection', connection);
        };
    }

    register(HttpRequest req, [GenericReceiver recv] ) {
        if (this.recv != null) {
            recv.doSendFrame(closeFrame(2010, "Another connection still open"));
            recv.didClose();
            return;
        }
        if (to_tref != null) {
            to_tref.cancel();
            to_tref = null;
        }
        if (readyState == Transport.CLOSING) {
            recv.doSendFrame(close_frame);
            recv.didClose();
            to_tref = new Timer(disconnectDelay, (Timer t) => timeout_cb());
            return;
        }
        // Registering. From now on 'unregister' is responsible for
        // setting the timer.
       this.recv = recv;
       this.recv.session = this;

        // Save parameters from request
        decorateConnection(req);

        // first, send the open frame
        if (readyState == Transport.CONNECTING) {
            recv.doSendFrame('o');
            readyState = Transport.OPEN;
            // Emit the open event, but not right now
            //process.nextTick @emit_open
            new Timer(0, (Timer t) => emit_open());
        }

        // At this point the transport might have gotten away (jsonp).
        if (this.recv == null) {
            return;
        }
        tryFlush();
        return;
    }

    unregister([int status, String reason]) {
        recv.session = null;
        recv = null;
        if (to_tref != null) {
            to_tref.cancel();
        }
        to_tref = new Timer(disconnectDelay, (Timer t) => timeout_cb());
    }

    tryFlush() {
        if (!send_buffer.isEmpty() ) {
          var sb = send_buffer;
          send_buffer = [];
          recv.doSendBulk(sb);
        } else {
            if (to_tref != null) {
                to_tref.cancel();
            }
            var x;
            x = () {
                if (recv != null) {
                    to_tref = new Timer(heartbeatDelay, (Timer t) => x());
                    recv.doSendFrame("h");
                }
            };
            to_tref = new Timer(heartbeatDelay, (Timer t) => x());
        }
        return;
    }

    didTimeout() {
        if (to_tref != null) {
            to_tref.cancel();
            to_tref = null;
        }
        if (readyState != Transport.CONNECTING &&
            readyState != Transport.OPEN &&
            readyState != Transport.CLOSING) {
            throw new Exception('INVALID_STATE_ERR');
        }
        if (recv != null) {
            throw new Exception('RECV_STILL_THERE');
        }
        readyState = Transport.CLOSED;

        connection.on.end.dispatch(connection);
        connection.on.close.dispatch(connection);
        
        connection = null;
        
        if (sessionId != null) {
          MAP.remove(sessionId);
          sessionId = null;
        }
    }

    didMessage(payload) {
        if (readyState == Transport.OPEN) {
            connection.on.data.dispatch(payload);
        }
    }

    bool send(String payload) {
        if (readyState != Transport.OPEN) {
            return false;
        }
        send_buffer.add(payload);
        if (recv != null) {
            tryFlush();
        }
        return true;
    }

    bool close([int status=1000, String reason="Normal closure"]) {
        if (readyState != Transport.OPEN) {
            return false;
        }
        readyState = Transport.CLOSING;
        close_frame = closeFrame(status, reason);
        if (recv != null) {
            // Go away.
            recv.doSendFrame(close_frame);
            recv.didClose();
            if (recv != null) {
                unregister();
            }
        }
        return true;
    }
    
    closeFrame(status, reason) => 'c${JSON.stringify([status, reason])}';

}