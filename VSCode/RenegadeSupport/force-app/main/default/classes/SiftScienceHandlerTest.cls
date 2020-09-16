@isTest
private class SiftScienceHandlerTest {
    @istest
    static void getScoreTest(){
        Sift_Science_setting__c setting = new Sift_Science_setting__c();
        setting.URL__c = 'https://api.siftscience.com/v204/score';
        setting.API_KEY__c = '4f9895adccb39be7';
        insert setting;
        Test.setMock(HttpCalloutMock.class, new APIMock());
        Test.startTest();
        SiftScienceHandler.Response response = SiftScienceHandler.getScore('test@mail.com');
        System.assertEquals(0.5, response.scores.get('payment_abuse').score);
        Test.stopTest();
    }
    
    @istest
    static void getScoreBadTest(){
        Test.setMock(HttpCalloutMock.class, new APIMock());
        Test.startTest();
        SiftScienceHandler.Response response = SiftScienceHandler.getScore(null);
        System.assertEquals(1, response.status);
        Test.stopTest();
    }
    
    public class APIMock implements HttpCalloutMock {
        public Map<String,String> responseBodyMap;
    
        public APIMock(){
            responseBodyMap = new Map<String,String>();
            SiftScienceHandler.Response resObject = new SiftScienceHandler.Response();
            resObject.status = 0;
            resObject.error_message = '';
            resObject.description = '';
            resObject.is_bad = false;
            resObject.time_x = DateTime.now().getTime();
            resObject.user_id = 'test@mail.com';
            resObject.scores = new Map<String, SiftScienceHandler.Scores>();
            SiftScienceHandler.Scores score = new SiftScienceHandler.Scores();
            score.score = 0.5;
            score.reasons = new List<SiftScienceHandler.Reason>();
            SiftScienceHandler.Reason reason = new SiftScienceHandler.Reason();
            reason.name = 'test';
            reason.value = '10';
            score.reasons.add(reason);
            resObject.scores.put('payment_abuse', score);
            responseBodyMap.put('https://api.siftscience.com/v204/score/'+resObject.user_id +'/',JSON.serialize(resObject).replace('"time_x":', '"time":'));
        }
    
        public HTTPResponse respond(HTTPRequest req) {
            String endpoint = req.getEndpoint();
            if(endpoint.contains('?')){
                endpoint = endpoint.split('\\?')[0];
            }
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(responseBodyMap.get(endpoint));
            res.setStatusCode(200);
            System.debug(res);
            return res;
        }
    }
    
 /*   @isTest
    static void siftScienceHandlerTest(){
        Sift_Science_setting__c setting = new Sift_Science_setting__c();
        setting.URL__c = 'https://api.siftscience.com/v204/events?return_score=true';
        setting.API_KEY__c = '4f9895adccb39be7';
        insert setting;
        Account ac = TestUtil.createCustomerAccount(); 
        Payment_Method__c paymentMethod = TestUtil.createpaymentMethod(ac.Id,'Credit Card');
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, Null, paymentMethod.Id);
        Test.setMock(HttpCalloutMock.class, new APIMock());
        Test.startTest();
        SiftScienceHandler.Response resp = SiftScienceHandler.getScore(so);
        System.assertEquals(resp.status,200);
        Test.stopTest();
        
    }
    
    public class APIMock implements HttpCalloutMock {
        public Map<String,String> responseBodyMap;
    
        public APIMock(){
            responseBodyMap = new Map<String,String>();
            SiftScienceHandler.Reason reason = new SiftScienceHandler.Reason();
            reason.name = 'test';
            reason.value = 'test1';
            SiftScienceHandler.Payment_abuse abuse = new SiftScienceHandler.Payment_abuse();
            abuse.score = 22;
            abuse.reasons = new List<SiftScienceHandler.Reason>{reason};
            SiftScienceHandler.Scores scores = new SiftScienceHandler.Scores();
            scores.payment_abuse = abuse;
            SiftScienceHandler.Score_response score = new SiftScienceHandler.Score_response();
            score.status = 200;
            score.error_message = 'Test';
            score.user_id = 'fdsfds';
            score.workflow_statuses = new List<String>{'OK'};
            SiftScienceHandler.Response resp = new SiftScienceHandler.Response();
            resp.status = 200;
            resp.error_message = 'Test';
            resp.timetime = 213321321;
            resp.request = 'test';
            resp.score_response = score;
            System.debug(JSON.serialize(resp));
            String responseBody = JSON.serialize(resp);
            responseBodyMap.put('https://api.siftscience.com/v204/events',responseBody);
        }
    
        public HTTPResponse respond(HTTPRequest req) {
            String endpoint = req.getEndpoint();
            if(endpoint.contains('?')){
                endpoint = endpoint.split('\\?')[0];
            }
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(responseBodyMap.get(endpoint));
            res.setStatusCode(200);
            System.debug(res);
            return res;
        }
    }*/
}