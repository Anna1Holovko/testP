/* Calculate the longitude and latitude based on account Billing address and display the value in BillingLocation field on Account */

public class AccountBillingGeolocation{




    @future (callout=true)  // future method needed to run callouts from Triggers
    static public void updateLocations(Map<Id, Boolean> accountIdToIsSameAddressMap){
        Map<Id, Account> accountMap = new Map<Id, Account>([ SELECT  BillingStreet, 
                                                BillingCity, 
                                                BillingState, 
                                                BillingPostalCode, 
                                                BillingCountry 
                                        FROM Account 
                                        WHERE Id IN: accountIdToIsSameAddressMap.keySet()]);
        
        for(Id id_i : accountIdToIsSameAddressMap.keySet()){
            Account account_i = accountMap.get(id_i);
            String billingAddress = '';
            if (account_i.BillingStreet!= null)
                billingAddress += account_i.BillingStreet +', ';
            if (account_i.BillingCity!= null) 
                billingAddress += account_i.BillingCity +', ';
            if (account_i.BillingState!= null) 
                billingAddress += account_i.BillingState +' ';
            if (account_i.BillingPostalCode != null)
                billingAddress += account_i.BillingPostalCode +', ';
            if (account_i.BillingCountry != null)  
                billingAddress += account_i.BillingCountry;
            

            GeolocationManager.Geolocation geoData = GeolocationManager.obtainGeolocationData(billingAddress);
            if(geoData != null && geoData.lat != null){
                account_i.BillingLocation__Latitude__s = geoData.lat;
                account_i.BillingLocation__Longitude__s = geoData.lon;
                if (accountIdToIsSameAddressMap.get(id_i)){
	                account_i.Location__Latitude__s = geoData.lat;  
	                account_i.Location__Longitude__s = geoData.lon; 
                }
            }
        }

        update accountMap.values();
    }
}