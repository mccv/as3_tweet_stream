package com.twitter.stream
{

  /**
  * Represents a geo tag
  */
  public class Geo
  {
    public var latitude:Number = NaN;
    public var longitude:Number = NaN;
    public function Geo()
    {
    }
    
    /**
    * Builds a Geo object from a JSON object
    */
    public static function fromJSON(json:Object): Geo {
      //ex: "geo":{"type":"Point","coordinates":[37.18137251,-93.25014557]}
      if (json != null) {
        var geo:Geo = new Geo();
        // note that Twitter currently writes these as lat/long, which is the
        // opposite of the GEO JSON spec
        geo.latitude = json['coordinates'][0];
        geo.longitude = json['coordinates'][1];
        trace("parsed a geo, lat/long = " + geo.latitude + "/" + geo.longitude);
        return geo;
      } else {
        return null;
      }
    }
  }
}