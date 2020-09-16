global class AccountDataFixBatch implements Database.Batchable<sObject>, Database.Stateful{
    
    Set<String> openedSOstatusesSet = Opened_SO_statuses__c.getAll().keySet();
    DateTime createdDateFrom; 
    
    global AccountDataFixBatch() {
        Time zTime = Time.newInstance(0, 0, 0, 0);
        this.createdDateFrom = DateTime.newInstanceGMT (2019, 1, 1);
    }
    
    global AccountDataFixBatch(Date createdDateFrom) {
        Time zTime = Time.newInstance(0, 0, 0, 0);
        this.createdDateFrom = DateTime.newInstanceGMT(createdDateFrom, zTime);
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        String query = 'SELECT Id, Number_of_Opened_Sales_Orders__c FROM Account';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Account> scope){
        AggregateResult[] groupedResults = [
            SELECT COUNT(Id)numbSO, Customer_Name__c
            FROM Sales_Order__c
            WHERE Customer_Name__c IN: scope AND Customer_Name__c <> null AND Order_Status__c IN: openedSOstatusesSet AND CreatedDate > :createdDateFrom
            GROUP BY Customer_Name__c
        ];
        Map<Id, Integer> accIdToNumbOpenSoMap = new Map<Id, Integer>();
        List<Account> accToUpdateList = new List<Account>();
        for (AggregateResult ar : groupedResults) {
            Id accId = (Id)ar.get('Customer_Name__c');
            Integer numbOpenSO = (Integer)ar.get('numbSO');
            accIdToNumbOpenSoMap.put(accId, numbOpenSO);
        }
        
        for(Account acc_i: scope) {
            Integer numbOpenSO = (accIdToNumbOpenSoMap.containsKey(acc_i.Id)) ? accIdToNumbOpenSoMap.get(acc_i.Id) : 0;
            SYstem.debug('acc_i.Number_of_Opened_Sales_Orders__c  '+acc_i.Number_of_Opened_Sales_Orders__c );
            SYstem.debug('numbOpenSO '+numbOpenSO );
            if(acc_i.Number_of_Opened_Sales_Orders__c != numbOpenSO) {
                acc_i.Number_of_Opened_Sales_Orders__c = numbOpenSO;
                accToUpdateList.add(acc_i);
            }
        }
        if(accToUpdateList.size() > 0){
            DataBase.update(accToUpdateList, false);
        }
    }
    
    global void finish(Database.BatchableContext jobIdParam) {
    }  
}