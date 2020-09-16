global class SalesOrderSharingBatch implements Database.Batchable<sObject> {
    String query;
    DateTime createdDateFrom; 

    global SalesOrderSharingBatch() {
        Time zTime = Time.newInstance(0, 0, 0, 0);
        this.createdDateFrom = DateTime.newInstanceGMT (2019, 12, 31);
    }
    
    global SalesOrderSharingBatch(Date createdDateFrom) {
        Time zTime = Time.newInstance(0, 0, 0, 0);
        this.createdDateFrom = DateTime.newInstanceGMT(createdDateFrom, zTime);
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator('SELECT Id, Delivery_Company__c, Related_Sales_Order__c FROM Shipment__c WHERE Delivery_Company__c != null AND Related_Sales_Order__r.CreatedDate > :createdDateFrom');
    }

    global void execute(Database.BatchableContext BC, List<Shipment__c> scope) {
        ShipmentTriggerHandler.shareSalesOrderProcess(null, scope);
    }

    global void finish(Database.BatchableContext BC) {

    }
}