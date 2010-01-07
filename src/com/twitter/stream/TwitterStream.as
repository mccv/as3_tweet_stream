package com.twitter.stream
{
  import com.adobe.serialization.json.JSON;
  
  import flash.events.ErrorEvent;
  import flash.events.Event;
  import flash.events.EventDispatcher;
  import flash.events.HTTPStatusEvent;
  import flash.events.IOErrorEvent;
  import flash.events.ProgressEvent;
  import flash.events.SecurityErrorEvent;
  import flash.events.TimerEvent;
  import flash.net.URLRequest;
  import flash.net.URLStream;
  import flash.utils.ByteArray;
  import flash.utils.Timer;
	
	public class TwitterStream extends EventDispatcher {
	  /** the URL we'll connect to */
    protected var streamURL:String;
    /** the stream that shuffles bytes from the streaming API */     
		protected var stream:URLStream;
		/** the last time we attempted a connection */
		protected var lastConnectAttempt:int = 0;
    /** the last time we attempted a connection */
    protected var lastConnect:int = 0;
		/** our current retry attempt */
		protected var retryAttempt:int = 0;
		/** our max number of retries */
		protected var maxRetries:int = 5;
		/** the length of our json message */
		protected var msgLength:int = 0;
		/** our json string (in progress) */
		protected var jsonMessage:ByteArray = null;
    /** timer object that retries a connection */
    protected var retryTimer:Timer = null;
    /** our logger */
    protected var log:Logger = new Logger("TwitterStream");
    
    [Bindable] public var lastHTTPStatus:HTTPStatusEvent = null;

    /** 
    * the reconnect wait time multiplier in milliseconds.
    * Note that this is multiplied by the square of the retry attempt to get
    * a decaying backoff reconnect attempt frequency 
    */
    public var reconnectWait:int = 1000;
    
    /**
    * the parameter/value that tells the streaming API to include message
    * length delimiters
    */
    public static var delimitedParam:String = "delimited=length";

    /**
    * Create a new stream processor
    */
		public function TwitterStream(baseURL:String) {
		  // make sure our URL is length delimited
      streamURL = makeDelimited(baseURL);
      // set up logger
      log.activeLevels[Logger.DEBUG] = false;
		  connect();
		}

    /**
    * add delimited=length to a url if it doesn't already have that param
    */
    protected function makeDelimited(url:String):String {
      var retURL:String = url;
      if (url.indexOf(delimitedParam) == -1) {
        if (url.indexOf("?") > 0) {
          retURL = url + "&";
        }
        retURL = retURL + delimitedParam;
      }
      return retURL;
    }
    
		/**
		 * Open a connection to the streaming API
		 */
		private function connect():void {
		  // null this out first, so we queue another connect attempt if we fail here
		  retryTimer = null;
		  log.info("connecting to " + streamURL);
      // log the time of our connection attempt
      lastConnectAttempt = new Date().time;
      // and get our stream in order
      stream = new URLStream();
      var request:URLRequest = new URLRequest(streamURL);
      // note, this pops up a nasty dialog box.  Probably a better way to do this.
      request.authenticate = true;
      configureListeners(stream);
      stream.load(request);
		}
		
		/**
		 * Close our stream
		 */
		public function disconnect():void {
		  try {
		    stream.close();
		  } catch (e:Error) {
		    // nothing?
		    log.warning("error disconnecting stream: " + e);
		  }
		  // reset our message building state machine
		  resetMessageState();
		  stream = null;
		}

    public function fail():void {
      log.error("failed to connect to " + streamURL + ", no further attempts will be made");
      disconnect();
      dispatchEvent(new ErrorEvent(TwitterStreamEvent.CONNECTION_FAILED));
    }
    
    public function queueReconnect():void {
      // try later
      if (retryTimer == null) {
        if (retryAttempt < maxRetries) {
          log.info("queuing a reconnect. This is retry attempt " + retryAttempt);
          retryTimer = new Timer(retryAttempt*retryAttempt*reconnectWait, 1);
          retryTimer.addEventListener(TimerEvent.TIMER, reconnect);
          retryTimer.start();
          // bump up the current try
          retryAttempt += 1;
        } else {
          // this is a hard failure
          fail();
        }
      }
    }
    
    /**
    * Terminate the current connection and reestablish
    */
    public function reconnect(event:TimerEvent):void {
      try {
        disconnect();
        connect();
      } catch(e: Error) {
        log.error("error in reconnect(): " + e);
        try {
          disconnect();
        } catch (e2: Error) {
          // noop
          log.warning("error disconnecting stream in reconnect(): " + e2);
        }
        queueReconnect();
      }
    }
    
    /**
    * add listeners for all reasonable messages
    */
		private function configureListeners(dispatcher:EventDispatcher):void {
      dispatcher.addEventListener(Event.COMPLETE, completeHandler);
      dispatcher.addEventListener(HTTPStatusEvent.HTTP_STATUS, httpStatusHandler);
      dispatcher.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
      dispatcher.addEventListener(Event.OPEN, openHandler);
      dispatcher.addEventListener(ProgressEvent.PROGRESS, progressHandler);
      dispatcher.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
    }

    /**
    * Called when new bytes (should) be available
    */
    private function handleBytes():void {
      // assumption: usually this will come in one or two TCP packets
      // we'll get a full tweet in one or two reads.
    	if (stream.bytesAvailable > 0) {
      	var bytes:ByteArray = new ByteArray();
        stream.readBytes(bytes);

      	if (msgLength > 0) {
      	  // we know how long the message is, we're just building it now
      	  buildMessage(bytes);
      	} else {
      	  // no known message length, which means the first bit of this read
      	  // should be the message length followed by a newline
      	  buildMessageLength(bytes);
      	}
      }
    }
    
    /**
    * Extract a message length from a byte array.
    * This should be an ASCII number string, followed by a newline
    */
    private function buildMessageLength(bytes:ByteArray):void {
      // read a string from what's left in the byte array
      var msg:String = bytes.readUTFBytes(bytes.length - bytes.position);
      // split it on newline.  This should give us two string elements
      var splits:Array = msg.split("\n");
      if (splits.length > 0) {
        // the first element is the message length
        msgLength = parseInt(splits[0]);
        jsonMessage = null;
        log.debug("got msgLength = " + msgLength);
        // now write the rest of the byte array into a new byte array
        // note that we could have many splits depending on how many messages
        // we got in our byte buffer
        var msgByteArray:ByteArray = new ByteArray();
        bytes.position = splits[0].length + 1;
        bytes.readBytes(msgByteArray);
        // and now that we have the length of our message, build it!
        buildMessage(msgByteArray);
      }
    }
    
    /**
    * Build a JSON message from the byte array.
    * This expects msgLength to be set.
    */
    private function buildMessage(bytes: ByteArray):void {
      if (jsonMessage == null) {
        jsonMessage = bytes;
      } else {
        // if we didn't get the whole message in the first progress
        // event, concatenate the two buffers
        var newBytes:ByteArray = new ByteArray();
        newBytes.writeBytes(jsonMessage);
        // this write is offset by the length of the first write
        newBytes.writeBytes(bytes);
        jsonMessage = newBytes;
      }
      // if we have more bytes than our message length, read it, parse it out and dispatch
      if(jsonMessage.length >= msgLength) {
        // reset buffer.  Important!
        jsonMessage.position = 0;
        var msgStr:String = jsonMessage.readUTFBytes(msgLength);
        parseMessage(msgStr);
        // reset the message state, in case we already have the next message in our buffer 
        resetMessageState();
        // if we do have leftovers, extract a message length and keep going
        // until we end up with an empty byte array here
        if (jsonMessage.position != jsonMessage.length) {
          // copy remaining bytes into a fresh byte array
          var leftovers:ByteArray = new ByteArray();
          jsonMessage.readBytes(leftovers);
          buildMessageLength(leftovers);
        }
      }
    }

    /**
    * Parse a Twitter object out of a JSON string
    */
    private function parseMessage(message:String): void {
      log.debug("parsing json message: " + message);
      try {
        var json:Object = JSON.decode(message);
        if (json['text'] != null) {
          var status:Status = Status.fromJSON(json);
          log.debug("dispatch status event with text = " + status.text);
          dispatchEvent(status);
        } else if(json['delete'] != null) {
          var deleteStatus:DeleteStatus = DeleteStatus.fromJSON(json);
          log.debug("dispatch deleteStatus event with id = " + deleteStatus.status.id);
          dispatchEvent(deleteStatus);
        } else if(json['limit'] != null) {
          var limit:Limit = Limit.fromJSON(json);
          log.debug("dispatch limit event with track = " + limit.track);
          dispatchEvent(limit);
        } else if(json['scrub_geo'] != null) {
          var scrubGeo:ScrubGeo = ScrubGeo.fromJSON(json);
          log.debug("dispatch scrub geo event for user = " + scrubGeo.userId);
          dispatchEvent(scrubGeo); 
        }
      } catch (e:Error) {
        log.error("error parsing Twitter object from string: " + message);
        log.error("error is " + e.toString());
      }
    }
    
    /**
    * Reset fields used by our hobo message state machine
    */
    public function resetMessageState():void {
      msgLength = 0;
    }


    /**
    * shut down the current connection, reopen it
    */
    private function completeHandler(event:Event):void {
      log.debug("completeHandler: " + event);
      dispatchEvent(event);
      handleBytes();
      queueReconnect();
    }

    /**
    * probably a no-op
    */
    private function openHandler(event:Event):void {
      log.debug("openHandler: " + event);
      dispatchEvent(event);
    }

    /**
    * this is called when we receive new bytes.  Should
    * read a line, parse it to JSON, fire an event
    */
    private function progressHandler(event:Event):void {
      log.debug("progressHandler: " + event);
      dispatchEvent(event);
      handleBytes();
    }

    /**
    * probably somebody trying to do this from a browser environment.
    * propagate the event?
    */
    private function securityErrorHandler(event:SecurityErrorEvent):void {
      log.debug("securityErrorHandler: " + event);
      dispatchEvent(event);
    }

    /**
    * gets the HTTP response stuff back.  Check for 200, take appropriate
    * response on non-200s (reconnect, propagate event)
    */
    private function httpStatusHandler(event:HTTPStatusEvent):void {
      log.debug("httpStatusHandler: " + event);
      dispatchEvent(event);
      this.lastHTTPStatus = event;
      // stuff in the 2xx range is good.  Reset our retry counters and keep processing
      if (event.status > 199 && event.status < 300) {
        retryAttempt = 0;
        retryTimer = null;
        lastConnect = new Date().time;
      }
      // stuff in the 3xx range is terminal.  Shouldn't hit redirects on the streaming API
      if (event.status > 299 && event.status < 499) {
        log.error("got a 3xx HTTP response code: " + event);
        fail();
      }
      // stuff in the 4xx range is terminal
      if (event.status > 399 && event.status < 500) {
        log.error("got a 4xx HTTP response code: " + event);
        fail();
      }
      // stuff in the 5xx range is recoverable, try a reconnect
      if (event.status > 499) {
        log.warning("got a 5xx HTTP response code: " + event);
        queueReconnect();
      }
      // if they're outside the general HTTP range, we're probably in a browser.  Treat the code as recoverable
      if (event.status < 200 || event.status > 599) {
        log.warning("got an out of range HTTP response code (probably browser/flash jank): " + event);
        queueReconnect();
      }
    }

    /**
    * happens when a general (non-HTTP) error occurs. 
    * Just attempt a reconnect
    */
    private function ioErrorHandler(event:IOErrorEvent):void {
      log.info("I/O error processing twitter stream " + event);
      queueReconnect();
    }
	}
}