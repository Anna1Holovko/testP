@isTest
private class GuardianManagerTest {
    @isTest
    static void sendRequestTest(){
        Guardian_Setting__c guardianSetting = new Guardian_Setting__c();
        guardianSetting.Token_Expiration__c = null;
        guardianSetting.Token_endpoint__c = 'https://gpp-service.com/was/Token';
        guardianSetting.End_point__c = 'https://gpp-service.com/ereg-test/transaction';
        guardianSetting.Key__c = '123';
        insert guardianSetting;
        Account ac = TestUtil.createCustomerAccount(); 
        Products__c Pro = TestUtil.createConfigProduct();
        Pro.SKU_List__c = '1';
        update Pro;
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, Null, Null);
        SO_Line_Items__c sol = TestUtil.createsalesOrderLineItem(so.Id,Pro.Id,null,null,5);
        so = [SELECT Id,Order_Date__c,Grand_Total__c,Protection_Plan_Cost__c,TaxAmount__c,Shipping_Handle__c,Name,Bill_To__c,Billing_Street__c,Billing_City__c,Billing_State__c,Billing_ZipCode__c,Billing_Phone__c,
              Ship_To__c, Magento_order_No__c, Plan_code__c, Shipping_Street__c,Shipping_City__c,Shipping_State__c,Shipping_ZipCode__c,Shipping_Phone__c, Email__c FROM Sales_Order__c WHERE Id = :so.Id];
        Test.setMock(HttpCalloutMock.class, new APIMock());
        Test.startTest();
        string body = GuardianManager.generateBody(so);
        GuardianManager.Response resp = GuardianManager.sendRequest(so, body);
        System.assertEquals('Test2', resp.links[0].Title);
        Test.stopTest();
    }
    
    @isTest
    static void VoidPlanTest(){
        Guardian_Setting__c guardianSetting = new Guardian_Setting__c();
        guardianSetting.Token_Expiration__c = null;
        guardianSetting.Token_endpoint__c = 'https://gpp-service.com/was/Token';
        guardianSetting.End_point__c = 'https://gpp-service.com/ereg-test/transaction';
        guardianSetting.Void_endpoint__c = 'https://gpp-service.com/ereg-test/transaction';
        guardianSetting.Key__c = '123';
        insert guardianSetting;
        
        Test.setMock(HttpCalloutMock.class, new APIMock());
        
        Test.startTest();
        GuardianManager.Response resp = GuardianManager.VoidPlan('/test');
        System.assertEquals('Test2', resp.links[0].Title);
        Test.stopTest();
        
    }
    
    public class APIMock implements HttpCalloutMock {
        public Map<String,String> responseBodyMap;
        
        public APIMock(){
            responseBodyMap = new Map<String,String>();
            String responseBody = '{"access_token":"testtoken","expires_in":"32321"}';
            responseBodyMap.put('https://gpp-service.com/was/Token',responseBody);
            
            responseBody = '{"results":[{"Info":"Test"}],"links":[{"Title":"Test2","Href":"Test"}]}';
            responseBodyMap.put('https://gpp-service.com/ereg-test/transaction123',responseBody);
            
            responseBody = '{"results":[{"Info":"Test"}],"links":[{"Title":"Test2","Href":"Test"}]}';
            responseBodyMap.put('https://gpp-service.com/ereg-test/transaction/test',responseBody);
        }
        
        public HTTPResponse respond(HTTPRequest req) {
            String endpoint = req.getEndpoint();
            if(endpoint.contains('?')){
                endpoint = endpoint.split('\\?')[0];
            }
            System.debug('endpoint---->'+endpoint);
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(responseBodyMap.get(endpoint));
            res.setStatusCode(200);
            System.debug(res);
            return res;
        }
    }
}