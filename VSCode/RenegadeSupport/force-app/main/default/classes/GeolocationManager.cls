public class GeolocationManager {
    public static Boolean isRun = true;
    
    public static Geolocation obtainGeolocationData(String address) {
        Geolocation geoData = new Geolocation(); 
        try{
            Google_API__c key = Google_API__c.getValues('Google API');
            address = EncodingUtil.urlEncode(address, 'UTF-8');
            Http h = new Http();
            HttpRequest req = new HttpRequest(); 
            req.setEndpoint('https://maps.googleapis.com/maps/api/geocode/json?key='+key.key__c+'&address='+address+'&sensor=false');
            req.setMethod('GET');
            req.setTimeout(60000);

            HttpResponse res = h.send(req);
            JSONParser parser = JSON.createParser(res.getBody());
            while (parser.nextToken() != null) {
                if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'Location')){
                    parser.nextToken(); // object start
                    while (parser.nextToken() != JSONToken.END_OBJECT){
                        String txt = parser.getText();
                        parser.nextToken();
                        if (txt == 'lat')
                        geoData.lat = parser.getDoubleValue();
                        else if (txt == 'lng')
                        geoData.lon = parser.getDoubleValue();
                    } 
                }
            }
        }catch(Exception e){}

        return geoData;
        
    }


    public class Geolocation{
        public Double lat { get; set; }
        public Double lon { get; set; }
    }
}