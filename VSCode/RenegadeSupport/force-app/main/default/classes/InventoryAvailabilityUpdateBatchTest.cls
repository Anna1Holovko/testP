@isTest
class InventoryAvailabilityUpdateBatchTest {
    
    @TestSetup
    static void setup(){
        insert new List<Inventory__c> {new Inventory__c(Quantity__c = 1, Product_condition__c = 'Resellable'),
            							new Inventory__c(Quantity__c = 0, Product_condition__c = 'Resellable'),
            							new Inventory__c(Quantity__c = 42, Product_condition__c = 'Consignment')
            							};                        
    }
    
    @isTest
    static void testBatch() {
        List<String> productConditionList = new List<String> { 'Resellable', 'Unopened' };
        Test.startTest();
        	Database.executeBatch( new InventoryAvailabilityUpdateBatch(), 1);
        Test.stopTest(); 
        System.assertEquals(1, [SELECT id FROM Inventory__c WHERE Quantity__c > 0 AND Product_condition__c IN :productConditionList].size());
        System.assertEquals(2, [SELECT id FROM Inventory__c WHERE Quantity__c = 0 OR Product_condition__c NOT IN :productConditionList].size());
    }
    
}