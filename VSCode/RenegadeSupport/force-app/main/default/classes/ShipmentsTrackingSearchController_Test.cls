/*
*   Author : Vishnu Bijjula | Kairos Tech
*   Class  : ShipmentsTrackingSearchController_Test
*   Purpose: This test class is to cover the code for ShipmentsTrackingSearchController class.
*/
@isTest
public class ShipmentsTrackingSearchController_Test {
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
        
        Account ac = TestUtil.createCustomerAccount(); 
        
        Account deliveryAccount = TestUtil.createDeliveryAccount();
        
        Account manufactureAccount = TestUtil.createManufacturerAccount(true,false, 'Email');
        
        Account warehouseAccount = TestUtil.createWarehouseAccount();
        
        Trucking_Rule__c trucking = TestUtil.createTruckingRules(manufactureAccount.Id,deliveryAccount.Id);
        
        Products__c configPro = TestUtil.createConfigProduct();
        
        Products__c pro = TestUtil.createSimpleProduct(configPro.id,manufactureAccount.id);
        Products__c bundlePro = TestUtil.createBundleProduct(); 
        Products__c protectionPro = TestUtil.createprotectionProduct();
        
        List<Inventory__c> inventoryList = new List<Inventory__c>();
        inventoryList.add(TestUtil.createInventoryNotInsert(pro.id,5,warehouseAccount.id));
        inventoryList.add(TestUtil.createInventoryNotInsert(configPro.id,5,warehouseAccount.id));
        inventoryList.add(TestUtil.createInventoryNotInsert(bundlePro.id,5,warehouseAccount.id));
        insert inventoryList;
        
        Bundle_Item__c bundleItem = TestUtil.createBundleItemProduct(configPro.id, bundlePro.id);
        
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, deliveryAccount.id, Null);
        
        List<SO_Line_Items__c> items = new List<SO_Line_Items__c>();
        items.add(TestUtil.createsalesOrderLineItemNotInsert(so.id, pro.id, null,null,2));
        items.add(TestUtil.createsalesOrderLineItemNotInsert(so.id, pro.id, configPro.id,null,3));
        items.add(TestUtil.createsalesOrderLineItemNotInsert(so.id, bundlePro.id, null,bundleItem.id,4));
        insert items;
    }
    
    @isTest static void showProductsTest()
    {
        Id soId;
        SO_Line_Items__c Sol;
        SO_Line_Items__c configSol;
        SO_Line_Items__c bundledSol;
        List<SO_Line_Items__c> items = [SELECT Id, Quantity__c, Sales_Order__c FROM SO_Line_Items__c];
        for (SO_Line_Items__c item_i : items) {
            soId = item_i.Sales_Order__c;
            if (item_i.Quantity__c == 2) {
                Sol = item_i;
            }
            else if (item_i.Quantity__c == 3) {
                configSol = item_i;
            }
            else {
                bundledSol = item_i;
            }
        }    
        Purchase_Order__c purchaseOrder1 = TestUtil.createpurchaseorder(soId, 'Manufacturer PO');
        
        List<PO_Line_Items__c> poItems = new List<PO_Line_Items__c>();
        poItems.add(TestUtil.createpoitemNotInsert(purchaseOrder1.id, Sol.id));
        poItems.add(TestUtil.createpoitemNotInsert(purchaseOrder1.id, configSol.id));
        poItems.add(TestUtil.createpoitemNotInsert(purchaseOrder1.id, bundledSol.id));
        insert poItems;
        
        Shipment__c shipment = TestUtil.createshipment(purchaseOrder1.id, soId, 'Ship Via Delivery Company');
        
        Shipment_Line_Item__c shipmentItems = TestUtil.createshipmentItem(shipment.id, poItems[0].id);
        
        Test.startTest();
        PageReference pref = Page.ShipmentsTrackingSearchPage;
        test.setCurrentPage(pref);
        
        ShipmentsTrackingSearchController controller = new ShipmentsTrackingSearchController();
        
        String query = ShipmentsTrackingSearchController.searchPurchaseOrders('','','');
        String query1 = ShipmentsTrackingSearchController.searchPurchaseOrders('Draft','SH-000012','Aico');
        String shipmentList = '[{"attributes":{"type":"Shipment__c","url":"/services/data/v37.0/sobjects/Shipment__c/a0Nq00000023EPqEAM"},"Name":"SH-000010","Delivery_Company_Name__c":"Zenith Bloomfield NJ","Shipment_Status__c":"Deluxed With Issues","Ship_From__c":"Ashley","Id":"a0Nq00000023EPqEAM","RecordTypeId":"012q00000004eQeAAI","Shipment_Line_Itmes__r":{"totalSize":1,"done":true,"records":[{"attributes":{"type":"Shipment_Line_Item__c","url":"/services/data/v37.0/sobjects/Shipment_Line_Item__c/a0Mq0000002w9MNEAY"},"Shipment__c":"a0Nq00000023EPqEAM","Id":"a0Mq0000002w9MNEAY","Name":"SHL-000011","Product_Image_URL__c":"http://rfg-media.s3.amazonaws.com/catalog/product/5/8/58300-28-sd_3.jpg","Product_Name__c":"Acieona Slate Swivel Rocker Recliner","Quantity__c":2,"Shipment_Item_Status__c":"Deluxing with Issue"}]}}]';
        Apexpages.currentPage().getParameters().put('productlistfromparam',shipmentList);
        controller.showProducts();
        Apexpages.currentPage().getParameters().put('productbundlelistfromparam',query);
        //controller.showBundelProducts();
        controller.showpopup();
        controller.closeselectionPopup();
        controller.goToShipmentslist();
        
        query = 'SELECT name,Delivery_Company_Name__c,Delivery_Date_Actual__c,Trucking_Company_name__c,Shipment_Status__c,Ship_From__c,(select id,Name,Product_Image_URL__c,Product_Name__c,Quantity__c,Shipment_Item_Status__c from Shipment_Line_Itmes__r) from Shipment__c ORDER BY Id ASC limit 20';
        String nextPurchase = ShipmentsTrackingSearchController.getNextPurchaseOrders(shipment.id,query);
        String prevPurchase = ShipmentsTrackingSearchController.getPrevPurchaseOrders(null,query);                
        
        System.assertEquals(nextPurchase, prevPurchase);
        Test.stopTest();
    }
}