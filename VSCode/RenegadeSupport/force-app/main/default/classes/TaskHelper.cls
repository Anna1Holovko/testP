public class TaskHelper 
{
    public static void createTaskForInvoice(List<Invoice__c> invoiceList) {
        Map<String, InvoiceTaskSettings__c> settingsMap = InvoiceTaskSettings__c.getAll();
        Set<Id> salesOrderIdSet = new Set<Id>();
        for (Invoice__c invoice_i : invoiceList) {
            salesOrderIdSet.add(invoice_i.Sales_Order__c);
        }
        System.debug('settingsMap: ' + settingsMap);
        List<Task> taskListToInsert = new List<Task>();
        Set<Id> salesOrderWithOpenTaskSet = new Set<Id>();
        for(Sales_Order__c currentSalesOrder : [SELECT Id, (SELECT Id FROM Tasks WHERE Subject = :settingsMap.get('Subject').Value__c AND Status = :settingsMap.get('Status').Value__c ) 
                                                FROM Sales_Order__c 
                                                WHERE Id IN :salesOrderIdSet]){
            System.debug('currentSalesOrder: ' + currentSalesOrder);
            if(!currentSalesOrder.Tasks.isEmpty()){
                salesOrderWithOpenTaskSet.add(currentSalesOrder.Id);
            }
        }
        System.debug('salesOrderWithOpenTaskSet: ' + salesOrderWithOpenTaskSet);
        for (Invoice__c invoice_i : invoiceList) {
            if(salesOrderWithOpenTaskSet.contains(invoice_i.Sales_Order__c)){
                continue;
            }
            Task task_i = new Task(WhatId = invoice_i.Sales_Order__c);
            for (InvoiceTaskSettings__c setting_i : settingsMap.values()) {
                task_i.put(setting_i.Name, setting_i.Value__c);
            }
            taskListToInsert.add(task_i);
        }
        if(!taskListToInsert.isEmpty()){
            insert taskListToInsert;
        }
        
    }

    public static void updateObjectName(set<id> taskIdset)
    {
        list<task> tasklist = new list<task>();
        string relatedTo;
        for(Task taskObj: [select id,whatid,what.type from task where id IN :taskIdset ]) 
        {
            relatedTo = taskObj.what.type;
            if(relatedTo != null){
                if(relatedTo.endsWith('__c')){
                    relatedTo = relatedTo.removeEnd('__c');
                }
                
                relatedTo = relatedTo.replaceall('_',' '); 
                taskObj.Related_To__c = relatedTo;
                
                
            }
            tasklist.add(taskObj);
            
        }
        update tasklist;
    }
    
    public static void updateUserLookup(List<task> taskList,set<id> taskIdset)
    {
        map<string,string> userMap = new map<string,string>();
        map<id,string> objectTypeMap = new map<id,string>();
        string relatedTo;
        for(user userObj : [select id,name from user where userType='Standard'])
        {
            userMap.put(userObj.name, userObj.id);
        }
        
        for(Task taskObj: [select id,whatid,what.type from task where id IN :taskIdset])
        {
            if(taskObj != null && taskObj.whatid <> null)
            {
                relatedTo = taskobj.what.type;
                relatedTo = relatedTo.removeEnd('__c');
                relatedTo = relatedTo.replaceall('_',' '); 
                objectTypeMap.put(taskObj.id,relatedTo);
            }
        }
        for(Task taskObj : taskList)
        {
            if(taskObj.Assigned_To__c !=null)
            {
                if(userMap.containsKey(taskObj.Assigned_To__c))
                {
                    taskObj.OwnerId = userMap.get(taskObj.Assigned_To__c);
                }
            }
            if(taskObj != null && taskObj.whatid != null && objectTypeMap.containsKey(taskObj.id) )
            {
                taskObj.Related_To__c = objectTypeMap.get(taskObj.id);
            }
        }
    }
}