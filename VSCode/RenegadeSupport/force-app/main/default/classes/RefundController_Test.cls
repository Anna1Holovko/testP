/*
*   Author : Vishnu Bijjula | Kairos Tech
*   Class  : RefundController_Test
*   Purpose: This test class is to cover the code for RefundController class.
*/
@isTest
public class RefundController_Test {
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
        
        Account manufactureAccount = TestUtil.createManufacturerAccount(false,true, 'Email');
        Products__c bundlePro = TestUtil.createBundleProduct(); 
        bundlePro.Select_Manufacturer__c = manufactureAccount.id;
        update bundlePro;
        
        paypalObj=new Paypal_OAuth__c();
        paypalObj.name='Auth';
        paypalObj.Client_ID__c='123asdfghtresg';
        paypalObj.Client_Secret__c='testClientsecret';
        paypalObj.EndPoint__c='https://api.sandbox.paypal.com'; 
        
        insert paypalObj;
        
        authObj = new AuthorizeDotNetTokens__c();
        authObj.name = 'Auth';
        authObj.API_Name__c = '4k3Cq5EL';
        authObj.transactionKey__c = '52d375h64Rq7yVVN';
        authObj.Endpoint__c = 'https://api.authorize.net/xml/v1/request.api';
        
        insert authObj;
    }
    
    private static Account getmanufactureAcc() {
        return [SELECT Id,Name,Authorize_net_Profile_ID__c,Order_Communication_Type__c,Direct_Shipping__c,Ship_To_HUB__c,recordtype.Name FROM Account where recordtype.Name='Manufacturer' LIMIT 1];
    }
    
    private static Products__c getbundlePro() {
        return [SELECT Id,Name,Select_Manufacturer__c,recordtype.Name FROM Products__c where recordtype.Name='Bundled' LIMIT 1];
    }
    
    public static testMethod void isselectCustomerLocationForCancellationRefund()
    {
        Account ac = TestUtil.createCustomerAccount();
        Account deliveryAccount = TestUtil.createDeliveryAccount();
        
        Products__c configPro = TestUtil.createConfigProduct();     
        Products__c pro = TestUtil.createSimpleProduct(configPro.id,Null);
        
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, deliveryAccount.id, Null);    
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,4);
        Sol.Quantity_Invoiced__c = 4;
        update Sol;
        
        Refund_Process__c RP = TestUtil.createRefundProcess('Customer Location',true);
        Refund_Process__c RP1 = TestUtil.createRefundProcess('Delivery Hub',true);        
        Refund_Process__c RP2 = TestUtil.createRefundProcess('En Route',false);
        
        Test.startTest();
        PageReference pref = Page.CreateRefundPage;
        test.setCurrentPage(pref);
        ApexPages.currentPage().getParameters().put('Id',so.id);
        ApexPages.StandardController sc = new ApexPages.StandardController(so);   
        RefundController refundProcess = new RefundController(sc);
        
        refundProcess.getSelectRefundoption(); 
        refundProcess.getSelectLocationoption();
        
        refundProcess.selectRefund = 'Cancellation';
        refundProcess.isselectCustomerLocation();
        refundProcess.selectLocation = 'Customer Location';
        refundProcess.selectCanReason = 'Customer Preference';
        refundProcess.shippingChargesCalculation();
        Test.StopTest();
        System.assertEquals(RP.Name, refundProcess.selectLocation);
    }
    
    public static testMethod void isselectCustomerLocationForCancellationRefundInvalidLocation()
    {
        Account ac = TestUtil.createCustomerAccount();        
        Account deliveryAccount = TestUtil.createDeliveryAccount();
        
        Products__c configPro = TestUtil.createConfigProduct();        
        Products__c pro = TestUtil.createSimpleProduct(configPro.id,Null);
        
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, deliveryAccount.id, Null);        
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,4);
        Sol.Quantity_Invoiced__c = 4;
        update Sol;
        
        Refund_Process__c RP = TestUtil.createRefundProcess('Customer Location',true);        
        Refund_Process__c RP1 = TestUtil.createRefundProcess('Delivery Hub',true);        
        Refund_Process__c RP2 = TestUtil.createRefundProcess('En Route',false);
        
        Test.startTest();
        try{
            PageReference pref = Page.CreateRefundPage;
            test.setCurrentPage(pref);
            ApexPages.currentPage().getParameters().put('Id',so.id);
            ApexPages.StandardController sc = new ApexPages.StandardController(so);   
            RefundController refundProcess = new RefundController(sc);
            
            refundProcess.getSelectRefundoption(); 
            refundProcess.getSelectLocationoption();
            refundProcess.selectLocation = RP2.Name;
            System.assertEquals(RP2.Name, refundProcess.selectLocation);
            
            refundProcess.selectRefund = 'Cancellation';
            refundProcess.selectCanReason = 'Customer Preference';
            refundProcess.isselectCustomerLocation();
        }
        catch(Exception e)
        {
            system.assert(False,'No Refund is to be Generated');
        }
        Test.StopTest();
    }
    
    public static testMethod void isClickedonRefundwhenQuantityRefundedisNull() 
    {
        Account ac = TestUtil.createCustomerAccount();
        Account manufactureAccount = getmanufactureAcc();
        Account deliveryAccount = TestUtil.createDeliveryAccount();
        
        Products__c configPro = TestUtil.createConfigProduct();
        Products__c pro = TestUtil.createSimpleProduct(configPro.id,Null);
        
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, deliveryAccount.id, Null);        
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,4); 
        Sol.Price__c = 1000;
        Sol.Quantity_Invoiced__c = 4;
        update Sol;
        SO_Line_Items__c updateSol = [Select id,Price__c,Quantity_Refunded__c,Quantity_Invoiced__c,Quantity__c,TaxAmount__c,DiscountAmount__c from SO_Line_Items__c where id=:Sol.id];
                
        Refund_Process__c RP = TestUtil.createRefundProcess('Customer Location',true);        
        Refund_Process__c RP1 = TestUtil.createRefundProcess('Delivery Hub',true);        
        Refund_Process__c RP2 = TestUtil.createRefundProcess('En Route',false);
        
        Test.startTest();
        PageReference pref = Page.CreateRefundPage;
        test.setCurrentPage(pref);
        ApexPages.currentPage().getParameters().put('Id',so.id);
        ApexPages.StandardController sc = new ApexPages.StandardController(so);   
        RefundController refundProcess = new RefundController(sc);
        refundProcess.isChecked = true;
        
        refundProcess.isRefundAll=true;
        refundProcess.selectRefund = 'Cancellation';
        refundProcess.isClickedonRefund();
        refundProcess.selectLocation = RP1.name; 
        Test.StopTest();
    }
    
    public static testMethod void isClickedonRefundwhenQuantityRefunded() 
    {
        Account ac = TestUtil.createCustomerAccount();
        Account manufactureAccount = getmanufactureAcc();
        Account deliveryAccount = TestUtil.createDeliveryAccount();
        
        Products__c bundlePro = getbundlePro();
        
        Payment_Method__c pm = TestUtil.createpaymentMethod(ac.id,'Credit Card (Authorize.net)');
        
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, deliveryAccount.id, pm.id);
        SO_Line_Items__c bundleSetSol = TestUtil.createsalesOrderLineItem(so.id, bundlePro.id, null,null,4);
        bundleSetSol.Quantity_Invoiced__c = 4;
        update bundleSetSol;
        
        Transaction__c trac = TestUtil.createTrasaction(so.id,pm.id,'CAPTURE_ONLY');
        trac.Amount__c = 500;
        trac.Refunded_Amount__c = 100;
        update trac;
        
        Refund_Process__c RP = TestUtil.createRefundProcess('Customer Location',true);
        
        Refund_Process__c RP1 = TestUtil.createRefundProcess('Delivery Hub',true);
        
        Refund_Process__c RP2 = TestUtil.createRefundProcess('En Route',false);
        
        Invoice__c inv = TestUtil.createreceivablesInvoice(so.id);
        inv.Order_Transaction_Type__c = trac.id;
        update inv;
        
        Test.startTest();
        PageReference pref = Page.CreateRefundPage;
        ApexPages.currentPage().getParameters().put('Id',so.id);
        test.setCurrentPage(pref);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(so);   
        RefundController refundProcess = new RefundController(sc);
        
        refundProcess.isRefundAll = false;
        
        RefundController.ItemsorderWrapper itemWrapper = new RefundController.ItemsorderWrapper(bundleSetSol,null,'1','1500','100','20','0','120','50','0.00',false);
        
        refundProcess.soRelatedList.put(manufactureAccount.name+bundleSetSol.id,itemWrapper);
        refundProcess.isChecked = true;
        
        Test.StopTest();
        System.assertEquals('none', refundProcess.selectLocation);
    }
    
    public static testMethod void onChangecalcInvoiceCancellation() 
    {
        Account ac = TestUtil.createCustomerAccount();
        Account manufactureAccount = getmanufactureAcc();
        Account deliveryAccount = TestUtil.createDeliveryAccount();
        
        Products__c configPro = TestUtil.createConfigProduct();
        Products__c pro = TestUtil.createSimpleProduct(configPro.id,Null);
        Products__c bundlePro = getbundlePro();
        
        Bundle_Item__c bundleItem = TestUtil.createBundleItemProduct(configPro.id, bundlePro.id);
        
        Payment_Method__c pm = TestUtil.createpaymentMethod(ac.id,'Credit Card (Authorize.net)');
        
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, deliveryAccount.id, pm.id);
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,4);
        Sol.Custom_Price__c = 1000;
        Sol.Quantity_Invoiced__c = 4;
        update Sol;
        
        SO_Line_Items__c configSol = TestUtil.createsalesOrderLineItem(so.id, pro.id, configPro.id,null,4);
        configSol.Quantity_Invoiced__c = 4;
        configSol.Custom_Price__c = 500;
        update configSol;
        SO_Line_Items__c bundleSetSol = TestUtil.createsalesOrderLineItem(so.id, bundlePro.id, null,null,4);
        bundleSetSol.Quantity_Invoiced__c = 4;
        configSol.Custom_Price__c = 500;
        update bundleSetSol;
        SO_Line_Items__c bundleSol = TestUtil.createsalesOrderLineItem(so.id, bundlePro.id, null,bundleItem.id,4);
        bundleSol.Quantity_Invoiced__c = 4;
        update bundleSol;
        
        Transaction__c trac = TestUtil.createTrasaction(so.id,pm.id,'CAPTURE_ONLY');
        trac.Amount__c = 500;
        trac.Refunded_Amount__c = 100;
        update trac;
        
        Refund_Process__c RP = TestUtil.createRefundProcess('Customer Location',true);
        
        Refund_Process__c RP1 = TestUtil.createRefundProcess('Delivery Hub',true);
        
        Refund_Process__c RP2 = TestUtil.createRefundProcess('En Route',false);
        
        Invoice__c inv = TestUtil.createreceivablesInvoice(so.id);
        inv.Order_Transaction_Type__c = trac.id;
        update inv;
        
        Test.startTest();
        PageReference pref = Page.CreateRefundPage;
        ApexPages.currentPage().getParameters().put('Id',so.id);
        test.setCurrentPage(pref);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(so);   
        RefundController refundProcess = new RefundController(sc);
        
        refundProcess.isRefundAll=false;
        RefundController.bundleItemsorderWrapper bundleWrapper = new RefundController.bundleItemsorderWrapper(bundleSol,'1','1','100','20','0','120','50');
        List<RefundController.bundleItemsorderWrapper> bundleWrapperList = new List<RefundController.bundleItemsorderWrapper>();
        bundleWrapperList.add(bundleWrapper);
        
        RefundController.ItemsorderWrapper itemWrapper = new RefundController.ItemsorderWrapper(bundleSetSol,bundleWrapperList,'1','1500','100','20','0','120','50','0.00',false);
        
        refundProcess.soRelatedList.put(manufactureAccount.name+bundleSetSol.id,itemWrapper);
        
        refundProcess.getSelectRefundoption();
        refundProcess.getSelectLocationoption();
        refundProcess.getSelectReasonoption();
        
        refundProcess.selectRefund = 'Cancellation';
        refundProcess.selectCanReason = 'Customer Preference';
        refundProcess.isClickedonRefund();
        refundProcess.selectLocation = RP1.name;
        refundProcess.onChangecalcInvoice();
        Test.StopTest();
        System.assertEquals(RP1.name, refundProcess.selectLocation);
    }
    
    public static testMethod void onChangecalcInvoiceCompensation() 
    {
        Account ac = TestUtil.createCustomerAccount();
        Account manufactureAccount = getmanufactureAcc();
        Account deliveryAccount = TestUtil.createDeliveryAccount();
        
        Products__c configPro = TestUtil.createConfigProduct();
        Products__c pro = TestUtil.createSimpleProduct(configPro.id,Null);
        
        Payment_Method__c pm = TestUtil.createpaymentMethod(ac.id,'Credit Card (Authorize.net)');
        
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, deliveryAccount.id, pm.id);
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,4);
        Sol.Quantity_Invoiced__c = 4;
        update Sol;
        SO_Line_Items__c configSol = TestUtil.createsalesOrderLineItem(so.id, pro.id, configPro.id,null,4);
        configSol.Quantity_Invoiced__c = 4;
        update configSol;
        
        Transaction__c trac = TestUtil.createTrasaction(so.id,pm.id,'CAPTURE_ONLY');
        trac.Amount__c = 500;
        trac.Refunded_Amount__c = 100;
        update trac;
        
        Refund_Process__c RP = TestUtil.createRefundProcess('Customer Location',true);
        
        Refund_Process__c RP1 = TestUtil.createRefundProcess('Delivery Hub',true);
        
        Refund_Process__c RP2 = TestUtil.createRefundProcess('En Route',false);
        
        Invoice__c inv = TestUtil.createreceivablesInvoice(so.id);
        inv.Order_Transaction_Type__c = trac.id;
        update inv;
        
        Test.startTest();
        PageReference pref = Page.CreateRefundPage;
        ApexPages.currentPage().getParameters().put('Id',so.id);
        test.setCurrentPage(pref);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(so);   
        RefundController refundProcess = new RefundController(sc);
        
        RefundController.ItemsorderWrapper itemWrapper = new RefundController.ItemsorderWrapper(Sol,null,'1','1500','100','20','0','120','50','0.00',false);
        
        refundProcess.soRelatedList.put(manufactureAccount.name+Sol.id,itemWrapper);
        
        refundProcess.isRefundAll=true;
        refundProcess.selectRefund = 'Compensation';
        refundProcess.getSelectRefundoption();
        refundProcess.getSelectCompReasonoption();
        refundProcess.getSelectConditionaloption();
        refundProcess.isClickedonRefund();
        refundProcess.onChangecalcInvoice();        
        Test.StopTest();
        System.assertEquals('Compensation', refundProcess.selectRefund);
    }
    
    public static testMethod void testsubmitRefundthroughCancellation() 
    {
        Account ac = TestUtil.createCustomerAccount();
        Account manufactureAccount = getmanufactureAcc();
        Account deliveryAccount = TestUtil.createDeliveryAccount();
        
        Products__c configPro = TestUtil.createConfigProduct();
        Products__c pro = TestUtil.createSimpleProduct(configPro.id,Null);
        Products__c bundlePro = getbundlePro();
        
        Bundle_Item__c bundleItem = TestUtil.createBundleItemProduct(configPro.id, bundlePro.id);
        
        Payment_Method__c pm = TestUtil.createpaymentMethod(ac.id,'Credit Card (Authorize.net)');
        
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, deliveryAccount.id, pm.id);
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,4);
        Sol.Quantity_Invoiced__c = 4;
        Sol.Total__c= 20000;
        update Sol;
        
        SO_Line_Items__c configSol = TestUtil.createsalesOrderLineItem(so.id, pro.id, configPro.id,null,4);
        configSol.Quantity_Invoiced__c = 4;
        configSol.Total__c= 20000;
        update configSol;
        
        SO_Line_Items__c bundleSetSol = TestUtil.createsalesOrderLineItem(so.id, bundlePro.id, null,null,4);
        bundleSetSol.Quantity_Invoiced__c = 4;
        bundleSetSol.Total__c= 20000;
        update bundleSetSol;
        
        SO_Line_Items__c bundleSol = TestUtil.createsalesOrderLineItem(so.id, bundlePro.id, null,bundleItem.id,4);
        bundleSol.Quantity_Invoiced__c = 4;
        bundleSol.Total__c= 20000;
        update bundleSol;
        
        Transaction__c trac = TestUtil.createTrasaction(so.id,pm.id,'CAPTURE_ONLY');
        trac.Amount__c = 2000;
        trac.Refunded_Amount__c = 0;
        update trac;
        
        Refund_Process__c RP = TestUtil.createRefundProcess('Customer Location',true);
        Refund_Process__c RP1 = TestUtil.createRefundProcess('Delivery Hub',true);
        Refund_Process__c RP2 = TestUtil.createRefundProcess('En Route',false);
        
        Invoice__c inv = TestUtil.createreceivablesInvoice(so.id);
        inv.Order_Transaction_Type__c = trac.id;
        update inv;
        
        Test.startTest();
        PageReference pref = Page.CreateRefundPage;
        ApexPages.currentPage().getParameters().put('Id',so.id);
        test.setCurrentPage(pref);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(so);   
        RefundController refundProcess = new RefundController(sc);
        
        RefundController.bundleItemsorderWrapper bundleWrapper = new RefundController.bundleItemsorderWrapper(bundleSol,'1','1','100','20','0','120','50');
        List<RefundController.bundleItemsorderWrapper> bundleWrapperList = new List<RefundController.bundleItemsorderWrapper>();
        bundleWrapperList.add(bundleWrapper);
        
        RefundController.ItemsorderWrapper itemWrapper = new RefundController.ItemsorderWrapper(bundleSetSol,bundleWrapperList,'1','1500','100','20','0','120','50','0.00',false);
        
        refundProcess.soRelatedList.put(manufactureAccount.name+bundleSetSol.id,itemWrapper);
        
        refundProcess.isselectRefund();       
        refundProcess.isRefundAll = true;
        refundProcess.selectRefund = 'Cancellation';
        refundProcess.selectLocation = RP.Name;
        refundProcess.selectConditioalFurniture = 'Unopened';
        refundProcess.isPickupNeeded = true;
        refundProcess.selectCanReason = 'Customer Preference';
        refundProcess.invObj = inv;
        refundProcess.onChangecalcInvoice();
        refundProcess.isClickedonRefund();
        refundProcess.grandTotal = 0;
        List<String> ListElem = new List<String>(refundProcess.soRelatedList.keySet());

        refundProcess.soRelatedList.get(ListElem.get(0)).SoItem.Quantity_Refunded__c = 1;
        refundProcess.submitRefund();
        Test.StopTest();
    }
    
    public static testMethod void testsubmitRefundthroughCompensation() 
    {
        Account ac = TestUtil.createCustomerAccount();
        Account manufactureAccount = getmanufactureAcc();
        Account deliveryAccount = TestUtil.createDeliveryAccount();
        
        Products__c configPro = TestUtil.createConfigProduct();
        Products__c pro = TestUtil.createSimpleProduct(configPro.id,Null);
        Products__c bundlePro = getbundlePro();
        
        Bundle_Item__c bundleItem = TestUtil.createBundleItemProduct(configPro.id, bundlePro.id);
        
        Payment_Method__c pm = TestUtil.createpaymentMethod(ac.id,'Credit Card (Authorize.net)');
        
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, deliveryAccount.id, pm.id);
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,4);
        Sol.Quantity_Invoiced__c = 4;
        update Sol;
        
        SO_Line_Items__c configSol = TestUtil.createsalesOrderLineItem(so.id, pro.id, configPro.id,null,4);
        configSol.Quantity_Invoiced__c = 4;
        update configSol;
        
        SO_Line_Items__c bundleSetSol = TestUtil.createsalesOrderLineItem(so.id, bundlePro.id, null,null,4);
        bundleSetSol.Quantity_Invoiced__c = 4;
        update bundleSetSol;
        
        SO_Line_Items__c bundleSol = TestUtil.createsalesOrderLineItem(so.id, bundlePro.id, null,bundleItem.id,4);
        bundleSol.Quantity_Invoiced__c = 4;
        update bundleSol;
        
        Transaction__c trac = TestUtil.createTrasaction(so.id,pm.id,'CAPTURE_ONLY');
        trac.Amount__c = 20000;
        trac.Refunded_Amount__c = 0;
        update trac;
        
        Refund_Process__c RP = TestUtil.createRefundProcess('Customer Location',true);
        
        Refund_Process__c RP1 = TestUtil.createRefundProcess('Delivery Hub',true);
        
        Refund_Process__c RP2 = TestUtil.createRefundProcess('En Route',false);
        
        Invoice__c inv = TestUtil.createreceivablesInvoice(so.id);
        inv.Order_Transaction_Type__c = trac.id;
        update inv;
        
        Test.startTest();
        PageReference pref = Page.CreateRefundPage;
        ApexPages.currentPage().getParameters().put('Id',so.id);
        test.setCurrentPage(pref);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(so);   
        RefundController refundProcess = new RefundController(sc);
        
        RefundController.bundleItemsorderWrapper bundleWrapper = new RefundController.bundleItemsorderWrapper(bundleSol,'1','1','100','20','0','120','50');
        List<RefundController.bundleItemsorderWrapper> bundleWrapperList = new List<RefundController.bundleItemsorderWrapper>();
        bundleWrapperList.add(bundleWrapper);
        
        RefundController.ItemsorderWrapper itemWrapper = new RefundController.ItemsorderWrapper(bundleSetSol,bundleWrapperList,'1','1500','100','20','0','120','50','0.00',false);
        
        refundProcess.soRelatedList.put(manufactureAccount.name+bundleSetSol.id,itemWrapper);
        
        refundProcess.isselectRefund();       
        refundProcess.isRefundAll = true;
        refundProcess.selectRefund = 'Compensation';
        refundProcess.invObj = inv;
        
        refundProcess.onChangecalcInvoice();
        refundProcess.isClickedonRefund();
        refundProcess.selectCompReason = 'Slightly Damaged';
        refundProcess.selectReason = 'Renegade';
        refundProcess.customDiscount =10000;
        refundProcess.submitRefund();
        Test.StopTest();
        System.assertEquals('Compensation', refundProcess.selectRefund);
    }
    

