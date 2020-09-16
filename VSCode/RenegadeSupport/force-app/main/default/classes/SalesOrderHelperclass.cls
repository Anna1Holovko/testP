/*For a Sales order, Retrieve and Map  BillingAddress and Shipping Address values from customerAddress records of a customer  for  given zipcode 
* and street values ,else create a customer address records if given zipcode and street values aren't mapped with zipcode and street values
* in customer address*/

global with sharing class SalesOrderHelperclass 
{
    /*global static void customerBillingShippingAddresses(list<Sales_Order__c> salesOrderBillingList,list<Sales_Order__c> salesOrderShippingList) {
        list<Customer_Addresses__c> caBillinglist = new list<Customer_Addresses__c>();
        list<Customer_Addresses__c> caShippinglist = new list<Customer_Addresses__c>();
        Set<id> accountIds = new Set<Id>();
        System.debug('salesOrderBillingList : '+salesOrderBillingList);
        System.debug('salesOrderShippingList : '+salesOrderShippingList);
        try {
            if(salesOrderBillingList.size() > 0) {
                for(Sales_Order__c SO : salesOrderBillingList) {
                    accountIds.add(SO.Customer_Billing_Address__c);
                }
                if(accountIds.size() > 0) {
                    caBillinglist = [select id,name,Cell__c,Zip_Postal_Code__c,Street_Address__c,City__c,State__c,Account__c,Telephone__c,AddressType__c,Country__c from Customer_Addresses__c where Id In :accountIds];
                    System.debug('caBillinglist : '+caBillinglist);
                    for(Sales_Order__c SO : salesOrderBillingList)
                    {
                        for(Customer_Addresses__c CA : caBillinglist) {
                            if(CA.id == SO.Customer_Billing_Address__c) {
                                CA.Street_Address__c = SO.Billing_Street__c;
                                CA.City__c = SO.Billing_City__c;
                                CA.State__c = SO.Billing_State__c;
                                CA.Zip_Postal_Code__c = SO.Billing_ZipCode__c;
                                CA.Country__c = SO.Billing_Country__c;
                            }
                        }
                    }
                    update caBillinglist;
                } 
            }
            if(salesOrderShippingList.size() > 0) {
                for(Sales_Order__c SO : salesOrderShippingList) {
                    accountIds.add(SO.Customer_shipping_Address__c);
                }
                if(accountIds.size() > 0) {
                    caShippinglist = [select id,name,Cell__c,Zip_Postal_Code__c,Street_Address__c,City__c,State__c,Account__c,Telephone__c,AddressType__c,Country__c from Customer_Addresses__c where Id In :accountIds];
                    System.debug('caShippinglist : '+caShippinglist);
                    for(Sales_Order__c SO : salesOrderShippingList)
                    {
                        for(Customer_Addresses__c CA : caShippinglist) {
                            if(CA.id == SO.Customer_shipping_Address__c) {
                                CA.Street_Address__c = SO.Shipping_Street__c;
                                CA.City__c = SO.Shipping_City__c;
                                CA.State__c = SO.Shipping_State__c;
                                CA.Zip_Postal_Code__c = SO.Shipping_ZipCode__c;
                                CA.Country__c = SO.Shipping_Country__c;
                            }
                        }
                    }
                    update caShippinglist;
                } 
            }
        }
        catch(Exception ex) {
            System.debug('Message :: '+ex.getMessage()+', Cause : '+ex.getCause()+', Line Number : '+ex.getLineNumber());
        }
    }*/
    
    /* global static void CAautopopulateAddress(list<Sales_Order__c> salesorders) {
       Set<Id> CAIds = new Set<Id>();
        try {
            for(Sales_Order__c SO : salesorders) {
                if(SO.Customer_Billing_Address__c != null) {
                    CAIds.add(SO.Customer_Billing_Address__c);
                }
                if(SO.Customer_shipping_Address__c != null) {
                    CAIds.add(SO.Customer_shipping_Address__c);
                }
            }
            System.debug('CAIds : '+CAIds);
            if(CAIds.Size() > 0) {
                Map<Id,Customer_Addresses__c> CAMap = new Map<Id,Customer_Addresses__c>([select id,Name,Cell__c,Zip_Postal_Code__c,Street_Address__c,City__c,State__c,Account__c,Telephone__c,AddressType__c from Customer_Addresses__c where Id In :CAIds Order By Account__c]);
                System.debug('CAMap : '+CAMap);
                for(Sales_Order__c SO : salesorders) {
                    System.debug('CAMap Contains Billing : '+CAMap.containsKey(SO.Customer_Billing_Address__c));
                    System.debug('CAMap Contains Shipping : '+CAMap.containsKey(SO.Customer_shipping_Address__c));
                    if(CAMap.containsKey(SO.Customer_Billing_Address__c)) {
                        SO.Bill_To__c = CAMap.get(SO.Customer_Billing_Address__c).Name;
                        SO.Billing_City__c = CAMap.get(SO.Customer_Billing_Address__c).City__c;
                        SO.Billing_State__c = CAMap.get(SO.Customer_Billing_Address__c).State__c;
                        SO.Billing_Street__c = CAMap.get(SO.Customer_Billing_Address__c).Street_Address__c;
                        SO.Billing_ZipCode__c =CAMap.get(SO.Customer_Billing_Address__c).Zip_Postal_Code__c;
                        SO.Billing_Phone__c = CAMap.get(SO.Customer_Billing_Address__c).Telephone__c;
                        SO.Mobile__c = CAMap.get(SO.Customer_Billing_Address__c).Cell__c;
                    }
                    if(CAMap.containsKey(SO.Customer_shipping_Address__c)) {
                        SO.Ship_to__c = CAMap.get(SO.Customer_shipping_Address__c).Name;
                        SO.Shipping_City__c = CAMap.get(SO.Customer_shipping_Address__c).City__c;
                        SO.Shipping_State__c = CAMap.get(SO.Customer_shipping_Address__c).State__c;
                        SO.Shipping_Street__c = CAMap.get(SO.Customer_shipping_Address__c).Street_Address__c;
                        SO.Shipping_ZipCode__c = CAMap.get(SO.Customer_shipping_Address__c).Zip_Postal_Code__c; 
                        SO.Shipping_Phone__c = CAMap.get(SO.Customer_shipping_Address__c).Telephone__c;
                        SO.Shipping_Mobile__c = CAMap.get(SO.Customer_shipping_Address__c).Cell__c;
                    }
                }
            } 
        }
        catch(Exception ex) {
            System.debug('Message :: '+ex.getMessage()+', Cause : '+ex.getCause()+', Line Number : '+ex.getLineNumber());
        }
    }
    */
    /* Call the apex class of ShippingLocationCallouts whenever new Sales Order is created and existing Sales Order is updated with shipping address*/

    // Moved to SalesOrderTriggerHandler
    /*global static void GeolocationcaluculationInsert(list<Sales_Order__c> newsalesorders)
    {        
        for (Sales_Order__c soObj : newsalesorders)   
        {
            if (soObj.Location__Latitude__s == null && (soObj.Shipping_Street__c!=null || soObj.Shipping_City__c!=null || soObj.Shipping_State__c!=null || soObj.Shipping_ZipCode__c!=null)) 
            {
                ShippingLocationCallouts.getLocation(soObj.Shipping_Street__c,soObj.Shipping_City__c,soObj.Shipping_State__c,soObj.Shipping_ZipCode__c,soObj.id);
            }
        }
    }
    
    global static void GeolocationcaluculationUpdate(list<Sales_Order__c> newsalesorders,map<id,Sales_Order__c> oldSOmap)
    {
        for(Sales_Order__c soObj : newsalesorders)   
        {
            if(soObj.Shipping_Street__c != oldSOmap.get(soObj.id).Shipping_Street__c || soObj.Shipping_City__c != oldSOmap.get(soObj.id).Shipping_City__c ||soObj.Shipping_ZipCode__c != oldSOmap.get(soObj.id).Shipping_ZipCode__c||soObj.Location__Latitude__s == null)
            {
            	try {
                	ShippingLocationCallouts.getLocation(soObj.Shipping_Street__c,soObj.Shipping_City__c,soObj.Shipping_State__c,soObj.Shipping_ZipCode__c,soObj.id);
            	}
            	catch(exception e){}
            }  
        }    
    }*/
}