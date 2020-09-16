@isTest
private class SetSOManufacturerBatchTest {
    @isTest
    static void testBatch(){
        google_API__c googleAPI = new Google_API__c(Name='Google API',Key__c='AIzaSyCAmP-yM5hc67O4stT-VyzMRmDTaVYfXzQ');
        insert googleAPI;
        
        Account ac = TestUtil.createCustomerAccount(); 
        Account manufactureAccount = TestUtil.createManufacturerAccount(true,false, 'Email');
        
        Products__c Pro = TestUtil.createConfigProduct();
        pro.Select_Manufacturer__c = manufactureAccount.Id;
        update pro;

        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, Null, Null);
        so.Shipping_ZipCode__c = '10101';
        update so;

        Shipping_Zip_Codes__c zipCode = new Shipping_Zip_Codes__c();
        zipCode.Zip_Code__c = '10101';
        zipCode.TaxJar_Sales_Tax__c = 10;
        insert zipCode;
        
        Purchase_Order__c po = TestUtil.createpurchaseorder(so.id,'Manufacturer PO');
                
        SO_Line_Items__c Sol = new SO_Line_Items__c(Sales_Order__c = so.id,
                                                                   Products__c = pro.id,
                                                                   Config_Product__c = null,
                                                                   Bundle_Item__c = null,
                                                                   Item__c = 'Processing',
                                                                   Quantity__c = 5,
                                                                   Price__c = 20,
                                                                   Custom_Price__c = 0,
                                                                   Quantity_Invoiced__c = 0,
                                                                   Quantity_Refunded__c = 0);
        insert Sol;
        Test.startTest();
        database.executeBatch(new SetSOManufacturerBatch(), 1 );
        Test.stopTest();
    }
}