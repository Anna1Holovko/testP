@isTest
private  class CovidMailingBatchTest {
    
    @testSetup static void setUp() {
        MagentoAuth__c magentoAuth = new MagentoAuth__c(Name='MagentoOAuth', AccessTokenURL__c='http://stage01.colemanfurniture.com/oauth/token',
                                        AuthorizationURL__c='http://stage01.colemanfurniture.com/admin/oauth_authorize',
                                        CallbackURL__c='https://c.cs41.visual.force.com/apex/CompleteAuth', password__c='rfgstage0987',
                                        ClientKey__c='ulzh3hgcx5pcmfkvbcd7x369bxfqjzmp',ClientSecret__c='p1khnuudmoowwiq1avhx8cjj9g573j70',
                                        RequestTokenURL__c='http://stage01.colemanfurniture.com/oauth/initiate/',
                                        RestEndpoint__c='http://stage01.colemanfurniture.com/api/rest',username__c='stage');
        insert magentoAuth;
        
        MagentoTokens__c magentoToken = new MagentoTokens__c(Name='OAuth', isAccess__c=false,owner__c='00555000000IFiGAAW',
                                           secret__c='vrz4dsnqxlf7uj3cq9qs89meferbyf5g', token__c='mbxbk9y7ylsx9kh4lay7y1fvmqursrcb');
        
        insert magentoToken;
        
        Google_API__c googleAPI = new Google_API__c(Name='Google API',Key__c='AIzaSyCAmP-yM5hc67O4stT-VyzMRmDTaVYfXzQ');
        insert googleAPI;

        Account customerAccount = TestUtil.createCustomerAccount(); 
        customerAccount.Web_Site__c = '1';
        update customerAccount;

        Account deliveryAccount = TestUtil.createDeliveryAccount();
        Sales_Order__c salesOrder = TestUtil.createsalesOrder(customerAccount.id, deliveryAccount.id, Null);
        Purchase_Order__c po = TestUtil.createpurchaseorder(salesOrder.id,'Manufacturer PO');
    }
    @IsTest
    static void testCovidEmail(){
        Purchase_Order__c po = [SELECT Id FROM Purchase_Order__c LIMIT 1];
        po.Load_Date__c = Date.today().addDays(1);
        update po;
        Test.startTest();
        database.executeBatch(new CovidMailingBatch(), 50 );
        Test.stopTest();
        String jobId = System.schedule('CovidMailingBatchTestJob',
                                        '0 0 0 15 3 ?', 
                                       new CovidMailingBatch());   
        
    }

    @IsTest
    static void testCovidEmailLongEta(){
        Purchase_Order__c po = [SELECT Id FROM Purchase_Order__c LIMIT 1];
        po.Load_Date__c = Date.today().addDays(22);
        update po;
        Test.startTest();
        database.executeBatch(new CovidMailingBatch(false), 50 );
        Test.stopTest();
        
    }
}