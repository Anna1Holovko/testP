/*
*   Author : Vishnu Bijjula | Kairos Tech
*   Class  : AccountRelSalesOrdersController_test
*   Purpose: This test class is used to code coverage for AccountRelSalesOrdersController.
*/
@isTest
public class AccountRelSalesOrdersController_Test {
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
    
    public static testMethod void testAccountRelSalesOrdersController() 
    {
        //Account Creation
        Account ac = TestUtil.createCustomerAccount();
        Account deliveryAccount = TestUtil.createDeliveryAccount();
        Account manufactureAccount = TestUtil.createManufacturerAccount(true,false, 'Email');
        Account warehouseAccount = TestUtil.createWarehouseAccount();
        
        //Products Creation
        Products__c configPro = TestUtil.createConfigProduct();
        Products__c pro = TestUtil.createSimpleProduct(configPro.id,manufactureAccount.id);
        Products__c bundlePro = TestUtil.createBundleProduct();
        
        Bundle_Item__c bundleItem = TestUtil.createBundleItemProduct(configPro.id, bundlePro.id);
        
        //Payment Method Creation
        Payment_Method__c pm = TestUtil.createpaymentMethod(deliveryAccount.id,'PayPal');
        
        //SalesOrder Creation
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, deliveryAccount.id, pm.id);
        
        //SalesOrder Line Item Creation
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,5);
        SO_Line_Items__c configSol = TestUtil.createsalesOrderLineItem(so.id, pro.id, configPro.id,null,2);
        SO_Line_Items__c bundleSol = TestUtil.createsalesOrderLineItem(so.id, bundlePro.id, null,null,1);
        SO_Line_Items__c bundleItemSol = TestUtil.createsalesOrderLineItem(so.id, bundlePro.id, null,bundleItem.id,1);
        
        //Transaction Creation
        Transaction__c trac = TestUtil.createTrasaction(so.id,pm.id,'AUTH_ONLY');
        trac.Status__c = 'Authorized';
        update trac;  
        
        test.startTest();        
        pageReference pref = page.AccountRelSalesorders;
        Test.setCurrentPage(pref);
        ApexPages.currentPage().getParameters().put('customerid',ac.id);
        AccountRelSalesOrdersController controller = new AccountRelSalesOrdersController();
        
        controller.SOID = so.id;
        list<Transaction__c> transacList = controller.getTransactionDetails();
        map<SO_Line_Items__c,list<SO_Line_Items__c>> soItemsMap = controller.getSoLineItems();
        controller.ShowSOLineItems();
        test.stopTest();
        System.assert(transacList != null);
    }
}