public static testMethod void testsubmitRefundthroughCompensationEditedOrder() 
    {
        Account ac = TestUtil.createCustomerAccount();
        Account manufactureAccount = getmanufactureAcc();
        Account deliveryAccount = TestUtil.createDeliveryAccount();
        
        Products__c configPro = TestUtil.createConfigProduct();
        Products__c pro = TestUtil.createSimpleProduct(configPro.id,Null);
        Products__c bundlePro = getbundlePro();
        
        Bundle_Item__c bundleItem = TestUtil.createBundleItemProduct(configPro.id, bundlePro.id);
        
        Payment_Method__c pm = TestUtil.createpaymentMethod(ac.id,'Credit Card (Authorize.net)');
        
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, deliveryAccount.id, pm.id);
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,4);
        Sol.Quantity_Invoiced__c = 4;
        update Sol;
        
        SO_Line_Items__c configSol = TestUtil.createsalesOrderLineItem(so.id, pro.id, configPro.id,null,4);
        configSol.Quantity_Invoiced__c = 4;
        update configSol;
        
        SO_Line_Items__c bundleSetSol = TestUtil.createsalesOrderLineItem(so.id, bundlePro.id, null,null,4);
        bundleSetSol.Quantity_Invoiced__c = 4;
        update bundleSetSol;
        
        SO_Line_Items__c bundleSol = TestUtil.createsalesOrderLineItem(so.id, bundlePro.id, null,bundleItem.id,4);
        bundleSol.Quantity_Invoiced__c = 4;
        update bundleSol;
        
        Transaction__c trac = TestUtil.createTrasaction(so.id,pm.id,'CAPTURE_ONLY');
        trac.Amount__c = 20000;
        trac.Refunded_Amount__c = 0;
        update trac;
        
        Refund_Process__c RP = TestUtil.createRefundProcess('Customer Location',true);
        
        Refund_Process__c RP1 = TestUtil.createRefundProcess('Delivery Hub',true);
        
        Refund_Process__c RP2 = TestUtil.createRefundProcess('En Route',false);
        
        Invoice__c inv = TestUtil.createreceivablesInvoice(so.id);
        inv.Order_Transaction_Type__c = trac.id;
        update inv;
        
        Test.startTest();
        PageReference pref = Page.CreateRefundPage;
        ApexPages.currentPage().getParameters().put('Id',so.id);
        test.setCurrentPage(pref);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(so);   
        RefundController refundProcess = new RefundController(sc);
        
        RefundController.bundleItemsorderWrapper bundleWrapper = new RefundController.bundleItemsorderWrapper(bundleSol,'1','1','100','20','0','120','50');
        List<RefundController.bundleItemsorderWrapper> bundleWrapperList = new List<RefundController.bundleItemsorderWrapper>();
        bundleWrapperList.add(bundleWrapper);
        
        RefundController.ItemsorderWrapper itemWrapper = new RefundController.ItemsorderWrapper(bundleSetSol,bundleWrapperList,'1','1500','100','20','0','120','50','0.00',false);
        
        refundProcess.soRelatedList.put(manufactureAccount.name+bundleSetSol.id,itemWrapper);
        
        refundProcess.isselectRefund();       
        refundProcess.isRefundAll = true;
        refundProcess.selectRefund = 'Edited order';
        refundProcess.invObj = inv;
        
        refundProcess.onChangecalcInvoice();
        refundProcess.isClickedonRefund();
        refundProcess.selectCompReason = 'Slightly Damaged';
        refundProcess.selectReason = 'Renegade';
        refundProcess.customDiscount =10000;
        refundProcess.submitRefund();
        Test.StopTest();
        System.assertEquals('Edited order', refundProcess.selectRefund);
    }
    

    public static testMethod void testsubmitRefundthroughCancellationwithselectLocationwithNone() 
    {
        Account ac = TestUtil.createCustomerAccount();
        Account manufactureAccount = getmanufactureAcc();
        Account deliveryAccount = TestUtil.createDeliveryAccount();
        
        Products__c configPro = TestUtil.createConfigProduct();
        Products__c pro = TestUtil.createSimpleProduct(configPro.id,Null);
        Products__c bundlePro = getbundlePro();
        
        Bundle_Item__c bundleItem = TestUtil.createBundleItemProduct(configPro.id, bundlePro.id);
        
        Payment_Method__c pm = TestUtil.createpaymentMethod(ac.id,'Credit Card (Authorize.net)');
        
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, deliveryAccount.id, pm.id);
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,4);
        Sol.Quantity_Invoiced__c = 4;
        update Sol;
        
        SO_Line_Items__c configSol = TestUtil.createsalesOrderLineItem(so.id, pro.id, configPro.id,null,4);
        configSol.Quantity_Invoiced__c = 4;
        update configSol;
        
        SO_Line_Items__c bundleSetSol = TestUtil.createsalesOrderLineItem(so.id, bundlePro.id, null,null,4);
        bundleSetSol.Quantity_Invoiced__c = 4;
        update bundleSetSol;
        
        SO_Line_Items__c bundleSol = TestUtil.createsalesOrderLineItem(so.id, bundlePro.id, null,bundleItem.id,4);
        bundleSol.Quantity_Invoiced__c = 4;
        update bundleSol;
        
        Transaction__c trac = TestUtil.createTrasaction(so.id,pm.id,'CAPTURE_ONLY');
        trac.Amount__c = 20000;
        trac.Refunded_Amount__c = 0;
        update trac;
        
        Refund_Process__c RP = TestUtil.createRefundProcess('Customer Location',true);
        
        Refund_Process__c RP1 = TestUtil.createRefundProcess('Delivery Hub',true);
        
        Refund_Process__c RP2 = TestUtil.createRefundProcess('En Route',false);
        
        Invoice__c inv = TestUtil.createreceivablesInvoice(so.id);
        inv.Order_Transaction_Type__c = trac.id;
        update inv;
        
        Test.startTest();
        PageReference pref = Page.CreateRefundPage;
        ApexPages.currentPage().getParameters().put('Id',so.id);
        test.setCurrentPage(pref);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(so);   
        RefundController refundProcess = new RefundController(sc);
        
        RefundController.bundleItemsorderWrapper bundleWrapper = new RefundController.bundleItemsorderWrapper(bundleSol,'1','1','100','20','0','120','50');
        List<RefundController.bundleItemsorderWrapper> bundleWrapperList = new List<RefundController.bundleItemsorderWrapper>();
        bundleWrapperList.add(bundleWrapper);
        
        RefundController.ItemsorderWrapper itemWrapper = new RefundController.ItemsorderWrapper(bundleSetSol,bundleWrapperList,'1','1500','100','20','0','120','50','0.00',false);
        
        refundProcess.soRelatedList.put(manufactureAccount.name+bundleSetSol.id,itemWrapper);
        
        refundProcess.isRefundAll=true;
        refundProcess.invObj = inv;
        refundProcess.selectRefund = 'Cancellation';
        refundProcess.selectLocation = 'none';
        refundProcess.selectConditioalFurniture = 'none';
        
        refundProcess.isClickedonRefund();
        refundProcess.submitRefund();
        Test.StopTest();
        System.assertEquals('none', refundProcess.selectLocation);
    }
    
    public static testMethod void testsubmitRefundthroughCancellationwithselectConditioalFurniturewithNone() 
    {
        Account ac = TestUtil.createCustomerAccount();
        Account manufactureAccount = getmanufactureAcc();
        Account deliveryAccount = TestUtil.createDeliveryAccount();
        
        Products__c configPro = TestUtil.createConfigProduct();
        Products__c pro = TestUtil.createSimpleProduct(configPro.id,Null);
        Products__c bundlePro = getbundlePro();
        
        Bundle_Item__c bundleItem = TestUtil.createBundleItemProduct(configPro.id, bundlePro.id);
        
        Payment_Method__c pm = TestUtil.createpaymentMethod(ac.id,'Credit Card (Authorize.net)');
        
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, deliveryAccount.id, pm.id);
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,4);
        Sol.Quantity_Invoiced__c = 4;
        update Sol;
        
        SO_Line_Items__c configSol = TestUtil.createsalesOrderLineItem(so.id, pro.id, configPro.id,null,4);
        configSol.Quantity_Invoiced__c = 4;
        update configSol;
        
        SO_Line_Items__c bundleSetSol = TestUtil.createsalesOrderLineItem(so.id, bundlePro.id, null,null,4);
        bundleSetSol.Quantity_Invoiced__c = 4;
        update bundleSetSol;
        
        SO_Line_Items__c bundleSol = TestUtil.createsalesOrderLineItem(so.id, bundlePro.id, null,bundleItem.id,4);
        bundleSol.Quantity_Invoiced__c = 4;
        update bundleSol;
        
        Transaction__c trac = TestUtil.createTrasaction(so.id,pm.id,'CAPTURE_ONLY');
        trac.Amount__c = 20000;
        trac.Refunded_Amount__c = 0;
        update trac;
        
        Refund_Process__c RP = TestUtil.createRefundProcess('Customer Location',true);
        
        Refund_Process__c RP1 = TestUtil.createRefundProcess('Delivery Hub',true);
        
        Refund_Process__c RP2 = TestUtil.createRefundProcess('En Route',false);
        
        Invoice__c inv = TestUtil.createreceivablesInvoice(so.id);
        inv.Order_Transaction_Type__c = trac.id;
        update inv;
        
        Test.startTest();
        PageReference pref = Page.CreateRefundPage;
        ApexPages.currentPage().getParameters().put('Id',so.id);
        test.setCurrentPage(pref);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(so);   
        RefundController refundProcess = new RefundController(sc);
        
        RefundController.bundleItemsorderWrapper bundleWrapper = new RefundController.bundleItemsorderWrapper(bundleSol,'1','1','100','20','0','120','50');
        List<RefundController.bundleItemsorderWrapper> bundleWrapperList = new List<RefundController.bundleItemsorderWrapper>();
        bundleWrapperList.add(bundleWrapper);
        
        RefundController.ItemsorderWrapper itemWrapper = new RefundController.ItemsorderWrapper(bundleSetSol,bundleWrapperList,'1','1500','100','20','0','120','50','0.00',false);
        
        refundProcess.soRelatedList.put(manufactureAccount.name+bundleSetSol.id,itemWrapper);        
        refundProcess.invObj = inv;
        refundProcess.selectRefund = 'Cancellation';
        refundProcess.selectLocation = RP2.Name;
        refundProcess.selectConditioalFurniture = 'none';
        
        refundProcess.isClickedonRefund();
        refundProcess.submitRefund();
        Test.StopTest();
        System.assertEquals('none', refundProcess.selectConditioalFurniture);
    }
    
    public static testMethod void testsubmitRefundthroughCompensationwithselectReasonwithNone() 
    {
        Account ac = TestUtil.createCustomerAccount();
        Account manufactureAccount = getmanufactureAcc();
        Account deliveryAccount = TestUtil.createDeliveryAccount();
        
        Products__c configPro = TestUtil.createConfigProduct();
        Products__c pro = TestUtil.createSimpleProduct(configPro.id,Null);
        Products__c bundlePro = getbundlePro();
        
        Bundle_Item__c bundleItem = TestUtil.createBundleItemProduct(configPro.id, bundlePro.id);
        
        Payment_Method__c pm = TestUtil.createpaymentMethod(ac.id,'Credit Card (Authorize.net)');
        
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, deliveryAccount.id, pm.id);
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,4);
        Sol.Quantity_Invoiced__c = 4;
        update Sol;
        
        SO_Line_Items__c configSol = TestUtil.createsalesOrderLineItem(so.id, pro.id, configPro.id,null,4);
        configSol.Quantity_Invoiced__c = 4;
        update configSol;
        
        SO_Line_Items__c bundleSetSol = TestUtil.createsalesOrderLineItem(so.id, bundlePro.id, null,null,4);
        bundleSetSol.Quantity_Invoiced__c = 4;
        update bundleSetSol;
        
        SO_Line_Items__c bundleSol = TestUtil.createsalesOrderLineItem(so.id, bundlePro.id, null,bundleItem.id,4);
        bundleSol.Quantity_Invoiced__c = 4;
        update bundleSol;
        
        Transaction__c trac = TestUtil.createTrasaction(so.id,pm.id,'CAPTURE_ONLY');
        trac.Amount__c = 20000;
        trac.Refunded_Amount__c = 0;
        update trac;
        
        Refund_Process__c RP = TestUtil.createRefundProcess('Customer Location',true);
        
        Refund_Process__c RP1 = TestUtil.createRefundProcess('Delivery Hub',true);
        
        Refund_Process__c RP2 = TestUtil.createRefundProcess('En Route',false);
        
        Invoice__c inv = TestUtil.createreceivablesInvoice(so.id);
        inv.Order_Transaction_Type__c = trac.id;
        update inv;
        
        Test.startTest();
        PageReference pref = Page.CreateRefundPage;
        ApexPages.currentPage().getParameters().put('Id',so.id);
        test.setCurrentPage(pref);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(so);   
        RefundController refundProcess = new RefundController(sc);
        
        RefundController.bundleItemsorderWrapper bundleWrapper = new RefundController.bundleItemsorderWrapper(bundleSol,'1','1','100','20','0','120','50');
        List<RefundController.bundleItemsorderWrapper> bundleWrapperList = new List<RefundController.bundleItemsorderWrapper>();
        bundleWrapperList.add(bundleWrapper);
        
        RefundController.ItemsorderWrapper itemWrapper = new RefundController.ItemsorderWrapper(bundleSetSol,bundleWrapperList,'1','1500','100','20','0','120','50','0.00',false);
        
        refundProcess.soRelatedList.put(manufactureAccount.name+bundleSetSol.id,itemWrapper);
        
        refundProcess.isRefundAll=true;
        refundProcess.invObj = inv;
        refundProcess.selectRefund = 'Compensation';
        refundProcess.selectReason = 'none';
        refundProcess.selectCompReason = 'none';
        refundProcess.compensationComments = 'Test Comments';
        
        refundProcess.isClickedonRefund();
        refundProcess.submitRefund();
        
        Test.StopTest();
        System.assertEquals('none', refundProcess.selectReason);
    }
    



    public static testMethod void testsubmitRefundthroughCompensationwithselectCompReasonwithNone() 
    {
        Account ac = TestUtil.createCustomerAccount();
        Account manufactureAccount = getmanufactureAcc();
        Account deliveryAccount = TestUtil.createDeliveryAccount();
        
        Products__c configPro = TestUtil.createConfigProduct();
        Products__c pro = TestUtil.createSimpleProduct(configPro.id,Null);
        Products__c bundlePro = getbundlePro();
        
        Bundle_Item__c bundleItem = TestUtil.createBundleItemProduct(configPro.id, bundlePro.id);
        
        Payment_Method__c pm = TestUtil.createpaymentMethod(ac.id,'Credit Card (Authorize.net)');
        
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, deliveryAccount.id, pm.id);
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,4);
        Sol.Quantity_Invoiced__c = 4;
        update Sol;
        
        SO_Line_Items__c configSol = TestUtil.createsalesOrderLineItem(so.id, pro.id, configPro.id,null,4);
        configSol.Quantity_Invoiced__c = 4;
        update configSol;
        
        SO_Line_Items__c bundleSetSol = TestUtil.createsalesOrderLineItem(so.id, bundlePro.id, null,null,4);
        bundleSetSol.Quantity_Invoiced__c = 4;
        update bundleSetSol;
        
        SO_Line_Items__c bundleSol = TestUtil.createsalesOrderLineItem(so.id, bundlePro.id, null,bundleItem.id,4);
        bundleSol.Quantity_Invoiced__c = 4;
        update bundleSol;
        
        Transaction__c trac = TestUtil.createTrasaction(so.id,pm.id,'CAPTURE_ONLY');
        trac.Amount__c = 200;
        trac.Refunded_Amount__c = 0;
        update trac;
        
        Refund_Process__c RP = TestUtil.createRefundProcess('Customer Location',true);
        
        Refund_Process__c RP1 = TestUtil.createRefundProcess('Delivery Hub',true);
        
        Refund_Process__c RP2 = TestUtil.createRefundProcess('En Route',false);
        
        Invoice__c inv = TestUtil.createreceivablesInvoice(so.id);
        inv.Order_Transaction_Type__c = trac.id;
        update inv;
        
        Test.startTest();
        PageReference pref = Page.CreateRefundPage;
        ApexPages.currentPage().getParameters().put('Id',so.id);
        test.setCurrentPage(pref);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(so);   
        RefundController refundProcess = new RefundController(sc);
        
        RefundController.bundleItemsorderWrapper bundleWrapper = new RefundController.bundleItemsorderWrapper(bundleSol,'1','1','100','20','0','120','50');
        List<RefundController.bundleItemsorderWrapper> bundleWrapperList = new List<RefundController.bundleItemsorderWrapper>();
        bundleWrapperList.add(bundleWrapper);
        
        RefundController.ItemsorderWrapper itemWrapper = new RefundController.ItemsorderWrapper(bundleSetSol,bundleWrapperList,'1','1500','100','20','0','120','50','0.00',false);
        
        refundProcess.soRelatedList.put(manufactureAccount.name+bundleSetSol.id,itemWrapper);        
        refundProcess.isRefundAll=true;
        refundProcess.invObj = inv;
        refundProcess.selectLocation = RP2.name;            
        refundProcess.selectRefund = 'Compensation';
        refundProcess.selectReason = 'renegade';
        refundProcess.selectCompReason = 'none';
        refundProcess.compensationComments = 'Test Comments';
        
        refundProcess.isClickedonRefund();
        refundProcess.submitRefund();
        Test.StopTest();
        System.assertEquals('none', refundProcess.selectCompReason);
    }
    
    public static testMethod void submitRefundwithSelectRefundasNull()
    {
        Account ac = TestUtil.createCustomerAccount();
        Account manufactureAccount = getmanufactureAcc();
        Account deliveryAccount = TestUtil.createDeliveryAccount();
        
        Products__c configPro = TestUtil.createConfigProduct();
        Products__c pro = TestUtil.createSimpleProduct(configPro.id,Null);
        Products__c bundlePro = getbundlePro();
        
        Bundle_Item__c bundleItem = TestUtil.createBundleItemProduct(configPro.id, bundlePro.id);
        
        Payment_Method__c pm = TestUtil.createpaymentMethod(deliveryAccount.id,'Credit Card (Authorize.net)');
        
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, deliveryAccount.id, pm.id);
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,4);
        Sol.Quantity_Invoiced__c = 4;
        update Sol;
        
        SO_Line_Items__c configSol = TestUtil.createsalesOrderLineItem(so.id, pro.id, configPro.id,null,4);
        configSol.Quantity_Invoiced__c = 4;
        update configSol;
        
        SO_Line_Items__c bundleSetSol = TestUtil.createsalesOrderLineItem(so.id, bundlePro.id, null,null,4);
        bundleSetSol.Quantity_Invoiced__c = 4;
        update bundleSetSol;
        
        SO_Line_Items__c bundleSol = TestUtil.createsalesOrderLineItem(so.id, bundlePro.id, null,bundleItem.id,4);
        bundleSol.Quantity_Invoiced__c = 4;
        update bundleSol;
        
        Transaction__c trac = TestUtil.createTrasaction(so.id,pm.id,'CAPTURE_ONLY');
        trac.Amount__c = 200;
        trac.Refunded_Amount__c = 0;
        update trac;
        
        Refund_Process__c RP = TestUtil.createRefundProcess('Customer Location',true);
        
        Refund_Process__c RP1 = TestUtil.createRefundProcess('Delivery Hub',true);
        
        Refund_Process__c RP2 = TestUtil.createRefundProcess('En Route',false);
        
        Invoice__c inv = TestUtil.createreceivablesInvoice(so.id);
        inv.Order_Transaction_Type__c = trac.id;
        update inv;
        
        Test.startTest();
        PageReference pref = Page.CreateRefundPage;
        ApexPages.currentPage().getParameters().put('Id',so.id);
        test.setCurrentPage(pref);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(so);   
        RefundController refundProcess = new RefundController(sc);
        
        RefundController.bundleItemsorderWrapper bundleWrapper = new RefundController.bundleItemsorderWrapper(bundleSol,'1','1','100','20','0','120','50');
        List<RefundController.bundleItemsorderWrapper> bundleWrapperList = new List<RefundController.bundleItemsorderWrapper>();
        bundleWrapperList.add(bundleWrapper);
        
        RefundController.ItemsorderWrapper itemWrapper = new RefundController.ItemsorderWrapper(bundleSetSol,bundleWrapperList,'1','1500','100','20','0','120','50','0.00',false);
        
        refundProcess.invObj = inv;
        refundProcess.isRefundAll=true;
        
        refundProcess.selectRefund = 'none';
        refundProcess.submitRefund();
        Test.StopTest();
        System.assertEquals('none', refundProcess.selectRefund);
    }
    
    public static testMethod void RefundCallOutWithCreditCardWithTransaction()
    {
        Account ac = TestUtil.createCustomerAccount();
        Account manufactureAccount = getmanufactureAcc();
        Account deliveryAccount = TestUtil.createDeliveryAccount();
        
        Products__c configPro = TestUtil.createConfigProduct();
        Products__c pro = TestUtil.createSimpleProduct(configPro.id,Null);
        Products__c bundlePro = getbundlePro();
        
        Bundle_Item__c bundleItem = TestUtil.createBundleItemProduct(configPro.id, bundlePro.id);
        
        Payment_Method__c pm = TestUtil.createpaymentMethod(ac.id,'Credit Card (Authorize.net)');
        
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, deliveryAccount.id, pm.id);
                
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,4);
        Sol.Quantity_Invoiced__c = 4;
        update Sol;
        
        SO_Line_Items__c configSol = TestUtil.createsalesOrderLineItem(so.id, pro.id, configPro.id,null,4);
        configSol.Quantity_Invoiced__c = 4;
        update configSol;
        
        SO_Line_Items__c bundleSetSol = TestUtil.createsalesOrderLineItem(so.id, bundlePro.id, null,null,4);
        bundleSetSol.Quantity_Invoiced__c = 4;
        update bundleSetSol;
        
        SO_Line_Items__c bundleSol = TestUtil.createsalesOrderLineItem(so.id, bundlePro.id, null,bundleItem.id,4);
        bundleSol.Quantity_Invoiced__c = 4;
        update bundleSol;
        
        Transaction__c trac = TestUtil.createTrasaction(so.id,pm.id,'CAPTURE_ONLY');
        trac.Amount__c = 200;
        trac.Status__c='Captured';
        trac.Refunded_Amount__c = 0;
        update trac;
        
        Refund_Process__c RP = TestUtil.createRefundProcess('Customer Location',true);
        
        Refund_Process__c RP1 = TestUtil.createRefundProcess('Delivery Hub',true);
        
        Refund_Process__c RP2 = TestUtil.createRefundProcess('En Route',false);
        
        Invoice__c inv = TestUtil.createreceivablesInvoice(so.id);
        inv.Order_Transaction_Type__c = trac.id;
        update inv;
        
        Test.startTest();
        PageReference pref = Page.CreateRefundPage;
        ApexPages.currentPage().getParameters().put('Id',so.id);
        test.setCurrentPage(pref);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(so);   
        
        so.Payment_Method__c = 'Credit Card (Authorize.net)';
        update so;
        Test.setMock(HttpCalloutMock.class, new SalesOrder_AuthorizeDotNetHttpMock());
        RefundController.refund(''+so.id,''+inv.id,''+pm.id,100,0, system.now());
        
        Test.StopTest();
    }
    
    public static testMethod void RefundCallOutWithPayPal()
    {
        Account ac = TestUtil.createCustomerAccount();
        Account manufactureAccount = getmanufactureAcc();
        Account deliveryAccount = TestUtil.createDeliveryAccount();
        
        Products__c configPro = TestUtil.createConfigProduct();
        Products__c pro = TestUtil.createSimpleProduct(configPro.id,Null);
        Products__c bundlePro = getbundlePro();
        
        Bundle_Item__c bundleItem = TestUtil.createBundleItemProduct(configPro.id, bundlePro.id);
        
        Payment_Method__c pm = TestUtil.createpaymentMethod(ac.id,'PayPal');
        
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, deliveryAccount.id, pm.id);
        so.Payment_Method__c = 'PayPal';
        update so;
        
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,4);
        Sol.Quantity_Invoiced__c = 4;
        update Sol;
        
        SO_Line_Items__c configSol = TestUtil.createsalesOrderLineItem(so.id, pro.id, configPro.id,null,4);
        configSol.Quantity_Invoiced__c = 4;
        update configSol;
        
        SO_Line_Items__c bundleSetSol = TestUtil.createsalesOrderLineItem(so.id, bundlePro.id, null,null,4);
        bundleSetSol.Quantity_Invoiced__c = 4;
        update bundleSetSol;
        
        SO_Line_Items__c bundleSol = TestUtil.createsalesOrderLineItem(so.id, bundlePro.id, null,bundleItem.id,4);
        bundleSol.Quantity_Invoiced__c = 4;
        update bundleSol;
        
        Transaction__c trac = TestUtil.createTrasaction(so.id,pm.id,'CAPTURE_ONLY');
        trac.Amount__c = 200;
        trac.Status__c='Captured';
        trac.Refunded_Amount__c = 0;
        update trac;
        
        Refund_Process__c RP = TestUtil.createRefundProcess('Customer Location',true);
        
        Refund_Process__c RP1 = TestUtil.createRefundProcess('Delivery Hub',true);
        
        Refund_Process__c RP2 = TestUtil.createRefundProcess('En Route',false);
        
        Invoice__c inv = TestUtil.createreceivablesInvoice(so.id);
        inv.Order_Transaction_Type__c = trac.id;
        update inv;
        
        Test.startTest();
        PageReference pref = Page.CreateRefundPage;
        ApexPages.currentPage().getParameters().put('Id',so.id);
        test.setCurrentPage(pref);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(so);   
        RefundController refundProcess = new RefundController(sc);
        
        Test.setMock(HttpCalloutMock.class, new SalesOrder_AuthorizeDotNetHttpMock());
        RefundController.refund(''+so.id,''+inv.id,''+pm.id,100,0, system.now());        
        Test.StopTest();
    }
    	@isTest
        public static void GppCancelationTest() 
    	{
        Account ac = TestUtil.createCustomerAccount();
        Account manufactureAccount = getmanufactureAcc();
        Account deliveryAccount = TestUtil.createDeliveryAccount();
        
        Products__c configPro = TestUtil.createConfigProduct();
        Products__c pro = TestUtil.createSimpleProduct(configPro.id,Null);
        Products__c bundlePro = getbundlePro();
        
        Bundle_Item__c bundleItem = TestUtil.createBundleItemProduct(configPro.id, bundlePro.id);
        
        Payment_Method__c pm = TestUtil.createpaymentMethod(ac.id,'Credit Card (Authorize.net)');
        
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, deliveryAccount.id, pm.id);
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,4);
        Sol.Quantity_Invoiced__c = 4;
        update Sol;
        
        SO_Line_Items__c configSol = TestUtil.createsalesOrderLineItem(so.id, pro.id, configPro.id,null,4);
        configSol.Quantity_Invoiced__c = 4;
        update configSol;
        
        SO_Line_Items__c bundleSetSol = TestUtil.createsalesOrderLineItem(so.id, bundlePro.id, null,null,4);
        bundleSetSol.Quantity_Invoiced__c = 4;
        update bundleSetSol;
        
        SO_Line_Items__c bundleSol = TestUtil.createsalesOrderLineItem(so.id, bundlePro.id, null,bundleItem.id,4);
        bundleSol.Quantity_Invoiced__c = 4;
        update bundleSol;
        
        Transaction__c trac = TestUtil.createTrasaction(so.id,pm.id,'CAPTURE_ONLY');
        trac.Amount__c = 20000;
        trac.Refunded_Amount__c = 0;
        update trac;
        
        Refund_Process__c RP = TestUtil.createRefundProcess('Customer Location',true);
        
        Refund_Process__c RP1 = TestUtil.createRefundProcess('Delivery Hub',true);
        
        Refund_Process__c RP2 = TestUtil.createRefundProcess('En Route',false);
        
        Invoice__c inv = TestUtil.createreceivablesInvoice(so.id);
        inv.Order_Transaction_Type__c = trac.id;
        update inv;
        
        Test.startTest();
        PageReference pref = Page.CreateRefundPage;
        ApexPages.currentPage().getParameters().put('Id',so.id);
        test.setCurrentPage(pref);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(so);   
        RefundController refundProcess = new RefundController(sc);
        
        RefundController.bundleItemsorderWrapper bundleWrapper = new RefundController.bundleItemsorderWrapper(bundleSol,'1','1','100','20','0','120','50');
        List<RefundController.bundleItemsorderWrapper> bundleWrapperList = new List<RefundController.bundleItemsorderWrapper>();
        bundleWrapperList.add(bundleWrapper);
        
        RefundController.ItemsorderWrapper itemWrapper = new RefundController.ItemsorderWrapper(bundleSetSol,bundleWrapperList,'1','1500','100','20','0','120','50','0.00',false);
        //getTableData
                
        refundProcess.invObj = inv;
        //refundProcess.selectRefund = 'Cancellation';
        refundProcess.blockRefund();
            
        refundProcess.selectLocation = RP2.Name;
        refundProcess.selectConditioalFurniture = 'Unopened';
        refundProcess.selectCanReason = 'Customer Preference';
        refundProcess.soRelatedList.put(manufactureAccount.name+bundleSetSol.id,itemWrapper);    
        refundProcess.getSelectCanReasonoption();
        refundProcess.getSelectShippingChargeOption();
        refundProcess.getSelectFormOfCompensationoption();
        refundProcess.submitRefund();
        refundProcess.getTableData();
        Test.StopTest();
        //System.assertEquals('none', refundProcess.selectConditioalFurniture);
    }
  
}