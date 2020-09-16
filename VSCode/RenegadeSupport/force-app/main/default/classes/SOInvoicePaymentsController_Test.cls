/*
*   Author : Vishnu Bijjula | Kairos Tech
*   Class  : SOInvoicePaymentsController_Test
*   Purpose: This test class is to cover the code for SOInvoicePaymentsController class.
*/
@isTest
public class SOInvoicePaymentsController_Test {
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
    
    static testMethod void displayPaymentsWithPayables() 
    {
        Account ac = TestUtil.createCustomerAccount();
        
        Account manufactureAccount = TestUtil.createManufacturerAccount(false,false, 'Email');
        
        Products__c configPro = TestUtil.createConfigProduct();
        
        Products__c pro = TestUtil.createSimpleProduct(Null,manufactureAccount.id);
        
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, Null, Null);
        
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,2);
        
        Payment_Method__c payMethod = TestUtil.createpaymentMethod(ac.id, 'Credit Card (Authorize.net)');
        
        Invoice__c invoice = TestUtil.createpayableInvoice(so.id);
        
        Transaction__c trans = TestUtil.createTrasaction(so.id,payMethod.id, 'CREDIT');
        trans.Invoice__c = invoice.id;
        update trans;
        
        Test.startTest();
        PageReference pref = Page.SOInvoicePayments;
        test.setCurrentPage(pref);
        ApexPages.currentPage().getParameters().put('Id',so.id);
        apexPages.StandardController sc = new ApexPages.StandardController(invoice);   
        SOInvoicePaymentsController controller = new SOInvoicePaymentsController(sc);
        controller.invoiceid = ''+invoice.id;
        controller.displayPayments();
        
        Invoice__c inv = [select recordtype.name from Invoice__c where id=:controller.invoiceid];
        Test.StopTest();
        system.assertEquals('Payables', inv.recordtype.name);
    }
    static testMethod void displayPaymentsWithReceivables()
    {
        Account ac = TestUtil.createCustomerAccount();
        
        Account manufactureAccount = TestUtil.createManufacturerAccount(false,false, 'Email');
        
        Products__c configPro = TestUtil.createConfigProduct();
        
        Products__c pro = TestUtil.createSimpleProduct(Null,manufactureAccount.id);
        
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, Null, Null);
        
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,2);
        
        Payment_Method__c payMethod = TestUtil.createpaymentMethod(ac.id, 'Credit Card (Authorize.net)');
        
        Invoice__c invoice = TestUtil.createreceivablesInvoice(so.id);
        
        Transaction__c trans = TestUtil.createTrasaction(so.id,payMethod.id, 'CAPTURE_ONLY');
        trans.Invoice__c = invoice.id;
        update trans;
        
        Test.startTest();
        PageReference pref = Page.SOInvoicePayments;
        test.setCurrentPage(pref);
        ApexPages.currentPage().getParameters().put('Id',so.id);
        ApexPages.StandardController sc = new ApexPages.StandardController(invoice);   
        SOInvoicePaymentsController controller = new SOInvoicePaymentsController(sc);
        controller.invoiceid = ''+invoice.id;
        controller.displayPayments();
        
        Invoice__c inv = [select recordtype.name from Invoice__c where id=:controller.invoiceid];
        Test.StopTest();
        system.assertEquals('Receivables', inv.recordtype.name);
    }
}