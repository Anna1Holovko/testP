/*
*   Author : Vishnu Bijjula | Kairos Tech
*   Class  : CreateInvoicePageController_Test
*   Purpose: This class is used to cover the code Coverage for CreateInvoicePageController class.
*/
@isTest
public class CreateInvoicePageController_Test
{
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
        authObj.Endpoint__c = 'https://api.authorize.net/xml/v1/request.api';
        
        insert authObj;
    }
    
    public static testMethod void testContollerWithNull() 
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
        
        SO_Line_Items__c updtSol = [Select Id,Price__c,Quantity_Invoiced__c,Quantity__c,Tax_Amount__c,DiscountAmount__c from SO_Line_Items__c where id=:Sol.id];
        updtSol.Price__c = Null;
        updtSol.Quantity_Invoiced__c = Null;
        Update updtSol;
            
        Inventory__c invent = TestUtil.createInventory(pro.id,6,warehouseAccount.id);
                
        Inventory__c configInvent = TestUtil.createInventory(configPro.id,4,warehouseAccount.id);
                
        Inventory__c bundleInvent = TestUtil.createInventory(bundlePro.id,1,warehouseAccount.id);
                       
		test.startTest();        
        pageReference pref = page.createInvoicepage;
        Test.setCurrentPage(pref);
        Apexpages.StandardController stcon = new Apexpages.StandardController(so);
        createInvoicepageController invcon = new createInvoicepageController(stcon);
        createInvoicepageController.ItemsorderWrapper WrapperClass = new createInvoicepageController.ItemsorderWrapper(updtSol,'4', '1500','64','500','2000');
        
        System.assertEquals(updtSol.Price__c, Null);
        test.stopTest();
    }
        
    public static testMethod void submitInvoiceForCreditCardPaymentWithNoTransaction() 
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
        Products__c protectionPro = TestUtil.createprotectionProduct();
        
        Bundle_Item__c bundleItem = TestUtil.createBundleItemProduct(configPro.id, bundlePro.id);
        
        //Payment Method Creation
        Payment_Method__c pm = TestUtil.createpaymentMethod(deliveryAccount.id,'Credit Card');
        Payment_Method__c getPMRecordType = [Select id,RecordType.Name from Payment_Method__c where id=:pm.id];
        
        //SalesOrder Creation
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, deliveryAccount.id, pm.id);
        
        Sales_Order__c updtSo = [Select id,Payment_Status__c from Sales_Order__c where id=:so.id];
        updtSo.Payment_Status__c = 'Authorized';
        update updtSo;
        
		//SalesOrder Line Item Creation
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(updtSo.id, pro.id, null,null,2);
                
        SO_Line_Items__c configSol = TestUtil.createsalesOrderLineItem(updtSo.id, pro.id, configPro.id,null,2);
        
        SO_Line_Items__c bundleSol = TestUtil.createsalesOrderLineItem(updtSo.id, bundlePro.id, null,bundleItem.id,3);
        
        SO_Line_Items__c protectionSol = TestUtil.createsalesOrderLineItem(updtSo.id, protectionPro.id, null,null,1);
        
        //Transaction Creation
        Transaction__c trac = TestUtil.createTrasaction(so.id,pm.id,'AUTH_ONLY');
        
        Inventory__c invent = TestUtil.createInventory(pro.id,6,warehouseAccount.id);
                
        Inventory__c configInvent = TestUtil.createInventory(configPro.id,4,warehouseAccount.id);
                
        Inventory__c bundleInvent = TestUtil.createInventory(bundlePro.id,1,warehouseAccount.id);
                               
		test.startTest();        
        pageReference pref = page.createInvoicepage;
        Test.setCurrentPage(pref);
        Apexpages.StandardController stcon = new Apexpages.StandardController(updtSo);
        createInvoicepageController invcon = new createInvoicepageController(stcon);
        createInvoicepageController.ItemsorderWrapper WrapperClass = new createInvoicepageController.ItemsorderWrapper(sol,'4', '1500','64','500','2000');
        
        invcon.isChecked = true;
        invcon.submitInvoice();
        System.assertEquals(getPMRecordType.RecordType.Name, 'Credit Card');
        test.stopTest();
    }
    
    public static testMethod void submitInvoiceForCreditCardPaymentWithTransaction() 
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
        Payment_Method__c pm = TestUtil.createpaymentMethod(deliveryAccount.id,'Credit Card');
        Payment_Method__c getPMRecordType = [Select id,RecordType.Name from Payment_Method__c where id=:pm.id];
        
        //SalesOrder Creation
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, deliveryAccount.id, pm.id);
        
        Sales_Order__c updtSo = [Select id,Payment_Status__c from Sales_Order__c where id=:so.id];
        updtSo.Payment_Status__c = 'Authorized';
        update updtSo;
        
		//SalesOrder Line Item Creation
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(updtSo.id, pro.id, null,null,2);
                
        SO_Line_Items__c configSol = TestUtil.createsalesOrderLineItem(so.id, pro.id, configPro.id,null,2);
        
        SO_Line_Items__c bundleSol = TestUtil.createsalesOrderLineItem(so.id, bundlePro.id, null,bundleItem.id,3);
        
        //Transaction Creation
        Transaction__c trac = TestUtil.createTrasaction(so.id,pm.id,'AUTH_ONLY');
        trac.Status__c = 'Authorized';
        update trac;
        
        Inventory__c invent = TestUtil.createInventory(pro.id,6,warehouseAccount.id);
        Inventory__c configInvent = TestUtil.createInventory(configPro.id,4,warehouseAccount.id);
        Inventory__c bundleInvent = TestUtil.createInventory(bundlePro.id,1,warehouseAccount.id);
                               
        pageReference pref = page.createInvoicepage;
        Test.setCurrentPage(pref);
        Apexpages.StandardController stcon = new Apexpages.StandardController(updtSo);
        createInvoicepageController invcon = new createInvoicepageController(stcon);
        createInvoicepageController.ItemsorderWrapper WrapperClass = new createInvoicepageController.ItemsorderWrapper(sol,'4', '1500','64','500','2000');
        
        invcon.isChecked = true;
        Test.setMock(HttpCalloutMock.class, new SalesOrder_AuthorizeDotNetHttpMock());
        test.startTest();
        invcon.submitInvoice();
        test.stopTest();
        System.assertEquals(getPMRecordType.RecordType.Name, 'Credit Card');
    }
   
    public static testMethod void submitInvoiceForPayPalPaymentWithTransaction() 
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
        Payment_Method__c getPMRecordType = [Select id,Amount__c,RecordType.Name from Payment_Method__c where id=:pm.id];
        
        //SalesOrder Creation
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, deliveryAccount.id, pm.id);
        
        Sales_Order__c updtSo = [Select id,Payment_Status__c,Payment_Type__c from Sales_Order__c where id=:so.id];
        updtSo.Payment_Status__c = 'Authorized';
        update updtSo;
        
		//SalesOrder Line Item Creation
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(updtSo.id, pro.id, null,null,2);
        
        SO_Line_Items__c configSol = TestUtil.createsalesOrderLineItem(so.id, pro.id, configPro.id,null,1);
        
        SO_Line_Items__c bundleSol = TestUtil.createsalesOrderLineItem(so.id, bundlePro.id, null,bundleItem.id,3);
        
        //Transaction Creation
        Transaction__c trac = TestUtil.createTrasaction(so.id,pm.id,'AUTH_ONLY');
        trac.Status__c = 'Authorized';
        update trac;
        
        Inventory__c invent = TestUtil.createInventory(pro.id,6,warehouseAccount.id);
                
        Inventory__c configInvent = TestUtil.createInventory(configPro.id,4,warehouseAccount.id);
                
        Inventory__c bundleInvent = TestUtil.createInventory(bundlePro.id,1,warehouseAccount.id);
        
        pageReference pref = page.createInvoicepage;
        Test.setCurrentPage(pref);
        Apexpages.StandardController stcon = new Apexpages.StandardController(updtSo);
        createInvoicepageController invcon = new createInvoicepageController(stcon);
        createInvoicepageController.ItemsorderWrapper WrapperClass = new createInvoicepageController.ItemsorderWrapper(sol,'4', '1500','64','500','2000');
        
        invcon.isChecked = false;
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new SalesOrder_AuthorizeDotNetHttpMock());
        
        invcon.submitInvoice();
        test.stopTest();
        System.assertEquals(getPMRecordType.RecordType.Name, 'PayPal');
    }
   
    public static testMethod void submitInvoiceForPayPalPaymentWithoutTransaction() 
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
        Payment_Method__c getPMRecordType = [Select id,RecordType.Name from Payment_Method__c where id=:pm.id];
        
        //SalesOrder Creation
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, deliveryAccount.id, pm.id);
        
        Sales_Order__c updtSo = [Select id,Payment_Status__c,Payment_Type__c from Sales_Order__c where id=:so.id];
        updtSo.Payment_Status__c = 'Authorized';
        updtSo.Payment_Method__c = 'PayPal';
        update updtSo;
        
		//SalesOrder Line Item Creation
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(updtSo.id, pro.id, null,null,2);
        
        SO_Line_Items__c configSol = TestUtil.createsalesOrderLineItem(so.id, pro.id, configPro.id,null,1);
        
        SO_Line_Items__c bundleSol = TestUtil.createsalesOrderLineItem(so.id, bundlePro.id, null,bundleItem.id,3);
        
        //Transaction Creation
        Transaction__c trac = TestUtil.createTrasaction(so.id,pm.id,'AUTH_ONLY');
        
        Inventory__c invent = TestUtil.createInventory(pro.id,6,warehouseAccount.id);
                
        Inventory__c configInvent = TestUtil.createInventory(configPro.id,4,warehouseAccount.id);
                
        Inventory__c bundleInvent = TestUtil.createInventory(bundlePro.id,1,warehouseAccount.id);
                               
		test.startTest();        
        pageReference pref = page.createInvoicepage;
        Test.setCurrentPage(pref);
        Apexpages.StandardController stcon = new Apexpages.StandardController(updtSo);
        createInvoicepageController invcon = new createInvoicepageController(stcon);
        createInvoicepageController.ItemsorderWrapper WrapperClass = new createInvoicepageController.ItemsorderWrapper(sol,'4', '1500','64','500','2000');
        
        invcon.isChecked = true;
        
        Test.setMock(HttpCalloutMock.class, new SalesOrder_AuthorizeDotNetHttpMock());
        invcon.submitInvoice();
        System.assertEquals(getPMRecordType.RecordType.Name, 'PayPal');
        test.stopTest();
    }
    
    public static testMethod void doRefund() 
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
        Inv.Refund_Approval_Status__c = 'Refund Approved';
        Inv.Invoice_Status__c = 'Refund-Failed';
        Inv.Order_Transaction_Type__c = tracCaptureOnly.id;
        update Inv;
        
        Inv.Reason_for_Refund__c = 'Compensation';
        Inv.Invoice_Status__c = 'Refund-Success';
        update Inv;
        
        Inv.Reason_for_Refund__c = 'Compensation';
        Inv.Invoice_Status__c = 'Refund-Failed';
        update Inv;
        
        delete Inv;
        delete InvLineItem1;
        test.stopTest();
        System.assertEquals('CAPTURE_ONLY',tracCaptureOnly.Transaction_Type__c);
    }
    
    public static testMethod void doRefundForCompensation() 
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
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,2);
        
        SO_Line_Items__c configSol = TestUtil.createsalesOrderLineItem(so.id, pro.id, configPro.id,null,2);
        
        SO_Line_Items__c bundleSol = TestUtil.createsalesOrderLineItem(so.id, bundlePro.id, null,bundleItem.id,2);
        
        //Transaction Creation
        Transaction__c tracAuthOnly = TestUtil.createTrasaction(so.id,pm.id,'AUTH_ONLY');
        
        Transaction__c tracCaptureOnly = TestUtil.createTrasaction(so.id,pm.id,'CAPTURE_ONLY');
        
        Invoice__c Inv = TestUtil.createpayableInvoice(so.id);
        Inv.Reason_for_Refund__c = 'Compensation';
        Inv.Compensation_Reason__c = 'Slightly Damaged';
        Inv.Refund_Handle_By__c = 'Renegade';
        update Inv;
        
        Invoice_Line_Item__c InvLineItem = TestUtil.createInvoiceLineItem(so.id,Sol.Id, Inv.id);
        
        Invoice__c Inv1 = TestUtil.createpayableInvoice(so.id);
        Invoice_Line_Item__c InvLineItem1 = TestUtil.createInvoiceLineItem(so.id,Sol.Id, Inv1.id);
        
        test.startTest();        
        Inv.Refund_Approval_Status__c = 'Refund Approved';
        Inv.Invoice_Status__c = 'Refund-Failed';
        Inv.Order_Transaction_Type__c = tracCaptureOnly.id;
        update Inv;
        
        Inv.Reason_for_Refund__c = 'Compensation';
        Inv.Invoice_Status__c = 'Refund-Success';
        update Inv;
        
        Inv.Reason_for_Refund__c = 'Compensation';
        Inv.Invoice_Status__c = 'Refund-Failed';
        update Inv;
        
        delete Inv;
        delete InvLineItem1;
        test.stopTest();
        System.assertEquals('CAPTURE_ONLY',tracCaptureOnly.Transaction_Type__c);
    }
    
    public static testMethod void doRefundFORReceivableInvoice() 
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
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,2);
        
        SO_Line_Items__c configSol = TestUtil.createsalesOrderLineItem(so.id, pro.id, configPro.id,null,2);
        SO_Line_Items__c bundleSol = TestUtil.createsalesOrderLineItem(so.id, bundlePro.id, null,null,2);
        SO_Line_Items__c bundleItemSol = TestUtil.createsalesOrderLineItem(so.id, bundlePro.id, null,bundleItem.id,2);
        
        //Transaction Creation
        Transaction__c tracAuthOnly = TestUtil.createTrasaction(so.id,pm.id,'AUTH_ONLY');
        Transaction__c tracCaptureOnly = TestUtil.createTrasaction(so.id,pm.id,'CAPTURE_ONLY');
        
        Invoice__c Inv = TestUtil.createreceivablesInvoice(so.id);
        Invoice_Line_Item__c InvLineItem = TestUtil.createInvoiceLineItem(so.id,Sol.Id, Inv.id);
        
        test.startTest();        
        Inv.Invoice_Status__c = 'Capture-Success';
        update Inv;
                
        delete Inv;
        test.stopTest();
        System.assertEquals('CAPTURE_ONLY',tracCaptureOnly.Transaction_Type__c);
    }
}