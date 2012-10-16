sockjs-protocol-tests:
	./sockjs-protocol/venv/bin/python sockjs-protocol/sockjs-protocol-0.3.3.py BaseUrlGreeting
	./sockjs-protocol/venv/bin/python sockjs-protocol/sockjs-protocol-0.3.3.py InfoTest
	./sockjs-protocol/venv/bin/python sockjs-protocol/sockjs-protocol-0.3.3.py SessionURLs
	./sockjs-protocol/venv/bin/python sockjs-protocol/sockjs-protocol-0.3.3.py Protocol
	./sockjs-protocol/venv/bin/python sockjs-protocol/sockjs-protocol-0.3.3.py XhrStreaming
#	./sockjs-protocol/venv/bin/python sockjs-protocol/sockjs-protocol-0.3.3.py XhrPolling

