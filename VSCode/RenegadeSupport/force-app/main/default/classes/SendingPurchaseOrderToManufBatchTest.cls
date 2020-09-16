@isTest
public with sharing class SendingPurchaseOrderToManufBatchTest {
    @isTest
    static void testBatch(){
        Account customerAccount = TestUtil.createCustomerAccount(); 
        Account deliveryAccount = TestUtil.createDeliveryAccount();
        Account manufactureAccount = TestUtil.createManufacturerAccount(true,false, 'Email');
        Account warehouseAccount = TestUtil.createWarehouseAccount();
        Account truckingAccount = TestUtil.createTruckingAccount();
        truckingAccount.Name = 'Watkins';
        update truckingAccount;
        
        Products__c configPro = TestUtil.createConfigProduct();
        Products__c simplePro = TestUtil.createSimpleProduct(configPro.id,manufactureAccount.id);
        Products__c bundlePro = TestUtil.createBundleProduct();
        bundlePro.Select_Manufacturer__c = manufactureAccount.id;
        update bundlePro;
        
        Inventory__c bundleinventoryItem = TestUtil.createInventory(bundlePro.id,5,warehouseAccount.id);
        
        Bundle_Item__c bundleItem = TestUtil.createBundleItemProduct(configPro.id, bundlePro.id);
		Payment_Method__c paymentMethod = TestUtil.createpaymentMethod(customerAccount.Id, 'Manual payment');
        
        Sales_Order__c salesOrder = TestUtil.createsalesOrder(customerAccount.id, deliveryAccount.id, paymentMethod.Id);

        
        SO_Line_Items__c bundleSol = TestUtil.createsalesOrderLineItem(salesOrder.id, bundlePro.id, null,null,3);
        
        SO_Line_Items__c bundledSol = TestUtil.createsalesOrderLineItem(salesOrder.id, bundlePro.id, null,bundleItem.id,2);

        /*Purchase_Order__c purchaseOrderEDI = TestUtil.createpurchaseorder(salesOrder.Id, 'Manufacturer PO');
        purchaseOrderEDI.Status__c = 'Draft';
        purchaseOrderEDI.Order_Communication_Type__c = 'EDI';
        purchaseOrderEDI.EDI_Status__c = null;
        */
        Purchase_Order__c purchaseOrderEmail = TestUtil.createpurchaseorder(salesOrder.Id, 'Manufacturer PO');
        purchaseOrderEmail.Status__c = 'Draft';
        purchaseOrderEmail.Order_Communication_Type__c = 'Email';
		
        update new List<Purchase_Order__c>{purchaseOrderEmail};
        
        Test.startTest();
            database.executeBatch(new SendingPurchaseOrderToManufacturerBatch(), 2);
        Test.stopTest();
        String jobId = System.schedule('SendingPurchaseOrderToManufacturerBatchTestJob',
                                        '0 0 0 15 3 ?', 
                                       new SendingPurchaseOrderToManufacturerBatch()); 
        System.assertEquals(true, [SELECT Send_Email_To_Manufacturer_WF__c FROM Purchase_Order__c WHERE ID = :purchaseOrderEmail.Id].Send_Email_To_Manufacturer_WF__c);
    }
}