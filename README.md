# SockJS

This is a [SockJS](http://sockjs.org) server written in Dart.
It is based on [sockjs-node](https://github.com/sockjs/sockjs-node)

## Tests

To run the tests first start the test_server:

	dart bin/test_server.dart

Then make sure you have all the dependencies installed (see below) call `make <target>`

### QUnit Tests (from SockJS Client)

Open your browser at:

	http://localhost:8081/tests-qunit.html
	
### SockJS Protocol Tests

First update the sockjs-protocol submodule:

	git submodule update --init

You must have Python 2.X and `virtualenv` installed. You can install it via `pip install virtualenv` or `sudo apt-get install python-virtualenv`.

Finally checkout the dependencies:
	
	make -f sockjs-protocol/Makefile test_deps

An run the tests:

	make sockjs-protocol-tests	


### Autobahn

First install the autobahn test suite. 

Open a command shell, and install from Python package index (this uses virtualenv):

	./venv/bin/easy_install autobahntestsuite

Then just run the tests:
	
	make ws-raw-echo-test ws-raw-fuzzing



