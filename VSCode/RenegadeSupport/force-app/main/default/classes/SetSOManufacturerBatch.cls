global class SetSOManufacturerBatch implements Database.Batchable<sObject> {
    global List<Sales_Order__c> start(Database.BatchableContext jobId) {
        List<Sales_Order__c> orderList = [  SELECT  Id
                                            FROM Sales_Order__c WHERE IsManufacturerSet__c = false];
        return orderList;
    }

    global void execute(Database.BatchableContext jobId, List<Sales_Order__c> recordList) {
        Set<Id> orderIdSet = new Set<Id>();
        for(Sales_Order__c order_i : recordList){
            orderIdSet.add(order_i.Id);
        }
        SO_Line_ItemTriggerHandler.setSOManufacturer(orderIdSet);
    }

    global void finish(Database.BatchableContext jobIdParam) {

    }
}