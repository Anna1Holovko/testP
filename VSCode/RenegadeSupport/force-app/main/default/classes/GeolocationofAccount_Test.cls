/*
*   Author : Vishnu Bijjula | Kairos Tech
*   Class  : GeolocationofAccount_test
*   Purpose: This test class to cover the code coverage for GeolocationofAccount trigger and Helper Class.
*/
@isTest
public class GeolocationofAccount_Test {
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
    }
    
    static testMethod void TestManufacturerAndDeliveryUpdate()
    {
        Google_API__c googleAPI = new Google_API__c(Name='Google API',Key__c='AIzaSyCAmP-yM5hc67O4stT-VyzMRmDTaVYfXzQ');
        insert googleAPI;
        
        Account deliveryAccount = TestUtil.createDeliveryAccount();
        Account manufactureAccount = TestUtil.createManufacturerAccount(true,false, 'Email');
        
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        deliveryAccount.ShippingCity = 'Texas';
        update deliveryAccount;
            
        manufactureAccount.BillingCity = 'Texas';
        update manufactureAccount;       
        
        Account customerAccount = TestUtil.createCustomerAccount();
        update customerAccount;
        
     //   MagentoFunctions MF = new MagentoFunctions();
     //   MF.getUrlParams('http://stage01.colemanfurniture.com/api/rest/customers/64908/addresses?oauth_consumer_key=ulzh3hgcx5pcmfkvbcd7x369bxfqjzmp&oauth_token=mbxbk9y7ylsx9kh4lay7y1fvmqursrcb&oauth_signature_method=HMAC-SHA1&oauth_timestamp=1457990505&oauth_nonce=TVQCNw&oauth_version=1.0&oauth_signature=gjxBYsQPXL1KFtyvqQyaELZyK7c=');
   	//		 MF.generateSignature('POST','http://stage01.colemanfurniture.com/api/rest/customers/64908/addresses','dfhhfdh','123456799');
     //   MF.generateRandomString(10);
        test.stopTest();
        system.assertEquals(null, customerAccount.Magento_Account_Id__c);
    }
}