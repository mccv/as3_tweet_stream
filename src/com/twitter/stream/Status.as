package com.twitter.stream{
  
  import flash.events.Event;

  /**
  * Represents a Twitter Status (tweet)
  */
  public class Status extends Event{

    public var createdAt:String = null;
    public var favorited:Boolean = false;
    public var geo:Object = null;
    public var id:Number = NaN;   
    public var inReplyToScreenName:String = null;
    public var inReplyToStatusId:Number = NaN;
    public var inReplyToUserId:Number = NaN;
    public var source:String = null;
    public var text:String = null;
    public var truncated:Boolean = false;
    public var user:User = null;
  
    public function Status():void {
      super(TwitterStreamEvent.STATUS);
    }
    
    /**
    * Build a Status from a JSON object
    */
    public static function fromJSON(json:Object):Status {
      var status:Status = new Status();
      status.createdAt = json['created_at'];
      status.favorited = json['favorited'];
      status.geo = Geo.fromJSON(json['geo']);
      status.inReplyToScreenName = json['in_reply_to_screen_name'];
      status.inReplyToStatusId = json['in_reply_to_status_id'];
      status.inReplyToUserId = json['in_reply_to_user_id'];
      status.source = json['source'];
      status.text = json['text'];
      status.truncated = json['truncated'];
      status.user = User.fromJSON(json['user']);
      return status;
    }
  }	
}
