#library("web");

#import("dart:io");
#import("dart:mirrors");

class AppException implements Exception {
  final String message;
  final int status;
  const AppException({this.status: 0, this.message: ""});
  String toString() => "AppException: $status ($message)";
}

typedef HandlerFn(HttpRequest r, HttpResponse res, [content, nextFilter]);

class Dispatcher implements Iterable {
  List dispatcher = [];
  _addRoute(String method, path, List<HandlerFn> chain) => dispatcher.add([method, path, chain]);
  GET(path, chain) => _addRoute('GET', path, chain);
  POST(path, chain) => _addRoute('POST', path, chain);
  OPTIONS(path, chain) => _addRoute('OPTIONS', path, chain);
  
  Iterator iterator() => dispatcher.iterator();
}

class App {
  
  App();

  generateHandler(Dispatcher dispatcher) => (HttpRequest r, HttpResponse res) {
   
    var req = new AppRequest(r);
    
    var extra = "";
    
    //if typeof res.writeHead is "undefined"
    //    fake_response(req, res)
    //utils.objectExtend(req, url.parse(req.url, true))
    
    req.startDate = new Date.now();

    var found = false;
    var allowed_methods = [];
    
    for (var row in dispatcher) {

      var method = row[0], 
          path = row[1], 
          funs = row[2];
      if (path is! List) {
        path = [path];
      }

      //print("checking method=(${req.method}==$method) path=(${req.path}==$path)");
      
      // path[0] must be a regexp
      Match match = (path[0] as RegExp).firstMatch(req.path);
      
      if (match == null) {
        continue;
      }
      
      if (!new RegExp(method).hasMatch(req.method)) {
        allowed_methods.add(method);
        continue;
      }
      
      //print("found method=$method path=$path");
      
      var matches = match.groupCount();
      
      for (var i = 1; i <= matches; i++) {
        var m = match.group(i);
        switch(path[i]) {
          case "session":
            req.session = m;
            break;
          case "server":
            req.server = m;
            break;
        }
      }
      
      funs = new List.from(funs);
      
      req.nextFilter = (data) => executeRequest(funs, req, res, data);
      req.nextFilter(extra);
 
      
      found = true;
      break;
    }

    if (!found) {
      if (!allowed_methods.isEmpty()) {
        handle405(req, res, allowed_methods);
      } else {
        handle404(req, res);
        logRequest(req, res, true);
        return;
      }
    }
    
  };
     
  executeRequest(List<HandlerFn> funs, HttpRequest r, HttpResponse res, data) {
    
    var req = new AppRequest(r);
    
    try {
      do  {
        // must replicate the shift to modify the array
        var fun = funs.removeAt(0);
        fun(req, res, data, req.nextFilter); 
      } while(!funs.isEmpty());
    } on AppException catch (e) {   
      switch (e.status) {
        case 0:
          return;
        case 404:
          handle404(req, res, e);
          break;
        case 405:
          handle405(req, res, []);
          break;
        default:
          handleError(req, res, e);
      }
    } on Dynamic catch (e) {
      handleError(req, res, e);
    } finally {
      logRequest(req, res, true);
    }
  }
  
  logRequest(HttpRequest r, HttpResponse res, data) {
    var req = new AppRequest(r);
    var td = (new Date.now()).difference(req.startDate).inMilliseconds;
    log('info', "${req.method} ${req.uri} $td ms ${res.headers.toString()}");
      //(res.finished)? res._header.split('\r')[0].split(' ')[1] : '(unfinished)'}");
    return data;
  }
    
  expose(HttpRequest r, HttpResponse res, [content, nextFilter]) {
    //if res.finished
    //return content
      if ((content != null) && (res.headers.value(HttpHeaders.CONTENT_TYPE) == null)) {
        res.headers.add(HttpHeaders.CONTENT_TYPE, 'text/plain');
      }
      //if (content != null && (res.headers.value(HttpHeaders.CONTENT_LENGTH) == null) ) {
      //  res.headers.add(HttpHeaders.CONTENT_LENGTH, content.length);
      //}
    
      res.outputStream.writeString(content, Encoding.UTF_8);
      res.outputStream.close();
      return true;
  }
          
