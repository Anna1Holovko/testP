@isTest
private class AccountDataFixBatchTest {
    
    @isTest
    static void testBatch(){
        Opened_SO_statuses__c openedSOstatusesSetting = new Opened_SO_statuses__c();
        openedSOstatusesSetting.Name = 'Processing';
        insert openedSOstatusesSetting;
        
        Account acc = TestUtil.createCustomerAccount();
        Sales_Order__c so = TestUtil.createsalesOrder(acc.id, Null, Null);
        
        so.Order_Status__c = 'Processing';
        update so;

        acc.Number_of_Opened_Sales_Orders__c = null;
        update acc;
        
        Test.startTest();
        Date dateFrom = Date.newInstance(2020, 1, 1);
        Database.executeBatch(new AccountDataFixBatch(dateFrom), 1 );
        Test.stopTest();
    }
}