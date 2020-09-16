/*
*   Author : Vishnu Bijjula | Kairos Tech
*   Class  : purchaseOrderSearchController_Test
*   Purpose: This class is to code coverage the purchaseOrderSearchController.
*/
@isTest
public class purchaseOrderSearchController_Test {
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
    
    static testMethod void showProductsTest()
    {
        Id manufactureId = [SELECT Id FROM Account WHERE Name = 'Manufacture Account' LIMIT 1].Id;
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
        
        Purchase_Order__c purchaseOrder = TestUtil.createpurchaseorder(soId, 'Manufacturer PO');
        purchaseOrder.Ship_From__c = manufactureid;
        update purchaseOrder;
        Purchase_Order__c purchaseOrderList = [SELECT Id,Name from Purchase_Order__c where id=:purchaseOrder.id];
        
        PO_Line_Items__c poLineItems = TestUtil.createpoitem(purchaseOrder.id, Sol.id);
        
        Test.startTest();
        PageReference pref = Page.purchaseOrderSearchPage;
        test.setCurrentPage(pref);
        
        purchaseOrderSearchController controller = new purchaseOrderSearchController();
        
        string query=purchaseOrderSearchController.searchPurchaseOrders('On Order',purchaseOrderList.name, 'Manufacture Account');
        Apexpages.currentPage().getParameters().put('productlistfromparam',query);
        controller.showProducts();
        Apexpages.currentPage().getParameters().put('productbundlelistfromparam',query);
        controller.showpopup();
        controller.closeselectionPopup();
        
        query=  'SELECT Id,Load_Date__c,Manufacturer_Name__c,Name,Sales_Order__r.Name,Status__c,Total_Items_Ordered__c,(select id,name,Product_Image_URL__c,Product__c,Quantity__c,So_Line_Item_Number__c,Product_SKU__c from PO_Line_Item__r) from Purchase_Order__c';
        purchaseOrderSearchController.getNextPurchaseOrders(null,query);
        String prevPurchase = purchaseOrderSearchController.getPrevPurchaseOrders(null,query);
        controller.showBundelProducts();
        controller.goToPurchaseorderList();
        Test.stopTest();
    }
}