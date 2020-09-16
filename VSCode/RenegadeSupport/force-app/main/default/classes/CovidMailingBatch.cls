global class CovidMailingBatch implements Database.Batchable<sObject>, Schedulable, Database.Stateful {
    String query;
    String fieldToUpdate;
    Boolean isRunLong;

    global CovidMailingBatch() {     
        this.isRunLong = true;
        this.fillShortNotification();
    }

    global CovidMailingBatch(Boolean isShort) { 
        if(isShort){
            this.fillShortNotification();
        }else{
            this.fillLongNotification();
        }
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        for(Purchase_Order__c purchaseOrder_i : (List<Purchase_Order__c>) scope){
            purchaseOrder_i.put(fieldToUpdate, true);
        }
        update scope;
    }

    global void finish(Database.BatchableContext BC) {
        if( this.isRunLong != null && this.isRunLong == true){
            database.executeBatch(new CovidMailingBatch(false), 50 );
        }
    }

    global void execute(SchedulableContext sc) {
        
        database.executeBatch(new CovidMailingBatch(), 50 );
    }

    void fillLongNotification(){
        this.query = 'SELECT Id FROM Purchase_Order__c ' + 
                'WHERE Status__c IN (\'On Order\', \'Draft\') ' + 
                ' AND Sales_Order__r.CreatedDate < LAST_N_DAYS:14 ' + 
                ' AND Sales_Order__r.CreatedDate > 2019-12-01T00:00:00Z ' + 
                ' AND Load_Date__c >= NEXT_N_DAYS:21 ' + 
                ' AND Covid_19_notification_long_ETA__c = false AND Covid_19_notification_short_ETA__c = false';
        this.fieldToUpdate = 'Covid_19_notification_long_ETA__c';  
    }

    void fillShortNotification(){
        this.query = 'SELECT Id FROM Purchase_Order__c ' + 
                'WHERE Status__c IN (\'On Order\', \'Draft\') ' + 
                ' AND Sales_Order__r.CreatedDate > 2019-12-01T00:00:00Z ' + 
                ' AND Sales_Order__r.CreatedDate < LAST_N_DAYS:14 ' + 
                ' AND Load_Date__c > TODAY ' + 
                ' AND Load_Date__c <= NEXT_N_DAYS:21 ' + 
                ' AND Covid_19_notification_long_ETA__c = false AND Covid_19_notification_short_ETA__c = false';
        this.fieldToUpdate = 'Covid_19_notification_short_ETA__c';  
    }
}