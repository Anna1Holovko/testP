global with sharing class SendingPurchaseOrderToManufacturerBatch  implements Database.Batchable<sObject>, Schedulable, Database.Stateful, Database.AllowsCallouts{
    String batchType;
    final Date lastCreatedDate = Date.newInstance(2020, 6, 29);
    final DateTime ediCreatedDate = DateTime.now().addMinutes(-2);
    final String query = 'SELECT Id, Order_Communication_Type__c, Resend__c FROM Purchase_Order__c'
                        + ' WHERE Status__c = \'Draft\' AND Do_not_notify_manufacturer__c = FALSE AND CreatedDate > :lastCreatedDate ';

    global SendingPurchaseOrderToManufacturerBatch(){
        this('EDI');
    }

    global SendingPurchaseOrderToManufacturerBatch(String batchType){
        this.batchType = batchType.toLowerCase();
    }
    
    global List<Purchase_Order__c> start(Database.BatchableContext jobId) {
        List<Purchase_Order__c> purchaseOrderList; 
        if(batchType == 'edi') {
            purchaseOrderList = obtainsEDIPurchaseOrder();
        }else if(batchType == 'email') {
            purchaseOrderList = obtainsEmailPurchaseOrder();
        }
        return purchaseOrderList;
    }

    global List<Purchase_Order__c> obtainsEDIPurchaseOrder(){
        return Database.query(query+' AND Order_Communication_Type__c = \'EDI\' AND EDI_Status__c = null AND CreatedDate < :ediCreatedDate');
    }

    global List<Purchase_Order__c> obtainsEmailPurchaseOrder(){
        return Database.query(query+' AND Order_Communication_Type__c = \'Email\' AND Email_sent_to_manufacturer__c = false');
    }

    global void execute(Database.BatchableContext jobId, List<Purchase_Order__c> recordList) {
        System.debug('recordList: '+recordList);
        if(batchType == 'edi') {
            PurchaseOrderOutboundFrom.sendFormNotfuture(recordList.get(0).Id);
        }else if(batchType == 'email') {
            for(Purchase_Order__c purchaseOrder_i : recordList){
                purchaseOrder_i.Send_Email_To_Manufacturer_WF__c = true;
            }
            update recordList;
        }
    }
        
    global void finish(Database.BatchableContext jobIdParam) {
        
        if(batchType == 'edi'){
            database.executeBatch(new SendingPurchaseOrderToManufacturerBatch('email'), 10);
        }else{
            
            List<CronTrigger> prevFinishedJobList = [SELECT Id FROM CronTrigger WHERE State ='DELETED' AND CronJobDetail.Name LIKE '%SendingPurchaseOrderToManufacturerBatch%'];
            if(prevFinishedJobList.size() > 0){
                System.abortJob(prevFinishedJobList[0].id);
            }
            
            Integer intervalInMinutes = 15;
            DateTime currentTimePlusInterval = Datetime.now().addMinutes(intervalInMinutes);
            
            String day = String.valueOf(currentTimePlusInterval.day());
            String month = String.valueOf(currentTimePlusInterval.month());
            String hour = String.valueOf(currentTimePlusInterval.hour());
            String minute = String.valueOf(currentTimePlusInterval.minute());
            String second = String.valueOf(currentTimePlusInterval.second());
            String year = String.valueOf(currentTimePlusInterval.year());
            String strSchedule = '0 ' + minute + ' ' + hour + ' ' + day + ' ' + month + ' ?' + ' ' + year;
            if(!Test.isRunningTest()) System.schedule('SendingPurchaseOrderToManufacturerBatch - ' + currentTimePlusInterval, strSchedule, new SendingPurchaseOrderToManufacturerBatch('edi'));
        }
        
    }

    global void execute(SchedulableContext sc) {
        database.executeBatch(new SendingPurchaseOrderToManufacturerBatch('EDI'), 1 );
    }
}