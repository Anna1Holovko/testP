/*
*   Author : Vishnu Bijjula & Sowdhanya Karri | Kairos Tech
*   Class  : SalesOrderSearchController_Test
*   Purpose: This test class is to cover the code coverage for SalesOrderSearchController class.
*/
@isTest
public class SalesOrderSearchController_Test {
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
        TestUtil.createprotectionProduct();
    }
    
    private static Products__c getprotectionPro() {
        return [SELECT Id, recordtype.Name FROM Products__c where recordtype.Name='Protection Plan' LIMIT 1];
    }
    
    @isTest static void showProductsTest()
    {
        Account ac = TestUtil.createCustomerAccount(); 
        
        Account deliveryAccount = TestUtil.createDeliveryAccount();
        
        Account manufactureAccount = TestUtil.createManufacturerAccount(true,false, 'Email');
        
        Account warehouseAccount = TestUtil.createWarehouseAccount();
        
        Trucking_Rule__c trucking = TestUtil.createTruckingRules(manufactureAccount.Id,deliveryAccount.Id);
        
        Products__c configPro = TestUtil.createConfigProduct();
        
        Products__c pro = TestUtil.createSimpleProduct(configPro.id,manufactureAccount.id);
        Products__c bundlePro = TestUtil.createBundleProduct(); 
        Products__c protectionPro = getprotectionPro();
        
        Inventory__c inventoryItem = TestUtil.createInventory(pro.id,5,warehouseAccount.id);
        Inventory__c configinventoryItem = TestUtil.createInventory(configPro.id,5,warehouseAccount.id);
        Inventory__c bundleinventoryItem = TestUtil.createInventory(bundlePro.id,5,warehouseAccount.id);
        
        Bundle_Item__c bundleItem = TestUtil.createBundleItemProduct(configPro.id, bundlePro.id);
        
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, deliveryAccount.id, Null);
        so.Email__c = 'testmail@salesforce.com';
        so = [Select id,Order_Status__c,name,Customer_Name__c,Email__c from Sales_Order__c];
        
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,2);
        
        SO_Line_Items__c configSol = TestUtil.createsalesOrderLineItem(so.id, pro.id, configPro.id,null,2);
        SO_Line_Items__c mainBundledSol = TestUtil.createsalesOrderLineItem(so.id, bundlePro.id, null,null,2);
        
        SO_Line_Items__c bundledSol = TestUtil.createsalesOrderLineItem(so.id, bundlePro.id, null,bundleItem.id,2);
        Test.startTest();
        PageReference pref = Page.SalesOrderSearchPage;
        test.setCurrentPage(pref);
        
        SalesOrderSearchController controller = new SalesOrderSearchController();
        
        String query = SalesOrderSearchController.searchProducts('','','','');
        String getquery = SalesOrderSearchController.searchProducts(''+so.Order_Status__c,''+so.name,''+so.Customer_Name__c,''+so.Email__c);
        
        controller.OptionsId = so.id;
        controller.getSoRelatedList();
        
        Apexpages.currentPage().getParameters().put('productlistfromparam',query);
        controller.showProducts();
        Apexpages.currentPage().getParameters().put('productbundlelistfromparam',query);
        controller.showpopup();
        controller.closeselectionPopup();
        
        String productsJSON = '[{"attributes":{"type":"Products__c","url":"/services/data/v37.0/sobjects/Products__c/a0Gq000000395Z9EAI"},"Id":"a0Gq000000395Z9EAI","RecordTypeId":"012q00000004eQXAAY","Type__c":"Simple","Sales_Price__c":2400.00,"Regular_Price__c":2599.00,"Special_Price_Hidden__c":0.00,"Select_Manufacturer__c":"001q000000QWaQpAAL","Product_Image_URL__c":"http://rfg-media.s3.amazonaws.com/catalog/product/b/e/bellacera-silo-chest-main-38070-45_2.jpg","Name":"Bella Cera 9-Drawer Chest","SKU__c":"AIC-38070-45","RecordType":{"attributes":{"type":"RecordType","url":"/services/data/v37.0/sobjects/RecordType/012q00000004eQXAAY"},"Name":"Simple","Id":"012q00000004eQXAAY"},"Select_Manufacturer__r":{"attributes":{"type":"Account","url":"/services/data/v37.0/sobjects/Account/001q000000QWaQpAAL"},"Name":"Aico","Id":"001q000000QWaQpAAL","RecordTypeId":"012q00000004eQ7AAI"},storedQuery}]';
        Apexpages.currentPage().getParameters().put('productlistfromparam',productsJSON);
        controller.showProducts();
        
        query = 'select id,name,Magento_order_No__c,Order_Date__c,Email__c,Bill_To__c,Ship_to__c,Payment_Status__c,Sales_Rep_Name__c,Grand_Total__c,order_status__c,(select id,Name,ProductImageUrl__c,Product_Name__c,Manufacturer__c,Item__c,UnitPrice__c from SO_Line_Items__r) from sales_order__c';
        String nextPurchase = SalesOrderSearchController.getNextProducts(so.id,query);
        String prevPurchase = SalesOrderSearchController.getPrevProducts(null,query);  
        
        controller.goTosalesorderlist();
        
        Test.stopTest();
        //System.assertEquals(null, nextPurchase);
    }
}