@isTest
public with sharing class TrackingServiceFedExTest {
    static String TRACKING_SERVICE_NAME = 'FedEx';
    
    @testsetup
    static void setup(){
        
        Tracking_Service_FedEx__c settings = Tracking_Service_FedEx__c.getOrgDefaults();
        settings.Endpoint__c = 'https://wsbeta.fedex.com:443/web-services';
        settings.AccountNumber__c = 'testNumber';
        settings.Key__c = 'testKey';
        settings.MeterNumber__c = 'TestMeterNumber';
        settings.Password__c = 'password';
        
        upsert settings;
    }
    
    @isTest
    static void TrackingServiceFedExTest() {
        Map<String, String> repsonseHeaders = new Map<String, String> {
            'Content-Type' => 'text-xml'
        };
        
        Map<String, TrackingServiceMock.responseDataWrapper> TrackingNumberToResponseDataMap = new Map<String, TrackingServiceMock.responseDataWrapper>{
            'SuccessTrackingFedEx' => new TrackingServiceMock.ResponseDataWrapper(repsonseHeaders, obtainSuccessResponseBody() , 200 , TRACKING_SERVICE_NAME)       
        };
        
    	Test.setMock(HttpCalloutMock.class, new TrackingServiceMock(TrackingNumberToResponseDataMap, TRACKING_SERVICE_NAME ));
        
        Test.startTest();
        	System.assertEquals('20200605', ShipmentTackingManager.track('SuccessTrackingFedEx', 'TrackingServiceFedEx').stringDate);
    	Test.stopTest();
    }
    
    static String obtainSuccessResponseBody(){
        StaticResource staticResourse = [SELECT Id, Body FROM StaticResource WHERE Name = 'TrackingServiceXMLFedExSuccessResponse' LIMIT 1];
        return staticResourse.Body.toString();
    }
}