global class SO_NearerDeliveryCompaniesController {
/*  It Calculates the Longitude and latitude values of Customer Shipping Location using NearByDeliveryComapanyInPOVF and find Neared Delivery Companies . 
And calculate the distance In Miles between Customer Shipping location and Delivery company location , display the value in Sales Order - 
Distance In Miles ,Neares Delivery Company and List of All Nearer Delivery Companies with corresponding distance values */
    global static list<account> deliverycompanies = new list<account>();
    global static account acc = new account(); 
    global String MY_KEY{get;set;}
    
    public SO_NearerDeliveryCompaniesController(ApexPages.StandardSetController controller) {
        Google_API__c key = Google_API__c.getValues('Google API');
        System.debug('Key: '+key.key__c);
        
        MY_KEY = 'https://maps.googleapis.com/maps/api/js?key='+key.key__c+'&sensor=falsekey.key__c'; 
    }
    @RemoteAction 
    // Find Accounts nearest a geolocation  
    global static List<Sales_Order__c> getNearby(String lat, String lon,string soID,String deliveryId,String lat1, String lon1,string deliverycomanyname) 
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
        deliverycompanies =database.Query(queryString);
        system.debug('deliverycompanies :' + deliverycompanies);
        if(deliverycompanies !=null && deliverycompanies.size()>0)
          acc=deliverycompanies[0];
     
        SO_NearerDeliveryCompaniesController.calculateHaversineDistance(deliverycompanies,soID,decimal.valueof(lat),decimal.valueof(lon),decimal.valueof(lat1),decimal.valueof(lon1),deliverycomanyname);
        return(database.Query(queryString));
    } 
    public static decimal calculateHaversineDistance(list<account> accList ,string salesorderId,Decimal lat1, Decimal lon1, Decimal lat2, Decimal lon2,string deliverycomanyname)
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
        Sales_Order__c so=new Sales_Order__c(); 
        so.id=salesorderId;  
        //so.Distance_In_Miles__c= Math.round(dDistance);   
        //so.Nearest_Delivery_Company__c = acc.Name;  
        so.Delivery_Companies_Distance__c = '';
        
        if(deliverycomanyname !=null && dDistance !=null)
        {
            //Suggested Delivery
            so.Delivery_Companies_Distance__c+=' Suggested Delivery:  ';
            so.Delivery_Companies_Distance__c+=deliverycomanyname+' - '+Math.round(dDistance) +' Miles  \n';
        }
        
        for(string deliverycompanyTemp: deliveryComapniesList.keyset())
        {
            so.Delivery_Companies_Distance__c+=deliverycompanyTemp+' - '+integer.valueof(deliveryComapniesList.get(deliverycompanyTemp)) +' Miles  \n';
        } 
        
        //so.Delivery_Companies_Distance__c+=deliverycompanyName+' - '+Math.round(dDistance);
        system.debug('so ' +so);
        try{
        	update so; 
        }
        catch (exception e){
        	system.debug('errpr: ' + e.getmessage());
        } 
        
        return Math.round(dDistance); 
    } 
}