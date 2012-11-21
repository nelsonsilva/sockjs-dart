part of sockjs;

class Transport {
  static const CONNECTING = 0;
  static const OPEN = 1;
  static const CLOSING = 2;
  static const CLOSED = 3;

  static int SESSION_ID = 0;

  static Session _register(HttpRequest req, web.App server, GenericReceiver receiver, [String session_id = null]) {
    var session = Session.bySessionId(session_id);
    if (session == null) {
      session = new Session(session_id, server);
    }
    session.register(req, receiver);
    return session;
  }

  static register(HttpRequest req, web.App server, GenericReceiver receiver)
    => _register(req, server, receiver, new web.AppRequest(req).sessionId );

  static registerNoSession(HttpRequest req, web.App server, GenericReceiver receiver)
    => _register(req, server, receiver);

}


