@isTest
private class FinanceIntegrationManagerTest {

  
  @isTest static void captureWithChargeIdTest() {
        
        Finance_Setting__c rule = new Finance_Setting__c();
        rule.URL__c = 'test';
        rule.Private_key__c = '456';
        insert rule;
        
        
        Test.setMock(HttpCalloutMock.class, new HTTPResponseFinanceIntegrationManager());
        Test.startTest();
        FinanceIntegrationManager.capture('258');
        Test.stopTest();
    }
    
    
    public class HTTPResponseFinanceIntegrationManager implements HttpCalloutMock {
        // Implement this interface method
        public HTTPResponse respond(HTTPRequest req) {
            // Create a fake response 
            HttpResponse res = new HttpResponse(); 
            Map<String, Object> objMap = new Map<String, Object>();
            objMap.put('id','1111111');
            objMap.put('chargeId','222');
            objMap.put('message','test');
            res.setBody(JSON.serialize(objMap)); 
            res.setStatusCode(200); 
            
            return res;
        }
    
  }
  
  @isTest static void voidWithChargeIdTest() {

        Finance_Setting__c rule = new Finance_Setting__c();
        rule.URL__c = 'test';
        rule.Private_key__c = '456';
        insert rule;
        
        Test.setMock(HttpCalloutMock.class, new HTTPResponseFinanceIntegrationManager());
        Test.startTest();
        FinanceIntegrationManager.voidWithChargeId('258');
        Test.stopTest();
  }
  
}