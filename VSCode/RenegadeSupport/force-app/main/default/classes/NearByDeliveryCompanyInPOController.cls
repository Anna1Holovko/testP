/*  It takes the Longitude and latitude values of Manufacturer Location from NearByDeliveryComapanyInPOVF and find Neared Delivery Companies . 
And calculate the distance In Miles between Manufacturer location and Delivery company location , display the value in Purchase Order - 
Distance In Miles ,Neares Delivery Company and List of All Nearer Delivery Companies */

global class NearByDeliveryCompanyInPOController {
    global static list<account> deliverycompanies = new list<account>();
    global static account acc = new account(); 
    global String MY_KEY{get;set;}
    
    global NearByDeliveryCompanyInPOController(ApexPages.StandardSetController controller) 
    {
        Google_API__c key = Google_API__c.getValues('Google API');
        System.debug('Key: '+key.key__c);
        
        MY_KEY = 'https://maps.googleapis.com/maps/api/js?key='+key.key__c+'&sensor=falsekey.key__c'; 
    }
        
    @RemoteAction 
    global static List<Sales_Order__c> getNearbyDelivery(String lat, String lon,string soID,String deliveryId,String lat1, String lon1,string deliverycomanyname) 
    {
        // If geolocation isn't set, use Eindhoven (or any other city)
        // Put a default location latitue and longitude here, this could be where you are located the most
        // and will only be used as a backup if the browser can not get your location details
        
        recordtype rectypeId=[select id from recordtype where sObjecttype='Account' AND name='Delivery Company'];
        
        String queryString = 
            'SELECT Id, Name, Location__Longitude__s, Location__Latitude__s, ' +'ShippingStreet, Phone, ShippingCity,ShippingPostalCode ' +
            'FROM Account ' +'WHERE Is_active__c = true and Location__Latitude__s != null and Location__Longitude__s != null and  RecordTypeID = \''+rectypeId.id+'\' AND DISTANCE(Location__c, GEOLOCATION('+lat+','+lon+'), \'km\') < 805' 
            + 'ORDER BY DISTANCE(Location__c, GEOLOCATION('+lat+','+lon+'), \'km\') '+ 'LIMIT 3';
        // Run and return the query results 
                
        return(database.Query(queryString));
    } 
    
    @RemoteAction   
    // Find Accounts nearest a geolocation 
    //global static List<Purchase_Order__c> getNearby(String lat, String lon,string soID,String deliveryId,String lat1, String lon1) 
    global static List<Purchase_Order__c> getNearby(string poid,String lat, String lon,String lat1,String lon1,string deliverycomanyname) 
    { 
        // If geolocation isn't set, use Eindhoven (or any other city)
        // Put a default location latitue and longitude here, this could be where you are located the most
        // and will only be used as a backup if the browser can not get your location details
        
        if(lat == null || lon == null || lat.equals('') || lon.equals('')) 
        {
            // system.debug('lati '+ lat +'longi' + lon );
            lat ='51.096214';
            lon = '3.683153';  
        }  
        // Purchase_Order__c porecType = [Select Ship_From__r.RecordType.Name from Purchase_Order__c where id = :poid];
        System.debug('lat: '+lat);
        System.debug('lon: '+lon);
        recordtype rectypeId=[select id from recordtype where name='Delivery Company'];
        system.debug('recrID: '+rectypeId);
        String queryString = 
            'SELECT Id, Name, Location__Longitude__s, Location__Latitude__s, ' +'ShippingStreet,ShippingCity,ShippingPostalCode,BillingStreet, Phone, BillingCity ' +
            'FROM Account ' +'WHERE Is_active__c = true and Location__Longitude__s!= null and Location__Latitude__s!=null and RecordTypeID = \''+rectypeId.id+'\' AND DISTANCE(Location__c, GEOLOCATION('+lat+','+lon+'), \'km\') < 805'
            + 'ORDER BY DISTANCE(Location__c, GEOLOCATION('+lat+','+lon+'), \'km\') '+ 'LIMIT 3';
        // Run and return the query results 
        deliverycompanies = database.Query(queryString);
        System.debug('deliverycompanies: '+deliverycompanies);
        acc=deliverycompanies[0];
        if(lat1!=null && lon!=null)
            calculateHaversineDistance(deliverycompanies,poid,decimal.valueof(lat),decimal.valueof(lon),decimal.valueof(lat1),decimal.valueof(lon1),deliverycomanyname);
        else
            calculateHaversineDistance(deliverycompanies,poid,decimal.valueof(lat),decimal.valueof(lon),acc.Location__Latitude__s,acc.Location__Longitude__s,deliverycomanyname);     
        return(database.Query(queryString)); 
    }
    
    public static Decimal calculateHaversineDistance(list<account> accList,string poid,Decimal lat1, Decimal lon1, Decimal lat2, Decimal lon2,string deliverycomanyname)
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
            // Double rounded = dDistance.setScale(2, RoundingMode.HALF_UP);
            deliveryComapniesList.put(actemp.Name,Math.Round(dDistance)); 
            system.debug('deliveryComapniesList'+deliveryComapniesList);
        } 
        
        Double dArrivalLat = lat2 * 3.14159 / 180;
        Double dArrivalLong = lon2 * 3.14159 / 180;
        
        Double dDeltaLong = dArrivalLong - dDepartLong;
        Double dDeltaLat = dArrivalLat - dDepartLat; 
        
        // calculate angle using the haversine formula
        Double dHaversineResult = Math.Sin( dDeltaLat / 2 ) * Math.Sin( dDeltaLat / 2 ) 
            + Math.Cos( dDepartLat ) * Math.Cos( dArrivalLat )  
            * Math.Sin( dDeltaLong / 2 ) * Math.Sin( dDeltaLong / 2 );
        
        // calculate distance by multiplying arc-tangent by the planet radius in miles
        Double dDistance = 3958.76 * 2 * Math.Atan2( Math.Sqrt( dHaversineResult ), Math.Sqrt( 1 - dHaversineResult ) );
        
        // Update Distance value in Sales Order and return the distance
        Purchase_Order__c po=new Purchase_Order__c();  
        po.id=poid;
        po.Delivery_Companies_Distance__c='';  
        
        if(deliverycomanyname !=null && dDistance !=null)
        {
            //Suggested Delivery
            po.Delivery_Companies_Distance__c+=' Suggested Delivery:  ';
            po.Delivery_Companies_Distance__c+=deliverycomanyname+' - '+Math.round(dDistance) +' Miles  \n';
            system.debug('po.Delivery_Companies_Distance__c'+ po.Delivery_Companies_Distance__c);
        }
        
        for(string deliverycompanyTemp: deliveryComapniesList.keyset())
        {
            po.Delivery_Companies_Distance__c +=deliverycompanyTemp+' - '+deliveryComapniesList.get(deliverycompanyTemp) +' Miles  \n';
            system.debug('po.Delivery_Companies_Distance__c'+ po.Delivery_Companies_Distance__c);
        }
        po.Nearest_Delivery_Company__c = acc.Name;  
        
        update po; 
        system.debug('po: '+po); 
        system.debug('dDistance'+Math.Round(dDistance)); 
        
        return  Math.Round(dDistance);
    }    
}