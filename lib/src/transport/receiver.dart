class Receiver {
  SockJSConnection connection;
}

abstract class GenericReceiver extends Receiver {
  
    OutputStream thingy;
    var thingy_end_cb;
    Session session;
    
    // HttpResponse response;
    HttpConnectionInfo connectionInfo;
    
    get protocol;
    
    //GenericReceiver([this.thingy]) {
    //    setUp();
    //}

    setUp() {
        thingy_end_cb = () => didAbort(1006, "Connection closed");
        
        //thingy.onClosed = thingy_end_cb;
        //thingy.addListener('end', thingy_end_cb);
    }

    tearDown() {
        thingy.onClosed = thingy_end_cb;
        //thingy.removeListener('end', thingy_end_cb);
        thingy_end_cb = null;
    }

    didAbort(int status, String reason) {
        didClose(status, reason);
        if (session != null) {
            session.didTimeout();
        }
    }

    didClose([int status, String reason]) {
        if (thingy != null) {
            tearDown();
            thingy = null;
        }
        if (session != null) {
            session.unregister(status, reason);
        }
    }

    doSendBulk(List messages) {
        var q_msgs = messages.map((m) => '"$m"');
        var str = Strings.join(q_msgs, ',');
        doSendFrame('a[$str]');
    }
    
    abstract doSendFrame(payload);
}


/** Write stuff to response, using chunked encoding if possible. */
abstract class ResponseReceiver extends GenericReceiver {
    var max_response_size;
    var curr_response_size = 0;

    HttpResponse response;
    var options;
    
    ResponseReceiver(this.response, {num responseLimit: null} ) { //: super(response.outputStream) {
      
       
        this.connectionInfo = response.connectionInfo;
        
        try {
            // setKeepAlive
            // since we already accessed the outputstream we cannot change persistentConnection
            response.persistentConnection = true; //, 5000);
            response.headers.add(HttpHeaders.CONNECTION, "keep-alive");
            
            
        } catch (e) {
          print("Got exception $e");
        }
        
        if (max_response_size == null) {
            max_response_size = responseLimit;
        }
        
    }

    doSendFrame(payload) {
        curr_response_size += payload.length;
        var r = false;
        try {
            var res = response.outputStream.writeString(payload);
            r = true;
        } catch (x) {
          print("Got exception $x");
        }
        if ((max_response_size != null) && (curr_response_size >= max_response_size)) {
            didClose();
        }
        return r;
    }

    didClose([status, reason]) {
        super.didClose();
        try {
            response.outputStream.close();
        } catch (x) {}
        response = null;
    }
}


