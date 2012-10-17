sockjs-protocol-tests:
	./venv/bin/python sockjs-protocol/sockjs-protocol-0.3.3.py BaseUrlGreeting
	./venv/bin/python sockjs-protocol/sockjs-protocol-0.3.3.py InfoTest
	./venv/bin/python sockjs-protocol/sockjs-protocol-0.3.3.py SessionURLs
	./venv/bin/python sockjs-protocol/sockjs-protocol-0.3.3.py Protocol
	./venv/bin/python sockjs-protocol/sockjs-protocol-0.3.3.py XhrStreaming
#	./venv/bin/python sockjs-protocol/sockjs-protocol-0.3.3.py XhrPolling

ws-raw-fuzzing:
	./venv/bin/wstest -m fuzzingclient -s ./test/fuzzingclient.json

ws-raw-echo-test:
	./venv/bin/python ./test/wsechotest.py  ws://localhost:8081/echo/websocket

