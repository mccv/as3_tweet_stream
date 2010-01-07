package com.twitter.stream {
  /**
  * Constants for Twitter stream event types
  */
  public class TwitterStreamEvent {
    public static var STATUS:String = "twitter_status";
    public static var DELETE_STATUS:String = "twitter_delete_status";
    public static var LIMIT:String = "twitter_limit";
    public static var SCRUB_GEO:String = "twitter_scrub_geo";
    public static var CONNECTION_FAILED:String = "twitter_connect_failed";
  }
}