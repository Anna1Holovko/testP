global with sharing class ShipmentDatesAndStatusFromCarrier implements Database.Batchable<SObject>,  Database.AllowsCallouts, Schedulable, Database.Stateful {
    final Set<String> trachingServiceNameSet = new Set<String>{'UPS', 'FedEx'}; 
    final Set<String> ShipmentStatusSet = new Set<String>{'En Route Shipments', 'Delivery Scheduled', 'Out for Delivery', 'Routing'};
    final Date lastCreatedDate = Date.newInstance(2020, 1, 4); //2020, 15, 6
    Map<String, IShipmentTrackingService.ResponseWrapperTrackingService> shipmentIdToTrackingServiceResponse = new Map <String, IShipmentTrackingService.ResponseWrapperTrackingService> ();
    Boolean allowUpdateFlag = true;
    global List<Shipment__c> start(Database.BatchableContext jobId) {
        return [SELECT Id, CreatedDate, Tracking_Number__c, Drop_Off_Date_Expected__c
                FROM Shipment__c 
                WHERE Carrier_name__c IN :trachingServiceNameSet AND CreatedDate > :lastCreatedDate
                AND Tracking_Number__c != null 
                AND (Drop_Off_Date_Actual__c = null AND Drop_Off_Date_Expected__c <= TODAY AND Shipment_Status__c IN :ShipmentStatusSet) 
                ];
    }   

    global void execute(Database.BatchableContext jobId, List<Shipment__c> recordList ){
        if(!allowUpdateFlag){
            return;
        }
        allowUpdateFlag = false;
        List<String> shipmentIdToUpdateShipmentLineItemsList = new List<String>();
        for(Shipment__c currentShipment_i : recordList){
            IShipmentTrackingService.ResponseWrapperTrackingService response = ShipmentTackingManager.track(currentShipment_i.Tracking_Number__c, 'TrackingService' + currentShipment_i.Carrier_Name__c);
            shipmentIdToTrackingServiceResponse.put(currentShipment_i.Id, response); 
            if(response.deliveryStatus == 'Delivered'){
                currentShipment_i.Drop_Off_Date_Actual__c = response.actualDeliveryDate;
                shipmentIdToUpdateShipmentLineItemsList.add(currentShipment_i.Id);
            } else if (response.scheduleDate != null && response.scheduleDate != currentShipment_i.Drop_Off_Date_Expected__c ) {
                currentShipment_i.Drop_Off_Date_Expected__c = response.scheduleDate;
            } else if(response.scheduleDate == null) {
                currentShipment_i.Review_Shipment__c = true;
            }
        }

        List<Shipment_Line_Item__c> shipmnetLineItemToUpdateList = [SELECT Id 
                                                                    FROM Shipment_Line_Item__c 
                                                                    WHERE Shipment__c IN :shipmentIdToUpdateShipmentLineItemsList];
        for(Shipment_Line_Item__c curentShipmentLineItem_i : shipmnetLineItemToUpdateList){
            curentShipmentLineItem_i.Shipment_Item_Status__c = 'Delivered No Issues';
        }
        System.debug('recordList: ' + recordList);
        System.debug('shipmnetLineItemToUpdateList: ' + shipmnetLineItemToUpdateList);
        update recordList;
        if(!shipmnetLineItemToUpdateList.isEmpty()){
            update shipmnetLineItemToUpdateList;
        }
    }

    global void finish(Database.BatchableContext jobId){

    }

    global void execute(SchedulableContext sc){
        database.executeBatch(new ShipmentDatesAndStatusFromCarrier(), 200 );
    }
}