@isTest
public with sharing class ShipmentDatesAndStatusFromCarrierBtcTest {
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
        Account ac = TestUtil.createCustomerAccount(); 
        Products__c Pro = TestUtil.createConfigProduct();
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, Null, Null);
        Purchase_Order__c po = TestUtil.createpurchaseorder(so.id,'Manufacturer PO');    
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,5);
        PO_Line_Items__c POl = TestUtil.createpoitem(po.id, Sol.id);
        Shipment__c ship = TestUtil.createshipment(po.id, So.id,'Ship Via Delivery Company');
        ship.Tracking_Number__c = 'SuccessTrackingUPS';
        ship.Carrier__c = 'LTL';
        ship.Carrier_Name__c = 'UPS';
        ship.Shipment_Status__c = 'Delivery Scheduled';
        update ship;
        Shipment_Line_Item__c shipitem = TestUtil.createshipmentItem(ship.id, POl.id);
        
        Test.setMock(HttpCalloutMock.class, new TrackingServiceMock(getMockData(), TRACKING_SERVICE_NAME ));
        Test.startTest();
			Database.executeBatch(new ShipmentDatesAndStatusFromCarrierBatch(), 1);
        	System.schedule('ShipmentDatesAndStatusFromCarrierBatch',' 0 0 0 15 3 ? 2022', new ShipmentDatesAndStatusFromCarrierBatch());
        Test.stopTest();
    }
    
    static Map<String, TrackingServiceMock.responseDataWrapper> getMockData(){
        Map<String, String> repsonseHeaders = new Map<String, String> {
            'Content-Type' => 'application/json'
        };
        
        Map<String, TrackingServiceMock.responseDataWrapper> TrackingNumberToResponseDataMap = new Map<String, TrackingServiceMock.responseDataWrapper>{
            'SuccessTrackingUPS' => new TrackingServiceMock.ResponseDataWrapper(repsonseHeaders, obtainSuccessResponseBody() , 200 , TRACKING_SERVICE_NAME)
        };
        return TrackingNumberToResponseDataMap;
    }
    
    static String obtainSuccessResponseBody() {
        return '{"trackResponse": {"shipment": [{ "package": [{ "trackingNumber": "1Z44R7R60390945454", "deliveryDate": [ { "type": "DEL", "date": "20200210" }],"deliveryTime": {"startTime": "", "endTime": "103115","type": "DEL" }, ' 
            + ' "activity": [ {"location": { "address": { "city": "ARLINGTON", "stateProvince": "VA","postalCode": "", "country": "US"}},"status": {"type": "D","description": "Delivered", "code": "KB" },"date": "20200504","time": "103115" }]}]}]}}';
    }
}