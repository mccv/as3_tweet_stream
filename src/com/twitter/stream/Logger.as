package com.twitter.stream
{
  public class Logger
  {
    public static var ERROR:String = "error";
    public static var WARNING:String = "warning";
    public static var INFO:String = "info";
    public static var DEBUG:String = "debug";

    public var name:String;
    public var activeLevels:Object = new Object();
    public function Logger(name:String) {
      this.name = name;
      activeLevels[ERROR] = true;
      activeLevels[WARNING] = true;
      activeLevels[INFO] = true;
      activeLevels[DEBUG] = true;
    }

    public function log(level:String, msg:String):void {
      if(activeLevels[level]) {
        trace(name + " - " + level + " - " + msg);
      }
    }
    
    public function error(msg:String):void {
      log(ERROR, msg);      
    }

    public function warning(msg:String):void {
      log(WARNING, msg);      
    }

    public function info(msg:String):void {
      log(INFO, msg);      
    }

    public function debug(msg:String):void {
      log(DEBUG, msg);      
    }
  }
}