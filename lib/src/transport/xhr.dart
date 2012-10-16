class XhrStreamingReceiver extends ResponseReceiver {
    get protocol => "xhr-streaming";
    
    XhrStreamingReceiver(var response, {num responseLimit: null} ) : super(response, responseLimit: responseLimit);
    
    doSendFrame(payload) => super.doSendFrame( "$payload\n");
}

class XhrPollingReceiver extends XhrStreamingReceiver {
  
  get protocol => "xhr-polling";
  
  XhrPollingReceiver(var response ) : super(response, responseLimit: 1);
  
}