/* Calculate the longitude and latitude based on Customer Shipping address and display the value in Location field */

public class ShippingLocationCallouts 
{ 
    // Moved to SalesOrderTriggerHandler
   /* @future (callout=true)  // future method needed to run callouts from Triggers
    static public void getLocation(string street, string city, string state, string zipcode, string SOid)
    {   
        System.debug('getLocation');
        Google_API__c key = Google_API__c.getValues('Google API');
        System.debug('Key: '+key.key__c);
        // create an address string  
        String MY_KEY = key.key__c; 
        
        String address=''; 
        
        if (street != null) 
            address += street +', ';  
        if (city != null)
            address += city +', ';
        if (state != null)  
            address += state +' ';
        if (zipcode != null)
            address += zipcode +', ';   
        
        if(address!='')
        { 
            address = EncodingUtil.urlEncode(address, 'UTF-8');
            
            // build callout   
            Http h = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://maps.googleapis.com/maps/api/geocode/json?key='+MY_KEY+'&address='+address+'&sensor=false');
            //req.setEndpoint('https://maps.googleapis.com/maps/api/geocode/json?address='+address+'&sensor=false');
            req.setMethod('GET');
            req.setTimeout(60000);
            
            try
            { 
                // callout 
                HttpResponse res;
                if(test.isRunningTest())
                {
                    MockHttpResponseGenerator mockHttp=new MockHttpResponseGenerator();
                    res=mockHttp.respond(req);
                    System.debug('running res'+res.getBody());
                }
                else
                {
                    res = h.send(req);
                    System.debug('res'+res.getBody());
                }
                
                // parse coordinates from response 
                JSONParser parser = JSON.createParser(res.getBody());
                system.debug('parser  '+ parser);
                double lat = null;  
                double lon = null; 
                
                while (parser.nextToken() != null) 
                {                
                    if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'location'))
                    {
                        parser.nextToken(); // object start
                        while (parser.nextToken() != JSONToken.END_OBJECT)
                        {
                            String txt = parser.getText();
                            parser.nextToken();
                            if (txt == 'lat')  
                                lat = parser.getDoubleValue();
                            else if (txt == 'lng')
                                lon = parser.getDoubleValue();
                        } 
                    } 
                } 
                // update coordinates if we get back 
                if (lat != null)
                { 
                    Sales_Order__c SOObj=new Sales_Order__c();
                    Sales_Order__c so = [select Delivery_Companies_Distance__c, Delivery_Company__c, Delivery_Company__r.Name, Delivery_Company__r.Location__Latitude__s, Delivery_Company__r.Location__Longitude__s from Sales_Order__c where id = :SOid]; 
                    
                    SOObj.id=SOid;
                    SOObj.Location__Latitude__s = lat;  
                    SOObj.Location__Longitude__s = lon;
                     SOObj.Delivery_Companies_Distance__c = getNearby(string.valueof(SOObj.Location__Latitude__s), string.valueof(SOObj.Location__Longitude__s),string.valueof(so.id), string.valueof(so.Delivery_Company__c), string.valueof(so.Delivery_Company__r.Location__Latitude__s), string.valueof(so.Delivery_Company__r.Location__Longitude__s), string.valueof(so.Delivery_Company__r.Name));
                     System.debug(SOObj.Delivery_Companies_Distance__c);
                    update SOObj; 
                }
            } 
            catch (Exception e) 
            { 
                System.debug(LoggingLevel.ERROR, 'Error Geocoding Address - ' + e.getMessage());
            }
        }
    } 
      
    public static string getNearby(String lat, String lon,string soID,String deliveryId,String lat1, String lon1,string deliverycomanyname) 
    {
        // If geolocation isn't set, use Eindhoven (or any other city)
        // Put a default location latitue and longitude here, this could be where you are located the most
        // and will only be used as a backup if the browser can not get your location details
        
        if(lat == null || lon == null || lat.equals('') || lon.equals('')) 
		{
			lat ='51.096214'; 
			lon = '3.683153'; 
		}    
        //recordtype rectypeId=[select id from recordtype where name='Delivery Company'];
        //System.debug('deliveryId: '+deliveryId);
       
        String queryString = 
            'SELECT Id, Name, Location__Longitude__s, Location__Latitude__s, ' +'ShippingStreet, Phone, ShippingCity,ShippingPostalCode ' +
            'FROM Account ' +'WHERE Is_active__c = true and Location__Latitude__s != null and Location__Longitude__s != null and  RecordType.name = \'Delivery Company\' AND DISTANCE(Location__c, GEOLOCATION('+lat+','+lon+'), \'km\') < 805'  
            + 'ORDER BY DISTANCE(Location__c, GEOLOCATION('+lat+','+lon+'), \'km\') '+ 'LIMIT 3';
        // Run and return the query results 
        
        system.debug('query string contains :' + querystring);
        list<Account> deliverycompanies = database.Query(queryString);
        system.debug('deliverycompanies :' + deliverycompanies);
     
        
        return calculateHaversineDistance(deliverycompanies,soID,decimal.valueof(lat),decimal.valueof(lon),decimal.valueof(lat1),decimal.valueof(lon1),deliverycomanyname);
        
    } 
    public static string calculateHaversineDistance(list<account> accList ,string salesorderId,Decimal lat1, Decimal lon1, Decimal lat2, Decimal lon2,string deliverycomanyname)
    {
        // convert to radians
        Double dDepartLat = lat1 * 3.14159 / 180;
        Double dDepartLong = lon1 * 3.14159 / 180; 
        map<string,Double> deliveryComapniesList=new map<string,Double>();
        
        for(account actemp: accList)
        {
            Double dArrivalLat = actemp.Location__Latitude__s * 3.14159 / 180;
            Double dArrivalLong = actemp.Location__Longitude__s * 3.14159 / 180;
            
            Double dDeltaLong = dArrivalLong - dDepartLong;
            Double dDeltaLat = dArrivalLat - dDepartLat; 
            
            // calculate angle using the haversine formula
            Double dHaversineResult = Math.Sin( dDeltaLat / 2 ) * Math.Sin( dDeltaLat / 2 ) 
                + Math.Cos( dDepartLat ) * Math.Cos( dArrivalLat )  
                * Math.Sin( dDeltaLong / 2 ) * Math.Sin( dDeltaLong / 2 );
            
            // calculate distance by multiplying arc-tangent by the planet radius in miles
            Double dDistance = 3958.76 * 2 * Math.Atan2( Math.Sqrt( dHaversineResult ), Math.Sqrt( 1 - dHaversineResult ));
            deliveryComapniesList.put(actemp.Name,Math.round(dDistance)); 
        } 
        
        Double dArrivalLat;
        Double dArrivalLong;
        Double dDeltaLong;
        Double dDeltaLat;
        Double dHaversineResult;
        Double dDistance; 
        
        if(lat2 !=null && lon2 !=null)
        {
            dArrivalLat = lat2 * 3.14159 / 180;
            dArrivalLong = lon2 * 3.14159 / 180;
            
            dDeltaLong = dArrivalLong - dDepartLong;
            dDeltaLat = dArrivalLat - dDepartLat; 
            
            // calculate angle using the haversine formula
            dHaversineResult = Math.Sin( dDeltaLat / 2 ) * Math.Sin( dDeltaLat / 2 ) 
                + Math.Cos( dDepartLat ) * Math.Cos( dArrivalLat )  
                * Math.Sin( dDeltaLong / 2 ) * Math.Sin( dDeltaLong / 2 );
            
            // calculate distance by multiplying arc-tangent by the planet radius in miles
            dDistance = 3958.76 * 2 * Math.Atan2( Math.Sqrt( dHaversineResult ), Math.Sqrt( 1 - dHaversineResult ) );
        }
        
        // Update Distance value in Sales Order and return the distance
        //Sales_Order__c so=new Sales_Order__c(); 
        //so.id=salesorderId;  
        //so.Distance_In_Miles__c= Math.round(dDistance);   
        //so.Nearest_Delivery_Company__c = acc.Name;  
        //so.Delivery_Companies_Distance__c = '';
        string ret = '';
        if(deliverycomanyname !=null && dDistance !=null)
        {
            //Suggested Delivery
            ret +=' Suggested Delivery:  ';
            ret +=deliverycomanyname+' - '+Math.round(dDistance) +' Miles  \n';
        }
        
        for(string deliverycompanyTemp: deliveryComapniesList.keyset())
        {
            ret +=deliverycompanyTemp+' - '+integer.valueof(deliveryComapniesList.get(deliverycompanyTemp)) +' Miles  \n';
        } 
        
        //so.Delivery_Companies_Distance__c+=deliverycompanyName+' - '+Math.round(dDistance);
        return ret; 
    }    */
}