trigger TransactionObjectTrigger on Transaction__c (after insert) {
    map<id,Transaction__c> transactionMap;
    list<Sales_Order__c> salesOrderList;
    if(trigger.isAfter && trigger.isInsert) {
        transactionMap = new map<id,Transaction__c>();
        for(Transaction__c trans : trigger.new) {
            System.debug('Transaction Sales_Order id :: '+trans.Sales_Order__c+', Status :: '+trans.Status__c+', Transaction Type :: '+trans.Transaction_Type__c);
            if(trans.Sales_Order__c != null && (trans.Status__c == 'Authorized' && (trans.Transaction_Type__c == 'AUTH_ONLY' || trans.Transaction_Type__c == 'authorization'))) {
                transactionMap.put(trans.Sales_Order__c,trans);
            }
            if(trans.Sales_Order__c != null && (trans.Status__c == 'Captured' && trans.Transaction_Type__c == 'CAPTURE_ONLY')) {
                transactionMap.put(trans.Sales_Order__c,trans);
            }
            if(trans.Sales_Order__c != null && (trans.Status__c == 'Failed' && trans.Transaction_Type__c == 'CAPTURE_ONLY')) {
                transactionMap.put(trans.Sales_Order__c,trans);
            }
        }
        System.debug('transactionMap :: '+transactionMap);
        if(transactionMap.size() > 0) {
            salesOrderList = [Select id,Payment_Status__c from Sales_Order__c where id in :transactionMap.keySet()]; 
            for(Sales_Order__c SO : salesOrderList) {
                if(transactionMap.containsKey(SO.id) && (transactionMap.get(SO.id).Status__c == 'Authorized' && (transactionMap.get(SO.id).Transaction_Type__c == 'AUTH_ONLY' || transactionMap.get(SO.id).Transaction_Type__c == 'authorization'))) {
                    SO.Payment_Status__c = 'Authorized';
                }
                if(transactionMap.containsKey(SO.id) && (transactionMap.get(SO.id).Status__c == 'Captured' && transactionMap.get(SO.id).Transaction_Type__c == 'CAPTURE_ONLY')) {
                    SO.Payment_Status__c = 'Received';
                }
                if(transactionMap.containsKey(SO.id) && (transactionMap.get(SO.id).Status__c == 'Failed' && transactionMap.get(SO.id).Transaction_Type__c == 'CAPTURE_ONLY')) {
                    SO.Payment_Status__c = 'Capture-sFailed';
                }
            }
            System.debug('salesOrderList :: '+salesOrderList);
            if(salesOrderList.size() > 0) {
               update salesOrderList; 
            }
        }
    }
}