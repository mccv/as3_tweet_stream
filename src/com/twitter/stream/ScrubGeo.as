package com.twitter.stream
{
  import flash.events.Event;
  
  /**
  * Represents a scrub geo data event.
  * This is sent when a user you're tracking deletes their geo data.
  */
  public class ScrubGeo extends Event{
    public var userId:Number = NaN;
    public var upToStatusId:Number = NaN;
    
    public function ScrubGeo():void {
      super(TwitterStreamEvent.SCRUB_GEO);
    }
    
    /**
    * Build a ScrubGeo object from a JSON object
    */
    public static function fromJSON(json:Object): ScrubGeo {
      var scrubGeo:ScrubGeo = new ScrubGeo();
      scrubGeo.userId = json['user_id'];
      scrubGeo.upToStatusId = json['up_to_status_id'];
      return scrubGeo;
    }
  } 
}
