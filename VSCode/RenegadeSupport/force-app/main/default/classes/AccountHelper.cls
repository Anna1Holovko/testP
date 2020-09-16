public class AccountHelper 
{
    /*@future(callout=true)
    public static void createMagentoAccount(string accountId)
    {
       MagentoCustomerGenerator requestObject;
       MagentoFunctions functionObject=new MagentoFunctions();
       //  MagentoCustomerParser responseObject;
              string responseObject;
        
        
        
        account accountVar = new Account();
        accountVar = [select id,name,First_Name__c,Last_Name__c,Email__c,Magento_Updated_at__c,Magento_Created_at__c,Magento_Account_Id__c,BillingStreet,BillingCity,BillingState,BillingPostalCode, shippingStreet,shippingCity,shippingState,shippingPostalCode,Phone,Mobile__c,Authorize_net_Profile_ID__c from account where id=:accountId];
        
        if(accountVar <> Null && accountVar.Magento_Account_Id__c == null)
        {
            requestObject = new MagentoCustomerGenerator(accountVar.First_Name__c,accountVar.Last_Name__c,accountVar.Email__c,'1','1');
          
            if(requestObject <> null) 
            {
                string request=Json.serialize(requestObject);
                responseObject=functionObject.createNewCustomerInMagento(request);
                if(Test.isRunningTest())
                {
                    responseObject='123';
                   // responseObject.created_at=''+system.Datetime.now();
                    //responseObject.updated_at=''+system.Datetime.now();
                }
                
                if(responseObject<>null)
                {
                     if(responseObject <> Null)
                    {
                      accountVar.Magento_Account_Id__c=responseObject;
                    } 
                    
                    if(responseObject <> Null)
                    {
                        accountVar.Magento_Created_at__c=system.Datetime.now(); 
                    }
                    if(responseObject <> Null)
                    {
                        
                        accountVar.Magento_Updated_at__c=system.Datetime.now(); 
                    }
                    
                  /*  if(responseObject.authnetcim_profile_id <> Null)
                    {
                        accountVar.Authorize_net_Profile_ID__c=responseObject.authnetcim_profile_id;    
                    }*/
                    /*
                    MagentoCustomerAddressGenerator billingAddressRequest=new MagentoCustomerAddressGenerator(accountVar.First_Name__c,accountVar.Last_Name__c,accountVar.BillingStreet,accountVar.BillingCity,accountVar.BillingState,accountVar.BillingPostalCode,'Billing',accountVar.Phone);
                    functionObject.createCustomerAddress(Json.serialize(billingAddressRequest), responseObject);
                    system.debug('billingAddressRequest '+billingAddressRequest);
                    
                    MagentoCustomerAddressGenerator shippingAddressRequest=new MagentoCustomerAddressGenerator(accountVar.First_Name__c,accountVar.Last_Name__c,accountVar.shippingStreet,accountVar.shippingCity,accountVar.shippingState,accountVar.shippingPostalCode,'Shipping',accountVar.Phone);
                    functionObject.createCustomerAddress(Json.serialize(shippingAddressRequest), responseObject);
                     system.debug('shippingAddressRequest '+shippingAddressRequest);
                }
                
                database.update(accountVar);
            }
        }
    }*/
}