  handleError(HttpRequest r, HttpResponse res, x) {
    //if res.finished
    //return x
    
    if (x is AppException) {
      res.statusCode = x.status;
      res.outputStream.writeString(x.message);
      res.outputStream.close();
    } else {
      try {
        res.statusCode = 500;
        res.outputStream.writeString("500 - Internal Server Error");
      } catch (y) {
        var req = new AppRequest(r);
        log('error', 'Exception on ${req.method} ${req.uri} in filter ${req.lastFun}:\n ${x}');
      }
    }
    return true;
  }
  
  handle405(HttpRequest req, HttpResponse res, List<String> methods) {

    res.headers.set(HttpHeaders.ALLOW, Strings.join(methods, ', '));
    res.statusCode = 405;
    
    // Cannot close since HttpParser is waiting for the body!
    if(req.contentLength == -1) {
      res.detachSocket().socket.close();
    } else {
      res.outputStream.close();
    }
    
    return true;
  }

  handle404(HttpRequest req, HttpResponse res, [data]) {
    //if (res.finished) { 
    //  return data;
    //}

    res.statusCode = 404;
    res.outputStream.writeString('404 Error: Page not found\n');
    res.outputStream.close();

    return true;
  }
  
  cache_for(HttpRequest req, HttpResponse res, [content, nextFilter]) {
    var cache_for = 365 * 24 * 60 * 60; // one year.
    // See: http://code.google.com/speed/page-speed/docs/caching.html
    res.headers.add(HttpHeaders.CACHE_CONTROL, 'public, max-age=$cache_for');
    var exp = new Date.now().millisecondsSinceEpoch;
    exp += cache_for * 1000;
    
    res.headers.add(HttpHeaders.EXPIRES, new Date.fromMillisecondsSinceEpoch(exp, true));
    return content;
  }
      
  h_no_cache(HttpRequest req, HttpResponse res, [content, nextFilter]) {
    res.headers.add(HttpHeaders.CACHE_CONTROL, 'no-store, no-cache, must-revalidate, max-age=0');
    return content;
  }
      
  expect_xhr(HttpRequest req, HttpResponse res, [c, nextFilter]) {

    List<int> data = null;
    
    req.inputStream.onData = () {
      int available = req.inputStream.available();
      data = req.inputStream.read();
   };
   
   req.inputStream.onClosed = () {
     int available = req.inputStream.available();
     var content = null;
     
     var contentType = req.headers.value(HttpHeaders.CONTENT_TYPE);
     

     if (contentType == null) {
       contentType = '';
     }
    
     contentType = contentType.split(';')[0];
     
     switch(contentType) {
       case 'text/plain':
       case 'T':
       case 'application/json':
       case 'application/xml':
       case '':
       case 'text/xml':
         if (data != null) {
          content = new String.fromCharCodes(data);
         }
         break;
       default:
         log('error', 'Unsupported content-type $contentType');
     }
     
     nextFilter(content);
   };
   
   throw new AppException(status:0);
  }
  
  log(severity, line) => print(line);
}

typedef AppFilter(data);

class AppRequest implements HttpRequest {
  
  static Expando _expando = new Expando();
  
  HttpRequest httpRequest;
  
  Date startDate;
  
  AppFilter nextFilter;
  
  String lastFun;
  
  String server;
  
  String session;
  
  AppRequest._internal(this.httpRequest);
  
  factory AppRequest(HttpRequest httpRequest) {
    if (httpRequest is AppRequest) {
      return httpRequest;
    }
    if (_expando[httpRequest] == null) {
      _expando[httpRequest] = new AppRequest._internal(httpRequest);
    }
    return _expando[httpRequest];
  }
      
  // HttpRequest delegate methods
  int get contentLength => httpRequest.contentLength;
  bool get persistentConnection => httpRequest.persistentConnection;
  String get method => httpRequest.method;
  String get uri => httpRequest.uri;
  String get path => httpRequest.path;
  String get queryString => httpRequest.queryString;
  Map<String, String> get queryParameters => httpRequest.queryParameters;
  HttpHeaders get headers => httpRequest.headers;
  List<Cookie> get cookies => httpRequest.cookies;
  InputStream get inputStream => httpRequest.inputStream;
  String get protocolVersion => httpRequest.protocolVersion;
  HttpConnectionInfo get connectionInfo => httpRequest.connectionInfo;
}
