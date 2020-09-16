@isTest
private class AffirmIntagrationManagerTest {
	
	@isTest static void captureWithChargeIdTest() {
        
        AffirmTokens__c rule = new AffirmTokens__c();
        rule.Endpoint__c = 'test';
        rule.Public_key__c = '123';
        rule.Private_key__c = '456';
        rule.Furniture_ETC_Public_key__c = '123';
        rule.Furniture_ETC_Private_key__c = '456';
        rule.Home_gallery_stores_Public_key__c = '123';
        rule.Home_gallery_stores_Private_key__c = '456';
        insert rule;
        
        AffirmIntagrationManager.Request req = new AffirmIntagrationManager.Request('159','testCarrier','true');
        
        Test.setMock(HttpCalloutMock.class, new HTTPResponseAffirmIntagrationManager());
        Test.startTest();
        AffirmIntagrationManager.captureWithChargeId('258', req, '1');
        AffirmIntagrationManager.captureWithChargeId('258', req, '2');
        AffirmIntagrationManager.captureWithChargeId('258', req, '3');
        Test.stopTest();
    }
    
    
    public class HTTPResponseAffirmIntagrationManager implements HttpCalloutMock {
        // Implement this interface method
        public HTTPResponse respond(HTTPRequest req) {
            // Create a fake response 
            HttpResponse res = new HttpResponse(); 
            Map<String, Object> objMap = new Map<String, Object>();
            objMap.put('id','1111111');
            objMap.put('transaction_id','222');
            objMap.put('message','test');
            res.setBody(JSON.serialize(objMap)); 
            res.setStatusCode(200); 
            
            return res;
        }
		
	}
	
	@isTest static void voidWithChargeIdTest() {

		AffirmTokens__c rule = new AffirmTokens__c();
        rule.Endpoint__c = 'test';
        rule.Public_key__c = '123';
        rule.Private_key__c = '456';
        rule.Furniture_ETC_Public_key__c = '123';
        rule.Furniture_ETC_Private_key__c = '456';
        rule.Home_gallery_stores_Public_key__c = '123';
        rule.Home_gallery_stores_Private_key__c = '456';
        insert rule;
        
        Test.setMock(HttpCalloutMock.class, new HTTPResponseAffirmIntagrationManager());
        Test.startTest();
        AffirmIntagrationManager.voidWithChargeId('258', '1');
        AffirmIntagrationManager.voidWithChargeId('258', '2');
        AffirmIntagrationManager.voidWithChargeId('258', '3');
        Test.stopTest();
	}
	
}