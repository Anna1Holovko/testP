/* Calculate the longitude and latitude based on account Shipping address and display the value in Location field */

public class AccountGeolocation 
{

    @future (callout=true)  // future method needed to run callouts from Triggers
    static public void updateLocations(Map<Id, Boolean> accountIdToIsSameAddressMap){
        Map<Id, Account> accountMap = new Map<Id, Account>([ SELECT  ShippingStreet, 
                                                ShippingCity, 
                                                ShippingState, 
                                                ShippingPostalCode, 
                                                ShippingCountry 
                                        FROM Account 
                                        WHERE Id IN: accountIdToIsSameAddressMap.keySet()]);
        
        for(Id id_i : accountIdToIsSameAddressMap.keySet()){
            Account account_i = accountMap.get(id_i);
            String shippingaddress = '';
            if (account_i.ShippingStreet!= null)
                shippingaddress += account_i.ShippingStreet +', ';
            if (account_i.ShippingCity!= null) 
                shippingaddress += account_i.ShippingCity +', ';
            if (account_i.ShippingState!= null) 
                shippingaddress += account_i.ShippingState +' ';
            if (account_i.ShippingPostalCode != null)
                shippingaddress += account_i.ShippingPostalCode +', ';
            if (account_i.ShippingCountry != null)  
                shippingaddress += account_i.ShippingCountry;
            

            GeolocationManager.Geolocation geoData = GeolocationManager.obtainGeolocationData(shippingaddress);
            if(geoData != null && geoData.lat != null){
                account_i.Location__Latitude__s = geoData.lat;
                account_i.Location__Longitude__s = geoData.lon;
                if (accountIdToIsSameAddressMap.get(id_i)){
	                account_i.BillingLocation__Latitude__s = geoData.lat;  
	                account_i.BillingLocation__Longitude__s = geoData.lon; 
                }
            }
        }

        update accountMap.values();
    }
}