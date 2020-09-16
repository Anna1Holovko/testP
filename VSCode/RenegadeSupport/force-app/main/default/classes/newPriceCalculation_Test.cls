/*
*   Author : Vishnu Bijjula | Kairos Tech
*   Class  : newPriceCalculation_Test
*   Purpose: This class is to code coverage the newPriceCalculation.
*/
@isTest
public class newPriceCalculation_Test {
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
    
	static testMethod void testapprovalProcessCalculation()
    {
        Account ac = TestUtil.createCustomerAccount(); 
        
        Account deliveryAccount = TestUtil.createDeliveryAccount();
        Account manufactureAccount = TestUtil.createManufacturerAccount(true,false, 'Email');
        Account warehouseAccount = TestUtil.createWarehouseAccount();
        
        Trucking_Rule__c trucking = TestUtil.createTruckingRules(manufactureAccount.Id,deliveryAccount.Id);
        
        Products__c configPro = TestUtil.createConfigProduct();
        configPro.Special_Price_From_Date__c = System.today();
        configPro.Special_Price_To_Date__c = System.today();
        configPro.Special_Price__c = 100;
        update configPro;
        
        Products__c pro = TestUtil.createSimpleProduct(configPro.id,manufactureAccount.id);
        pro.Special_Price_From_Date__c = System.today();
        pro.Special_Price_To_Date__c = System.today();
        pro.Special_Price__c = 100;
        update pro;
                
        Products__c bundlePro = TestUtil.createBundleProduct(); 
        Products__c protectionPro = TestUtil.createprotectionProduct();
        
        Inventory__c inventoryItem = TestUtil.createInventory(pro.id,5,warehouseAccount.id);
        Inventory__c configinventoryItem = TestUtil.createInventory(configPro.id,5,warehouseAccount.id);
        Inventory__c bundleinventoryItem = TestUtil.createInventory(bundlePro.id,5,warehouseAccount.id);
        
        Bundle_Item__c bundleItem = TestUtil.createBundleItemProduct(configPro.id, bundlePro.id);
        
        Promotions__c promotion = TestUtil.createPromotion('Promo Code', '');
        Promotions__c promotionList = [Select id, Type__c from Promotions__c Limit 1];
        
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, deliveryAccount.id, null);
        so.Promotion__c = promotion.id;
        update so;
        
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,2);
        SO_Line_Items__c configSol = TestUtil.createsalesOrderLineItem(so.id, pro.id, configPro.id,null,2);
        SO_Line_Items__c bundledSol = TestUtil.createsalesOrderLineItem(so.id, bundlePro.id, null,null,2);        
        SO_Line_Items__c bundleItemSol = TestUtil.createsalesOrderLineItem(so.id, bundlePro.id, configPro.id,bundleItem.id,2);
        
        test.startTest();
        newPriceCalculation controller = new newPriceCalculation();
        list<string> salesorderids = new list<string>();
        salesorderids.add(so.id);
        controller.approvalProcessCalculation(salesorderids);
        test.stopTest();
        System.assertEquals(null, promotionList.Type__c);
    }
    
    static testMethod void testCalculation()
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
        
        Promotions__c promotion = TestUtil.createPromotion('Promo Code', 'General');
        Promotions__c promotionList = [Select id, Type__c from Promotions__c Limit 1];
        
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, deliveryAccount.id, Null);
        so.Promotion__c = promotion.id;
        update so;
        
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,2);
        SO_Line_Items__c configSol = TestUtil.createsalesOrderLineItem(so.id, pro.id, configPro.id,null,2);
        SO_Line_Items__c bundledSol = TestUtil.createsalesOrderLineItem(so.id, bundlePro.id, null,null,2);        
        SO_Line_Items__c bundleItemSol = TestUtil.createsalesOrderLineItem(so.id, bundlePro.id, configPro.id,bundleItem.id,2);
        
        Tax_Percentage__c TP = new Tax_Percentage__c(Name='New York',Percentage__c=8.65);
        insert TP;
        test.startTest();
        newPriceCalculation controller = new newPriceCalculation();
        list<string> salesorderids = new list<string>();
        salesorderids.add(so.id);
        controller.calculation(salesorderids,'Approved',null,null);
        controller.updatecalculation(salesorderids);
        test.stopTest();
        System.assertEquals('General', promotionList.Type__c);
    }
    
    static testMethod void testupdateCalculation()
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
        
        Promotions__c promotion = TestUtil.createPromotion('Promo Code', 'Brand');
        Promotions__c promotionList = [Select id, Type__c from Promotions__c Limit 1];
        
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, deliveryAccount.id, Null);
        so.Promotion__c = promotion.id;
        update so;
        
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,2);
        SO_Line_Items__c configSol = TestUtil.createsalesOrderLineItem(so.id, pro.id, configPro.id,null,2);
        SO_Line_Items__c bundledSol = TestUtil.createsalesOrderLineItem(so.id, bundlePro.id, null,null,2);        
        SO_Line_Items__c bundleItemSol = TestUtil.createsalesOrderLineItem(so.id, bundlePro.id, null,bundleItem.id,2);
        
        Tax_Percentage__c TP = new Tax_Percentage__c(Name='New York',Percentage__c=8.65);
        insert TP;
        test.startTest();
        newPriceCalculation controller = new newPriceCalculation();
        list<string> salesorderids = new list<string>();
        salesorderids.add(so.id);
        controller.calculation(salesorderids,'Approved',null,null);
        controller.updatecalculation(salesorderids);
        test.stopTest();
        System.assertEquals('Brand', promotionList.Type__c);
    }
    
    static testMethod void testgetMainBundleWeight()
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
        
        Promotions__c promotion = TestUtil.createPromotion('Promo Code', 'General');
        Promotions__c promotionList = [Select id, Type__c from Promotions__c Limit 1];
        
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, deliveryAccount.id, Null);
        so.Promotion__c = promotion.id;
        update so;
        
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,2);
        SO_Line_Items__c configSol = TestUtil.createsalesOrderLineItem(so.id, pro.id, configPro.id,null,2);
        SO_Line_Items__c bundledSol = TestUtil.createsalesOrderLineItem(so.id, bundlePro.id, null,null,2);        
        SO_Line_Items__c bundleItemSol = TestUtil.createsalesOrderLineItem(so.id, bundlePro.id, configPro.id,bundleItem.id,2);
        
        Tax_Percentage__c TP = new Tax_Percentage__c(Name='New York',Percentage__c=8.65);
        insert TP;
        test.startTest();
        newPriceCalculation.getMainBundleWeight(so.id);
        test.stopTest();
        System.assertEquals('General', promotionList.Type__c);
    }
}