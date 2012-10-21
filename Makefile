sockjs-protocol-tests:
	./venv/bin/python sockjs-protocol/sockjs-protocol-0.3.3.py BaseUrlGreeting
	./venv/bin/python sockjs-protocol/sockjs-protocol-0.3.3.py InfoTest		 	
	./venv/bin/python sockjs-protocol/sockjs-protocol-0.3.3.py SessionURLs
	./venv/bin/python sockjs-protocol/sockjs-protocol-0.3.3.py Protocol
	./venv/bin/python sockjs-protocol/sockjs-protocol-0.3.3.py XhrStreaming
	./venv/bin/python sockjs-protocol/sockjs-protocol-0.3.3.py XhrPolling
	./venv/bin/python sockjs-protocol/sockjs-protocol-0.3.3.py WebsocketHttpErrors
	
	# ./venv/bin/python sockjs-protocol/sockjs-protocol-0.3.3.py IframePage
	# ./venv/bin/python sockjs-protocol/sockjs-protocol-0.3.3.py WebsocketHixie76
	# ./venv/bin/python sockjs-protocol/sockjs-protocol-0.3.3.py WebsocketHybi10
	# ./venv/bin/python sockjs-protocol/sockjs-protocol-0.3.3.py EventSource
	# ./venv/bin/python sockjs-protocol/sockjs-protocol-0.3.3.py HtmlFile
	# ./venv/bin/python sockjs-protocol/sockjs-protocol-0.3.3.py JsonPolling
	# ./venv/bin/python sockjs-protocol/sockjs-protocol-0.3.3.py JsessionidCookie
	# ./venv/bin/python sockjs-protocol/sockjs-protocol-0.3.3.py RawWebsocket
	# ./venv/bin/python sockjs-protocol/sockjs-protocol-0.3.3.py JSONEncoding	
	# ./venv/bin/python sockjs-protocol/sockjs-protocol-0.3.3.py HandlingClose
	# ./venv/bin/python sockjs-protocol/sockjs-protocol-0.3.3.py Http10
	# ./venv/bin/python sockjs-protocol/sockjs-protocol-0.3.3.py Http11
	

ws-raw-fuzzing:
	./venv/bin/wstest -m fuzzingclient -s ./test/fuzzingclient.json

ws-raw-echo-test:
	./venv/bin/python ./test/wsechotest.py  ws://localhost:8081/echo/websocket

