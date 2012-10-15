class ConnectionEvents extends event.Events {
  get data() => this["data"];
  get end() => this["end"];
  get close() => this["close"];
}

class SockJSConnection implements event.Emitter<ConnectionEvents>, HttpConnectionInfo { //extends stream.Stream
  
  ConnectionEvents on = new ConnectionEvents();
  SockJSSession session;
  Uuid id;
  Map headers;
  String prefix;
  
  var remoteHost;
  var remotePort;
  var address;

  var url;
  var pathname;
  var protocol;
  
  var localPort;
  
  SockJSConnection(this.session) {
        id  = new Uuid();
        headers = {};
        prefix = session.prefix;
  }

   toString() => '<SockJSConnection ${id.toString()}>';

   write(String string) => session.send(string);

    end([String string]) {
        if (?string) {
            write(string);
        }
        close();
        return null;
    }

    close([int code, String reason]) => session.close(code, reason);

    destroy() {
        removeAllListeners();
        end();
    }

    removeAllListeners() => on.removeAllListeners();
    
    destroySoon() => destroy();
    
    get readable => session.readyState == Transport.OPEN;
    get writable => session.readyState == Transport.OPEN;
    get readyState => session.readyState;
}