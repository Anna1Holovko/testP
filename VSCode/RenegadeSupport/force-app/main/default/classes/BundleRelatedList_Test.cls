/*
*   Author : Vishnu Bijjula | Kairos Tech
*   Class  : BundleRelatedList_Test
*   Purpose: This test class is used to code coverage for BundleRelatedList.
*/
@isTest
public class BundleRelatedList_Test {
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
    
    static testMethod void newBundleItem()
    {
        Account ac = TestUtil.createCustomerAccount(); 
        
        Account deliveryAccount = TestUtil.createDeliveryAccount();
        
        Account manufactureAccount = TestUtil.createManufacturerAccount(true,false, 'Email');
        
        Account warehouseAccount = TestUtil.createWarehouseAccount();
        
        Trucking_Rule__c trucking = TestUtil.createTruckingRules(manufactureAccount.Id,deliveryAccount.Id);
        
        Products__c configPro = TestUtil.createConfigProduct();
                        
        Products__c pro = TestUtil.createSimpleProduct(configPro.id,manufactureAccount.id);
        Products__c bundlePro = TestUtil.createBundleProduct(); 
        Bundle_Item__c bundleItem = TestUtil.createBundleItemProduct(configPro.id, bundlePro.id);
        
        Product_Fields__c customSettings = new Product_Fields__c(name='Bundle',sObject_Name__c='Bundle Item',Field_Id__c='00Nq0000000sbyd');
        insert customSettings;
        
        pagereference getPref;
        String prefix = Schema.getGlobalDescribe().get('Bundle_Item__c').getDescribe().getKeyPrefix();
        test.startTest();
            PageReference pref = Page.BundleRelatedList;
        	test.setCurrentPage(pref);
        	ApexPages.currentPage().getParameters().put('Id',pro.id);
        	ApexPages.StandardController sc = new ApexPages.StandardController(pro);   
        
        	BundleRelatedList controller = new BundleRelatedList(sc);
        	controller.getBiRelated();
        	getPref = controller.newBundleItem();
        test.stopTest();
            System.assertEquals('/'+prefix+'/e?CF00Nq0000000sbyd=sample+test&CF00Nq0000000sbyd_lkid='+pro.id+'&retURL=%2F'+pro.id, getPref.getUrl());
    }
}