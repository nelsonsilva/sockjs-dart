part of sockjs;

iframe(String sockjsUrl) => (HttpRequest req, HttpResponse res, [data, nextFilter]) {

  var content = """<!DOCTYPE html>
<html>
<head>
  <meta http-equiv="X-UA-Compatible" content="IE=edge" />
  <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
  <script>
    document.domain = document.domain;
    _sockjs_onload = function(){SockJS.bootstrap_iframe();};
  </script>
  <script src="$sockjsUrl"></script>
</head>
<body>
  <h2>Don't panic!</h2>
  <p>This is a SockJS hidden iframe. It's used for cross domain magic.</p>
</body>
</html>""";

  var quoted_md5 = '"${utils.md5_hex(content)}"';

  String v = req.headers.value('if-none-match');

  if ((v != null) && (v == quoted_md5)) {
    res.statusCode = 304;
    return '';
  }

  res.headers.add(HttpHeaders.CONTENT_TYPE, 'text/html; charset=UTF-8');
  res.headers.add('ETag', quoted_md5);

  print(content);
  return content;
};