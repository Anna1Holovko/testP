global class PurchaseOrderCreationBatch implements Database.Batchable<sObject>, Schedulable, Database.AllowsCallouts{

    global List<Sales_Order__c> start(Database.BatchableContext jobId) {
        List<Sales_Order__c> orderList = [  SELECT  Id,
                                                    Customer_shipping_Address__c,
                                                    Carrier__c,
                                                    Requested_Arrival_Date__c,
                                                    Eligible_for_PO_bulk_creation__c,
                                                    Manufacturer__c,
                                          			IsFedexable__c,
													Delivery_Company__c,
													Shipping_ZipCode__c,
													Nearest_Delivery_Company__c,
                                                    Default_Carrier__c,
                                                    Delivery_Company__r.Exclude_From_Bulk_Creation__c,
                                                    Suggested_Trucking_Company__c
                                            FROM Sales_Order__c
                                            WHERE Create_PO__c = true AND PO_created_in_bulk__c = false];
        return orderList;
    }

    global void execute(Database.BatchableContext jobId, List<Sales_Order__c> recordList) {
        Map<Id, Sales_Order__c> salesOrderMap = new Map<Id, Sales_Order__c>();
        List<Sales_Order__c> salesOrderToUpdateList = new List<Sales_Order__c>();
        Set<Id> deliveryAccountIdSet = new Set<Id>();
        for(Sales_Order__c order_i : recordList){
            if(order_i.Manufacturer__c != null){
                deliveryAccountIdSet.add(order_i.Manufacturer__c);
            }
            if(!order_i.Eligible_for_PO_bulk_creation__c){
                fillFailedOrder(salesOrderToUpdateList, order_i, 'NOT Eligible');
            }else if(order_i.Manufacturer__c == null){
                fillFailedOrder(salesOrderToUpdateList, order_i, 'Can\'t create PO for multiple manufacturers');
            }else if(order_i.Carrier__c == null && order_i.IsFedexable__c == true){
                fillFailedOrder(salesOrderToUpdateList, order_i, 'Carrier was empty when tried to create Purchase Order');
            }else if(order_i.IsFedexable__c == false && order_i.Delivery_Company__r != null && order_i.Delivery_Company__r.Exclude_From_Bulk_Creation__c == true){
                 fillFailedOrder(salesOrderToUpdateList, order_i, 'Suggested delivery compay was empty when tried to create Purchase Order of Bulk PO creation doesn\'t support this delivery company.');          
            }else if(order_i.Requested_Arrival_Date__c == null){
                fillFailedOrder(salesOrderToUpdateList, order_i, 'Requested arrival date was empty when tried to create Purchase Order');
            }else{
                salesOrderMap.put(order_i.Id, order_i);
            }
        }
        PurchaseOrderCreationHelper.accountIdSet = deliveryAccountIdSet;
        Map<Id, List<PurchaseOrderCreationHelper.SoLineWrapper>> salesOrderItemMap = PurchaseOrderCreationHelper.obtainSOItems(salesOrderMap.keySet());

        Map<Purchase_Order__c, List<PO_Line_Items__c>> poToItemsMap = PurchaseOrderCreationHelper.createPoAndItems(salesOrderItemMap,salesOrderMap);
        
        PurchaseOrderCreationHelper.insertPoAndItems(poToItemsMap);
        if(salesOrderToUpdateList.size() > 0){
            DataBase.update(salesOrderToUpdateList, false);
        }
    }

    void fillFailedOrder(List<Sales_Order__c> salesOrderToUpdateList, Sales_Order__c order_i , String failedReason){
        order_i.Create_PO__c = false;
        order_i.Failed_to_update_in_bulk__c = true;
        order_i.Failed_to_update_in_bulk_reason__c = failedReason;
        salesOrderToUpdateList.add(order_i);
    }

    global void finish(Database.BatchableContext jobIdParam) {
        List<CronTrigger> prevFinishedJobList = [SELECT Id FROM CronTrigger WHERE State ='DELETED' AND CronJobDetail.Name LIKE '%PurchaseOrderCreationBatch%'];
        if(prevFinishedJobList.size() > 0){
            System.abortJob(prevFinishedJobList[0].id);
        }
        
        Integer intervalInMinutes = 15;
        DateTime currentTimePlusInterval = Datetime.now().addMinutes(intervalInMinutes);

        String day = string.valueOf(currentTimePlusInterval.day());
        String month = string.valueOf(currentTimePlusInterval.month());
        String hour = string.valueOf(currentTimePlusInterval.hour());
        String minute = string.valueOf(currentTimePlusInterval.minute());
        String second = string.valueOf(currentTimePlusInterval.second());
        String year = string.valueOf(currentTimePlusInterval.year());
        String strSchedule = '0 ' + minute + ' ' + hour + ' ' + day + ' ' + month + ' ?' + ' ' + year;
        if(!Test.isRunningTest()) System.schedule('PurchaseOrderCreationBatch - ' + currentTimePlusInterval, strSchedule, new PurchaseOrderCreationBatch());
        
    }

    global void execute(SchedulableContext sc) {
        
        database.executeBatch(new PurchaseOrderCreationBatch(), 5 );
    }
}