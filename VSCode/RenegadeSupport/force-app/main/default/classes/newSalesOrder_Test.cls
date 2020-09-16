/*
*   Author : Sowdhanya Karri | Kairos Tech
*   Class  : newSalesOrder_Test
*   Purpose: This class is to code coverage the newSalesOrder.
*/
@IsTest 
public with sharing class newSalesOrder_Test  
{
    public static account customerAccount = new account();
    public static account internalAccount = new account();
    public static account manufacturerAccount = new account();
    public static list<Products__c> productsList = new list<Products__c> ();
    public static list<Bundle_Item__c > bundleItemList = new list<Bundle_Item__c > ();
    public static Products__c configProducts = new Products__c ();
    public static Products__c protectionProducts = new Products__c ();
    public static Products__c bundleProducts = new Products__c ();
    public static Products__c sinmpleProduct = new Products__c ();
    public static Paypal_OAuth__c paypalObj;
    public static Sales_Order__c soOrdr = new Sales_Order__c();
    
    public static SalesOrder__c getAfirmTaskDetails {get;set;}
    public static SalesOrder__c getPayPalTaskDetails {get;set;}
    public static SalesOrder__c getAmazonTaskDetails {get;set;}
    public static SalesOrder__c getManualTaskDetails {get;set;}
    
    public static AuthorizeDotNetTokens__c authObj {get;set;}
    public static MagentoAuth__c magentoAuth;
    public static MagentoTokens__c magentoToken;
    
    @testSetup static void setUp() 
    {
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
        
        TestUtil.createBundleProduct();
        TestUtil.createprotectionProduct();
        customerAccount = TestUtil.createCustomerAccount();
        soOrdr = TestUtil.createsalesOrder(customerAccount.Id,null,null);
        
        paypalObj = new Paypal_OAuth__c();
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

        Customer_Addresses__c customerAdress = TestUtil.CustomerAddress(customerAccount.Id, 'Primary Shipping Address', 'Test');
		
        Google_API__c googleAPI = new Google_API__c(Name='Google API',Key__c='AIzaSyCAmP-yM5hc67O4stT-VyzMRmDTaVYfXzQ');
        insert googleAPI;
        
        Tax_Percentage__c tpObj=new Tax_Percentage__c();
        tpObj.name='NY';
        tpObj.Percentage__c=8.62;
        insert tpObj;

    }
    
    private static Products__c getbundlePro() {
        return [SELECT Id,name,recordtype.Name FROM Products__c where recordtype.Name='Bundled' LIMIT 1];
    }
    
    private static Products__c getprotectionPro() {
        return [SELECT Id,name,recordtype.Name FROM Products__c where recordtype.Name='Protection Plan' LIMIT 1];
    }
    
    public static testmethod void newSalesOrderAccountTestMethod()
    { 
        /*Google_API__c googleAPI = new Google_API__c(Name='Google API',Key__c='AIzaSyCAmP-yM5hc67O4stT-VyzMRmDTaVYfXzQ');
        insert googleAPI;
        
        Tax_Percentage__c tpObj=new Tax_Percentage__c();
        tpObj.name='NY';
        tpObj.Percentage__c=8.62;
        insert tpObj;
        */
        States__c stateValue = new States__c();
        stateValue.Name = 'New York';
        insert stateValue;
        
        internalAccount=TestUtil.createInternalEmployeeAccount(UserInfo.getUserId());
        
        manufacturerAccount=TestUtil.createManufacturerAccount(true,false,'Email');
        
        Promotions__c promocodeObj=new Promotions__c();
        
        promocodeObj.Name='Test Prom';
        promocodeObj.Coupon_Code__c='Aico 100';
        promocodeObj.Min_Sub_Total__c=10;
        promocodeObj.Date_Expire__c=system.today().adddays(1);
        promocodeObj.Date_Start__c=system.today().adddays(-1);
        promocodeObj.Discount_Amount__c=200;
        promocodeObj.Type__c='General';
        promocodeObj.Brands_to_Exclude__c = manufacturerAccount.Name;
        

        
        Promotions__c promocodeObj1=new Promotions__c();
        
        promocodeObj1.Name='Test Prom';
        promocodeObj1.Coupon_Code__c='summer 1';
        promocodeObj1.Min_Sub_Total__c=10;
        promocodeObj1.Date_Expire__c=system.today().adddays(1);
        promocodeObj1.Date_Start__c=system.today().adddays(-1);
        promocodeObj1.Discount_Amount__c=1;
        promocodeObj1.Type__c='General';
        
        insert new List<Promotions__c> {promocodeObj, promocodeObj1};
        
        configProducts=TestUtil.createConfigProduct();
        configProducts.Tier_Price_For_Bundle__c=20;
        update configProducts;
        protectionProducts=getprotectionPro();
        bundleProducts = getbundlePro();
        productsList.add(TestUtil.createSimpleProductNotInsert(configProducts.Id,manufacturerAccount.Id));
        productsList.add(TestUtil.createSimpleProductNotInsert(null,manufacturerAccount.Id));
        productsList.add(TestUtil.createSimpleProductNotInsert(configProducts.Id,manufacturerAccount.Id));
        insert productsList;
        Test.startTest();
        bundleItemList.add(TestUtil.createBundleItemProduct(configProducts.Id,bundleProducts.id));
        configProducts=TestUtil.createConfigProduct();
        
        
        customerAccount=TestUtil.createCustomerAccount();
        Customer_Addresses__c customerAdress = TestUtil.CustomerAddressNotInsert(customerAccount.Id, 'Primary Billing Address', 'Test');
        Customer_Addresses__c customerAdress2 = TestUtil.CustomerAddressNotInsert(customerAccount.Id, 'Primary Shipping Address', 'Test2');
        Customer_Addresses__c customerAdress3 = TestUtil.CustomerAddressNotInsert(customerAccount.Id, 'billing', 'Test2');
        Customer_Addresses__c customerAdress4 = TestUtil.CustomerAddressNotInsert(customerAccount.Id, 'shipping', 'Test2');
        insert new List<Customer_Addresses__c> {customerAdress, customerAdress2, customerAdress3, customerAdress4};
        //list<Customer_Addresses__c> CustomerAddressesNew = [select id,name,Account__c,AddressType__c from Customer_Addresses__c where Account__c =:customerAccount.Id];
        
      
		
        ApexPages.StandardController sc = new ApexPages.StandardController(soOrdr);
        newSalesOrderController newSalesOrderControllerObj=new newSalesOrderController(sc); 
        newSalesOrderControllerObj.getWebSiteList();
        system.assertEquals('Default Account', customerAccount.Name);
        
        
        newSalesOrderControllerObj.saveAccount();
        newSalesOrderControllerObj.accObject.First_Name__c ='test';
        newSalesOrderControllerObj.accObject.Last_Name__c='test';
        newSalesOrderControllerObj.accObject.Email__c = 'Test@testclass.com';
        newSalesOrderControllerObj.accObject.Phone = '9876543212';
        /*
        newSalesOrderControllerObj.saveAccount();
        
        newSalesOrderControllerObj.getWebSiteList();

        
        newSalesOrderControllerObj.SalesorderObject.Billing_Street__c = 'test';
        newSalesOrderControllerObj.SalesorderObject.Billing_City__c = 'test';
        newSalesOrderControllerObj.SalesorderObject.Billing_State__c = 'test';
        newSalesOrderControllerObj.SalesorderObject.Billing_ZipCode__c = 'test';
        newSalesOrderControllerObj.SalesorderObject.Billing_Country__c = 'test';
        
        newSalesOrderControllerObj.SalesorderObject.Shipping_Street__c = 'test';
        newSalesOrderControllerObj.SalesorderObject.Shipping_City__c = 'test';
        newSalesOrderControllerObj.SalesorderObject.Shipping_State__c = 'test';
        newSalesOrderControllerObj.SalesorderObject.Shipping_ZipCode__c = 'test';
        newSalesOrderControllerObj.SalesorderObject.Shipping_Country__c = 'test';
        newSalesOrderControllerObj.SalesorderObject.Promotion__c=promocodeObj.id;
        newSalesOrderControllerObj.saveAccount();
		
        newSalesOrderControllerObj.SalesorderObject.Shipping_Street__c = null;
        newSalesOrderControllerObj.saveAccount();
        
        newSalesOrderControllerObj.accObject=customerAccount;
        newSalesOrderControllerObj.saveAccount();

        newSalesOrderControllerObj.accObject.Email__c=null;
        newSalesOrderControllerObj.saveAccount();
        newSalesOrderControllerObj.savesalesorder();
        newSalesOrderControllerObj.showDistance();

        newSalesOrderControllerObj.SalesorderObject.Shipping_Street__c = 'too long string || '.repeat(15);
        newSalesOrderControllerObj.saveAccount();
	*/
        Test.stopTest();
    }
    
    public static testmethod void newSalesOrderTestMethod()
    {      
                
        Promotions__c promocodeObj=new Promotions__c();
        
        promocodeObj.Name='Test Prom';
        promocodeObj.Coupon_Code__c='Aico 100';
        promocodeObj.Min_Sub_Total__c=10;
        promocodeObj.Date_Expire__c=system.today().adddays(1);
        promocodeObj.Date_Start__c=system.today().adddays(-1);
        promocodeObj.Discount_Amount__c=200;
        promocodeObj.Type__c='Brand';
        promocodeObj.Is_Active__c = true;
        promocodeObj.Brand__c='Adesso';
        
        insert promocodeObj;
        
        internalAccount=TestUtil.createInternalEmployeeAccount(UserInfo.getUserId());
        
        manufacturerAccount=TestUtil.createManufacturerAccount(true,false,'Email');
        
        configProducts=TestUtil.createConfigProduct();
        configProducts.Tier_Price_For_Bundle__c=20;
        update configProducts;
        protectionProducts=getprotectionPro();
        bundleProducts = getbundlePro();
        
        productsList.add(TestUtil.createSimpleProduct(configProducts.Id,manufacturerAccount.Id));
        productsList.add(TestUtil.createSimpleProduct(null,manufacturerAccount.Id));
        bundleItemList.add(TestUtil.createBundleItemProduct(configProducts.Id,bundleProducts.id));
        configProducts=TestUtil.createConfigProduct();
        productsList.add(TestUtil.createSimpleProduct(configProducts.Id,manufacturerAccount.Id));
        
        customerAccount=TestUtil.createCustomerAccount();
        
        ApexPages.StandardController sc = new ApexPages.StandardController(soOrdr);
        newSalesOrderController newSalesOrderControllerObj=new newSalesOrderController(sc); 
        system.assertEquals('Default Account', customerAccount.Name);
        
        apexpages.currentpage().getparameters().put('productID',configProducts.Id);
        newSalesOrderControllerObj.productWrapperList.get(configProducts.id).selected=true;
        newSalesOrderControllerObj.addProduct();
        
        newSalesOrderControllerObj.OptionsId=bundleProducts.id;
        newSalesOrderControllerObj.getProductRelatedBundle();
        
        apexpages.currentpage().getparameters().put('productID',bundleProducts.id);
        newSalesOrderControllerObj.productWrapperList.get(bundleProducts.id).selected=true;
        newSalesOrderControllerObj.addProduct();
        
        apexpages.currentpage().getparameters().put('productID',bundleProducts.id);
        newSalesOrderControllerObj.productWrapperList.get(bundleProducts.id).selected=false;
        newSalesOrderControllerObj.addProduct();
        Test.startTest();
        apexpages.currentpage().getparameters().put('productID',bundleProducts.id);
        newSalesOrderControllerObj.productWrapperList.get(bundleProducts.id).selected=true;
        newSalesOrderControllerObj.addProduct();
        
        newSalesOrderControllerObj.addBundleProduct();
        
        newSalesOrderControllerObj.getProductRelatedBundle();
        
        newSalesOrderControllerObj.createSoItems();
        newSalesOrderControllerObj.getSoRelated();
        newSalesOrderControllerObj.getSoRelatedBundle();
        newSalesOrderControllerObj.updateProduct();
        
        SO_Line_Items__c soi=new SO_Line_Items__c();
        soi=[select id,Sales_Order__c,Products__r.recordtype.name from SO_Line_Items__c where Bundle_Item__c=null and  Products__r.recordtype.name='Bundled' and Sales_Order__c =: newSalesOrderControllerObj.SalesorderObject.id limit 1];
        
        system.assertEquals(newSalesOrderControllerObj.SalesorderObject.id,soi.Sales_Order__c);
        
        apexpages.currentpage().getParameters().put('SOItemId',soi.id);
        newSalesOrderControllerObj.SOItemId=soi.id;
        
        newSalesOrderControllerObj.SalesorderObject.Promotion__c=promocodeObj.id;
        newSalesOrderControllerObj.updatePromocode();
        
        newSalesOrderControllerObj.SalesorderObject.Promotion__c=promocodeObj.id;
        newSalesOrderControllerObj.AddProtectionPlan();
        
        newSalesOrderControllerObj.UpdateBundelItems();
        newSalesOrderControllerObj.updateQty();
        
        newSalesOrderControllerObj.SalesorderObject.Shipping_City__c='NY';
        newSalesOrderControllerObj.taxCalculation();
        /*
        newSalesOrderControllerObj.SalesorderObject.Shipping_State__c='NY';
        newSalesOrderControllerObj.taxCalculation();
        newSalesOrderControllerObj.protectionplanSOI.id=null;
        newSalesOrderControllerObj.AddProtectionPlan();
        
        newSalesOrderControllerObj.getSoRelated();
        */
        /*apexpages.currentpage().getParameters().put('Remove',soi.id);
        newSalesOrderControllerObj.RemoveProduct();
        
        newSalesOrderControllerObj.goTosalesorderlist();
        newSalesOrderControllerObj.goToHomePage();
        
        newSalesOrderControllerObj.cancelSalesOrder();
        newSalesOrderControllerObj.ShowBundelProduct();*/
        Test.stopTest();
    }
    
    public static testmethod void newSalesOrderTestMethod2()
    {      
        /*Google_API__c googleAPI = new Google_API__c(Name='Google API',Key__c='AIzaSyCAmP-yM5hc67O4stT-VyzMRmDTaVYfXzQ');
        insert googleAPI;
        
        Tax_Percentage__c tpObj=new Tax_Percentage__c();
        tpObj.name='NY';
        tpObj.Percentage__c=8.65;
        insert tpObj;
        */
        manufacturerAccount=TestUtil.createManufacturerAccount(true,false,'Email');
        
        Promotions__c promocodeObj=new Promotions__c();
        
        promocodeObj.Name='Test Prom';
        promocodeObj.Coupon_Code__c='Aico 100';
        promocodeObj.Min_Sub_Total__c=10;
        promocodeObj.Date_Expire__c=system.today().adddays(1);
        promocodeObj.Date_Start__c=system.today().adddays(-1);
        promocodeObj.Discount_Amount__c=200;
        promocodeObj.Type__c='General';
        promocodeObj.Is_Active__c = true;
        promocodeObj.Brands_to_Exclude__c = manufacturerAccount.Name;
        
        insert promocodeObj;
        
        Promotions__c promocodeObj1=new Promotions__c();
        
        promocodeObj1.Name='Test Prom';
        promocodeObj1.Coupon_Code__c='summer 1';
        promocodeObj1.Min_Sub_Total__c=10;
        promocodeObj1.Date_Expire__c=system.today().adddays(1);
        promocodeObj1.Date_Start__c=system.today().adddays(-1);
        promocodeObj1.Discount_Amount__c=1;
        promocodeObj1.Type__c='General';
        promocodeObj1.Is_Active__c = true;
        
        insert promocodeObj1;
        
        internalAccount=TestUtil.createInternalEmployeeAccount(UserInfo.getUserId());
        
        configProducts=TestUtil.createConfigProduct();
        configProducts.Tier_Price_For_Bundle__c=20;
        update configProducts;
        protectionProducts=getprotectionPro();
        bundleProducts = getbundlePro();
        productsList.add(TestUtil.createSimpleProduct(configProducts.Id,manufacturerAccount.Id));
        productsList.add(TestUtil.createSimpleProduct(null,manufacturerAccount.Id));
        bundleItemList.add(TestUtil.createBundleItemProduct(configProducts.Id,bundleProducts.id));
        configProducts=TestUtil.createConfigProduct();
        productsList.add(TestUtil.createSimpleProduct(configProducts.Id,manufacturerAccount.Id));
        
        customerAccount=TestUtil.createCustomerAccount();
        customerAccount.name = 'test Account';
        customerAccount.Authorize_net_Profile_ID__c = '12345';
        customerAccount.ShippingState='NY';
        update customerAccount;
        
        Payment_Method__c pymentId = TestUtil.createpaymentMethod(customerAccount.Id,'Credit Card');
        pymentId.Payment_Profile_ID__c = '12345';
        pymentId.Card_Type__c = 'Visa';
        pymentId.Card_Verification_Number__c = '127';
        pymentId.Credit_Card_Number__c = ''+Crypto.getRandomInteger();
        pymentId.Expiration_Month__c = '06- June';
        pymentId.Expiration_Year__c = '2019';
        pymentId.Magento_Payment_Id__c = ''+Crypto.getRandomInteger();
        pymentId.Name_on_Account__c = 'Test Account';
        pymentId.Payment_Profile_ID__c = ''+Crypto.getRandomInteger();
        pymentId.AVS_Response__c = 'Y';
        
        update pymentId;
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(soOrdr);
        newSalesOrderController newSalesOrderControllerObj=new newSalesOrderController(sc); 
        system.assertEquals('test Account', customerAccount.Name);
        
        apexpages.currentpage().getparameters().put('productID',configProducts.Id);
        newSalesOrderControllerObj.productWrapperList.get(configProducts.id).selected=true;
        newSalesOrderControllerObj.addProduct();
        
        newSalesOrderControllerObj.OptionsId=bundleProducts.id;
        newSalesOrderControllerObj.getProductRelatedBundle();
        
        apexpages.currentpage().getparameters().put('productID',bundleProducts.id);
        newSalesOrderControllerObj.productWrapperList.get(bundleProducts.id).selected=true;
        newSalesOrderControllerObj.addProduct();
        
        apexpages.currentpage().getparameters().put('productID',bundleProducts.id);
        newSalesOrderControllerObj.productWrapperList.get(bundleProducts.id).selected=false;
        newSalesOrderControllerObj.addProduct();
        
        apexpages.currentpage().getparameters().put('productID',bundleProducts.id);
        newSalesOrderControllerObj.productWrapperList.get(bundleProducts.id).selected=true;
        newSalesOrderControllerObj.addProduct();
        
        newSalesOrderControllerObj.addBundleProduct();
        
        newSalesOrderControllerObj.getProductRelatedBundle();
        
        newSalesOrderControllerObj.createSoItems();
        newSalesOrderControllerObj.getSoRelated();
        newSalesOrderControllerObj.getSoRelatedBundle();
        newSalesOrderControllerObj.updateProduct();
        
        SO_Line_Items__c soi=new SO_Line_Items__c();
        soi=[select id,Sales_Order__c,Products__r.recordtype.name from SO_Line_Items__c where Bundle_Item__c=null and  Products__r.recordtype.name='Bundled' and Sales_Order__c =: newSalesOrderControllerObj.SalesorderObject.id limit 1];
        
        system.assertEquals(newSalesOrderControllerObj.SalesorderObject.id,soi.Sales_Order__c);
        
        apexpages.currentpage().getParameters().put('SOItemId',soi.id);
        newSalesOrderControllerObj.SOItemId=soi.id;
        
        newSalesOrderControllerObj.SalesorderObject.Promotion__c=promocodeObj.id;
        newSalesOrderControllerObj.updatePromocode();
        list<Payment_Method__c> paymentMethods =new list<Payment_Method__c>();
        paymentMethods.add(pymentId);
        
        
        
        newSalesOrderControllerObj.insertPaymentMethod(paymentMethods,newSalesOrderControllerObj.SalesorderObject);
        Test.stopTest();
    }
    
    public static testmethod void newSalesOrderPaymentsMethod()
    {
         /*Google_API__c googleAPI = new Google_API__c(Name='Google API',Key__c='AIzaSyCAmP-yM5hc67O4stT-VyzMRmDTaVYfXzQ');
        insert googleAPI;
        
        Tax_Percentage__c tpObj=new Tax_Percentage__c();
        tpObj.name='NY';
        tpObj.Percentage__c=8.62;
        insert tpObj;
        */
        
        internalAccount=TestUtil.createInternalEmployeeAccount(UserInfo.getUserId());
        
        manufacturerAccount=TestUtil.createManufacturerAccount(true,false,'Email');
        productsList.add(TestUtil.createSimpleProduct(configProducts.Id,manufacturerAccount.Id));
        productsList.add(TestUtil.createSimpleProduct(configProducts.Id,manufacturerAccount.Id));
        
        sinmpleProduct=TestUtil.createSimpleProductwithoutMaster(manufacturerAccount.Id);
        
        customerAccount=TestUtil.createCustomerAccount();
        customerAccount.ShippingState='NY';
        update customerAccount;
        
        
        ApexPages.StandardController sc = new ApexPages.StandardController(soOrdr);
        newSalesOrderController newSalesOrderControllerObj=getPopulatedPage();
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new SalesOrder_AuthorizeDotNetHttpMock());
        // new newSalesOrderController(sc);  
         /*  
        newSalesOrderControllerObj.SalesorderObject.Customer_Name__c=customerAccount.id;
        
        newSalesOrderControllerObj.savesalesorder();
        
        Sales_Order__c SalesorderObjectObj=[select Customer_Name__c,(select id from SO_Line_Items__r) from Sales_Order__c where id=:newSalesOrderControllerObj.SalesorderObject.id ];
        system.assertEquals(SalesorderObjectObj.Customer_Name__c,customerAccount.id);
        
        apexpages.currentpage().getparameters().put('productID',sinmpleProduct.id);
        newSalesOrderControllerObj.productWrapperList.get(sinmpleProduct.id).selected=true;
        
        newSalesOrderControllerObj.addProduct();
        newSalesOrderControllerObj.createSoItems();
        newSalesOrderControllerObj.SalesorderObject.Order_ETA__c='Not Available';
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new SalesOrder_AuthorizeDotNetHttpMock());
        
        decimal total=newSalesOrderControllerObj.SalesorderObjectTemp.Grand_Total__c;
     
        newSalesOrderControllerObj.paymentType='CreditCard';
        newSalesOrderControllerObj.hasCard1=true;
        newSalesOrderControllerObj.hasCard3=true;
        newSalesOrderControllerObj.hasCard2=true;
        
        newSalesOrderControllerObj.paymentMethodVar.Card_Type__c='American Express';
        newSalesOrderControllerObj.paymentMethodVar.Card_Verification_Number__c='1234';
        newSalesOrderControllerObj.paymentMethodVar.Expiration_Month__c='11- November';
        newSalesOrderControllerObj.paymentMethodVar.Expiration_Year__c='2016';
        newSalesOrderControllerObj.paymentMethodVar.Credit_Card_Number__c='378282246310005';
        newSalesOrderControllerObj.paymentMethodVar.Amount__c=total-2;
        
        newSalesOrderControllerObj.paymentMethodVar1.Card_Type__c='American Express';
        newSalesOrderControllerObj.paymentMethodVar1.Card_Verification_Number__c='1234';
        newSalesOrderControllerObj.paymentMethodVar1.Expiration_Month__c='11- November';
        newSalesOrderControllerObj.paymentMethodVar1.Expiration_Year__c='2016';
        newSalesOrderControllerObj.paymentMethodVar1.Credit_Card_Number__c='371449635398431';
        newSalesOrderControllerObj.paymentMethodVar1.Amount__c=1;
        
        newSalesOrderControllerObj.paymentMethodVar2.Card_Type__c='American Express';
        newSalesOrderControllerObj.paymentMethodVar2.Card_Verification_Number__c='1234';
        newSalesOrderControllerObj.paymentMethodVar2.Expiration_Month__c='11- November';
        newSalesOrderControllerObj.paymentMethodVar2.Expiration_Year__c='2016';
        newSalesOrderControllerObj.paymentMethodVar2.Credit_Card_Number__c='378282246310005';
        newSalesOrderControllerObj.paymentMethodVar2.Amount__c=1;

        newSalesOrderControllerObj.SalesorderObject.Shipping_Street__c = 'test' ; 
        newSalesOrderControllerObj.SalesorderObject.Shipping_City__c = 'test'; 
        newSalesOrderControllerObj.SalesorderObject.Shipping_State__c = 'test'; 
        newSalesOrderControllerObj.SalesorderObject.shipping_ZipCode__c = 'test';

        newSalesOrderControllerObj.SalesorderObject.Billing_Street__c = 'test' ; 
        newSalesOrderControllerObj.SalesorderObject.Billing_City__c = 'test'; 
        newSalesOrderControllerObj.SalesorderObject.Billing_State__c = 'test'; 
        newSalesOrderControllerObj.SalesorderObject.Billing_ZipCode__c = 'test';
        newSalesOrderControllerObj.SalesorderObject.Bill_To__c = 'test';
*/
        newSalesOrderControllerObj.goToDetailPage();   
        
        /*
        newSalesOrderControllerObj.SalesorderObject.Order_ETA__c='Not Available';
        newSalesOrderControllerObj.custumpricetotal=0;
        newSalesOrderControllerObj.paymentType='PaypalInvoice';
        newSalesOrderControllerObj.goToDetailPage();
		       
        newSalesOrderControllerObj.paymentMethodVar.id=null;
        
        newSalesOrderControllerObj.paymentMethodVar.Check_Type__c='test';
        newSalesOrderControllerObj.paymentMethodVar.Name_on_Account__c='test';
        newSalesOrderControllerObj.paymentMethodVar.Routing_Number__c=123;
        newSalesOrderControllerObj.paymentMethodVar.Account_Number__c=1234;
        newSalesOrderControllerObj.paymentType='Paybycheck';
        newSalesOrderControllerObj.goToDetailPage();
        
        newSalesOrderControllerObj.paymentType='AmazonPay';
        newSalesOrderControllerObj.goToDetailPage();
        
        
        newSalesOrderControllerObj.paymentType='AffirmPay';
        newSalesOrderControllerObj.goToDetailPage();

        newSalesOrderControllerObj.paymentType='CreditCard';
        newSalesOrderControllerObj.goToDetailPage();
        
        newSalesOrderControllerObj.custumpricetotal=600;
        newSalesOrderControllerObj.paymentType='ManualPay';
        newSalesOrderControllerObj.goToDetailPage();*/
        test.stopTest();
    }
    @isTest
    public static void newSalesOrderPaymentsMethodPaypalInvoice(){
        /*Google_API__c googleAPI = new Google_API__c(Name='Google API',Key__c='AIzaSyCAmP-yM5hc67O4stT-VyzMRmDTaVYfXzQ');
        insert googleAPI;
        
        Tax_Percentage__c tpObj=new Tax_Percentage__c();
        tpObj.name='NY';
        tpObj.Percentage__c=8.62;
        insert tpObj;
        */
        
        internalAccount=TestUtil.createInternalEmployeeAccount(UserInfo.getUserId());
        
        manufacturerAccount=TestUtil.createManufacturerAccount(true,false,'Email');
        productsList.add(TestUtil.createSimpleProduct(configProducts.Id,manufacturerAccount.Id));
        productsList.add(TestUtil.createSimpleProduct(configProducts.Id,manufacturerAccount.Id));
        
        sinmpleProduct=TestUtil.createSimpleProductwithoutMaster(manufacturerAccount.Id);
        
        customerAccount=TestUtil.createCustomerAccount();
        customerAccount.ShippingState='NY';
        update customerAccount;
        
        
        ApexPages.StandardController sc = new ApexPages.StandardController(soOrdr);
        newSalesOrderController newSalesOrderControllerObj=getPopulatedPage();// new newSalesOrderController(sc);  
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new SalesOrder_AuthorizeDotNetHttpMock());

        decimal total=newSalesOrderControllerObj.SalesorderObjectTemp.Grand_Total__c;
        newSalesOrderControllerObj.SalesorderObject.Order_ETA__c='Not Available';
        newSalesOrderControllerObj.custumpricetotal=0;
        newSalesOrderControllerObj.paymentType='PaypalInvoice';
        newSalesOrderControllerObj.goToDetailPage();
        Test.stopTest();
    }
    
    @isTest
    public static void newSalesOrderPaymentsMethodPaypalInvoicePaybycheck(){
         /*Google_API__c googleAPI = new Google_API__c(Name='Google API',Key__c='AIzaSyCAmP-yM5hc67O4stT-VyzMRmDTaVYfXzQ');
        insert googleAPI;
        
        Tax_Percentage__c tpObj=new Tax_Percentage__c();
        tpObj.name='NY';
        tpObj.Percentage__c=8.62;
        insert tpObj;
        */
        
        internalAccount=TestUtil.createInternalEmployeeAccount(UserInfo.getUserId());
        
        manufacturerAccount=TestUtil.createManufacturerAccount(true,false,'Email');
        productsList.add(TestUtil.createSimpleProduct(configProducts.Id,manufacturerAccount.Id));
        productsList.add(TestUtil.createSimpleProduct(configProducts.Id,manufacturerAccount.Id));
        
        sinmpleProduct=TestUtil.createSimpleProductwithoutMaster(manufacturerAccount.Id);
        
        customerAccount=TestUtil.createCustomerAccount();
        customerAccount.ShippingState='NY';
        update customerAccount;
        
        
        ApexPages.StandardController sc = new ApexPages.StandardController(soOrdr);
        newSalesOrderController newSalesOrderControllerObj=getPopulatedPage();// new newSalesOrderController(sc);  
        
        test.startTest();
        	Test.setMock(HttpCalloutMock.class, new SalesOrder_AuthorizeDotNetHttpMock());
        
        newSalesOrderControllerObj.paymentMethodVar.id=null;
        
        newSalesOrderControllerObj.paymentMethodVar.Check_Type__c='test';
        newSalesOrderControllerObj.paymentMethodVar.Name_on_Account__c='test';
        newSalesOrderControllerObj.paymentMethodVar.Routing_Number__c=123;
        newSalesOrderControllerObj.paymentMethodVar.Account_Number__c=1234;
        newSalesOrderControllerObj.paymentType='Paybycheck';
        newSalesOrderControllerObj.goToDetailPage();
        test.stopTest();
    }
    
    @isTest
    public static void newSalesOrderPaymentsMethodPaypalAmazonPay(){
        /*Google_API__c googleAPI = new Google_API__c(Name='Google API',Key__c='AIzaSyCAmP-yM5hc67O4stT-VyzMRmDTaVYfXzQ');
        insert googleAPI;
        
        Tax_Percentage__c tpObj=new Tax_Percentage__c();
        tpObj.name='NY';
        tpObj.Percentage__c=8.62;
        insert tpObj;
        */
        
        internalAccount=TestUtil.createInternalEmployeeAccount(UserInfo.getUserId());
        
        manufacturerAccount=TestUtil.createManufacturerAccount(true,false,'Email');
        productsList.add(TestUtil.createSimpleProduct(configProducts.Id,manufacturerAccount.Id));
        productsList.add(TestUtil.createSimpleProduct(configProducts.Id,manufacturerAccount.Id));
        
        sinmpleProduct=TestUtil.createSimpleProductwithoutMaster(manufacturerAccount.Id);
        
        customerAccount=TestUtil.createCustomerAccount();
        customerAccount.ShippingState='NY';
        update customerAccount;
        
        
        ApexPages.StandardController sc = new ApexPages.StandardController(soOrdr);
        newSalesOrderController newSalesOrderControllerObj=getPopulatedPage();// new newSalesOrderController(sc);  

        test.startTest();
        Test.setMock(HttpCalloutMock.class, new SalesOrder_AuthorizeDotNetHttpMock());
        
        newSalesOrderControllerObj.paymentType='AmazonPay';
        newSalesOrderControllerObj.goToDetailPage();
        
        test.stopTest();
    }

     
    @isTest
    public static void newSalesOrderPaymentsMethodPaypalAffirmPay(){
        /*Google_API__c googleAPI = new Google_API__c(Name='Google API',Key__c='AIzaSyCAmP-yM5hc67O4stT-VyzMRmDTaVYfXzQ');
        insert googleAPI;
        
        Tax_Percentage__c tpObj=new Tax_Percentage__c();
        tpObj.name='NY';
        tpObj.Percentage__c=8.62;
        insert tpObj;
        */
        
        internalAccount=TestUtil.createInternalEmployeeAccount(UserInfo.getUserId());
        
        manufacturerAccount=TestUtil.createManufacturerAccount(true,false,'Email');
        productsList.add(TestUtil.createSimpleProduct(configProducts.Id,manufacturerAccount.Id));
        productsList.add(TestUtil.createSimpleProduct(configProducts.Id,manufacturerAccount.Id));
        
        sinmpleProduct=TestUtil.createSimpleProductwithoutMaster(manufacturerAccount.Id);
        
        customerAccount=TestUtil.createCustomerAccount();
        customerAccount.ShippingState='NY';
        update customerAccount;
        
        
        ApexPages.StandardController sc = new ApexPages.StandardController(soOrdr);
        newSalesOrderController newSalesOrderControllerObj=getPopulatedPage();// new newSalesOrderController(sc);  
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new SalesOrder_AuthorizeDotNetHttpMock());
        
        newSalesOrderControllerObj.paymentType='AffirmPay';
        newSalesOrderControllerObj.goToDetailPage();
        
        test.stopTest();
    }
    
     
    @isTest
    public static void newSalesOrderPaymentsMethodPaypalCreditCard(){
        /*Google_API__c googleAPI = new Google_API__c(Name='Google API',Key__c='AIzaSyCAmP-yM5hc67O4stT-VyzMRmDTaVYfXzQ');
        insert googleAPI;
        
        Tax_Percentage__c tpObj=new Tax_Percentage__c();
        tpObj.name='NY';
        tpObj.Percentage__c=8.62;
        insert tpObj;
        */
        
        internalAccount=TestUtil.createInternalEmployeeAccount(UserInfo.getUserId());
        
        manufacturerAccount=TestUtil.createManufacturerAccount(true,false,'Email');
        productsList.add(TestUtil.createSimpleProduct(configProducts.Id,manufacturerAccount.Id));
        productsList.add(TestUtil.createSimpleProduct(configProducts.Id,manufacturerAccount.Id));
        
        sinmpleProduct=TestUtil.createSimpleProductwithoutMaster(manufacturerAccount.Id);
        
        customerAccount=TestUtil.createCustomerAccount();
        customerAccount.ShippingState='NY';
        update customerAccount;
        
        
        ApexPages.StandardController sc = new ApexPages.StandardController(soOrdr);
        newSalesOrderController newSalesOrderControllerObj=getPopulatedPage();// new newSalesOrderController(sc);  
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new SalesOrder_AuthorizeDotNetHttpMock());
        
        newSalesOrderControllerObj.paymentType='CreditCard';
        newSalesOrderControllerObj.goToDetailPage();
        
        test.stopTest();
    }
    
     
    @isTest
    public static void newSalesOrderPaymentsMethodPaypalManualPay(){
         /*Google_API__c googleAPI = new Google_API__c(Name='Google API',Key__c='AIzaSyCAmP-yM5hc67O4stT-VyzMRmDTaVYfXzQ');
        insert googleAPI;
        
        Tax_Percentage__c tpObj=new Tax_Percentage__c();
        tpObj.name='NY';
        tpObj.Percentage__c=8.62;
        insert tpObj;
        */
        
        internalAccount=TestUtil.createInternalEmployeeAccount(UserInfo.getUserId());
        
        manufacturerAccount=TestUtil.createManufacturerAccount(true,false,'Email');
        productsList.add(TestUtil.createSimpleProduct(configProducts.Id,manufacturerAccount.Id));
        productsList.add(TestUtil.createSimpleProduct(configProducts.Id,manufacturerAccount.Id));
        
        sinmpleProduct=TestUtil.createSimpleProductwithoutMaster(manufacturerAccount.Id);
        
        customerAccount=TestUtil.createCustomerAccount();
        customerAccount.ShippingState='NY';
        update customerAccount;
        
        
        ApexPages.StandardController sc = new ApexPages.StandardController(soOrdr);
        newSalesOrderController newSalesOrderControllerObj=getPopulatedPage();// new newSalesOrderController(sc);  
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new SalesOrder_AuthorizeDotNetHttpMock());
        
        newSalesOrderControllerObj.custumpricetotal=600;
        newSalesOrderControllerObj.paymentType='ManualPay';
        newSalesOrderControllerObj.goToDetailPage();
        
        test.stopTest();
    }
    
    static newSalesOrderController getPopulatedPage(){
        ApexPages.StandardController sc = new ApexPages.StandardController(soOrdr);
        newSalesOrderController newSalesOrderControllerObj=new newSalesOrderController(sc);  
        
        newSalesOrderControllerObj.SalesorderObject.Customer_Name__c=customerAccount.id;
        
        newSalesOrderControllerObj.savesalesorder();
        
        Sales_Order__c SalesorderObjectObj=[select Customer_Name__c,(select id from SO_Line_Items__r) from Sales_Order__c where id=:newSalesOrderControllerObj.SalesorderObject.id ];
        system.assertEquals(SalesorderObjectObj.Customer_Name__c,customerAccount.id);
        
        apexpages.currentpage().getparameters().put('productID',sinmpleProduct.id);
        newSalesOrderControllerObj.productWrapperList.get(sinmpleProduct.id).selected=true;
        
        newSalesOrderControllerObj.addProduct();
        newSalesOrderControllerObj.createSoItems();
        newSalesOrderControllerObj.SalesorderObject.Order_ETA__c='Not Available';
        //test.startTest();
        //Test.setMock(HttpCalloutMock.class, new SalesOrder_AuthorizeDotNetHttpMock());
        
        decimal total=newSalesOrderControllerObj.SalesorderObjectTemp.Grand_Total__c;
        
        newSalesOrderControllerObj.paymentType='CreditCard';
        newSalesOrderControllerObj.hasCard1=true;
        newSalesOrderControllerObj.hasCard3=true;
        newSalesOrderControllerObj.hasCard2=true;
        
        newSalesOrderControllerObj.paymentMethodVar.Card_Type__c='American Express';
        newSalesOrderControllerObj.paymentMethodVar.Card_Verification_Number__c='1234';
        newSalesOrderControllerObj.paymentMethodVar.Expiration_Month__c='11- November';
        newSalesOrderControllerObj.paymentMethodVar.Expiration_Year__c='2016';
        newSalesOrderControllerObj.paymentMethodVar.Credit_Card_Number__c='378282246310005';
        newSalesOrderControllerObj.paymentMethodVar.Amount__c=total-2;
        
        newSalesOrderControllerObj.paymentMethodVar1.Card_Type__c='American Express';
        newSalesOrderControllerObj.paymentMethodVar1.Card_Verification_Number__c='1234';
        newSalesOrderControllerObj.paymentMethodVar1.Expiration_Month__c='11- November';
        newSalesOrderControllerObj.paymentMethodVar1.Expiration_Year__c='2016';
        newSalesOrderControllerObj.paymentMethodVar1.Credit_Card_Number__c='371449635398431';
        newSalesOrderControllerObj.paymentMethodVar1.Amount__c=1;
        
        newSalesOrderControllerObj.paymentMethodVar2.Card_Type__c='American Express';
        newSalesOrderControllerObj.paymentMethodVar2.Card_Verification_Number__c='1234';
        newSalesOrderControllerObj.paymentMethodVar2.Expiration_Month__c='11- November';
        newSalesOrderControllerObj.paymentMethodVar2.Expiration_Year__c='2016';
        newSalesOrderControllerObj.paymentMethodVar2.Credit_Card_Number__c='378282246310005';
        newSalesOrderControllerObj.paymentMethodVar2.Amount__c=1;

        newSalesOrderControllerObj.SalesorderObject.Shipping_Street__c = 'test' ; 
        newSalesOrderControllerObj.SalesorderObject.Shipping_City__c = 'test'; 
        newSalesOrderControllerObj.SalesorderObject.Shipping_State__c = 'test'; 
        newSalesOrderControllerObj.SalesorderObject.shipping_ZipCode__c = 'test';

        newSalesOrderControllerObj.SalesorderObject.Billing_Street__c = 'test' ; 
        newSalesOrderControllerObj.SalesorderObject.Billing_City__c = 'test'; 
        newSalesOrderControllerObj.SalesorderObject.Billing_State__c = 'test'; 
        newSalesOrderControllerObj.SalesorderObject.Billing_ZipCode__c = 'test';
        newSalesOrderControllerObj.SalesorderObject.Bill_To__c = 'test';
        return newSalesOrderControllerObj;
    }
    public static testmethod void remoteActionTestMethod()
    {
        /*Google_API__c googleAPI = new Google_API__c(Name='Google API',Key__c='AIzaSyCAmP-yM5hc67O4stT-VyzMRmDTaVYfXzQ');
        insert googleAPI;
        */
        internalAccount=new account();
        internalAccount=TestUtil.createInternalEmployeeAccount(UserInfo.getUserId());
        
        manufacturerAccount=TestUtil.createManufacturerAccount(true,false,'Email');
        
        customerAccount=TestUtil.createCustomerAccount();
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(soOrdr);
        newSalesOrderController newSalesOrderControllerObj=new newSalesOrderController(sc); 
        
        configProducts=TestUtil.createConfigProduct();
        protectionProducts=getprotectionPro();
        productsList.add(TestUtil.createSimpleProduct(configProducts.Id,manufacturerAccount.Id));
        productsList.add(TestUtil.createSimpleProduct(null,manufacturerAccount.Id));
        configProducts=TestUtil.createConfigProduct();
        productsList.add(TestUtil.createSimpleProduct(configProducts.Id,manufacturerAccount.Id));
        
        List<Configurable_Item__c> itemList = new List<Configurable_Item__c>();
        for(Products__c prod_i: productsList){
            Configurable_Item__c confifItem = new Configurable_Item__c ();
            confifItem.Configurable_Product__c = configProducts.id;
            confifItem.Product__c = prod_i.Id;
            itemList.add(confifItem);
        }
        insert itemList;
        
        
        
        
        string productlistfromparam=newSalesOrderController.searchProducts('','','',null);
        Apexpages.currentPage().getParameters().put('productlistfromparam',productlistfromparam);
        newSalesOrderControllerObj.showProducts();
        
        bundleProducts = getbundlePro();
        bundleItemList.add(TestUtil.createBundleItemProduct(configProducts.Id,bundleProducts.id));
        
        productlistfromparam=newSalesOrderController.searchProducts('Kin','a','Manufacture',null);
        Apexpages.currentPage().getParameters().put('productlistfromparam',productlistfromparam);
        newSalesOrderControllerObj.showProducts();
        
        string storedquery = 'select id,Final_OriginalPrice__c,Final_UnitPrice__c,recordtype.name,Type__c,Sales_Price__c,Regular_Price__c,Special_Price_Hidden__c,Select_Manufacturer__r.name,Product_Image_URL__c,recordtypeid,Name,SKU__c,(select id,Final_OriginalPrice__c,Final_UnitPrice__c,Product_Image_URL__c,Special_Price_Hidden__c ,Tier_Price_For_Bundle__c,Name,SKU__c,Regular_Price__c,Sales_Price__c,Special_Price__c,Image__c,Special_Price_From_Date__c,Special_Price_To_Date__c,Master_Products__c from Products__r),(select id,Product__r.recordtype.name,Include__c,Name,Bundle__r.name,Bundle__c,Product__c,Sales_Price__c,ImageURL__c,Bundle_Product_Name__c,SKU__c ,Selection_Qty__c from Bundle_Items1__r order by Include__c desc)  from Products__c where Master_Products__c=null and  recordtype.name!=\'Protection Plan\'  ';
        productlistfromparam=newSalesOrderController.getNextProducts(null,storedquery,null);
        productlistfromparam=newSalesOrderController.getPrevProducts(null,storedquery,null);
        
        productlistfromparam=newSalesOrderController.searchProducts('',bundleProducts.Name,'',null);
        Apexpages.currentPage().getParameters().put('productlistfromparam',productlistfromparam);
        newSalesOrderControllerObj.showProducts();
        newPriceCalculation.getMainBundleWeight(soOrdr.id);
        Test.stopTest();
    }
    
    public static testmethod void authorizeDotNetErrorMethod()
    {
        Test.startTest();
        string response='<?xml version="1.0" encoding="utf-8"?><deleteCustomerPaymentProfileResponse xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd"><refId>CF_Delete</refId><messages><resultCode>Error</resultCode><message><code>E00040</code><text>The record cannot be found.</text></message></messages></deleteCustomerPaymentProfileResponse>';
        
        AuthorizeDotNetError.parse(response);
        Test.stopTest();
    }
    
    public static testmethod void testvoidPaymentsMethod()
    {
        /*Google_API__c googleAPI = new Google_API__c(Name='Google API',Key__c='AIzaSyCAmP-yM5hc67O4stT-VyzMRmDTaVYfXzQ');
        insert googleAPI;
        
        Tax_Percentage__c tpObj=new Tax_Percentage__c();
        tpObj.name='NY';
        tpObj.Percentage__c=8.62;
        insert tpObj;
        */
        
        internalAccount = TestUtil.createInternalEmployeeAccount(UserInfo.getUserId());
        
        manufacturerAccount=TestUtil.createManufacturerAccount(true,false,'Email');
        productsList.add(TestUtil.createSimpleProduct(configProducts.Id,manufacturerAccount.Id));
        productsList.add(TestUtil.createSimpleProduct(configProducts.Id,manufacturerAccount.Id));
        
        sinmpleProduct = TestUtil.createSimpleProductwithoutMaster(manufacturerAccount.Id);
        
        customerAccount=TestUtil.createCustomerAccount();
        customerAccount.name = 'test Account';
        customerAccount.ShippingState='NY';
        customerAccount.Authorize_net_Profile_ID__c = '12345';
        update customerAccount;
        
        List<Payment_Method__c> PMLIst = new List<Payment_Method__c>();
        Payment_Method__c pymentId = TestUtil.createpaymentMethod(customerAccount.Id,'Credit Card');
        pymentId.Payment_Profile_ID__c = '12345';
        pymentId.Card_Type__c = 'Visa';
        pymentId.Card_Verification_Number__c = '127';
        pymentId.Credit_Card_Number__c = ''+Crypto.getRandomInteger();
        pymentId.Expiration_Month__c = '06- June';
        pymentId.Expiration_Year__c = '2019';
        pymentId.Magento_Payment_Id__c = ''+Crypto.getRandomInteger();
        pymentId.Name_on_Account__c = 'Test Account';
        pymentId.Payment_Profile_ID__c = ''+Crypto.getRandomInteger();
        pymentId.AVS_Response__c = 'Y';
        update pymentId;
        PMLIst.add(pymentId);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(soOrdr);
        newSalesOrderController newSalesOrderControllerObj = new newSalesOrderController(sc);  
        Test.startTest();
        newSalesOrderControllerObj.paymentMethodslist = PMLIst;
        list<newSalesOrderController.transactionWrapper> transwrapperList=new list<newSalesOrderController.transactionWrapper>();
        transwrapperList.add(new newSalesOrderController.transactionWrapper('12345679','12345679','12345679'));
        
        
        list<Payment_Method__c> paymentMethods =new list<Payment_Method__c>();
        paymentMethods.add(pymentId);
        
        Transaction__c t = TestUtil.createTrasaction(soOrdr.id, pymentId.id, 'AUTH_ONLY');
        newSalesOrderControllerObj.SalesorderObject.Customer_Name__c=customerAccount.id;
        insert  newSalesOrderControllerObj.SalesorderObject;
        newSalesOrderControllerObj.insertPaymentMethod(paymentMethods,newSalesOrderControllerObj.SalesorderObject);
        newSalesOrderControllerObj.voidPayments(transwrapperList);
        // newSalesOrderControllerObj.insertPaymentMethod(pymentId,customerAccount,'test Account');
        AuthorizeDotNetFunctions authFunction = new AuthorizeDotNetFunctions();
        authFunction.createCustomerRefundTransaction('378282246310005', '378282246310005','378282246310005','5555','120', system.now(), '878', false);
        //authFunction.createCustomerAuthAndCaptureTransaction('378282246310005', '378282246310005','5555','120');
        authFunction.CaptureaPreviouslyAuthorizedAmount(t.id, '120','5555', system.now(), false);
        authFunction.updatePaymentProfileAddress('TestName', '4829 N Oconnor Road, Apt 163', 'Irving', 'Texas', '75062', 'United States', '378282246310005', '2021/05','5555','liveMode');
        Test.stopTest();
    }
    
    
    public static testmethod void updateBrandPromocodeTestMethod() 
    {

        States__c stateValue = new States__c();
        stateValue.Name = 'New York';
        insert stateValue;
        
        internalAccount = TestUtil.createInternalEmployeeAccount(UserInfo.getUserId());
        customerAccount = TestUtil.createCustomerAccount();
        manufacturerAccount = TestUtil.createManufacturerAccount(true,false,'Email');
        set<String> manufactureList = new set<String>();
        manufactureList.add(manufacturerAccount.name);
        
        Promotions__c promocodeObj = TestUtil.createPromotion('Promo Code', 'Brand');
        promocodeObj.Brand__c = manufacturerAccount.name;
        update promocodeObj;
        
        Products__c simplewithoutMasterProduct = TestUtil.createSimpleProductwithoutMaster(manufacturerAccount.id);
        Products__c configProduct = TestUtil.createConfigProduct();
        Products__c simplewithConfigProduct = TestUtil.createSimpleProduct(configProduct.id, manufacturerAccount.id);
        Products__c bundleProduct = getbundlePro();
        Bundle_Item__c bundleItem = TestUtil.createBundleItemProductNotInsert(simplewithoutMasterProduct.id,bundleProduct.id);
        Bundle_Item__c bundleItem1 = TestUtil.createBundleItemProductNotInsert(configProduct.id,bundleProduct.id);
        
        insert new List<Bundle_Item__c> {bundleItem, bundleItem1};
            
        Configurable_Item__c confifItem = new Configurable_Item__c ();
        confifItem.Configurable_Product__c = configProduct.id;
        confifItem.Product__c = simplewithConfigProduct.Id;
        insert confifItem;
        
        list<Bundle_Item__c> BIList = new list<Bundle_Item__c>();
        BIList.add(bundleItem);
        BIList.add(bundleItem1);
        map<string,list<Bundle_Item__c>> ProductRelatedBundleTempList = new map<string,list<Bundle_Item__c>>();
        ProductRelatedBundleTempList.put(bundleProduct.id, BIList);
        
        Sales_Order__c salesOrder = TestUtil.createsalesOrder(customerAccount.Id,null,null);
        salesOrder.Promotion__c = promocodeObj.id;
        update salesOrder;
        
        SO_Line_Items__c SOItem = TestUtil.createsalesOrderLineItemNotInsert(salesOrder.id,simplewithoutMasterProduct.id,null,null,2);
        SOItem.Custom_Price__c = 0;
        SO_Line_Items__c SOItem1 = TestUtil.createsalesOrderLineItemNotInsert(salesOrder.id,configProduct.id,simplewithoutMasterProduct.id,null,2);
        SO_Line_Items__c SOItem2 = TestUtil.createsalesOrderLineItemNotInsert(salesOrder.id,bundleProduct.id,null,null,2);
        SO_Line_Items__c SOItem3 = TestUtil.createsalesOrderLineItemNotInsert (salesOrder.id,bundleProduct.id,null,bundleItem.id,2);
        SO_Line_Items__c SOItem4 = TestUtil.createsalesOrderLineItemNotInsert(salesOrder.id,bundleProduct.id,configProduct.id,bundleItem1.id,2);
        
        //update SOItem;
        /*
        SOItem = [select id,FedExable__c,Bundle_Items_Count__c,Products__r.Select_Manufacturer__r.name,Product_Record_Type__c,Custom_Price__c,Products__r.recordtypeid,Products__r.recordtype.name,TaxAmount__c,Sub_Total__c,Price__c,ProductImageUrl__c,name,Products__c,Products__r.Image__c,Products__r.name,Manufacturer__c,OriginalPrice__c,Product_Brand__c,
                  Products__r.Select_Manufacturer__c,Promotion_Brand__c,Quantity__c,DiscountAmount__c,Row_Total__c,Quantity_Invoiced__c,Sales_Order__c,Tax_Amount__c,Tax_Percent__c,Total__c,UnitPrice__c,Bundle_Item__c,Config_Product__c,Product_Name__c,ProductSKU__c,Product_Url__c,Item__c from SO_Line_Items__c where id=:SOItem.id];
        
		SOItem1 = [select id,FedExable__c,Bundle_Items_Count__c,Products__r.Select_Manufacturer__r.name,Product_Record_Type__c,Custom_Price__c,Products__r.recordtypeid,Products__r.recordtype.name,TaxAmount__c,Sub_Total__c,Price__c,ProductImageUrl__c,name,Products__c,Products__r.Image__c,Products__r.name,Manufacturer__c,OriginalPrice__c,Product_Brand__c,
                   Products__r.Select_Manufacturer__c,Promotion_Brand__c,Quantity__c,DiscountAmount__c,Row_Total__c,Quantity_Invoiced__c,Sales_Order__c,Tax_Amount__c,Tax_Percent__c,Total__c,UnitPrice__c,Bundle_Item__c,Config_Product__c,Product_Name__c,ProductSKU__c,Product_Url__c,Item__c from SO_Line_Items__c where id=:SOItem1.id];
        
        SOItem2 = [select id,FedExable__c,Bundle_Items_Count__c,Products__r.Select_Manufacturer__r.name,Product_Record_Type__c,Custom_Price__c,Products__r.recordtypeid,Products__r.recordtype.name,TaxAmount__c,Sub_Total__c,Price__c,ProductImageUrl__c,name,Products__c,Products__r.Image__c,Products__r.name,Manufacturer__c,OriginalPrice__c,Product_Brand__c,
                   Products__r.Select_Manufacturer__c,Promotion_Brand__c,Quantity__c,DiscountAmount__c,Row_Total__c,Quantity_Invoiced__c,Sales_Order__c,Tax_Amount__c,Tax_Percent__c,Total__c,UnitPrice__c,Bundle_Item__c,Config_Product__c,Product_Name__c,ProductSKU__c,Product_Url__c,Item__c from SO_Line_Items__c where id=:SOItem2.id];
        */
        List<SO_Line_Items__c> orderItemList = new List<SO_Line_Items__c> {SOItem, SOItem1, SOItem2, SOItem3, SOItem4};
        insert orderItemList;
        
        list<SO_Line_Items__c> BundelSOitems = [select id,FedExable__c,Bundle_Items_Count__c,Products__r.Select_Manufacturer__r.name,Product_Record_Type__c,Custom_Price__c,Products__r.recordtypeid,Products__r.recordtype.name,TaxAmount__c,Sub_Total__c,Price__c,ProductImageUrl__c,name,Products__c,Products__r.Image__c,Products__r.name,Manufacturer__c,OriginalPrice__c,Product_Brand__c,
                  Products__r.Select_Manufacturer__c,Promotion_Brand__c,Quantity__c,DiscountAmount__c,Row_Total__c,Quantity_Invoiced__c,Sales_Order__c,Tax_Amount__c,Tax_Percent__c,Total__c,UnitPrice__c,Bundle_Item__c,Config_Product__c,Product_Name__c,ProductSKU__c,Product_Url__c,Item__c from SO_Line_Items__c where id IN :orderItemList];
            /*new list<SO_Line_Items__c>();
        BundelSOitems.add(SOItem3);
        BundelSOitems.add(SOItem4);
        */
        List<selectoption> configpro = new List<selectoption>();
        configpro.add(new selectOption(simplewithConfigProduct.id,simplewithConfigProduct.name)); 
        
        map<string,newSalesOrderController.SelectedProductWrapper> SoRelated = new map<string,newSalesOrderController.SelectedProductWrapper>();
        SoRelated.put(SOItem.id,new newSalesOrderController.SelectedProductWrapper(SOItem,new list<SO_Line_Items__c>(),new list<selectoption>()));
        SoRelated.put(SOItem1.id,new newSalesOrderController.SelectedProductWrapper(SOItem1,new list<SO_Line_Items__c>(),configpro));
        SoRelated.put(SOItem2.id,new newSalesOrderController.SelectedProductWrapper(SOItem2,BundelSOitems,new list<selectoption>()));
        
        test.startTest();
        PageReference pref = Page.newSalesOrderPage;
        ApexPages.StandardController sc = new ApexPages.StandardController(salesOrder);
        apexpages.currentpage().getparameters().put('id',salesOrder.id);
        test.setCurrentPage(pref);
        newSalesOrderController newSalesOrderControllerObj = new newSalesOrderController(sc);
        
        newSalesOrderControllerObj.SalesorderObject = salesOrder;
        //newSalesOrderControllerObj.updatePromocode();
        
        newSalesOrderControllerObj.SoRelated = SoRelated;
        newSalesOrderControllerObj.manufactureList = manufactureList;
        newSalesOrderControllerObj.updatePromocode();
        
        test.stopTest();
    }
    
    public static testmethod void updateGeneralPromocodeTestMethod() 
    {
        /*Google_API__c googleAPI = new Google_API__c(Name='Google API',Key__c='AIzaSyCAmP-yM5hc67O4stT-VyzMRmDTaVYfXzQ');
        insert googleAPI;
        
        Tax_Percentage__c tpObj=new Tax_Percentage__c();
        tpObj.name='NY';
        tpObj.Percentage__c=8.62;
        insert tpObj;
        */
        
        States__c stateValue = new States__c();
        stateValue.Name = 'New York';
        insert stateValue;
        
        internalAccount = TestUtil.createInternalEmployeeAccount(UserInfo.getUserId());
        customerAccount = TestUtil.createCustomerAccount();
        manufacturerAccount = TestUtil.createManufacturerAccount(true,false,'Email');
        set<String> manufactureList = new set<String>();
        manufactureList.add(manufacturerAccount.name);
        
        Promotions__c promocodeObj = TestUtil.createPromotion('Promo Code', 'General');
        
        Products__c simplewithoutMasterProduct = TestUtil.createSimpleProductwithoutMaster(manufacturerAccount.id);
        Products__c configProduct = TestUtil.createConfigProduct();
        Products__c simplewithConfigProduct = TestUtil.createSimpleProduct(configProduct.id, manufacturerAccount.id);
        Products__c bundleProduct = getbundlePro();
        Bundle_Item__c bundleItem = TestUtil.createBundleItemProductNotInsert(simplewithoutMasterProduct.id,bundleProduct.id);
        Bundle_Item__c bundleItem1 = TestUtil.createBundleItemProductNotInsert(configProduct.id,bundleProduct.id);
        insert new List<Bundle_Item__c> {bundleItem, bundleItem1};
        Configurable_Item__c confifItem = new Configurable_Item__c ();
        confifItem.Configurable_Product__c = configProduct.id;
        confifItem.Product__c = simplewithConfigProduct.Id;
        insert confifItem;
        
        list<Bundle_Item__c> BIList = new list<Bundle_Item__c>();
        BIList.add(bundleItem);
        BIList.add(bundleItem1);
        map<string,list<Bundle_Item__c>> ProductRelatedBundleTempList = new map<string,list<Bundle_Item__c>>();
        ProductRelatedBundleTempList.put(bundleProduct.id, BIList);
        
        Sales_Order__c salesOrder = TestUtil.createsalesOrder(customerAccount.Id,null,null);
        salesOrder.Promotion__c = promocodeObj.id;
        update salesOrder;
        /*
        SO_Line_Items__c SOItem = TestUtil.createsalesOrderLineItem(salesOrder.id,simplewithoutMasterProduct.id,null,null,2);
        SOItem.Custom_Price__c = 0;
        update SOItem;
        SOItem = [select id,FedExable__c,Bundle_Items_Count__c,Products__r.Select_Manufacturer__r.name,Product_Record_Type__c,Custom_Price__c,Products__r.recordtypeid,Products__r.recordtype.name,TaxAmount__c,Sub_Total__c,Price__c,ProductImageUrl__c,name,Products__c,Products__r.Image__c,Products__r.name,Manufacturer__c,OriginalPrice__c,Product_Brand__c,
                  Products__r.Select_Manufacturer__c,Promotion_Brand__c,Quantity__c,DiscountAmount__c,Row_Total__c,Quantity_Invoiced__c,Sales_Order__c,Tax_Amount__c,Tax_Percent__c,Total__c,UnitPrice__c,Bundle_Item__c,Config_Product__c,Product_Name__c,ProductSKU__c,Product_Url__c,Item__c from SO_Line_Items__c where id=:SOItem.id];
        
        SO_Line_Items__c SOItem1 = TestUtil.createsalesOrderLineItem(salesOrder.id,configProduct.id,simplewithoutMasterProduct.id,null,2);
        SOItem1 = [select id,FedExable__c,Bundle_Items_Count__c,Products__r.Select_Manufacturer__r.name,Product_Record_Type__c,Custom_Price__c,Products__r.recordtypeid,Products__r.recordtype.name,TaxAmount__c,Sub_Total__c,Price__c,ProductImageUrl__c,name,Products__c,Products__r.Image__c,Products__r.name,Manufacturer__c,OriginalPrice__c,Product_Brand__c,
                   Products__r.Select_Manufacturer__c,Promotion_Brand__c,Quantity__c,DiscountAmount__c,Row_Total__c,Quantity_Invoiced__c,Sales_Order__c,Tax_Amount__c,Tax_Percent__c,Total__c,UnitPrice__c,Bundle_Item__c,Config_Product__c,Product_Name__c,ProductSKU__c,Product_Url__c,Item__c from SO_Line_Items__c where id=:SOItem1.id];
        
        SO_Line_Items__c SOItem2 = TestUtil.createsalesOrderLineItem(salesOrder.id,bundleProduct.id,null,null,2);
        SOItem2 = [select id,FedExable__c,Bundle_Items_Count__c,Products__r.Select_Manufacturer__r.name,Product_Record_Type__c,Custom_Price__c,Products__r.recordtypeid,Products__r.recordtype.name,TaxAmount__c,Sub_Total__c,Price__c,ProductImageUrl__c,name,Products__c,Products__r.Image__c,Products__r.name,Manufacturer__c,OriginalPrice__c,Product_Brand__c,
                   Products__r.Select_Manufacturer__c,Promotion_Brand__c,Quantity__c,DiscountAmount__c,Row_Total__c,Quantity_Invoiced__c,Sales_Order__c,Tax_Amount__c,Tax_Percent__c,Total__c,UnitPrice__c,Bundle_Item__c,Config_Product__c,Product_Name__c,ProductSKU__c,Product_Url__c,Item__c from SO_Line_Items__c where id=:SOItem2.id];
        
        SO_Line_Items__c SOItem3 = TestUtil.createsalesOrderLineItem(salesOrder.id,bundleProduct.id,null,bundleItem.id,2);
        SO_Line_Items__c SOItem4 = TestUtil.createsalesOrderLineItem(salesOrder.id,bundleProduct.id,configProduct.id,bundleItem1.id,2);
        */
        
        SO_Line_Items__c SOItem = TestUtil.createsalesOrderLineItemNotInsert(salesOrder.id,simplewithoutMasterProduct.id,null,null,2);
        SOItem.Custom_Price__c = 0;
        SO_Line_Items__c SOItem1 = TestUtil.createsalesOrderLineItemNotInsert(salesOrder.id,configProduct.id,simplewithoutMasterProduct.id,null,2);
        SO_Line_Items__c SOItem2 = TestUtil.createsalesOrderLineItemNotInsert(salesOrder.id,bundleProduct.id,null,null,2);
        SO_Line_Items__c SOItem3 = TestUtil.createsalesOrderLineItemNotInsert (salesOrder.id,bundleProduct.id,null,bundleItem.id,2);
        SO_Line_Items__c SOItem4 = TestUtil.createsalesOrderLineItemNotInsert(salesOrder.id,bundleProduct.id,configProduct.id,bundleItem1.id,2);
        List<SO_Line_Items__c> orderItemList = new List<SO_Line_Items__c> {SOItem, SOItem1, SOItem2, SOItem3, SOItem4};
        insert orderItemList;
        list<SO_Line_Items__c> BundelSOitems = [select id,FedExable__c,Bundle_Items_Count__c,Products__r.Select_Manufacturer__r.name,Product_Record_Type__c,Custom_Price__c,Products__r.recordtypeid,Products__r.recordtype.name,TaxAmount__c,Sub_Total__c,Price__c,ProductImageUrl__c,name,Products__c,Products__r.Image__c,Products__r.name,Manufacturer__c,OriginalPrice__c,Product_Brand__c,
                  Products__r.Select_Manufacturer__c,Promotion_Brand__c,Quantity__c,DiscountAmount__c,Row_Total__c,Quantity_Invoiced__c,Sales_Order__c,Tax_Amount__c,Tax_Percent__c,Total__c,UnitPrice__c,Bundle_Item__c,Config_Product__c,Product_Name__c,ProductSKU__c,Product_Url__c,Item__c from SO_Line_Items__c where id IN :orderItemList];
        
        /*
        list<SO_Line_Items__c> BundelSOitems = new list<SO_Line_Items__c>();
        BundelSOitems.add(SOItem3);
        BundelSOitems.add(SOItem4);
        */
        List<selectoption> configpro = new List<selectoption>();
        configpro.add(new selectOption(simplewithConfigProduct.id,simplewithConfigProduct.name)); 
        
        map<string,newSalesOrderController.SelectedProductWrapper> SoRelated = new map<string,newSalesOrderController.SelectedProductWrapper>();
        SoRelated.put(SOItem.id,new newSalesOrderController.SelectedProductWrapper(SOItem,new list<SO_Line_Items__c>(),new list<selectoption>()));
        SoRelated.put(SOItem1.id,new newSalesOrderController.SelectedProductWrapper(SOItem1,new list<SO_Line_Items__c>(),configpro));
        SoRelated.put(SOItem2.id,new newSalesOrderController.SelectedProductWrapper(SOItem2,BundelSOitems,new list<selectoption>()));
        
        salesOrder = [select id,Email__c,Mobile__c,Alternate_Email__c ,Customer_Billing_Address__c ,Notify_Customer_with_Email__c,
                      Customer_Name__c,Grand_Total__c,Order_ETA__c,Delivery_Companies_Distance__c,Discount_Amount_Total__c,
                      Discount_AmountTotal__c,TaxAmount__c,Shipping_Handle__c,Promotion__c,Sub_Total__c,
                      Billing_Street__c,Billing_City__c,Billing_State__c,Billing_Country__c,Billing_ZipCode__c,
                      Shipping_Street__c,Shipping_City__c,Shipping_State__c,Shipping_Country__c,Shipping_ZipCode__c
                      from Sales_Order__c where id =:salesOrder.id];
        test.startTest();
        PageReference pref = Page.newSalesOrderPage;
        ApexPages.StandardController sc = new ApexPages.StandardController(salesOrder);
        apexpages.currentpage().getparameters().put('id',salesOrder.id);
        test.setCurrentPage(pref);
        newSalesOrderController newSalesOrderControllerObj = new newSalesOrderController(sc);
        
        newSalesOrderControllerObj.SalesorderObject = salesOrder;
        
        newSalesOrderControllerObj.SoRelated = SoRelated;
        newSalesOrderControllerObj.manufactureList = manufactureList;
        newSalesOrderControllerObj.updatePromocode();
        
        
        promocodeObj.Brands_to_Exclude__c = 'Aico';
        Update promocodeObj;
        newSalesOrderControllerObj.updatePromocode();
        newPriceCalculation.getMainBundleWeight(salesOrder.id);
        test.stopTest();
    }
    
    public static testmethod void newSalesOrderAccountTestMethodNewCoverage ()
    { 
       /* Google_API__c googleAPI = new Google_API__c(Name='Google API',Key__c='AIzaSyCAmP-yM5hc67O4stT-VyzMRmDTaVYfXzQ');
        insert googleAPI;
        
        Tax_Percentage__c tpObj=new Tax_Percentage__c();
        tpObj.name='NY';
        tpObj.Percentage__c=8.62;
        insert tpObj;
        */
        States__c stateValue = new States__c();
        stateValue.Name = 'New York';
        insert stateValue;
        
        internalAccount=TestUtil.createInternalEmployeeAccount(UserInfo.getUserId());
        
        manufacturerAccount=TestUtil.createManufacturerAccount(true,false,'Email');
        
        Promotions__c promocodeObj=new Promotions__c();
        
        promocodeObj.Name='Test Prom';
        promocodeObj.Coupon_Code__c='Aico 100';
        promocodeObj.Min_Sub_Total__c=10;
        promocodeObj.Date_Expire__c=system.today().adddays(1);
        promocodeObj.Date_Start__c=system.today().adddays(-1);
        promocodeObj.Discount_Amount__c=200;
        promocodeObj.Type__c='General';
        promocodeObj.Brands_to_Exclude__c = manufacturerAccount.Name;
        
        //insert promocodeObj;
        
        Promotions__c promocodeObj1=new Promotions__c();
        
        promocodeObj1.Name='Test Prom';
        promocodeObj1.Coupon_Code__c='summer 1';
        promocodeObj1.Min_Sub_Total__c=10;
        promocodeObj1.Date_Expire__c=system.today().adddays(1);
        promocodeObj1.Date_Start__c=system.today().adddays(-1);
        promocodeObj1.Discount_Amount__c=1;
        promocodeObj1.Type__c='General';
        
        insert new List<Promotions__c> {promocodeObj, promocodeObj1};
        
        configProducts=TestUtil.createConfigProduct();
        configProducts.Tier_Price_For_Bundle__c=20;
        update configProducts;
        protectionProducts=getprotectionPro();
        bundleProducts = getbundlePro();
        productsList.add(TestUtil.createSimpleProduct(configProducts.Id,manufacturerAccount.Id));
        productsList.add(TestUtil.createSimpleProduct(null,manufacturerAccount.Id));
        bundleItemList.add(TestUtil.createBundleItemProduct(configProducts.Id,bundleProducts.id));
        configProducts=TestUtil.createConfigProduct();
        productsList.add(TestUtil.createSimpleProduct(configProducts.Id,manufacturerAccount.Id));
        
        customerAccount=TestUtil.createCustomerAccount();
        Customer_Addresses__c customerAdress = TestUtil.CustomerAddress(customerAccount.Id, 'Primary Billing Address', 'Test');
        Customer_Addresses__c customerAdress2 = TestUtil.CustomerAddress(customerAccount.Id, 'Primary Shipping Address', 'Test2');
        Customer_Addresses__c customerAdress3 = TestUtil.CustomerAddress(customerAccount.Id, 'billing', 'Test2');
        Customer_Addresses__c customerAdress4 = TestUtil.CustomerAddress(customerAccount.Id, 'shipping', 'Test2');
        list<Customer_Addresses__c> CustomerAddressesNew = [select id,name,Account__c,AddressType__c from Customer_Addresses__c where Account__c =:customerAccount.Id];
        

        ApexPages.StandardController sc = new ApexPages.StandardController(soOrdr);
        newSalesOrderController newSalesOrderControllerObj=new newSalesOrderController(sc); 
        
        //Test.startTest();
        
        
        newSalesOrderControllerObj.saveAccount();
        newSalesOrderControllerObj.accObject.First_Name__c ='test';
        newSalesOrderControllerObj.accObject.Last_Name__c='test';
        newSalesOrderControllerObj.accObject.Email__c = 'Test@testcssadlass.com';
        newSalesOrderControllerObj.accObject.Phone = '9876543212';
        
        newSalesOrderControllerObj.saveAccount();
        
        newSalesOrderControllerObj.getWebSiteList();
		Test.startTest();
        
        newSalesOrderControllerObj.SalesorderObject.Billing_Street__c = 'test';
        newSalesOrderControllerObj.SalesorderObject.Billing_City__c = 'test';
        newSalesOrderControllerObj.SalesorderObject.Billing_State__c = 'test';
        newSalesOrderControllerObj.SalesorderObject.Billing_ZipCode__c = 'test';
        newSalesOrderControllerObj.SalesorderObject.Billing_Country__c = 'test';
        
        newSalesOrderControllerObj.SalesorderObject.Shipping_Street__c = 'test';
        newSalesOrderControllerObj.SalesorderObject.Shipping_City__c = 'test';
        newSalesOrderControllerObj.SalesorderObject.Shipping_State__c = 'test';
        newSalesOrderControllerObj.SalesorderObject.Shipping_ZipCode__c = 'test';
        newSalesOrderControllerObj.SalesorderObject.Shipping_Country__c = 'test';
        newSalesOrderControllerObj.SalesorderObject.Promotion__c=promocodeObj.id;
        //newSalesOrderControllerObj.saveAccount();
        newSalesOrderControllerObj.accObject.Email__c = 'Test@testscssadlass.com';
        newSalesOrderControllerObj.getSoRelated();
        newSalesOrderControllerObj.saveAccount();
        newSalesOrderControllerObj.SalesorderObject.Customer_Name__c = customerAccount.Id;
        
        newSalesOrderControllerObj.savesalesorder();
        
		Products__c simplewithoutMasterProduct = TestUtil.createSimpleProductwithoutMaster(manufacturerAccount.id);
        Products__c configProduct = TestUtil.createConfigProduct();
        Products__c simplewithConfigProduct = TestUtil.createSimpleProduct(configProduct.id, manufacturerAccount.id);
        Products__c bundleProduct = getbundlePro();
        Bundle_Item__c bundleItem = TestUtil.createBundleItemProduct(simplewithoutMasterProduct.id,bundleProduct.id);
        Bundle_Item__c bundleItem1 = TestUtil.createBundleItemProduct(configProduct.id,bundleProduct.id);
        
        Configurable_Item__c confifItem = new Configurable_Item__c ();
        confifItem.Configurable_Product__c = configProduct.id;
        confifItem.Product__c = simplewithConfigProduct.Id;
        insert confifItem;
        
        list<Bundle_Item__c> BIList = new list<Bundle_Item__c>();
        BIList.add(bundleItem);
        BIList.add(bundleItem1);
        map<string,list<Bundle_Item__c>> ProductRelatedBundleTempList = new map<string,list<Bundle_Item__c>>();
        ProductRelatedBundleTempList.put(bundleProduct.id, BIList);
        
        Sales_Order__c salesOrder = newSalesOrderControllerObj.SalesorderObject;
        
        SO_Line_Items__c SOItem5 = TestUtil.createsalesOrderLineItemNotInsert(salesOrder.id,bundleProduct.id,null,null,2);  
        SOItem5.Custom_Price__c = 1;
        SOItem5.Bundle_Items_Count__c = 1;
        //update SOItem5;
        
        SO_Line_Items__c SOItem = TestUtil.createsalesOrderLineItemNotInsert(salesOrder.id,simplewithoutMasterProduct.id,null,null,2);
        SOItem.Custom_Price__c = 2;
        SOItem.Bundle_Items_Count__c = 1;
        //update SOItem;
        
        //SOItem = [select id,FedExable__c,Bundle_Items_Count__c,Products__r.Select_Manufacturer__r.name,Product_Record_Type__c,Custom_Price__c,Products__r.recordtypeid,Products__r.recordtype.name,TaxAmount__c,Sub_Total__c,Price__c,ProductImageUrl__c,name,Products__c,Products__r.Image__c,Products__r.name,Manufacturer__c,OriginalPrice__c,Product_Brand__c,
        //          Products__r.Select_Manufacturer__c,Promotion_Brand__c,Quantity__c,DiscountAmount__c,Row_Total__c,Quantity_Invoiced__c,Sales_Order__c,Tax_Amount__c,Tax_Percent__c,Total__c,UnitPrice__c,Bundle_Item__c,Config_Product__c,Product_Name__c,ProductSKU__c,Product_Url__c,Item__c from SO_Line_Items__c where id=:SOItem.id];
        
        SO_Line_Items__c SOItem1 = TestUtil.createsalesOrderLineItemNotInsert(salesOrder.id,configProduct.id,simplewithoutMasterProduct.id,null,2);
        SOItem1.Custom_Price__c = 2;
        SOItem1.Bundle_Items_Count__c = 1;
        //update SOItem5;
        
        //SOItem1 = [select id,FedExable__c,Bundle_Items_Count__c,Products__r.Select_Manufacturer__r.name,Product_Record_Type__c,Custom_Price__c,Products__r.recordtypeid,Products__r.recordtype.name,TaxAmount__c,Sub_Total__c,Price__c,ProductImageUrl__c,name,Products__c,Products__r.Image__c,Products__r.name,Manufacturer__c,OriginalPrice__c,Product_Brand__c,
        //           Products__r.Select_Manufacturer__c,Promotion_Brand__c,Quantity__c,DiscountAmount__c,Row_Total__c,Quantity_Invoiced__c,Sales_Order__c,Tax_Amount__c,Tax_Percent__c,Total__c,UnitPrice__c,Bundle_Item__c,Config_Product__c,Product_Name__c,ProductSKU__c,Product_Url__c,Item__c from SO_Line_Items__c where id=:SOItem1.id];
        
        SO_Line_Items__c SOItem2 = TestUtil.createsalesOrderLineItemNotInsert(salesOrder.id,bundleProduct.id,null,null,2);
        SOItem2.Custom_Price__c = 2;
        SOItem2.Bundle_Items_Count__c = 1;
        //update SOItem2;
        
        //SOItem2 = [select id,FedExable__c,Bundle_Items_Count__c,Products__r.Select_Manufacturer__r.name,Product_Record_Type__c,Custom_Price__c,Products__r.recordtypeid,Products__r.recordtype.name,TaxAmount__c,Sub_Total__c,Price__c,ProductImageUrl__c,name,Products__c,Products__r.Image__c,Products__r.name,Manufacturer__c,OriginalPrice__c,Product_Brand__c,
        //           Products__r.Select_Manufacturer__c,Promotion_Brand__c,Quantity__c,DiscountAmount__c,Row_Total__c,Quantity_Invoiced__c,Sales_Order__c,Tax_Amount__c,Tax_Percent__c,Total__c,UnitPrice__c,Bundle_Item__c,Config_Product__c,Product_Name__c,ProductSKU__c,Product_Url__c,Item__c from SO_Line_Items__c where id=:SOItem2.id];
        
        SO_Line_Items__c SOItem3 = TestUtil.createsalesOrderLineItemNotInsert(salesOrder.id,bundleProduct.id,null,bundleItem.id,2);
        SOItem3.Custom_Price__c = 2;
        SOItem3.Bundle_Items_Count__c = 1;
        insert new List<SO_Line_Items__c> {SOItem2, SOItem5, SOItem, SOItem3};
        /*
        update SOItem3;
        
        SO_Line_Items__c SOItem4 = TestUtil.createsalesOrderLineItem(salesOrder.id,bundleProduct.id,configProduct.id,bundleItem1.id,2);   
        SOItem4.Custom_Price__c = 2;
        SOItem4.Bundle_Items_Count__c = 1;
        update SOItem4;

        */
        
        newSalesOrderControllerObj.accObject.Email__c = 'Test@mail.net.com';
        newSalesOrderControllerObj.getSoRelated();
        newSalesOrderControllerObj.saveAccount();
        
        newSalesOrderControllerObj.updateProduct();
        
        Test.stopTest();
    }
}