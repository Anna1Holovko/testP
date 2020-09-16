global with sharing class ShipmentDatesAndStatusFromCarrierBatch implements Database.Batchable<SObject>,  Database.AllowsCallouts, Schedulable, Database.Stateful {
    final Set<String> trackingServiceNameSet = new Set<String>{'UPS', 'FedEx'}; 
    final Set<String> ShipmentStatusSet = new Set<String>{'En Route Shipments', 'Delivery Scheduled', 'Out for Delivery', 'Routing'};
    Date lastCreatedDate = Date.newInstance(2020, 6, 26); //2020, 6, 15
    Map<String, IShipmentTrackingService.ResponseWrapperTrackingService> shipmentIdToTrackingServiceResponse = new Map <String, IShipmentTrackingService.ResponseWrapperTrackingService> ();

    public ShipmentDatesAndStatusFromCarrierBatch() {
        Tracking_Service_Batch_setting__c batchSettings = Tracking_Service_Batch_setting__c.getOrgDefaults();
        if(batchSettings.Created_Date_Limit__c != null) {
            lastCreatedDate = batchSettings.Created_Date_Limit__c;
        }
    } 
    
    global List<Shipment__c> start(Database.BatchableContext jobId) {
        return [SELECT Id, CreatedDate, Tracking_Number__c, Drop_Off_Date_Expected__c, Carrier_name__c, Shipment_Status__c, Drop_Off_Date_Actual__c
                                        FROM Shipment__c 
                                        WHERE Carrier_name__c IN :trackingServiceNameSet AND CreatedDate > :lastCreatedDate
                                        AND Tracking_Number__c != null AND (NOT Tracking_Number__c like '%,%') AND (NOT Tracking_Number__c like '%;%')
                                        //AND (Drop_Off_Date_Actual__c = null AND Drop_Off_Date_Expected__c <= TODAY AND Shipment_Status__c IN :ShipmentStatusSet) 
                                        ];
    }   

    global void execute(Database.BatchableContext jobId, List<Shipment__c> recordList ){
        recordList = [SELECT Id, CreatedDate, Tracking_Number__c, Drop_Off_Date_Expected__c, Carrier_name__c, Shipment_Status__c, Drop_Off_Date_Actual__c
                    FROM Shipment__c 
                    WHERE Id IN :recordList];
        Map<String, Date> shipmentIdToUpdateShipmentLineItemsMap = new Map<String, Date>();
        Date currentDate = Date.today();

        for(Shipment__c currentShipment_i : recordList){
            IShipmentTrackingService.ResponseWrapperTrackingService response = ShipmentTackingManager.track(currentShipment_i.Tracking_Number__c, 'TrackingService' + currentShipment_i.Carrier_Name__c);
            if(currentShipment_i.Drop_Off_Date_Actual__c == null &&
               (currentShipment_i.Drop_Off_Date_Expected__c != null && currentShipment_i.Drop_Off_Date_Expected__c < currentDate) && 
               ShipmentStatusSet.contains(currentShipment_i.Shipment_Status__c)){

                if(response.deliveryStatus == 'Delivered' ){
                    if(response.actualDeliveryDate == null){
                        currentShipment_i.Tracking_service_request_message__c = response.errorMessage;
                        continue;
                    }
                    currentShipment_i.Drop_Off_Date_Actual__c = response.actualDeliveryDate;
                    shipmentIdToUpdateShipmentLineItemsMap.put(currentShipment_i.Id, response.actualDeliveryDate);
                    currentShipment_i.Review_Shipment__c = false;
                } else if(response.scheduleDate == null) {
                    currentShipment_i.Review_Shipment__c = true;
                }
            }
            currentShipment_i.Drop_Off_Date_Expected__c = response.scheduleDate != null ? response.scheduleDate : currentShipment_i.Drop_Off_Date_Expected__c;
            if(currentShipment_i.Drop_Off_Date_Expected__c  != null && currentShipment_i.Drop_Off_Date_Expected__c  >= currentDate) currentShipment_i.Review_Shipment__c = false;
            currentShipment_i.Dropoff_Date_Synced_With_Carrier_At__c = DateTime.now();

        }

        List<Shipment_Line_Item__c> shipmnetLineItemToUpdateList = [SELECT Id, Shipment__c
                                                                    FROM Shipment_Line_Item__c 
                                                                    WHERE Shipment__c IN :shipmentIdToUpdateShipmentLineItemsMap.keySet()];
        for(Shipment_Line_Item__c curentShipmentLineItem_i : shipmnetLineItemToUpdateList){
            curentShipmentLineItem_i.Shipment_Item_Status__c = 'Delivered No Issues';
            curentShipmentLineItem_i.Delivery_Date_Actual__c = shipmentIdToUpdateShipmentLineItemsMap.get(curentShipmentLineItem_i.Shipment__c);
        }
        update recordList;
        if(!shipmnetLineItemToUpdateList.isEmpty()) {
            update shipmnetLineItemToUpdateList;
        }
    }

    global void finish(Database.BatchableContext jobId){

    }

    global void execute(SchedulableContext sc){
        database.executeBatch(new ShipmentDatesAndStatusFromCarrierBatch(), 50 );
    }
}