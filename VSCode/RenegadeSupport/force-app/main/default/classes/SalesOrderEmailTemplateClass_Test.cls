/*
*   Author : Sowdhanya Karri And Vishnu Bijjula | Kairos Tech
*   Class  : SalesOrderEmailTemplateClass_Test
*   Purpose: This test class is to cover the code for SalesOrderEmailTemplateClass class.
*/
@isTest
public class SalesOrderEmailTemplateClass_Test {   
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
        
        Account acc = TestUtil.createCustomerAccount();
        Account deliveryAccount1 = TestUtil.createDeliveryAccount();
        TestUtil.createprotectionProduct();
                
        TestUtil.createsalesOrder(acc.id, deliveryAccount1.id, null);
    }
	
	private static Account getcustomerAcc() {
        return [SELECT Id, recordtype.Name FROM Account where recordtype.Name='Customer' LIMIT 1];
    }
    
    private static Account getdeliveryAcc() {
        return [SELECT Id, recordtype.Name FROM Account where recordtype.Name='Delivery Company' LIMIT 1];
    }
    
    private static Products__c getbundlePro() {
        return [SELECT Id, recordtype.Name FROM Products__c where recordtype.Name='Bundled' LIMIT 1];
    }
    
    private static Products__c getprotectionPro() {
        return [SELECT Id, recordtype.Name FROM Products__c where recordtype.Name='Protection Plan' LIMIT 1];
    }
    
    private static Sales_Order__c getSalesOrder() {
        return [SELECT Id FROM Sales_Order__c LIMIT 1];
    }
    
	Static testmethod void getSoRelatedList()
    {
        Account ac = getcustomerAcc(); 
        Account deliveryAccount = getdeliveryAcc();
        Account manufactureAccount = TestUtil.createManufacturerAccount(true,false, 'Email');
        Account warehouseAccount = TestUtil.createWarehouseAccount();
        
        Products__c configPro = TestUtil.createConfigProduct();
        Products__c bundlePro = TestUtil.createBundleProduct();
        Products__c protectionPro = getprotectionPro();
        
        Bundle_Item__c bundleItem = TestUtil.createBundleItemProduct(configPro.id, bundlePro.id);
        
        Sales_Order__c so = getSalesOrder();
        
        SO_Line_Items__c bundleSol = TestUtil.createsalesOrderLineItem(so.id, bundlePro.id, null,null,3);
        SO_Line_Items__c bundledSol = TestUtil.createsalesOrderLineItem(so.id, bundlePro.id, null,bundleItem.id,2);
        SO_Line_Items__c protectionSol = TestUtil.createsalesOrderLineItem(so.id, protectionPro.id, null,null,2);
        
        test.startTest();
        SalesOrderEmailTemplateClass templateClass = new SalesOrderEmailTemplateClass();
        templateClass.salesOrderId = so.id;
        map<string,SalesOrderEmailTemplateClass.SOItemsWrapper> soRelatedList = templateClass.getSoRelatedList();
        test.stopTest();
        //system.assertEquals(2, soItemsList[0].Quantity__c);
    }
    
    Static testmethod void getinvoiceItems()
    {
        Account ac = getcustomerAcc(); 
        Account deliveryAccount = getdeliveryAcc();
               
        Products__c configPro = TestUtil.createConfigProduct();
        Products__c bundlePro = TestUtil.createBundleProduct();
        Products__c protectionPro = getprotectionPro();
                
        Bundle_Item__c bundleItem = TestUtil.createBundleItemProduct(configPro.id, bundlePro.id);
        
        Sales_Order__c so = getSalesOrder();
        
        SO_Line_Items__c bundleSol = TestUtil.createsalesOrderLineItem(so.id, bundlePro.id, null,null,3);
        SO_Line_Items__c bundledSol = TestUtil.createsalesOrderLineItem(so.id, bundlePro.id, null,bundleItem.id,2);
        SO_Line_Items__c protectionSol = TestUtil.createsalesOrderLineItem(so.id, protectionPro.id, null,null,2);
        
        Invoice__c payInvoice = TestUtil.createpayableInvoice(so.id);
        Invoice_Line_Item__c payInvLineItem = TestUtil.createInvoiceLineItem(so.id,bundleSol.id, payInvoice.id);
        Invoice_Line_Item__c payproInvLineItem = TestUtil.createInvoiceLineItem(so.id,protectionSol.id, payInvoice.id);
        
        Invoice__c recInvoice = TestUtil.createreceivablesInvoice(so.id); 
        Invoice_Line_Item__c recInvLineItem = TestUtil.createInvoiceLineItem(so.id,bundleSol.id, recInvoice.id);
        Invoice_Line_Item__c recproInvLineItem = TestUtil.createInvoiceLineItem(so.id,protectionSol.id, recInvoice.id);
        
        test.startTest();
        SalesOrderEmailTemplateClass templateClass = new SalesOrderEmailTemplateClass();
        templateClass.invoiceId = payInvoice.id;
        List<Invoice_Line_Item__c> invItemsList = templateClass.getinvoiceItems();
        test.stopTest();
        //system.assertEquals(3, invItemsList[0].Quantity_Invoiced__c);
    }
}