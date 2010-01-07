package com.twitter.stream
{
  /**
  * Represents a Twitter user
  */
  public class User
  {
    public var verified:Boolean = false;
    public var followersCount:int = 0;
    public var friendsCount:int = 0;
    public var url:String = null;
    public var profileBackgroundColor: String = null;
    public var favouritesCount:int = 0;
    public var description:String = null;
    public var notification:String = null;
    public var profileTextColor:String = null;
    public var timeZone:String = null;
    public var statusesCount:int = 0;
    public var createdAt:String = null;
    public var profileLinkColor:String = null;
    public var geoEnabled:Boolean = false;
    public var profileBackgroundImageURL:String = null;
    public var isProtected:Boolean = false;
    public var profileImageURL:String = null;
    public var profileSidebarFillColor:String = null;
    public var location:String = null;
    public var name:String = null;
    public var following:String = null;
    public var profileBackgroundTile:Boolean = false;
    public var screenName:String = null;
    public var id:int = 0;
    public var utcOffset:int = 0;
    public var profileSidebarBorderColor:String = null;

    public function User()
    {
    }
    
    /**
    * Build a User from a JSON object
    */
    static public function fromJSON(json:Object):User {
      var user:User = new User();
      user.createdAt = json['created_at'];
      user.description = json['description'];
      return user;      
    }

  }
}