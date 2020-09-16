@isTest
private class AccountTriggerHandlerTest {
    static testMethod void insertAccount() {
        Magento_Integration_Setting__c setting = new Magento_Integration_Setting__c(API_User_ID__c = 'sdf', Oauth_version__c = '1.0', Oauth_token__c = '9z0finib6b54efwvaoysys0mf355qxh0',
                                                                                    Oauth_signature_method__c = 'HMAC-SHA1', Oauth_signature__c = '6rPjBUYswr2Ri43mAn/Vg7gMZR4=', Oauth_nonce__c = 'fOIwp7',
                                                                                    Oauth_consumer_key__c = 'ulzh3hgcx5pcmfkvbcd7x369bxfqjzmp', End_Point__c ='http://stage01.colemanfurniture.com/api/rest/salesforce/customer');
        insert setting;
        Account a = new Account(Name = 'Mantch', Email__c = 'mkurant@greencloudus.com', First_Name__c = 'Mantch',
                                Last_Name__c = 'Kurant', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId());
        insert a;
        
        Account ac = TestUtil.createDeliveryAccount();
        
        insert new Shipping_Zip_Codes__c(Zip_Code__c = '10101',
                                         TaxJar_Sales_Tax__c = 10,
                                         Delivery_Company_Account__c = ac.Id);
        
        Account ac2 = TestUtil.createCustomerAccount();
        Customer_Addresses__c customerBillingAddress = TestUtil.CustomerAddress(ac2.Id,'Primary Billing Address','Billing Account');
        Customer_Addresses__c customerShippingAddress = TestUtil.CustomerAddress(ac2.Id,'Primary Shipping Address','Shipping Account');
        SalesOrderTriggerHandler.emailSynchronized = true;
        Sales_Order__c so = new Sales_Order__c(Order_Status__c='Processing',
                                               Payment_Status__c='Processing',
                                               Customer_Name__c = ac2.Id,
                                               Email__c = 'test@email.com',
                                               Customer_Billing_Address__c = customerBillingAddress.id,
                                               Customer_shipping_Address__c = customerShippingAddress.id,
                                               Billing_Street__c = 'Plymouth meeting hall',
                                               Billing_ZipCode__c = '19462',
                                               Billing_Phone__c = '9142358645',
                                               Ship_to__c = 'Renegade Renegade',
                                               Send_ETA_notification_to_customer__c = true,
                                               Send_to_a_delivery_company__c = true,
                                               Bill_to__c = 'Renegade Renegade',
                                               Shipping_Street__c = '210 E Trade Street',
                                               Shipping_City__c = 'NY',
                                               Shipping_State__c = 'New York',
                                               Shipping_ZipCode__c = '10101',
                                               Shipping_Phone__c = '9144563521',
                                               Location__Latitude__s = 33.33333,
                                               Location__Longitude__s = 33.3333,
                                               Order_Date__c = System.now(),
                                               Delivery_Company__c = ac.Id,
                                               Delivery_company_Email__c = 'wrong@email.com');
        insert so;
        system.debug([SELECT Delivery_company_Email__c FROM Sales_Order__c WHERE Id =: so.Id][0].Delivery_company_Email__c);
        
        Test.startTest();
        
        ac.Email__c = 'different@email.com';
        update ac;
        
        Test.stopTest();
        system.debug([SELECT Delivery_company_Email__c FROM Sales_Order__c WHERE Id =: so.Id][0].Delivery_company_Email__c);
        
        System.assertEquals([SELECT Delivery_company_Email__c FROM Sales_Order__c WHERE Id =: so.Id][0].Delivery_company_Email__c, [SELECT Email__c FROM Account WHERE Id =: ac.Id][0].Email__c);
    }
}