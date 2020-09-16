@isTest
public class BulkPOcreationCntrTest {
    
    @isTest
    static void bulkPOcreationTest(){
        Account customerAccount = TestUtil.createCustomerAccount(); 
        Account deliveryAccount = TestUtil.createDeliveryAccount(); 
        Account manufactureAccount = TestUtil.createManufacturerAccount(true, false, 'Email');
        customerAccount.Number_of_Opened_Sales_Orders__c = 0;
        update customerAccount;
        
        Sales_Order__c salesOrder = TestUtil.createsalesOrder(customerAccount.id, deliveryAccount.id, Null);
        Sales_Order__c[] soList = [SELECT Id, Eligible_for_PO_bulk_creation__c, Name FROM Sales_Order__c];
        System.debug('soList '+soList);
        
        Test.startTest();
        Test.setCurrentPage(Page.BulkPOcreationPage);
        ApexPages.StandardSetController sc = new ApexPages.StandardSetController(soList);   
        BulkPOcreationCntr controller = new BulkPOcreationCntr(sc);
        sc.setSelected(soList);
        controller = new BulkPOcreationCntr(sc);
        controller.getCarrierOption();
        controller.userConfirmation();
        controller.checkAndUpdate();
        System.assertEquals(Label.Check_the_following_entries, controller.message);        
        Test.StopTest();
    }
}