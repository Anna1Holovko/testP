/*
*   Author : Vishnu Bijjula | Kairos Tech
*   Class  : SalesOrderPaymentsController_Test
*   Purpose: This test class is to cover the code for SalesOrderPaymentsController class.
*/
@isTest
public class SalesOrderPaymentsController_Test {
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
    
    static testMethod void displayPayments()
    {
        Account ac = TestUtil.createCustomerAccount();
        
        Account manufactureAccount = TestUtil.createManufacturerAccount(false,false, 'Email');
        
        Products__c configPro = TestUtil.createConfigProduct();
        
        Products__c pro = TestUtil.createSimpleProduct(Null,manufactureAccount.id);
        
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, Null, Null);
        
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,2);
        
        Test.startTest();
        PageReference pref = Page.SalesOrderPayments;
        test.setCurrentPage(pref);
        ApexPages.currentPage().getParameters().put('Id',so.id);
        ApexPages.StandardController sc = new ApexPages.StandardController(so);   
        
        SalesOrderPaymentsController controller = new SalesOrderPaymentsController(sc);
        controller.displayPayments();
        Test.StopTest();
        system.assertEquals(0, controller.paymentList.size());
    }
}