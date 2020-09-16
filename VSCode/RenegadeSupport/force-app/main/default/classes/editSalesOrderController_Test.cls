/*
*   Author : Sowdhanya Karri | Kairos Tech
*   Class  : editSalesOrderController_Test
*   Purpose: This class is to code coverage the editSalesOrderController Class.
*/
@isTest 
public with sharing class editSalesOrderController_Test 
{
    public static account customerAccount=new account();
    public static account internalAccount=new account();
    public static account manufacturerAccount=new account();
    public static account deliveryAccount=new account();
    
    public static list<Products__c> productsList = new list<Products__c> ();
    public static list<Bundle_Item__c > bundleItemList=new list<Bundle_Item__c > ();
    public static Products__c configProducts=new Products__c ();
    public static Products__c protectionProducts=new Products__c ();
    public static Products__c bundleProducts=new Products__c ();
    public static Products__c sinmpleProduct=new Products__c ();
    public static Paypal_OAuth__c paypalObj;
    public static Google_API__c googleAPI;
    public static AuthorizeDotNetTokens__c authObj {get;set;}
    
    public static SalesOrder__c getAfirmTaskDetails {get;set;}
    public static SalesOrder__c getPayPalTaskDetails {get;set;}
    public static SalesOrder__c getAmazonTaskDetails {get;set;}
    public static SalesOrder__c getManualTaskDetails {get;set;}
    public static MagentoAuth__c magentoAuth;
    public static MagentoTokens__c magentoToken;
    
    @testSetup static void setUp() {
        deliveryAccount = TestUtil.createDeliveryAccount();
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
        
        getAfirmTaskDetails = new SalesOrder__c(name='Affirm',Owner_Name__c=UserInfo.getName(),Task_Name__c='Follow-up the Order for Affirm');
        insert getAfirmTaskDetails;
        
        getPayPalTaskDetails = new SalesOrder__c(name='PayPal',Owner_Name__c=UserInfo.getName(),Task_Name__c='Generate Paypal Invoice');
        insert getPayPalTaskDetails;
        
        getAmazonTaskDetails = new SalesOrder__c(name='Amazon Payment',Owner_Name__c=UserInfo.getName(),Task_Name__c='Follow-up the Order for Amazon Payment');
        insert getAmazonTaskDetails;
        
        getManualTaskDetails = new SalesOrder__c(name='Manual Payment',Owner_Name__c=UserInfo.getName(),Task_Name__c='Follow-up the Order for Manual Payment');
        insert getManualTaskDetails;
        
        googleAPI = new Google_API__c(Name='Google API',Key__c='AIzaSyCAmP-yM5hc67O4stT-VyzMRmDTaVYfXzQ');
        insert googleAPI;
        
        bundleProducts = TestUtil.createBundleProduct();
        
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
        authObj.Endpoint__c = 'https://apitest.authorize.net/xml/v1/request.api';
        
        insert authObj;
    }

    @isTest
    public static void insertPaymentMethodTest() {

        Account customerAccount = TestUtil.createCustomerAccount();
        Account deliveryAccount = TestUtil.createDeliveryAccount();

        // --- //
        String payType = 'Credit Card';
        Payment_Method__c paymentMethod = TestUtil.createpaymentMethod(customerAccount.Id, payType);
        List<Payment_Method__c> paymentMethods = new List<Payment_Method__c>{paymentMethod};
    
        Sales_Order__c salesorderObject = TestUtil.createsalesOrder(customerAccount.Id, deliveryAccount.Id, paymentMethod.Id);
        Sales_Order__c savedSOObject = new Sales_Order__c(Id = salesorderObject.Id);
        Transaction__c transaction1 = TestUtil.createTrasaction(salesorderObject.Id, paymentMethod.Id,'AUTH_ONLY');
    
        ApexPages.StandardController controller = new ApexPages.StandardController(salesorderObject);
        editSalesOrderController esoController = new editSalesOrderController(controller);
        Boolean result = esoController.insertPaymentMethod(paymentMethods, savedSOObject);
        result = esoController.insertPaymentMethod(paymentMethods, salesorderObject);
      
        
		// --- //
        payType = 'Manual Payment';
        paymentMethod = TestUtil.createpaymentMethod(customerAccount.Id, payType);
        paymentMethod.Payment_Profile_ID__c = '123';
        paymentMethods = new List<Payment_Method__c>{paymentMethod};

        salesorderObject = TestUtil.createsalesOrder(customerAccount.Id, deliveryAccount.Id, paymentMethod.Id);
        savedSOObject = new Sales_Order__c(Id = salesorderObject.Id);
        transaction1 = TestUtil.createTrasaction(salesorderObject.Id, paymentMethod.Id,'AUTH_ONLY');

        controller = new ApexPages.StandardController(salesorderObject);
        esoController = new editSalesOrderController(controller);
        result = esoController.insertPaymentMethod(paymentMethods, savedSOObject);
        
       
        // --- //
        payType = 'Credit Card';
        paymentMethod = TestUtil.createpaymentMethod(customerAccount.Id, payType);
        paymentMethods = new List<Payment_Method__c>{paymentMethod};
        
        salesorderObject = TestUtil.createsalesOrder(customerAccount.Id, deliveryAccount.Id, paymentMethod.Id);
        customerAccount.Authorize_net_Profile_ID__c = null;
        update customerAccount;
		savedSOObject = new Sales_Order__c(Id = salesorderObject.Id);
        transaction1 = TestUtil.createTrasaction(salesorderObject.Id, paymentMethod.Id,'AUTH_ONLY');
  
        controller = new ApexPages.StandardController(salesorderObject);
        esoController = new editSalesOrderController(controller);
        
        //deleting soobject
        //delete salesorderObject;
        
        result = esoController.insertPaymentMethod(paymentMethods, savedSOObject);
        editSalesOrderController.transactionWrapper tw = new editSalesOrderController.transactionWrapper(null, null, null, null, null);
       
        
    }

    
    public static Products__c bundlePro() 
    {
        return [Select id,name from Products__c where recordType.Name='Bundled'];
    }
    
    @isTest
    public static void editSalesOrderTestMethod()
    {
        Tax_Percentage__c tpObj = new Tax_Percentage__c();
        tpObj.name='NY';
        tpObj.Percentage__c=8.62;
        insert tpObj;
        
        manufacturerAccount = TestUtil.createManufacturerAccount(true,false,'Email');
        
        Promotions__c promocodeObj = new Promotions__c();
        
        promocodeObj.Name='Test Prom';
        promocodeObj.Coupon_Code__c='Aico 100';
        promocodeObj.Min_Sub_Total__c=10;
        promocodeObj.Date_Expire__c=system.today().adddays(1);
        promocodeObj.Date_Start__c=system.today().adddays(-1);
        promocodeObj.Discount_Amount__c=200;
        promocodeObj.Type__c='Brand';
        promocodeObj.Brand__c=manufacturerAccount.name;
        
        insert promocodeObj;
        
        Promotions__c promocodeObj1=new Promotions__c();
        
        promocodeObj1.Name='Test Prom'; 
        promocodeObj1.Coupon_Code__c='summer 100';
        promocodeObj1.Min_Sub_Total__c=10;
        promocodeObj1.Date_Expire__c=system.today().adddays(1);
        promocodeObj1.Date_Start__c=system.today().adddays(-1);
        promocodeObj1.Discount_Amount__c=200;
        promocodeObj1.Type__c='General';
        promocodeObj1.Brands_to_Exclude__c = manufacturerAccount.name;
        
        insert promocodeObj1;
        
        internalAccount=TestUtil.createInternalEmployeeAccount(userinfo.getUserId());
        internalAccount.SalesRepAsUser__c=UserInfo.getUserId();
        update internalAccount;
        
        map<string,list<products__c>> configlist = new map<string,list<products__c>>();
        
        customerAccount = TestUtil.createCustomerAccount();
        
        configProducts = TestUtil.createConfigProduct();
        configProducts.Tier_Price_For_Bundle__c=20;
        update configProducts;
        
        protectionProducts = TestUtil.createprotectionProduct();
        bundleProducts = bundlePro();
        productsList.add(TestUtil.createSimpleProduct(configProducts.Id,manufacturerAccount.Id));
        productsList.add(TestUtil.createSimpleProduct(null,manufacturerAccount.Id));
        bundleItemList.add(TestUtil.createBundleItemProduct(configProducts.Id,bundleProducts.id));
        
        configlist.put(productsList[0].id,productsList);
        productsList.add(TestUtil.createSimpleProduct(configProducts.Id,manufacturerAccount.Id));
        
        sinmpleProduct=TestUtil.createSimpleProductwithoutMaster(manufacturerAccount.Id);
        
        Payment_Method__c pymentId=TestUtil.createpaymentMethod(customerAccount.Id,'Manual Payment');
        
        //Customer_Addresses__c cusAddressRecord=[select Account__r.Mobile__c,Account__r.Email__c,Name,Cell__c,City__c,Country__c,State__c,Street_Address__c,Telephone__c,Zip_Postal_Code__c from Customer_Addresses__c where Account__c=:customerAccount.id limit 1 ] ;
        Customer_Addresses__c billingAddress = TestUtil.customerAddress(customerAccount.id,'Primary Billing Address','Billing Account'); 
        Customer_Addresses__c shippingAddress = TestUtil.customerAddress(customerAccount.id,'Primary Shipping Address','Shipping Account');
        
        Sales_Order__c soOrdr=TestUtil.createsalesOrder(customerAccount.Id,deliveryAccount.Id,pymentId.id);
        
        soOrdr.Customer_Billing_Address__c=billingAddress.id;
        soOrdr.Customer_shipping_Address__c=shippingAddress.id;
        soOrdr.Order_Date__c=system.today();
        soOrdr.Check_for_Fraud__c = false;
        update soOrdr;
        soOrdr.Shipping_ZipCode__c = '47017';
        soOrdr.Billing_ZipCode__c = '47017';
        update soOrdr;
        
        SO_Line_Items__c SOItem=TestUtil.createsalesOrderLineItem(soOrdr.id,sinmpleProduct.id,null,null,1);
        SOItem=TestUtil.createsalesOrderLineItem(soOrdr.id,bundleProducts.id,productsList[0].id,bundleItemList[0].id,1);
        
        //test.startTest();
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(soOrdr);
        apexpages.currentpage().getparameters().put('id',soOrdr.id);
        editSalesOrderController editSalesOrderControllerObj = new editSalesOrderController(sc);
        
        editSalesOrderControllerObj.isSOModified();
        editSalesOrderController.BundleItemWrapper bundleWrapper = new editSalesOrderController.BundleItemWrapper(bundleItemList[0],configlist,true,'0',configProducts.name);
        editSalesOrderController.ProductWrapper ProductWrapper = new editSalesOrderController.ProductWrapper(productsList[0],configlist,true,configProducts.name,'0');
        
        editSalesOrderControllerObj.AutoFillAddress();
        editSalesOrderControllerObj.taxCalculation();
        editSalesOrderControllerObj.showDistance();
        
        editSalesOrderControllerObj.getSoRelated();
        
        editSalesOrderControllerObj.SalesorderObject.Promotion__c=promocodeObj1.id;
        editSalesOrderControllerObj.updatePromocode();
        
        apexpages.currentpage().getparameters().put('productID',bundleProducts.id);
        editSalesOrderControllerObj.addProduct();
        editSalesOrderControllerObj.addProduct();
        
        editSalesOrderControllerObj.productList = productsList;
        editSalesOrderControllerObj.getproducts();
        editSalesOrderControllerObj.OptionsId=bundleProducts.id;
        editSalesOrderControllerObj.getProductRelatedBundle();
        editSalesOrderControllerObj.getSoRelatedBundle();
        
        editSalesOrderControllerObj.updateProduct();
        editSalesOrderControllerObj.isSOModified();
        
        editSalesOrderControllerObj.cancelSalesOrder();
        
        // 
        editSalesOrderControllerObj.RemoveProduct();
        editSalesOrderControllerObj.UnRemoveProduct();
        
        Test.stopTest();
    }
    
    public static testmethod void editSalesOrderTestMethod1()
    {
        Tax_Percentage__c tpObj=new Tax_Percentage__c();
        tpObj.name='NY';
        tpObj.Percentage__c=8.62;
        insert tpObj;
        
        manufacturerAccount=TestUtil.createManufacturerAccount(true,false,'Email');
        
        Promotions__c promocodeObj=new Promotions__c();
        
        promocodeObj.Name='Test Prom';
        promocodeObj.Coupon_Code__c='Aico 100';
        promocodeObj.Min_Sub_Total__c=10;
        promocodeObj.Date_Expire__c=system.today().adddays(1);
        promocodeObj.Date_Start__c=system.today().adddays(-1);
        promocodeObj.Discount_Amount__c=200;
        promocodeObj.Type__c='Brand';
        promocodeObj.Brand__c=manufacturerAccount.name;
        
        insert promocodeObj;
        
        Promotions__c promocodeObj1=new Promotions__c();
        
        promocodeObj1.Name='Test Prom';
        promocodeObj1.Coupon_Code__c='summer 100';
        promocodeObj1.Min_Sub_Total__c=10;
        promocodeObj1.Date_Expire__c=system.today().adddays(1);
        promocodeObj1.Date_Start__c=system.today().adddays(-1);
        promocodeObj1.Discount_Amount__c=200;
        promocodeObj1.Type__c='General';
        promocodeObj1.Brands_to_Exclude__c = manufacturerAccount.name;
        
        insert promocodeObj1;
        
        internalAccount=TestUtil.createInternalEmployeeAccount(userinfo.getUserId());
        internalAccount.SalesRepAsUser__c=UserInfo.getUserId();
        update internalAccount;
        
        map<string,list<products__c>> configlist = new map<string,list<products__c>>();
        
        customerAccount=TestUtil.createCustomerAccount();
        
        configProducts=TestUtil.createConfigProduct();
        configProducts.Tier_Price_For_Bundle__c=20;
        update configProducts;
        
        protectionProducts=TestUtil.createprotectionProduct();
        bundleProducts = bundlePro();
        Bundle_Item__c bundleItem = TestUtil.createBundleItemProduct(configProducts.Id,bundleProducts.id);
        productsList.add(TestUtil.createSimpleProduct(configProducts.Id,manufacturerAccount.Id));
        productsList.add(TestUtil.createSimpleProduct(null,manufacturerAccount.Id));
        bundleItemList.add(TestUtil.createBundleItemProduct(configProducts.Id,bundleProducts.id));
        bundleItemList.add(bundleItem);
        //configProducts=TestUtil.createConfigProduct();
        
        configlist.put(productsList[0].id,productsList);
        productsList.add(TestUtil.createSimpleProduct(configProducts.Id,manufacturerAccount.Id));
        
        sinmpleProduct=TestUtil.createSimpleProductwithoutMaster(manufacturerAccount.Id);
        
        Payment_Method__c pymentId = TestUtil.createpaymentMethod(customerAccount.Id,'Manual Payment');
        
        Customer_Addresses__c billingAddress = TestUtil.customerAddress(customerAccount.id,'Primary Billing Address','Billing Account'); 
        Customer_Addresses__c shippingAddress = TestUtil.customerAddress(customerAccount.id,'Primary Shipping Address','Shipping Account');
        
        Sales_Order__c soOrdr=TestUtil.createsalesOrder(customerAccount.Id,deliveryAccount.Id,pymentId.id);
        
        soOrdr.Customer_Billing_Address__c = billingAddress.id;
        soOrdr.Customer_shipping_Address__c = shippingAddress.id;
        soOrdr.Order_Date__c=system.today();
        soOrdr.Check_for_Fraud__c = false;
        update soOrdr;
        
        SO_Line_Items__c SOItem=TestUtil.createsalesOrderLineItem(soOrdr.id,sinmpleProduct.id,null,null,1);
        SOItem=TestUtil.createsalesOrderLineItem(soOrdr.id,bundleProducts.id,productsList[0].id,bundleItemList[0].id,1);
        
        //test.startTest();
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(soOrdr);
        apexpages.currentpage().getparameters().put('id',soOrdr.id);
        editSalesOrderController editSalesOrderControllerObj = new editSalesOrderController(sc);
        
        editSalesOrderControllerObj.isSOModified();
        editSalesOrderController.BundleItemWrapper bundleWrapper = new editSalesOrderController.BundleItemWrapper(bundleItemList[0],configlist,true,'0',configProducts.name);
        editSalesOrderController.ProductWrapper ProductWrapper = new editSalesOrderController.ProductWrapper(productsList[0],configlist,true,configProducts.name,'0');
        
        editSalesOrderControllerObj.AutoFillAddress();
        editSalesOrderControllerObj.taxCalculation();
        editSalesOrderControllerObj.showDistance();
        
        editSalesOrderControllerObj.getSoRelated();
        
        editSalesOrderControllerObj.SalesorderObject.Promotion__c=promocodeObj.id;
        editSalesOrderControllerObj.updatePromocode();
        
        editSalesOrderControllerObj.SalesorderObject.Promotion__c=promocodeObj1.id;
        editSalesOrderControllerObj.updatePromocode();
        
        apexpages.currentpage().getparameters().put('productID',bundleProducts.id);
        editSalesOrderControllerObj.addProduct();
        editSalesOrderControllerObj.addProduct();
        
        editSalesOrderControllerObj.productList = productsList;
        editSalesOrderControllerObj.getproducts();
        editSalesOrderControllerObj.getSoRelatedBundle();
        editSalesOrderControllerObj.getProductRelatedBundle();
        editSalesOrderControllerObj.updateProduct();
        editSalesOrderControllerObj.SalesorderObject.Promotion__c = promocodeObj1.id;
        editSalesOrderControllerObj.AddProtectionPlan();
        editSalesOrderControllerObj.addProduct();
        editSalesOrderControllerObj.addBundleProduct();
        
        editSalesOrderControllerObj.UpdateBundelItems();
        editSalesOrderControllerObj.AddProtectionPlan();
        editSalesOrderControllerObj.showProtectionPlan();
        
        editSalesOrderControllerObj.custumpricetotal = 1500;
        editSalesOrderControllerObj.originalTotalDue = 10000;
        editSalesOrderControllerObj.paymentType='CreditCard';
        editSalesOrderControllerObj.submitOrder();
        Test.stopTest();
    }
    
    public static testmethod void editSalesOrderTestMethod2()
    {
        Promotions__c promocodeObj1=new Promotions__c();
        
        promocodeObj1.Name='Test Prom';
        promocodeObj1.Coupon_Code__c='summer 100';
        promocodeObj1.Min_Sub_Total__c=10;
        promocodeObj1.Date_Expire__c=system.today().adddays(1);
        promocodeObj1.Date_Start__c=system.today().adddays(-1);
        promocodeObj1.Discount_Amount__c=200;
        promocodeObj1.Type__c='General';
        promocodeObj1.Brands_to_Exclude__c = 'Ashley';
        
        insert promocodeObj1;
        
        internalAccount=TestUtil.createInternalEmployeeAccount(userinfo.getUserId());
        internalAccount.SalesRepAsUser__c=UserInfo.getUserId();
        update internalAccount;
        
        manufacturerAccount=TestUtil.createManufacturerAccount(true,false,'Email');
        
        customerAccount=TestUtil.createCustomerAccount();
        
        configProducts=TestUtil.createConfigProduct();
        configProducts.Tier_Price_For_Bundle__c=20;
        update configProducts;
        
        protectionProducts=TestUtil.createprotectionProduct();
        bundleProducts=bundlePro();
        configProducts=TestUtil.createConfigProduct();
        Bundle_Item__c bundleItem = TestUtil.createBundleItemProduct(configProducts.Id,bundleProducts.id);
        
        productsList.add(TestUtil.createSimpleProduct(configProducts.Id,manufacturerAccount.Id));
        productsList.add(TestUtil.createSimpleProduct(null,manufacturerAccount.Id));
        bundleItemList.add(bundleItem);
        productsList.add(TestUtil.createSimpleProduct(configProducts.Id,manufacturerAccount.Id));
        
        sinmpleProduct=TestUtil.createSimpleProductwithoutMaster(manufacturerAccount.Id);
        
        Payment_Method__c pymentId=TestUtil.createpaymentMethod(customerAccount.Id,'Manual Payment');
        
        Customer_Addresses__c billingAddress = TestUtil.customerAddress(customerAccount.id,'Primary Billing Address','Billing Account'); 
        Customer_Addresses__c shippingAddress = TestUtil.customerAddress(customerAccount.id,'Primary Shipping Address','Shipping Account');
        
        
        Sales_Order__c soOrdr=TestUtil.createsalesOrder(customerAccount.Id,deliveryAccount.Id,pymentId.id);
        soOrdr.Order_Date__c=system.today();
        soOrdr.Check_for_Fraud__c = false;
        update soOrdr;
        
        SO_Line_Items__c SOItem=TestUtil.createsalesOrderLineItem(soOrdr.id,sinmpleProduct.id,null,null,1);
        
        SO_Line_Items__c SOItem1=TestUtil.createsalesOrderLineItem(soOrdr.id,bundleProducts.id,productsList[0].id,null,1);
        SO_Line_Items__c SOItem2=TestUtil.createsalesOrderLineItem(soOrdr.id,bundleProducts.id,productsList[0].id,bundleItemList[0].id,1);
        SO_Line_Items__c SOItem3=TestUtil.createsalesOrderLineItem(soOrdr.id,configProducts.id,productsList[0].id,null,1);
        
        Test.startTest();
        
        ApexPages.StandardController sc = new ApexPages.StandardController(soOrdr);
        apexpages.currentpage().getparameters().put('id',soOrdr.id);
        editSalesOrderController editSalesOrderControllerObj = new editSalesOrderController(sc);
        
        apexpages.currentpage().getParameters().put('OptionsId',bundleProducts.id); 
        editSalesOrderControllerObj.ShowBundelProduct();
        editSalesOrderControllerObj.getProductRelatedBundle();
        editSalesOrderControllerObj.getProductRelatedBundle();
        
        apexpages.currentpage().getparameters().put('productID',bundleProducts.id);
        editSalesOrderControllerObj.addProduct();
        editSalesOrderControllerObj.addBundleProduct();        
        editSalesOrderControllerObj.SalesorderObject.Promotion__c=promocodeObj1.id;
        editSalesOrderControllerObj.getSoRelated();
        editSalesOrderControllerObj.updatePromocode();
        apexpages.currentpage().getParameters().put('OptionsId',bundleProducts.id);
        editSalesOrderControllerObj.getSoRelatedBundle();
        editSalesOrderControllerObj.updateProduct();
        editSalesOrderControllerObj.getSoRelated();
        string soID = SOItem1.id;
        
        editSalesOrderControllerObj.AddProtectionPlan();
        
        apexpages.currentpage().getParameters().put('SOItemId',soID);
        editSalesOrderControllerObj.SOItemId=soID;
        list<editSalesOrderController.BundleItemWrapper> SoRelatedBundle = new list<editSalesOrderController.BundleItemWrapper>();
        editSalesOrderController.BundleItemWrapper BTW = new editSalesOrderController.BundleItemWrapper(bundleItem,new map<string,list<products__c>>(),True,'2','Test Name');
        SoRelatedBundle.add(BTW);        
        editSalesOrderControllerObj.SoRelatedBundle = SoRelatedBundle;
        editSalesOrderControllerObj.UpdateBundelItems();
        
        editSalesOrderControllerObj.SalesorderObject.Order_ETA__c='Not Available';
        
        apexpages.currentpage().getParameters().put('Remove',soID);
        editSalesOrderControllerObj.RemoveProduct();
        
        editSalesOrderControllerObj.goTosalesorderlist();
        Test.stopTest();
    }
   
    public static testmethod void paymentsMethodthroughCreditCard()
    {
        manufacturerAccount=TestUtil.createManufacturerAccount(true,false,'Email');
        
        customerAccount=TestUtil.createCustomerAccount();
        customerAccount.Authorize_net_Profile_ID__c='12345';
        update customerAccount;
        
        configProducts=TestUtil.createConfigProduct();
        configProducts.Tier_Price_For_Bundle__c=20;
        update configProducts;
        
        protectionProducts=TestUtil.createprotectionProduct();
        bundleProducts=bundlePro();
        productsList.add(TestUtil.createSimpleProduct(configProducts.Id,manufacturerAccount.Id));
        productsList.add(TestUtil.createSimpleProduct(null,manufacturerAccount.Id));
        bundleItemList.add(TestUtil.createBundleItemProduct(configProducts.Id,bundleProducts.id));
        configProducts=TestUtil.createConfigProduct();
        productsList.add(TestUtil.createSimpleProduct(configProducts.Id,manufacturerAccount.Id));
        
        sinmpleProduct=TestUtil.createSimpleProductwithoutMaster(manufacturerAccount.Id);
        
        Payment_Method__c pymentId=TestUtil.createpaymentMethod(customerAccount.Id,'Credit Card (Authorize.net)');
        pymentId.Payment_Profile_ID__c='12345';
        update pymentId;
        
        Payment_Method__c pymentId1=TestUtil.createpaymentMethod(customerAccount.Id,'PayPal');
        
        Customer_Addresses__c billingAddress = TestUtil.customerAddress(customerAccount.id,'Primary Billing Address','Billing Account'); 
        Customer_Addresses__c shippingAddress = TestUtil.customerAddress(customerAccount.id,'Primary Shipping Address','Shipping Account');
        
        
        Sales_Order__c soOrdr=TestUtil.createsalesOrder(customerAccount.Id,deliveryAccount.Id,pymentId.id);
        soOrdr.Order_Date__c=system.today();
        soOrdr.Customer_Name__c=customerAccount.Id;
        soOrdr.Billing_City__c='ny';
        soOrdr.Billing_State__c='new york';
        soOrdr.Billing_Street__c='test street';
        soOrdr.Bill_To__c='sam';
        soOrdr.Email__c='sample@gmail.com';
        soOrdr.Billing_Phone__c='1234567908';
        soOrdr.shipping_City__c='ny';
        soOrdr.shipping_State__c='new york';
        soOrdr.shipping_Street__c='test street';
        soOrdr.ship_To__c='sam';
        soOrdr.Email__c='sample@gmail.com';
        soOrdr.shipping_Phone__c='1234567895';
        soOrdr.Check_for_Fraud__c = false;
        update soOrdr;
        
        Task taskVar = new Task();
        taskVar.ownerid = UserInfo.getUserId();
        taskVar.WhatId = soOrdr.id;
        taskVar.Subject = 'Follow-up the Order for Affirm';
        taskVar.description='Manual Order Payment has been created';
        taskVar.Status = 'Open';
        taskVar.ActivityDate = system.today();
        
        insert taskVar;
        
        Transaction__c transObj=TestUtil.createTrasaction(soOrdr.id,pymentId.id,'Credit Card (Authorize.net)');
        transObj.TransactionId__c='12345';
        update transObj;
        
        transObj=TestUtil.createTrasaction(soOrdr.id,pymentId1.id,'PayPal');
        transObj.TransactionId__c='12345';
        update transObj;
        
        SO_Line_Items__c SOItem=TestUtil.createsalesOrderLineItem(soOrdr.id,sinmpleProduct.id,null,null,1);
        SOItem.Custom_Price__c = 1000;
        update SOItem;
        
        SO_Line_Items__c SOItem1=TestUtil.createsalesOrderLineItem(soOrdr.id,bundleProducts.id,productsList[0].id,bundleItemList[0].id,1);
        SO_Line_Items__c SOItem2=TestUtil.createsalesOrderLineItem(soOrdr.id,configProducts.id,productsList[0].id,null,1);
        map<string,decimal> customPriceMap = new map<string,decimal>();
        customPriceMap.put(SOItem.id, 2000);
        
        States__c state = new States__c(Name='New York');
        insert state;
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SalesOrder_AuthorizeDotNetHttpMock());
        ApexPages.StandardController sc = new ApexPages.StandardController(soOrdr);
        apexpages.currentpage().getparameters().put('id',soOrdr.id);
        editSalesOrderController editSalesOrderControllerObj = new editSalesOrderController(sc);
        
        apexpages.currentpage().getParameters().put('OptionsId',bundleProducts.id);
        editSalesOrderControllerObj.ShowBundelProduct();
        editSalesOrderControllerObj.getProductRelatedBundle();
        editSalesOrderControllerObj.getProductRelatedBundle();
        
        editSalesOrderControllerObj.SalesorderObject.Order_ETA__c='Not Available';
        
        
        decimal total=editSalesOrderControllerObj.SalesorderObject.Grand_Total__c;
        editSalesOrderControllerObj.originalTotalDue = 10000;
        
        editSalesOrderControllerObj.paymentType='CreditCard';
        editSalesOrderControllerObj.hasCard1=true;
        editSalesOrderControllerObj.hasCard3=true;
        editSalesOrderControllerObj.hasCard2=true;
        
        editSalesOrderControllerObj.paymentMethodVar.Card_Type__c='American Express';
        editSalesOrderControllerObj.paymentMethodVar.Card_Verification_Number__c='1234';
        editSalesOrderControllerObj.paymentMethodVar.Expiration_Month__c='11- November';
        editSalesOrderControllerObj.paymentMethodVar.Expiration_Year__c='2016';
        editSalesOrderControllerObj.paymentMethodVar.Credit_Card_Number__c='378282246310005';
        editSalesOrderControllerObj.paymentMethodVar.Amount__c=total-2;
        
        editSalesOrderControllerObj.paymentMethodVar1.Card_Type__c='American Express';
        editSalesOrderControllerObj.paymentMethodVar1.Card_Verification_Number__c='1234';
        editSalesOrderControllerObj.paymentMethodVar1.Expiration_Month__c='11- November';
        editSalesOrderControllerObj.paymentMethodVar1.Expiration_Year__c='2016';
        editSalesOrderControllerObj.paymentMethodVar1.Credit_Card_Number__c='371449635398431';
        editSalesOrderControllerObj.paymentMethodVar1.Amount__c=1;
        
        editSalesOrderControllerObj.paymentMethodVar2.Card_Type__c='American Express';
        editSalesOrderControllerObj.paymentMethodVar2.Card_Verification_Number__c='1234';
        editSalesOrderControllerObj.paymentMethodVar2.Expiration_Month__c='11- November';
        editSalesOrderControllerObj.paymentMethodVar2.Expiration_Year__c='2016';
        editSalesOrderControllerObj.paymentMethodVar2.Credit_Card_Number__c='378282246310005';
        editSalesOrderControllerObj.paymentMethodVar2.Amount__c=1;
        
        editSalesOrderControllerObj.customPriceMap = customPriceMap;
        editSalesOrderControllerObj.originalTotalDue = 10000;
        editSalesOrderControllerObj.submitOrder();
        
        list<Payment_Method__c> paymentMethods =new list<Payment_Method__c>();
        paymentMethods.add(pymentId);
        Boolean isPay = editSalesOrderControllerObj.insertPaymentMethod(paymentMethods,editSalesOrderControllerObj.SalesorderObject);
        AuthorizeDotNetFunctions authorizeFunctions = new AuthorizeDotNetFunctions();
        authorizeFunctions.deletePaymentProfile('','');
        Test.stopTest();
    }
 
    public static testmethod void paymentsMethodthroughManualPay()
    {
        manufacturerAccount=TestUtil.createManufacturerAccount(true,false,'Email');
        
        customerAccount=TestUtil.createCustomerAccount();
        customerAccount.Authorize_net_Profile_ID__c='12345';
        update customerAccount;
        
        configProducts=TestUtil.createConfigProduct();
        configProducts.Tier_Price_For_Bundle__c=20;
        update configProducts;
        
        protectionProducts=TestUtil.createprotectionProduct();
        bundleProducts=bundlePro();
        productsList.add(TestUtil.createSimpleProduct(configProducts.Id,manufacturerAccount.Id));
        productsList.add(TestUtil.createSimpleProduct(null,manufacturerAccount.Id));
        bundleItemList.add(TestUtil.createBundleItemProduct(configProducts.Id,bundleProducts.id));
        configProducts=TestUtil.createConfigProduct();
        productsList.add(TestUtil.createSimpleProduct(configProducts.Id,manufacturerAccount.Id));
        
        sinmpleProduct=TestUtil.createSimpleProductwithoutMaster(manufacturerAccount.Id);
        
        Payment_Method__c pymentId=TestUtil.createpaymentMethod(customerAccount.Id,'Credit Card (Authorize.net)');
        pymentId.Payment_Profile_ID__c='12345';
        pymentId.Credit_Card_Number__c='123456';
        update pymentId;
        
        Customer_Addresses__c billingAddress = TestUtil.customerAddress(customerAccount.id,'Primary Billing Address','Billing Account'); 
        Customer_Addresses__c shippingAddress = TestUtil.customerAddress(customerAccount.id,'Primary Shipping Address','Shipping Account');
        
        Sales_Order__c soOrdr = TestUtil.createsalesOrder(customerAccount.Id,deliveryAccount.Id,pymentId.id);
        soOrdr.Order_Date__c=system.today();
        soOrdr.Customer_Name__c=customerAccount.Id;
        soOrdr.Billing_City__c='ny';
        soOrdr.Billing_State__c='new york';
        soOrdr.Billing_Street__c='test street';
        soOrdr.Bill_To__c='sam';
        soOrdr.Email__c='sample@gmail.com';
        soOrdr.Billing_Phone__c='1234567908';
        soOrdr.shipping_City__c='ny';
        soOrdr.shipping_State__c='new york';
        soOrdr.shipping_Street__c='test street';
        soOrdr.ship_To__c='sam';
        soOrdr.Email__c='sample@gmail.com';
        soOrdr.shipping_Phone__c='1234567895';
        soOrdr.Check_for_Fraud__c = false;
        update soOrdr;
        
        Transaction__c transObj=TestUtil.createTrasaction(soOrdr.id,pymentId.id,'Credit Card (Authorize.net)');
        transObj.TransactionId__c='12345';
        transObj.TransactionId__c='Authorized';
        update transObj;
        
        SO_Line_Items__c SOItem=TestUtil.createsalesOrderLineItem(soOrdr.id,sinmpleProduct.id,null,null,1);
        SOItem=TestUtil.createsalesOrderLineItem(soOrdr.id,bundleProducts.id,productsList[0].id,bundleItemList[0].id,1);
        SOItem=TestUtil.createsalesOrderLineItem(soOrdr.id,configProducts.id,productsList[0].id,null,1);
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SalesOrder_AuthorizeDotNetHttpMock());
        ApexPages.StandardController sc = new ApexPages.StandardController(soOrdr);
        apexpages.currentpage().getparameters().put('id',soOrdr.id);
        editSalesOrderController editSalesOrderControllerObj = new editSalesOrderController(sc);
        
        apexpages.currentpage().getParameters().put('OptionsId',bundleProducts.id);
        editSalesOrderControllerObj.ShowBundelProduct();
        editSalesOrderControllerObj.getProductRelatedBundle();
        editSalesOrderControllerObj.getProductRelatedBundle();
        
        editSalesOrderControllerObj.SalesorderObject.Order_ETA__c='Not Available';
        
        decimal total=editSalesOrderControllerObj.SalesorderObject.Grand_Total__c;
        editSalesOrderControllerObj.originalTotalDue = 10000;
        editSalesOrderControllerObj.paymentType='ManualPay';
        editSalesOrderControllerObj.submitOrder();
        Test.stopTest();
    }
    
    public static testmethod void paymentsMethodthroughAmazonPay()
    {
        manufacturerAccount=TestUtil.createManufacturerAccount(true,false,'Email');
        
        customerAccount=TestUtil.createCustomerAccount();
        customerAccount.Authorize_net_Profile_ID__c='12345';
        update customerAccount;
        
        configProducts=TestUtil.createConfigProduct();
        configProducts.Tier_Price_For_Bundle__c=20;
        update configProducts;
        
        protectionProducts=TestUtil.createprotectionProduct();
        bundleProducts=bundlePro();
        productsList.add(TestUtil.createSimpleProduct(configProducts.Id,manufacturerAccount.Id));
        productsList.add(TestUtil.createSimpleProduct(null,manufacturerAccount.Id));
        bundleItemList.add(TestUtil.createBundleItemProduct(configProducts.Id,bundleProducts.id));
        configProducts=TestUtil.createConfigProduct();
        productsList.add(TestUtil.createSimpleProduct(configProducts.Id,manufacturerAccount.Id));
        
        sinmpleProduct=TestUtil.createSimpleProductwithoutMaster(manufacturerAccount.Id);
        
        Payment_Method__c pymentId=TestUtil.createpaymentMethod(customerAccount.Id,'Credit Card (Authorize.net)');
        pymentId.Payment_Profile_ID__c='12345';
        pymentId.Credit_Card_Number__c='123456';
        update pymentId;
        
        Customer_Addresses__c billingAddress = TestUtil.customerAddress(customerAccount.id,'Primary Billing Address','Billing Account'); 
        Customer_Addresses__c shippingAddress = TestUtil.customerAddress(customerAccount.id,'Primary Shipping Address','Shipping Account');
        
        Sales_Order__c soOrdr = TestUtil.createsalesOrder(customerAccount.Id,deliveryAccount.Id,pymentId.id);
        soOrdr.Order_Date__c=system.today();
        soOrdr.Customer_Name__c=customerAccount.Id;
        soOrdr.Billing_City__c='ny';
        soOrdr.Billing_State__c='new york';
        soOrdr.Billing_Street__c='test street';
        soOrdr.Bill_To__c='sam';
        soOrdr.Email__c='sample@gmail.com';
        soOrdr.Billing_Phone__c='1234567908';
        soOrdr.shipping_City__c='ny';
        soOrdr.shipping_State__c='new york';
        soOrdr.shipping_Street__c='test street';
        soOrdr.ship_To__c='sam';
        soOrdr.Email__c='sample@gmail.com';
        soOrdr.shipping_Phone__c='1234567895';
        soOrdr.Check_for_Fraud__c = false;
        update soOrdr;
        
        Transaction__c transObj=TestUtil.createTrasaction(soOrdr.id,pymentId.id,'Credit Card (Authorize.net)');
        transObj.TransactionId__c='12345';
        transObj.TransactionId__c='Authorized';
        update transObj;
        
        SO_Line_Items__c SOItem = TestUtil.createsalesOrderLineItem(soOrdr.id,sinmpleProduct.id,null,null,1);
        SOItem = TestUtil.createsalesOrderLineItem(soOrdr.id,bundleProducts.id,productsList[0].id,bundleItemList[0].id,1);
        SOItem = TestUtil.createsalesOrderLineItem(soOrdr.id,configProducts.id,productsList[0].id,null,1);
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SalesOrder_AuthorizeDotNetHttpMock());
        ApexPages.StandardController sc = new ApexPages.StandardController(soOrdr);
        apexpages.currentpage().getparameters().put('id',soOrdr.id);
        editSalesOrderController editSalesOrderControllerObj = new editSalesOrderController(sc);
        
        apexpages.currentpage().getParameters().put('OptionsId',bundleProducts.id);
        editSalesOrderControllerObj.ShowBundelProduct();
        editSalesOrderControllerObj.getProductRelatedBundle();
        editSalesOrderControllerObj.getProductRelatedBundle();
        
        editSalesOrderControllerObj.SalesorderObject = soOrdr;
        editSalesOrderControllerObj.SalesorderObject.Order_ETA__c='Not Available';
        
        
        decimal total = editSalesOrderControllerObj.SalesorderObject.Grand_Total__c;
        editSalesOrderControllerObj.originalTotalDue = 10000;
        editSalesOrderControllerObj.paymentType='AmazonPay';
        editSalesOrderControllerObj.custumpricetotal = 100;
        editSalesOrderControllerObj.submitOrder();
        
        
        Test.stopTest();
    }
    
    public static testmethod void paymentsMethodthroughAffirmPay()
    {
        manufacturerAccount=TestUtil.createManufacturerAccount(true,false,'Email');
        
        customerAccount=TestUtil.createCustomerAccount();
        customerAccount.Authorize_net_Profile_ID__c='12345';
        update customerAccount;
        
        configProducts=TestUtil.createConfigProduct();
        configProducts.Tier_Price_For_Bundle__c=20;
        update configProducts;
        
        protectionProducts=TestUtil.createprotectionProduct();
        bundleProducts=bundlePro();
        productsList.add(TestUtil.createSimpleProduct(configProducts.Id,manufacturerAccount.Id));
        productsList.add(TestUtil.createSimpleProduct(null,manufacturerAccount.Id));
        bundleItemList.add(TestUtil.createBundleItemProduct(configProducts.Id,bundleProducts.id));
        configProducts=TestUtil.createConfigProduct();
        productsList.add(TestUtil.createSimpleProduct(configProducts.Id,manufacturerAccount.Id));
        
        sinmpleProduct=TestUtil.createSimpleProductwithoutMaster(manufacturerAccount.Id);
        
        Payment_Method__c pymentId=TestUtil.createpaymentMethod(customerAccount.Id,'Credit Card (Authorize.net)');
        pymentId.Payment_Profile_ID__c='12345';
        pymentId.Credit_Card_Number__c='123456';
        update pymentId;
        
        Customer_Addresses__c billingAddress = TestUtil.customerAddress(customerAccount.id,'Primary Billing Address','Billing Account'); 
        Customer_Addresses__c shippingAddress = TestUtil.customerAddress(customerAccount.id,'Primary Shipping Address','Shipping Account');
        
        Sales_Order__c soOrdr = TestUtil.createsalesOrder(customerAccount.Id,deliveryAccount.Id,pymentId.id);
        soOrdr.Order_Date__c=system.today();
        soOrdr.Customer_Name__c=customerAccount.Id;
        soOrdr.Billing_City__c='ny';
        soOrdr.Billing_State__c='new york';
        soOrdr.Billing_Street__c='test street';
        soOrdr.Bill_To__c='sam';
        soOrdr.Email__c='sample@gmail.com';
        soOrdr.Billing_Phone__c='1234567908';
        soOrdr.shipping_City__c='ny';
        soOrdr.shipping_State__c='new york';
        soOrdr.shipping_Street__c='test street';
        soOrdr.ship_To__c='sam';
        soOrdr.Email__c='sample@gmail.com';
        soOrdr.shipping_Phone__c='1234567895';
        soOrdr.Check_for_Fraud__c = false;
        update soOrdr;
        
        Transaction__c transObj=TestUtil.createTrasaction(soOrdr.id,pymentId.id,'Credit Card (Authorize.net)');
        transObj.TransactionId__c='12345';
        transObj.TransactionId__c='Authorized';
        update transObj;
        
        SO_Line_Items__c SOItem=TestUtil.createsalesOrderLineItem(soOrdr.id,sinmpleProduct.id,null,null,1);
        SOItem=TestUtil.createsalesOrderLineItem(soOrdr.id,bundleProducts.id,productsList[0].id,bundleItemList[0].id,1);
        SOItem=TestUtil.createsalesOrderLineItem(soOrdr.id,configProducts.id,productsList[0].id,null,1);
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SalesOrder_AuthorizeDotNetHttpMock());
        ApexPages.StandardController sc = new ApexPages.StandardController(soOrdr);
        apexpages.currentpage().getparameters().put('id',soOrdr.id);
        editSalesOrderController editSalesOrderControllerObj = new editSalesOrderController(sc);
        
        apexpages.currentpage().getParameters().put('OptionsId',bundleProducts.id);
        editSalesOrderControllerObj.ShowBundelProduct();
        editSalesOrderControllerObj.getProductRelatedBundle();
        editSalesOrderControllerObj.getProductRelatedBundle();
        
        editSalesOrderControllerObj.SalesorderObject.Order_ETA__c='Not Available';
        
        decimal total=editSalesOrderControllerObj.SalesorderObject.Grand_Total__c;
        editSalesOrderControllerObj.originalTotalDue = 10000;
        editSalesOrderControllerObj.paymentType='AffirmPay';
        editSalesOrderControllerObj.submitOrder();
        
        Test.stopTest();
    }
    
    public static testmethod void paymentsMethodthroughPaypalInvoice()
    {
        manufacturerAccount=TestUtil.createManufacturerAccount(true,false,'Email');
        
        customerAccount=TestUtil.createCustomerAccount();
        customerAccount.Authorize_net_Profile_ID__c='12345';
        update customerAccount;
        
        configProducts=TestUtil.createConfigProduct();
        configProducts.Tier_Price_For_Bundle__c=20;
        update configProducts;
        
        protectionProducts=TestUtil.createprotectionProduct();
        bundleProducts=bundlePro();
        productsList.add(TestUtil.createSimpleProduct(configProducts.Id,manufacturerAccount.Id));
        productsList.add(TestUtil.createSimpleProduct(null,manufacturerAccount.Id));
        bundleItemList.add(TestUtil.createBundleItemProduct(configProducts.Id,bundleProducts.id));
        configProducts=TestUtil.createConfigProduct();
        productsList.add(TestUtil.createSimpleProduct(configProducts.Id,manufacturerAccount.Id));
        
        sinmpleProduct=TestUtil.createSimpleProductwithoutMaster(manufacturerAccount.Id);
        
        Payment_Method__c pymentId=TestUtil.createpaymentMethod(customerAccount.Id,'Credit Card (Authorize.net)');
        pymentId.Payment_Profile_ID__c='12345';
        pymentId.Credit_Card_Number__c='123456';
        update pymentId;
        
        Customer_Addresses__c billingAddress = TestUtil.customerAddress(customerAccount.id,'Primary Billing Address','Billing Account'); 
        Customer_Addresses__c shippingAddress = TestUtil.customerAddress(customerAccount.id,'Primary Shipping Address','Shipping Account');
        
        Sales_Order__c soOrdr = TestUtil.createsalesOrder(customerAccount.Id,deliveryAccount.Id,pymentId.id);
        soOrdr.Order_Date__c=system.today();
        soOrdr.Customer_Name__c=customerAccount.Id;
        soOrdr.Billing_City__c='ny';
        soOrdr.Billing_State__c='new york';
        soOrdr.Billing_Street__c='test street';
        soOrdr.Bill_To__c='sam';
        soOrdr.Email__c='sample@gmail.com';
        soOrdr.Billing_Phone__c='1234567908';
        soOrdr.shipping_City__c='ny';
        soOrdr.shipping_State__c='new york';
        soOrdr.shipping_Street__c='test street';
        soOrdr.ship_To__c='sam';
        soOrdr.Email__c='sample@gmail.com';
        soOrdr.shipping_Phone__c='1234567895';
        soOrdr.Check_for_Fraud__c = false;
        update soOrdr;
        
        Transaction__c transObj=TestUtil.createTrasaction(soOrdr.id,pymentId.id,'Credit Card (Authorize.net)');
        transObj.TransactionId__c='12345';
        transObj.TransactionId__c='Authorized';
        update transObj;
        
        SO_Line_Items__c SOItem=TestUtil.createsalesOrderLineItem(soOrdr.id,sinmpleProduct.id,null,null,1);
        SOItem=TestUtil.createsalesOrderLineItem(soOrdr.id,bundleProducts.id,productsList[0].id,bundleItemList[0].id,1);
        SOItem=TestUtil.createsalesOrderLineItem(soOrdr.id,configProducts.id,productsList[0].id,null,1);
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SalesOrder_AuthorizeDotNetHttpMock());
        ApexPages.StandardController sc = new ApexPages.StandardController(soOrdr);
        apexpages.currentpage().getparameters().put('id',soOrdr.id);
        editSalesOrderController editSalesOrderControllerObj = new editSalesOrderController(sc);
        
        apexpages.currentpage().getParameters().put('OptionsId',bundleProducts.id);
        editSalesOrderControllerObj.ShowBundelProduct();
        editSalesOrderControllerObj.getProductRelatedBundle();
        editSalesOrderControllerObj.getProductRelatedBundle();
        
        editSalesOrderControllerObj.SalesorderObject.Order_ETA__c='Not Available';
        
        
        decimal total = editSalesOrderControllerObj.SalesorderObject.Grand_Total__c;
        editSalesOrderControllerObj.originalTotalDue = 10000;
        editSalesOrderControllerObj.paymentType='PaypalInvoice';
        editSalesOrderControllerObj.submitOrder();  
        //editSalesOrderControllerObj.voidPaypalPayments(transObj, null);
        Test.stopTest();
    }
    
    public static testmethod void paymentsMethodthroughPaybycheck()
    {
        manufacturerAccount=TestUtil.createManufacturerAccount(true,false,'Email');
        
        customerAccount=TestUtil.createCustomerAccount();
        customerAccount.Authorize_net_Profile_ID__c='12345';
        update customerAccount;
        
        configProducts=TestUtil.createConfigProduct();
        configProducts.Tier_Price_For_Bundle__c=20;
        update configProducts;
        
        protectionProducts=TestUtil.createprotectionProduct();
        bundleProducts=bundlePro();
        productsList.add(TestUtil.createSimpleProduct(configProducts.Id,manufacturerAccount.Id));
        productsList.add(TestUtil.createSimpleProduct(null,manufacturerAccount.Id));
        bundleItemList.add(TestUtil.createBundleItemProduct(configProducts.Id,bundleProducts.id));
        configProducts=TestUtil.createConfigProduct();
        productsList.add(TestUtil.createSimpleProduct(configProducts.Id,manufacturerAccount.Id));
        
        sinmpleProduct=TestUtil.createSimpleProductwithoutMaster(manufacturerAccount.Id);
        
        Payment_Method__c pymentId=TestUtil.createpaymentMethod(customerAccount.Id,'Credit Card (Authorize.net)');
        pymentId.Payment_Profile_ID__c='12345';
        pymentId.Credit_Card_Number__c='123456';
        update pymentId;
        
        Customer_Addresses__c billingAddress = TestUtil.customerAddress(customerAccount.id,'Primary Billing Address','Billing Account'); 
        Customer_Addresses__c shippingAddress = TestUtil.customerAddress(customerAccount.id,'Primary Shipping Address','Shipping Account');
        
        Sales_Order__c soOrdr = TestUtil.createsalesOrder(customerAccount.Id,deliveryAccount.Id,pymentId.id);
        soOrdr.Order_Date__c=system.today();
        soOrdr.Customer_Name__c=customerAccount.Id;
        soOrdr.Billing_City__c='ny';
        soOrdr.Billing_State__c='new york';
        soOrdr.Billing_Street__c='test street';
        soOrdr.Bill_To__c='sam';
        soOrdr.Email__c='sample@gmail.com';
        soOrdr.Billing_Phone__c='1234567908';
        soOrdr.shipping_City__c='ny';
        soOrdr.shipping_State__c='new york';
        soOrdr.shipping_Street__c='test street';
        soOrdr.ship_To__c='sam';
        soOrdr.Email__c='sample@gmail.com';
        soOrdr.shipping_Phone__c='1234567895';
        soOrdr.Check_for_Fraud__c = false;
        update soOrdr;
        
        Transaction__c transObj=TestUtil.createTrasaction(soOrdr.id,pymentId.id,'Credit Card (Authorize.net)');
        transObj.TransactionId__c='12345';
        transObj.TransactionId__c='Authorized';
        update transObj;
        
        SO_Line_Items__c SOItem=TestUtil.createsalesOrderLineItem(soOrdr.id,sinmpleProduct.id,null,null,1);
        SOItem=TestUtil.createsalesOrderLineItem(soOrdr.id,bundleProducts.id,productsList[0].id,bundleItemList[0].id,1);
        SOItem=TestUtil.createsalesOrderLineItem(soOrdr.id,configProducts.id,productsList[0].id,null,1);
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SalesOrder_AuthorizeDotNetHttpMock());
        ApexPages.StandardController sc = new ApexPages.StandardController(soOrdr);
        apexpages.currentpage().getparameters().put('id',soOrdr.id);
        editSalesOrderController editSalesOrderControllerObj = new editSalesOrderController(sc);
        
        apexpages.currentpage().getParameters().put('OptionsId',bundleProducts.id);
        editSalesOrderControllerObj.ShowBundelProduct();
        editSalesOrderControllerObj.getProductRelatedBundle();
        editSalesOrderControllerObj.getProductRelatedBundle();
        
        editSalesOrderControllerObj.SalesorderObject.Order_ETA__c='Not Available';
        
        
        decimal total=editSalesOrderControllerObj.SalesorderObject.Grand_Total__c;
        
        editSalesOrderControllerObj.paymentMethodVar.id=null;
        
        editSalesOrderControllerObj.paymentMethodVar.Check_Type__c='test';
        editSalesOrderControllerObj.paymentMethodVar.Name_on_Account__c='test';
        editSalesOrderControllerObj.paymentMethodVar.Routing_Number__c=123;
        editSalesOrderControllerObj.paymentMethodVar.Account_Number__c=1234;
        editSalesOrderControllerObj.originalTotalDue = 10000;
        editSalesOrderControllerObj.paymentType='Paybycheck';
        editSalesOrderControllerObj.submitOrder();
        Test.stopTest();
    }
    
    public static testmethod void remoteActionTestMethod()
    {
        internalAccount=new account();
        internalAccount=TestUtil.createInternalEmployeeAccount(userinfo.getUserId());
        internalAccount.SalesRepAsUser__c=UserInfo.getUserId();
        update internalAccount;
        
        manufacturerAccount=TestUtil.createManufacturerAccount(true,false,'Email');
        
        customerAccount=TestUtil.createCustomerAccount();
        
        sinmpleProduct=TestUtil.createSimpleProductwithoutMaster(manufacturerAccount.Id);
        
        Payment_Method__c pymentId=TestUtil.createpaymentMethod(customerAccount.Id,'Manual Payment');
        Sales_Order__c soOrdr=TestUtil.createsalesOrder(customerAccount.Id,deliveryAccount.Id,pymentId.id);
        
        SO_Line_Items__c SOItem=TestUtil.createsalesOrderLineItem(soOrdr.id,sinmpleProduct.id,null,null,1);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(soOrdr);
        apexpages.currentpage().getparameters().put('id',soOrdr.id);
        editSalesOrderController editSalesOrderControllerObj = new editSalesOrderController(sc);
        
        configProducts=TestUtil.createConfigProduct();
        protectionProducts=TestUtil.createprotectionProduct();
        productsList.add(TestUtil.createSimpleProduct(configProducts.Id,manufacturerAccount.Id));
        productsList.add(TestUtil.createSimpleProduct(null,manufacturerAccount.Id));
        configProducts=TestUtil.createConfigProduct();
        productsList.add(TestUtil.createSimpleProduct(configProducts.Id,manufacturerAccount.Id));
        
        Test.startTest();
        string productlistfromparam=editSalesOrderController.searchProducts('','','',soOrdr.id);
        Apexpages.currentPage().getParameters().put('productlistfromparam',productlistfromparam);
        editSalesOrderControllerObj.showProducts();
        
        bundleProducts=bundlePro();
        bundleItemList.add(TestUtil.createBundleItemProduct(configProducts.Id,bundleProducts.id));
        
        productlistfromparam=editSalesOrderController.searchProducts('Kin','a','Manufacture',soOrdr.id);
        Apexpages.currentPage().getParameters().put('productlistfromparam',productlistfromparam);
        editSalesOrderControllerObj.showProducts();
        
        string storedquery = 'select id,Final_OriginalPrice__c,Final_UnitPrice__c,recordtype.name,Type__c,Sales_Price__c,Regular_Price__c,Special_Price_Hidden__c,Select_Manufacturer__r.name,Product_Image_URL__c,recordtypeid,Name,SKU__c,(select id,Final_OriginalPrice__c,Final_UnitPrice__c,Product_Image_URL__c,Special_Price_Hidden__c ,Tier_Price_For_Bundle__c,Name,SKU__c,Regular_Price__c,Sales_Price__c,Special_Price__c,Image__c,Special_Price_From_Date__c,Special_Price_To_Date__c,Master_Products__c from Products__r),(select id,Product__r.recordtype.name,Include__c,Name,Bundle__r.name,Bundle__c,Product__c,Sales_Price__c,ImageURL__c,Bundle_Product_Name__c,SKU__c ,Selection_Qty__c from Bundle_Items1__r order by Include__c desc)  from Products__c where Master_Products__c=null and  recordtype.name!=\'Protection Plan\'  ';
        productlistfromparam=editSalesOrderController.getNextProducts(null,storedquery,soOrdr.id);
        productlistfromparam=editSalesOrderController.getPrevProducts(null,storedquery,soOrdr.id);
        
        productlistfromparam=editSalesOrderController.searchProducts('',bundleProducts.Name,'',soOrdr.id);
        Apexpages.currentPage().getParameters().put('productlistfromparam',productlistfromparam);
        editSalesOrderControllerObj.showProducts();
        
        Test.stopTest();
    } 
    
    public static testmethod void addProductsTestMethod() 
    {
        internalAccount=new account();
        internalAccount=TestUtil.createInternalEmployeeAccount(userinfo.getUserId());
        internalAccount.SalesRepAsUser__c=UserInfo.getUserId();
        update internalAccount;
        
        manufacturerAccount=TestUtil.createManufacturerAccount(true,false,'Email');
        
        customerAccount=TestUtil.createCustomerAccount();
        
        sinmpleProduct=TestUtil.createSimpleProductwithoutMaster(manufacturerAccount.Id);
        
        configProducts = TestUtil.createConfigProduct();
        protectionProducts = TestUtil.createprotectionProduct();
        Products__c simplewithCOnfig = TestUtil.createSimpleProduct(configProducts.Id,manufacturerAccount.Id);
        Products__c bundlePro = bundlePro();
        Bundle_Item__c simpleBI = TestUtil.createBundleItemProduct(sinmpleProduct.Id,bundlePro.id);
        Bundle_Item__c configBI = TestUtil.createBundleItemProduct(configProducts.Id,bundlePro.id);
        
        Payment_Method__c pymentId = TestUtil.createpaymentMethod(customerAccount.Id,'Manual Payment');
        Sales_Order__c soOrdr = TestUtil.createsalesOrder(customerAccount.Id,deliveryAccount.Id,pymentId.id);
        
        SO_Line_Items__c SOItem=TestUtil.createsalesOrderLineItem(soOrdr.id,sinmpleProduct.id,null,null,1);
        SO_Line_Items__c SOItem1=TestUtil.createsalesOrderLineItem(soOrdr.id,protectionProducts.id,null,null,1);
        
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(soOrdr);
        apexpages.currentpage().getparameters().put('id',soOrdr.id);
        editSalesOrderController editSalesOrderControllerObj = new editSalesOrderController(sc);  
        editSalesOrderControllerObj.getSoRelated();    
        
        editSalesOrderControllerObj.OptionsId = bundlePro.id;
        editSalesOrderControllerObj.getSoRelatedBundle();
        
        editSalesOrderControllerObj.updateProduct();
        
        Transaction__c t = TestUtil.createTrasaction(soOrdr.id, pymentId.id, 'AUTH_ONLY');
        
        AuthorizeDotNetFunctions authFunction = new AuthorizeDotNetFunctions();
        authFunction.createCustomerRefundTransaction('378282246310005', '378282246310005','378282246310005','5555','120', system.now(), '345345', false);
        //authFunction.createCustomerAuthAndCaptureTransaction('378282246310005', '378282246310005','5555','120');
        authFunction.CaptureaPreviouslyAuthorizedAmount(t.id, '120','5555', system.now(), false);
        authFunction.updatePaymentProfileAddress('TestName', '4829 N Oconnor Road, Apt 163', 'Irving', 'Texas', '75062', 'United States', '378282246310005', '2021/05','5555','liveMode');
        Test.stopTest();
    }
    
    public static testmethod void updatePromoTestMethod()
    {
        Tax_Percentage__c tpObj = new Tax_Percentage__c();
        tpObj.name = 'NY';
        tpObj.Percentage__c = 8.65;
        insert tpObj;
        
        customerAccount = TestUtil.createCustomerAccount();
        manufacturerAccount = TestUtil.createManufacturerAccount(true,false,'Email');
        deliveryAccount = TestUtil.createDeliveryAccount();
        set<String> manufactureList = new set<String>();
        
        Promotions__c promocodeObj = TestUtil.createPromotion('Promo Code','Brand');
        
        Promotions__c generalPromocode = TestUtil.createPromotion('Promo Code','General');
        
        Products__c simplewithoutMasterProduct = TestUtil.createSimpleProductwithoutMaster(manufacturerAccount.id);
        Products__c configProduct = TestUtil.createConfigProduct();
        Products__c simplewithConfigProduct = TestUtil.createSimpleProduct(configProduct.id, manufacturerAccount.id);
        Products__c bundleProduct = bundlePro();
        Bundle_Item__c bundleItem = TestUtil.createBundleItemProduct(simplewithoutMasterProduct.id,bundleProduct.id);
        Bundle_Item__c bundleItem1 = TestUtil.createBundleItemProduct(configProduct.id,bundleProduct.id);
        
        list<Bundle_Item__c> BIList = new list<Bundle_Item__c>();
        BIList.add(bundleItem);
        BIList.add(bundleItem1);
        map<string,list<Bundle_Item__c>> ProductRelatedBundleTempList = new map<string,list<Bundle_Item__c>>();
        ProductRelatedBundleTempList.put(bundleProduct.id, BIList);
        
        Sales_Order__c salesOrder = TestUtil.createsalesOrder(customerAccount.Id,deliveryAccount.Id,null);
        
        
        SO_Line_Items__c SOItem = TestUtil.createsalesOrderLineItem(salesOrder.id,simplewithoutMasterProduct.id,null,null,2);
        SO_Line_Items__c SOItem1 = TestUtil.createsalesOrderLineItem(salesOrder.id,configProduct.id,simplewithoutMasterProduct.id,null,2);
        SO_Line_Items__c SOItem2 = TestUtil.createsalesOrderLineItem(salesOrder.id,bundleProduct.id,null,bundleItem.id,2);
        
        test.startTest();
        PageReference pref = Page.editSalesOrderPage;
        ApexPages.StandardController sc = new ApexPages.StandardController(salesOrder);
        system.debug(' salesOrder' + salesOrder.id);
        test.setCurrentPage(pref);
        apexpages.currentpage().getparameters().put('id',salesOrder.id);
        editSalesOrderController editSalesOrderControllerObj = new editSalesOrderController(sc);
        editSalesOrderControllerObj.OptionsId = bundleProduct.id;
        editSalesOrderControllerObj.getProductRelatedBundle();
        editSalesOrderControllerObj.addBundleProduct();
        editSalesOrderControllerObj.getProductRelatedBundle();
        editSalesOrderControllerObj.getSoRelated();
        
        //editSalesOrderControllerObj.SalesorderObject = salesOrder;
        //editSalesOrderControllerObj.manufactureList = manufactureList;
        //editSalesOrderControllerObj.updatePromocode();
        
        editSalesOrderControllerObj.updatePromocode();
        
        
        editSalesOrderControllerObj.SalesorderObject.Promotion__c=promocodeObj.id;
        editSalesOrderControllerObj.updatePromocode();
        try
        {
            promocodeObj.Min_Sub_Total__c = 9000;
            update promocodeObj;
            editSalesOrderControllerObj.updatePromocode();
        }
        catch(exception ex)
        {
            
        }
        try
        {
            promocodeObj.Brand__c='Aico';
            update promocodeObj;
            editSalesOrderControllerObj.updatePromocode(); 
        }
        catch(exception ex)
        {
            
        }
       
        editSalesOrderControllerObj.SalesorderObject.Promotion__c= generalPromocode.id;
        editSalesOrderControllerObj.updatePromocode();
        
        generalPromocode.Brands_to_Exclude__c = 'Aico;Ashley;';
        update generalPromocode;
        editSalesOrderControllerObj.updatePromocode();
        try
        {
            generalPromocode.Brands_to_Exclude__c = 'Aico;Ashley;Manufacture Account;';
            update generalPromocode;
            editSalesOrderControllerObj.updatePromocode();
        }
        catch(exception ex)
        {
            
        } 
        try
        {
            generalPromocode.Min_Sub_Total__c = 9000;
            update generalPromocode;
            editSalesOrderControllerObj.updatePromocode();
        }
        catch(exception ex)
        {
            
        }
        try
        {
            generalPromocode.Discount_Amount__c = 9000;
            update generalPromocode;
            editSalesOrderControllerObj.updatePromocode();
        }
        catch(exception ex)
        {
            
        }
        test.stopTest();
    }
    
    public static testmethod void updateProductsTestMethod()
    {
        Tax_Percentage__c tpObj = new Tax_Percentage__c();
        tpObj.name = 'NY';
        tpObj.Percentage__c = 8.65;
        insert tpObj;
        
        customerAccount = TestUtil.createCustomerAccount();
        manufacturerAccount = TestUtil.createManufacturerAccount(true,false,'Email');
        deliveryAccount = TestUtil.createDeliveryAccount();
        set<String> manufactureList = new set<String>();
        
        Payment_Method__c pymentId = TestUtil.createpaymentMethod(customerAccount.Id,'Credit Card (Authorize.net)');
        
        Promotions__c promocodeObj = TestUtil.createPromotion('Promo Code','Brand');
        promocodeObj.Min_Sub_Total__c = 5000;
        update promocodeObj;
        
        Promotions__c generalPromocode = TestUtil.createPromotion('Promo Code','General');
        
        Products__c simplewithoutMasterProduct = TestUtil.createSimpleProductwithoutMaster(manufacturerAccount.id);
        Products__c configProduct = TestUtil.createConfigProduct();
        Products__c simplewithConfigProduct = TestUtil.createSimpleProduct(configProduct.id, manufacturerAccount.id);
        Products__c bundleProduct = bundlePro();
        Bundle_Item__c bundleItem = TestUtil.createBundleItemProduct(simplewithoutMasterProduct.id,bundleProduct.id);
        Bundle_Item__c bundleItem1 = TestUtil.createBundleItemProduct(configProduct.id,bundleProduct.id);
        
        list<Bundle_Item__c> BIList = new list<Bundle_Item__c>();
        BIList.add(bundleItem);
        BIList.add(bundleItem1);
        map<string,list<Bundle_Item__c>> ProductRelatedBundleTempList = new map<string,list<Bundle_Item__c>>();
        ProductRelatedBundleTempList.put(bundleProduct.id, BIList);
        
        Sales_Order__c salesOrder = TestUtil.createsalesOrder(customerAccount.Id,deliveryAccount.Id,pymentId.id);
        salesOrder.Promotion__c = promocodeObj.id;
        salesOrder.Check_for_Fraud__c = false;
        update salesOrder;
        
        SO_Line_Items__c SOItem = TestUtil.createsalesOrderLineItem(salesOrder.id,simplewithoutMasterProduct.id,null,null,2);
        SOItem.Custom_Price__c = 0;
        update SOItem;
        SO_Line_Items__c SOItem1 = TestUtil.createsalesOrderLineItem(salesOrder.id,configProduct.id,simplewithoutMasterProduct.id,null,2);
        SO_Line_Items__c SOItem2 = TestUtil.createsalesOrderLineItem(salesOrder.id,bundleProduct.id,null,null,2);
        SO_Line_Items__c SOItem3 = TestUtil.createsalesOrderLineItem(salesOrder.id,bundleProduct.id,null,bundleItem.id,2);
        SO_Line_Items__c SOItem4 = TestUtil.createsalesOrderLineItem(salesOrder.id,bundleProduct.id,configProduct.id,bundleItem1.id,2);
        
        list<SO_Line_Items__c> BundelSOitems = new list<SO_Line_Items__c>();
        BundelSOitems.add(SOItem3);
        BundelSOitems.add(SOItem4);
        
        List<selectoption> configpro = new List<selectoption>();
        configpro.add(new selectOption(simplewithConfigProduct.id,simplewithConfigProduct.name)); 
        
        map<string,editSalesOrderController.SelectedProductWrapper> SoRelated = new map<string,editSalesOrderController.SelectedProductWrapper>();
        SoRelated.put(SOItem.id,new editSalesOrderController.SelectedProductWrapper(SOItem,new list<SO_Line_Items__c>(),new list<selectoption>()));
        SoRelated.put(SOItem1.id,new editSalesOrderController.SelectedProductWrapper(SOItem1,new list<SO_Line_Items__c>(),configpro));
        SoRelated.put(SOItem2.id,new editSalesOrderController.SelectedProductWrapper(SOItem2,BundelSOitems,new list<selectoption>()));
        
        map<string,list<products__c>> configlist = new map<string,list<products__c>>();
        for(products__c pro : [select id,recordtype.name,Type__c,Sales_Price__c,Regular_Price__c,Special_Price_Hidden__c,Select_Manufacturer__r.name,
                               Product_Image_URL__c,recordtypeid,Name,SKU__c,(select id,Product_Image_URL__c,Special_Price_Hidden__c ,Tier_Price_For_Bundle__c,
                                                                              Name,SKU__c,Regular_Price__c,Sales_Price__c,Special_Price__c,Image__c,
                                                                              Special_Price_From_Date__c,Special_Price_To_Date__c,Master_Products__c from Products__r) from Products__c 
                               where Master_Products__c=null and recordtype.name!='Protection Plan' and id=:configProduct.id])
        {
            if(!configlist.containsKey(pro.id))
                configlist.put(pro.id,pro.Products__r);
        }
        configlist.put(simplewithConfigProduct.id,new list<products__c>());
        
        map<string,editSalesOrderController.insertProductsWrapper> insertedproductsIds = new map<string,editSalesOrderController.insertProductsWrapper>();
        insertedproductsIds.put(simplewithoutMasterProduct.id,new editSalesOrderController.insertProductsWrapper(1,null));
        
        map<id,editSalesOrderController.BundleItemWrapper> BIWrapper = new map<id,editSalesOrderController.BundleItemWrapper>();
        BIWrapper.put(bundleProduct.id,new editSalesOrderController.BundleItemWrapper(bundleItem,new map<string,list<products__c>>(),true,'0',null));
        BIWrapper.put(bundleProduct.id,new editSalesOrderController.BundleItemWrapper(bundleItem1,configlist,true,'0',simplewithConfigProduct.name));
        
        map<id,map<id,editSalesOrderController.BundleItemWrapper>> BundleList = new map<id,map<id,editSalesOrderController.BundleItemWrapper>>();
        //BundleList.put(bundleProduct.id, BIWrapper);
        test.startTest();
        PageReference pref = Page.editSalesOrderPage;
        ApexPages.StandardController sc = new ApexPages.StandardController(salesOrder);
        apexpages.currentpage().getparameters().put('id',salesOrder.id);
        test.setCurrentPage(pref);
        editSalesOrderController editSalesOrderControllerObj = new editSalesOrderController(sc);
        
        editSalesOrderControllerObj.SoRelated = SoRelated;
        editSalesOrderControllerObj.SalesorderObject = salesOrder;
        map<id,editSalesOrderController.ProductWrapper> selectedproducts = new map<id,editSalesOrderController.ProductWrapper>();
        selectedproducts.put(simplewithoutMasterProduct.Id, new editSalesOrderController.ProductWrapper(simplewithoutMasterProduct,new map<string,list<products__c>>(),true,null,'0'));
        selectedproducts.put(simplewithoutMasterProduct.Id, new editSalesOrderController.ProductWrapper(configProduct,configlist,true,simplewithConfigProduct.name,'0'));
        selectedproducts.put(simplewithoutMasterProduct.Id, new editSalesOrderController.ProductWrapper(simplewithConfigProduct,configlist,true,null,'0'));
        
        editSalesOrderControllerObj.selectedproducts = selectedproducts;
        try {
            editSalesOrderControllerObj.updateProduct();
        }
        catch(Exception ex) {
            
        }
        
        BundleList.put(simplewithConfigProduct.id, BIWrapper);
        editSalesOrderControllerObj.insertedproductsIds = insertedproductsIds;
        editSalesOrderControllerObj.BundleList = BundleList;
        try {
            editSalesOrderControllerObj.updateProduct();
        }
        catch(Exception ex) {
            
        } 
        apexpages.currentpage().getParameters().put('productID',simplewithoutMasterProduct.id);
        editSalesOrderControllerObj.addProduct();
        
        test.stopTest();
    }
  
}