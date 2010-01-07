package com.twitter.stream
{
  import flash.events.Event;
  
  /**
  * Represents a delete status message.  This is
  * sent when a user you are tracking deletes a tweet.
  * The Status object will be partially populated, containing
  * at least a userId and statusId.
  */
  public class DeleteStatus extends Event{
    
    public var status:Status = null;
    public function DeleteStatus():void {
      super(TwitterStreamEvent.DELETE_STATUS);
    }
    
    /**
    * Builds a DeleteStates object from a JSON object
    */
    public static function fromJSON(json:Object): DeleteStatus {
      if(json['status'] != null) {
        var deleteStatus:DeleteStatus = new DeleteStatus();
        deleteStatus.status = Status.fromJSON(json['status']);
        return deleteStatus;
      } else {
        return null;
      }
    }
  } 
}
