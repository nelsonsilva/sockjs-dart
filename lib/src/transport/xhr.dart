#library("xhr");

#import("dart:io");
#import("dart:json");
#import("package:sockjs/sockjs.dart");
#import("package:sockjs/src/web.dart", prefix:'web');
#import("package:sockjs/src/utils.dart", prefix:'utils');

class StreamingReceiver extends ResponseReceiver {
    get protocol => "xhr-streaming";
    
    StreamingReceiver(var response, {num responseLimit: null} ) : super(response, responseLimit: responseLimit);
    
    doSendFrame(payload) => super.doSendFrame( "$payload\n");
}

class PollingReceiver extends StreamingReceiver {
  
  get protocol => "xhr-polling";
  
  PollingReceiver(var response ) : super(response, responseLimit: 1);
  
}

options(HttpRequest req, HttpResponse res, [data, nextFilter]) {
  res.statusCode = 204;   // No content
  res.headers.add('Access-Control-Allow-Methods', 'OPTIONS, POST');
  res.headers.add('Access-Control-Max-Age', utils.getCacheFor(res));
  return '';
}

send(HttpRequest req, HttpResponse res, [data, nextFilter]) {
  
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

      
cors(HttpRequest req, HttpResponse res, [content, nextFilter]) {
  
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
  
streaming(web.App app, [num responseLimit]) => (HttpRequest req, HttpResponse res, [content, nextFilter]) {
 
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
  
  Transport.register(req, app, new StreamingReceiver(res, responseLimit: responseLimit) );
  
  return true;
};
       
poll(web.App app, [num responseLimit]) => (HttpRequest req, HttpResponse res, [content, nextFilter]) {
  res.headers.add(HttpHeaders.CONTENT_TYPE, 'application/javascript; charset=UTF-8');
  res.statusCode = 200;

  Transport.register(req, app, new PollingReceiver(res)); //,responseLimit: responseLimit));
  return true;
};