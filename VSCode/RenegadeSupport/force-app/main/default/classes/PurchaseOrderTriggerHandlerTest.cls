@istest
public with sharing class PurchaseOrderTriggerHandlerTest {
    public static testMethod void testTrigger()
    {
        Account ac = TestUtil.createCustomerAccount();  
        Account manufactureAccount = TestUtil.createManufacturerAccount(true,false, 'Email');
        
        Contact con = TestUtil.setupCustomerContact('Test', 'Name', manufactureAccount.id);
        
        Products__c Pro = TestUtil.createConfigProduct();
        
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, Null, Null);
        
        Recordtype poRecordType = [SELECT Id FROM RecordType WHERE SObjectType = 'Purchase_Order__c' and Name = 'Manufacturer PO'];
        
        Purchase_Order__c po = new Purchase_Order__c(Sales_Order__c = so.id,Status__c = 'On Order',Tracking_Number__c='1234', Carrier__c = '', Parts_PO__c = true, Replacement_PO__c = true);
        insert po;
        PO.Ship_From__c = manufactureAccount.id;
        PO.Carrier__c = 'LTL';
        update PO;
        
        po = [SELECT Id, Magento_Order_Number_Searchable__c, Magento_order_No__c FROM Purchase_Order__c WHERE Id =: po.Id];
        System.assertEquals(po.Magento_Order_Number_Searchable__c, po.Magento_order_No__c);
    }
}