/*
*   Author : Vishnu Bijjula & Sowdhanya Karri | Kairos Tech
*   Class  : productSearchController_Test
*   Purpose: This test class is to cover the code coverage for productSearchController class.
*/
@isTest
public class productSearchController_Test {
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
        Products__c protectionPro = TestUtil.createprotectionProduct();
        
        Inventory__c inventoryItem = TestUtil.createInventory(pro.id,5,warehouseAccount.id);
        Inventory__c configinventoryItem = TestUtil.createInventory(configPro.id,5,warehouseAccount.id);
        Inventory__c bundleinventoryItem = TestUtil.createInventory(bundlePro.id,5,warehouseAccount.id);
        
        Bundle_Item__c bundleItem = TestUtil.createBundleItemProduct(configPro.id, bundlePro.id);
        
        list<products__c> proList = [Select id from products__c];
        map<string,list<products__c>> configlist = new map<string,list<products__c>>();
        configlist.put(bundleItem.id,proList);
        
        Test.startTest();
        PageReference pref = Page.productSearchPage;
        test.setCurrentPage(pref);
        
        productSearchController controller = new productSearchController();
        productSearchController.BundleItemWrapper BW = new productSearchController.BundleItemWrapper(bundleItem,configlist);
            
        String query = productSearchController.searchProducts(pro.SKU__c,pro.name,manufactureAccount.name);
        
        String productList = '[{"attributes":{"type":"Products__c","url":"/services/data/v37.0/sobjects/Products__c/a0Gq000000395Z9EAI"},"Id":"a0Gq000000395Z9EAI","RecordTypeId":"012q00000004eQXAAY","Type__c":"Simple","Sales_Price__c":2400.00,"Regular_Price__c":2599.00,"Special_Price_Hidden__c":0.00,"Select_Manufacturer__c":"001q000000QWaQpAAL","Product_Image_URL__c":"http://rfg-media.s3.amazonaws.com/catalog/product/b/e/bellacera-silo-chest-main-38070-45_2.jpg","Name":"Bella Cera 9-Drawer Chest","SKU__c":"AIC-38070-45","RecordType":{"attributes":{"type":"RecordType","url":"/services/data/v37.0/sobjects/RecordType/012q00000004eQXAAY"},"Name":"Simple","Id":"012q00000004eQXAAY"},"Select_Manufacturer__r":{"attributes":{"type":"Account","url":"/services/data/v37.0/sobjects/Account/001q000000QWaQpAAL"},"Name":"Aico","Id":"001q000000QWaQpAAL","RecordTypeId":"012q00000004eQ7AAI"}}]';
        Apexpages.currentPage().getParameters().put('productlistfromparam',productList);
        controller.showProducts();
        
        String bundle = productSearchController.getOptions(bundlePro.id);
        Apexpages.currentPage().getParameters().put('productbundlelistfromparam',bundle);
        
        controller.closeselectionPopup();
        
        query = 'select id,recordtype.name,Type__c,Sales_Price__c,Regular_Price__c,Special_Price_Hidden__c,Select_Manufacturer__r.name,Product_Image_URL__c,recordtypeid,Name,SKU__c,(select id,Product_Image_URL__c,Special_Price_Hidden__c ,Tier_Price_For_Bundle__c,Name,SKU__c,Regular_Price__c,Sales_Price__c,Special_Price__c,Image__c,Special_Price_From_Date__c,Special_Price_To_Date__c,Master_Products__c from Products__r) from Products__c where Master_Products__c=null ';
        String getOption = productSearchController.getOptions(pro.id);
        
        String nextPurchase = productSearchController.getNextProducts(pro.id,query);
        String prevPurchase = productSearchController.getPrevProducts(null,query);  
        
        controller.showBundelProducts();
        controller.goToProductslist();
        Test.stopTest();
        System.assert(prevPurchase!=null);
    }
}