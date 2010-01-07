package com.twitter.stream
{
  import flash.events.Event;
  
  /**
  * Represents a track limit message.
  * If you get these, your track terms are broad enough that
  * Twitter has decided to limit the number of tweets sent
  * to your client.  The track field tells you how many tweets were
  * held back
  */
  public class Limit extends Event{
    
    public var track:Number = NaN;
    public function Limit():void {
      super(TwitterStreamEvent.LIMIT);
    }
    
    /**
    * Build a Limit object from a JSON object
    */
    public static function fromJSON(json:Object): Limit {
      var limit:Limit = new Limit();
      limit.track = json['track'];
      return limit;
    }
  } 
}
