import sys
from twisted.python import log
from twisted.internet import reactor
from autobahn.websocket import WebSocketClientFactory, WebSocketClientProtocol
from autobahn.websocket import connectWS

class EchoClientProtocol(WebSocketClientProtocol):

   def __init__(self):
      self.msg = "Hello, world!"

   def sendHello(self):
      self.sendMessage(self.msg)

   def onOpen(self):
      self.sendHello()

   def onMessage(self, msg, binary):
      print "Got echo: " + msg
      if msg == self.msg:
        print("It works!")
      else:
        print("Wrong message!")
      
      reactor.stop()

if __name__ == "__main__":
   if len(sys.argv) < 2:
      print "Need the WebSocket server address, i.e. ws://localhost:8081/echo/websocket"
      sys.exit(1)

   debug = False
   if debug:
      log.startLogging(sys.stdout)

   print "Using Twisted reactor class %s" % str(reactor.__class__)

   url = sys.argv[1]

   factory = WebSocketClientFactory(url, debug = debug, debugCodePaths = debug)
   factory.setProtocolOptions(version = 13)
   factory.protocol = EchoClientProtocol
   connectWS(factory)

   reactor.run()
