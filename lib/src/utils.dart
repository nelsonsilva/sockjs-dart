#library("utils");

#import("dart:io");
#import('dart:uri');
#import("dart:math", prefix:'Math');

bool verify_origin(String origin, List<String> list_of_origins) {
    if (list_of_origins.indexOf('*:*') != -1) {
        return true;
    }
    if (list_of_origins == null) {
        return false;
    }
    try {
        var uri = new Uri.fromString(origin);
        var origins = ["${uri.domain}:${uri.port}",
                   "${uri.domain}:*",
                   "*:${uri.port}"];
        if (origins.some((o) => list_of_origins.indexOf(o) != -1)) {
            return true;
        }
    } catch (x) { }

    return false;
}

Map<String, String> parseCookies(List<Cookie> cookies) {
    var res = {};
    cookies.forEach((Cookie cookie) {
      res[ cookie.name ] = cookie.value.trim();
    });
    return res;
}

random32() {
  var rnd = new Math.Random();
  var foo = () => rnd.nextInt(256);
  var v = [foo(), foo(), foo(), foo()];
  
  var x =  v[0] + (v[1]*256 ) + (v[2]*256*256) + (v[3]*256*256*256);
  return x;
}

getCacheFor(HttpResponse res) {
  String cacheFor = res.headers.value(HttpHeaders.CACHE_CONTROL);
  cacheFor = cacheFor.substring("public, max-age=".length);
  return Math.parseInt(cacheFor);
}
