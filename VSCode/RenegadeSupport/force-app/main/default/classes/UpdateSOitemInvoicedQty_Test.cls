/*
*   Author : Vishnu Bijjula | Kairos Tech
*   Class  : UpdateSOitemInvoicedQty_Test
*   Purpose: This test class is to cover the code for UpdateSOitemInvoicedQty class.
*/
@isTest
public class UpdateSOitemInvoicedQty_Test {
    public static Paypal_OAuth__c paypalObj;
    public static Google_API__c googleAPI;
    public static AuthorizeDotNetTokens__c authObj {get;set;}
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
        
        paypalObj = new Paypal_OAuth__c();
        paypalObj.name = 'Auth';
        paypalObj.Client_ID__c ='123asdfghtresg';
        paypalObj.Client_Secret__c ='testClientsecret';
        paypalObj.EndPoint__c='https://api.sandbox.paypal.com';
        
        insert paypalObj;
        
        authObj = new AuthorizeDotNetTokens__c();
        authObj.name = 'Auth';
        authObj.API_Name__c = '4k3Cq5EL';
        authObj.transactionKey__c = '52d375h64Rq7yVVN';
        
        insert authObj;
    }
    
    static testmethod void testaddPayableinvoicedSOItemUpdate() {
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
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,2);
        
        SO_Line_Items__c configSol = TestUtil.createsalesOrderLineItem(so.id, pro.id, configPro.id,null,2);
        
        SO_Line_Items__c bundleSol = TestUtil.createsalesOrderLineItem(so.id, bundlePro.id, null,bundleItem.id,2);
        
        //Transaction Creation
        Transaction__c tracAuthOnly = TestUtil.createTrasaction(so.id,pm.id,'AUTH_ONLY');
        Transaction__c tracCaptureOnly = TestUtil.createTrasaction(so.id,pm.id,'CAPTURE_ONLY');
        
        Invoice__c Inv = TestUtil.createpayableInvoice(so.id);
        Invoice_Line_Item__c InvLineItem = TestUtil.createInvoiceLineItem(so.id,Sol.Id, Inv.id);
        
        Invoice__c Inv1 = TestUtil.createpayableInvoice(so.id);
        Invoice_Line_Item__c InvLineItem1 = TestUtil.createInvoiceLineItem(so.id,Sol.Id, Inv1.id);
        
        test.startTest();        
        set<id> invoiceItems = new set<id>();
        
        for(Invoice_Line_Item__c invItems : [SELECT Id,Invoice__c,Items_invoiced__c,Quantity_Invoiced__c,Quantity_Ordered__c,Items_invoiced__r.Products__c,Quantity_to_Invoice__c,Quantity_To_Refund__c,Items_invoiced__r.Products__r.RecordType.Name,Invoice__r.RecordtypeId FROM Invoice_Line_Item__c where Invoice__c=:Inv.id]) {
            invoiceItems.add(invItems.id);
        }
        UpdateSOitemInvoicedQty.addinvoicedSOItemUpdate(invoiceItems);

        test.stopTest();
    }
    static testmethod void testaddReceivablesinvoicedSOItemUpdate() {
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
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,2);
        
        SO_Line_Items__c configSol = TestUtil.createsalesOrderLineItem(so.id, pro.id, configPro.id,null,2);
        
        SO_Line_Items__c bundleSol = TestUtil.createsalesOrderLineItem(so.id, bundlePro.id, null,bundleItem.id,2);
        
        //Transaction Creation
        Transaction__c tracAuthOnly = TestUtil.createTrasaction(so.id,pm.id,'AUTH_ONLY');
        Transaction__c tracCaptureOnly = TestUtil.createTrasaction(so.id,pm.id,'CAPTURE_ONLY');
        
        Invoice__c Inv = TestUtil.createreceivablesInvoice(so.id);
        Invoice_Line_Item__c InvLineItem = TestUtil.createInvoiceLineItem(so.id,Sol.Id, Inv.id);
        Invoice_Line_Item__c InvLineItem1 = TestUtil.createInvoiceLineItem(so.id,bundleSol.Id, Inv.id);
        
        test.startTest();        
        set<id> invoiceItems = new set<id>();
        
        for(Invoice_Line_Item__c invItems : [SELECT Id,Invoice__c,Items_invoiced__c,Quantity_Invoiced__c,Quantity_Ordered__c,Items_invoiced__r.Products__c,Quantity_to_Invoice__c,Quantity_To_Refund__c,Items_invoiced__r.Products__r.RecordType.Name,Invoice__r.RecordtypeId FROM Invoice_Line_Item__c where Invoice__c=:Inv.id]) {
            invoiceItems.add(invItems.id);
        }
        UpdateSOitemInvoicedQty.addinvoicedSOItemUpdate(invoiceItems);

        test.stopTest();
    }
    static testmethod void testremovePayableinvoicedSOItemUpdate() {
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
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,2);
        
        SO_Line_Items__c configSol = TestUtil.createsalesOrderLineItem(so.id, pro.id, configPro.id,null,2);
        
        SO_Line_Items__c bundleSol = TestUtil.createsalesOrderLineItem(so.id, bundlePro.id, null,bundleItem.id,2);
        
        //Transaction Creation
        Transaction__c tracAuthOnly = TestUtil.createTrasaction(so.id,pm.id,'AUTH_ONLY');
        Transaction__c tracCaptureOnly = TestUtil.createTrasaction(so.id,pm.id,'CAPTURE_ONLY');
        
        Invoice__c Inv = TestUtil.createpayableInvoice(so.id);
        Invoice_Line_Item__c InvLineItem = TestUtil.createInvoiceLineItem(so.id,Sol.Id, Inv.id);
        
        Invoice__c Inv1 = TestUtil.createpayableInvoice(so.id);
        Invoice_Line_Item__c InvLineItem1 = TestUtil.createInvoiceLineItem(so.id,Sol.Id, Inv1.id);
        
        test.startTest();        
        List<Invoice_Line_Item__c> invoiceItems = new List<Invoice_Line_Item__c>();
        
        for(Invoice_Line_Item__c invItems : [SELECT Id,Invoice__c,Items_invoiced__c,Quantity_Invoiced__c,Quantity_Ordered__c,Items_invoiced__r.Products__c,Quantity_to_Invoice__c,Quantity_To_Refund__c,Items_invoiced__r.Products__r.RecordType.Name,Invoice__r.RecordtypeId FROM Invoice_Line_Item__c where Invoice__c=:Inv.id]) {
            invoiceItems.add(invItems);
        }
        UpdateSOitemInvoicedQty.removeinvoicedSOItemUpdate(invoiceItems);

        test.stopTest();
    }
    static testmethod void testremoveReceivableinvoicedSOItemUpdate() {
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
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,2);
        
        SO_Line_Items__c configSol = TestUtil.createsalesOrderLineItem(so.id, pro.id, configPro.id,null,2);
        
        SO_Line_Items__c bundleSol = TestUtil.createsalesOrderLineItem(so.id, bundlePro.id, null,bundleItem.id,2);
        
        //Transaction Creation
        Transaction__c tracAuthOnly = TestUtil.createTrasaction(so.id,pm.id,'AUTH_ONLY');
        Transaction__c tracCaptureOnly = TestUtil.createTrasaction(so.id,pm.id,'CAPTURE_ONLY');
        
        Invoice__c Inv = TestUtil.createreceivablesInvoice(so.id);
        Invoice_Line_Item__c InvLineItem = TestUtil.createInvoiceLineItem(so.id,Sol.Id, Inv.id);
        Invoice_Line_Item__c InvLineItem1 = TestUtil.createInvoiceLineItem(so.id,bundleSol.Id, Inv.id);
        
        test.startTest();        
        List<Invoice_Line_Item__c> invoiceItems = new List<Invoice_Line_Item__c>();
        
        for(Invoice_Line_Item__c invItems : [SELECT Id,Invoice__c,Items_invoiced__c,Quantity_Invoiced__c,Quantity_Ordered__c,Items_invoiced__r.Products__c,Quantity_to_Invoice__c,Quantity_To_Refund__c,Items_invoiced__r.Products__r.RecordType.Name,Invoice__r.RecordtypeId FROM Invoice_Line_Item__c where Invoice__c=:Inv.id]) {
            invoiceItems.add(invItems);
        }
        UpdateSOitemInvoicedQty.removeinvoicedSOItemUpdate(invoiceItems);

        test.stopTest();
    }
}