@isTest
private class PurchaseOrderCreationBatchTest {
    public static Google_API__c googleAPI;
    public static MagentoAuth__c magentoAuth;
    public static MagentoTokens__c magentoToken;
    
    @testSetup static void setUp() {
        magentoAuth = new MagentoAuth__c(Name='MagentoOAuth', AccessTokenURL__c='http://stage01.colemanfurniture.com/oauth/token',
                                        AuthorizationURL__c='http://stage01.colemanfurniture.com/admin/oauth_authorize',
                                        CallbackURL__c='https://c.cs41.visual.force.com/apex/CompleteAuth', password__c='rfgstage0987',
                                        ClientKey__c='ulzh3hgcx5pcmfkvbcd7x369bxfqjzmp',ClientSecret__c='p1khnuudmoowwiq1avhx8cjj9g573j70',
                                        RequestTokenURL__c='http://stage01.colemanfurniture.com/oauth/initiate/',
                                        RestEndpoint__c='http://stage01.colemanfurniture.com/api/rest',username__c='stage');
        insert magentoAuth;
        
        magentoToken = new MagentoTokens__c(Name='OAuth', isAccess__c=false,owner__c='00555000000IFiGAAW',
                                           secret__c='vrz4dsnqxlf7uj3cq9qs89meferbyf5g', token__c='mbxbk9y7ylsx9kh4lay7y1fvmqursrcb');
        
        insert magentoToken;
        
        googleAPI = new Google_API__c(Name='Google API',Key__c='AIzaSyCAmP-yM5hc67O4stT-VyzMRmDTaVYfXzQ');
        insert googleAPI;
    }

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
        
        Sales_Order__c salesOrder = TestUtil.createsalesOrder(customerAccount.id, deliveryAccount.id, Null);
        salesOrder.Create_PO__c = true;
        salesOrder.Carrier__c = 'UPS';
        salesOrder.Requested_Arrival_Date__c = Date.today();
        salesOrder.Check_for_Fraud__c = false;
        salesOrder.Payment_Method__c = 'Credit Card';
        salesOrder.Payment_Status__c = 'Authorized';
        salesOrder.Order_Status__c = 'Out for Delivery';
        salesOrder.Manufacturer__c = manufactureAccount.Id;
        update salesOrder;
        
        SO_Line_Items__c bundleSol = TestUtil.createsalesOrderLineItem(salesOrder.id, bundlePro.id, null,null,3);
        
        SO_Line_Items__c bundledSol = TestUtil.createsalesOrderLineItem(salesOrder.id, bundlePro.id, null,bundleItem.id,2);

        Test.startTest();
        database.executeBatch(new PurchaseOrderCreationBatch(), 1 );
        Test.stopTest();
        String jobId = System.schedule('PurchaseOrderCreationBatchTestJob',
                                        '0 0 0 15 3 ?', 
                                       new PurchaseOrderCreationBatch()); 
    }
}