@isTest
public with sharing class TrackingServiceUPSTest {
    static String TRACKING_SERVICE_NAME = 'UPS';
    
    @testsetup
    static void setup(){
        Tracking_Service_UPS__c settings = Tracking_Service_UPS__c.getOrgDefaults();
        settings.Endpoint__c = 'https://onlinetools.ups.com/track/v1/details/';
        settings.AccessLicenseNumber__c = 'tes2312';
        upsert settings;
    }
    
    @isTest
    static void TrackingServiceUPSTest() {
        Map<String, String> repsonseHeaders = new Map<String, String> {
            'Content-Type' => 'application/json'
        };
        
        Map<String, TrackingServiceMock.responseDataWrapper> TrackingNumberToResponseDataMap = new Map<String, TrackingServiceMock.responseDataWrapper>{
            'SuccessTrackingUPS' => new TrackingServiceMock.ResponseDataWrapper(repsonseHeaders, obtainSuccessResponseBody() , 200 , TRACKING_SERVICE_NAME),
            'ErrorTrackingUPS' => new TrackingServiceMock.ResponseDataWrapper(repsonseHeaders, obtainErrorResponseBody() , 200 , TRACKING_SERVICE_NAME),
            'WarningTrackingUPS' => new TrackingServiceMock.ResponseDataWrapper(repsonseHeaders, obtainWarningResponseBody() , 200 , TRACKING_SERVICE_NAME)
                        
        };
        
    	Test.setMock(HttpCalloutMock.class, new TrackingServiceMock(TrackingNumberToResponseDataMap, TRACKING_SERVICE_NAME ));
        
        Test.startTest();
        	IShipmentTrackingService.ResponseWrapperTrackingService successResponse = ShipmentTackingManager.track('SuccessTrackingUPS', 'TrackingServiceUPS');
        	System.assertEquals('20200210', successResponse.stringDate);
            System.assertEquals('Delivered', successResponse.deliveryStatus);
            
        	System.assertEquals('Invalid inquiry number', ShipmentTackingManager.track('ErrorTrackingUPS', 'TrackingServiceUPS').errorMessage);
            System.assertEquals('Tracking Information Not Found', ShipmentTackingManager.track('WarningTrackingUPS', 'TrackingServiceUPS').errorMessage);
    	Test.stopTest();
    }
    
    static String obtainSuccessResponseBody() {
        return '{"trackResponse": {"shipment": [{ "package": [{ "trackingNumber": "1Z44R7R60390945454", "deliveryDate": [ { "type": "DEL", "date": "20200210" }],"deliveryTime": {"startTime": "", "endTime": "103115","type": "DEL" }, ' 
            + ' "activity": [ {"location": { "address": { "city": "ARLINGTON", "stateProvince": "VA","postalCode": "", "country": "US"}},"status": {"type": "D","description": "Delivered", "code": "KB" },"date": "20200504","time": "103115" }]}]}]}}';
    }
    
    static String obtainWarningResponseBody() {
        return '{ "trackResponse": {  "shipment": [ { "warnings": [  {  "code": "TW0001",  "message": "Tracking Information Not Found"  }  ]  } ] } }';
    }
    
    static String obtainErrorResponseBody() {
        return '{ "response": { "errors": [ { "code": "TV1002",  "message": "Invalid inquiry number" }  ] } }';
    }
    
}