public with sharing class getDeliverycompanyHelper 
{
    public static void salesorderDeliverycompany(list<Sales_Order__c> soMap,map<id,Sales_Order__c> soOldMap)
    {
        list<string> soZipcodes=new list<string>();
        
        map<String,Shipping_Zip_Codes__c> shippingZipcodemap = new map<String,Shipping_Zip_Codes__c>();
        
        for(Sales_Order__c oneSO : soMap)
        {
            if(soOldMap !=null)
            {
                if(oneSO.Shipping_ZipCode__c != Null && oneSO.Shipping_ZipCode__c != soOldMap.get(oneSO.id).Shipping_ZipCode__c && oneSO.Shipping_ZipCode__c.length() >= 5)
                {
                    soZipcodes.add(oneSO.Shipping_ZipCode__c.trim().substring(0, 5)); 
                } 
            }
            else
            {
                if(oneSO.Shipping_ZipCode__c != Null && oneSO.Shipping_ZipCode__c.length() >= 5)
                {
                    soZipcodes.add(oneSO.Shipping_ZipCode__c.trim().substring(0, 5)); 
                } 
            }
        }
        
        try
        {
            System.debug('soZipcodes: '+soZipcodes);
            if(soZipcodes.size()>0)
            {
                for(Shipping_Zip_Codes__c shippingZipCode: [SELECT City__c,Delivery_Company_Account__c,Id, Delivery_Company_Account__r.Email__c,Name,State__c,Zip_Code__c FROM Shipping_Zip_Codes__c where Delivery_Company_Account__c !=null and Zip_Code__c in : soZipcodes])
                {
                    shippingZipcodemap.put(shippingZipCode.Zip_Code__c,shippingZipCode);
                }
                System.debug('shippingZipcodemap: '+shippingZipcodemap);
                
                for(Sales_Order__c oneSO : soMap) 
                {
                    System.debug('shippingZipcodemap.containsKey(oneSO.Shipping_ZipCode__c.trim()): '+shippingZipcodemap.containsKey(oneSO.Shipping_ZipCode__c.trim().substring(0, 5)));
                    if(shippingZipcodemap.containsKey(oneSO.Shipping_ZipCode__c.trim().substring(0, 5)))
                    {
                        oneSO.Delivery_Company__c = shippingZipcodemap.get(oneSO.Shipping_ZipCode__c.trim().substring(0, 5)).Delivery_Company_Account__c;
                        oneSO.Delivery_company_Email__c = shippingZipcodemap.get(oneSO.Shipping_ZipCode__c.trim().substring(0, 5)).Delivery_Company_Account__r.Email__c;
                        System.debug('Delivery_Company__c: '+oneSO.Delivery_Company__c);
                    }
                    else
                    {
                        oneSO.Delivery_Company__c =null;
                        oneSO.Delivery_company_Email__c = null;
                    }
                }
            }
        }
        catch(Exception Ex)
        {
            System.debug('Exception Ex: '+ex.getmessage()+' Line no. '+ex.getLineNumber()+' Cause: '+ex.getCause());
        }
    }
}