/*
*   Author : Vishnu Bijjula | Kairos Tech
*   Class  : autoAssignCaseDepartmentHelper
*   Purpose: This class is to assign Case recordType based on Issue Type and Order Number
*/
public class autoAssignCaseDepartmentHelper {
    static Boolean isNotFlowRun = true;
    public static void updateCaseRecordType(list<Case> caseList,set<String> caseSalesOrderList)
    {
        try {
            Map<String,Id> getCaseRecordTypeIdmap = new Map<String,Id>();
            Map<String,Id> getSalesOrderIdmap = new Map<String,Id>();
            
            System.debug('caseSalesOrderList: '+caseSalesOrderList);
            System.debug('caseSalesOrderList: '+caseSalesOrderList.size());
            for(Sales_Order__c oneSalesOrder : [Select Id,Magento_order_No__c,Name from Sales_Order__c where Magento_order_No__c In :caseSalesOrderList Or Name In :caseSalesOrderList]) {
                if(caseSalesOrderList.contains(oneSalesOrder.Magento_order_No__c) && oneSalesOrder.Magento_order_No__c != null) {
                    getSalesOrderIdmap.put(oneSalesOrder.Magento_order_No__c, oneSalesOrder.id);
                }
                else If(caseSalesOrderList.contains(oneSalesOrder.Name) && oneSalesOrder.Name != null) {
                    getSalesOrderIdmap.put(oneSalesOrder.Name, oneSalesOrder.id);
                }
            }
            
            System.debug('getSalesOrderIdmap: '+getSalesOrderIdmap);
            
            for(Case__c onceCase : [Select Id,Name,RecordTypeId__c from Case__c where Name != null AND RecordTypeId__c != null])
            {
                getCaseRecordTypeIdmap.put(onceCase.Name, onceCase.RecordTypeId__c);
            }
            System.debug('getCaseRecordTypeIdmap: '+getCaseRecordTypeIdmap);
            for(Case oneCase : caseList) {
                oneCase.RecordTypeId = getCaseRecordTypeIdmap.get(oneCase.Support_Type__c);
                if(oneCase.Support_Type__c != null){
                    oneCase.Subject = oneCase.Support_Type__c;
                }
                if(oneCase.IsEscalated == true) {
                    oneCase.Priority = 'High';
                }
                else {
                    oneCase.Priority = 'Medium';
                }
                if(getSalesOrderIdmap.size() != 0) {
                    oneCase.Sales_Order__c = getSalesOrderIdmap.get(oneCase.Order_Number__c);
                }
                System.debug('oneCase: '+oneCase);
            }
        }
        catch(Exception Ex)
        {
            System.debug('Exception Ex: '+Ex.getMessage()+' Cause: '+Ex.getCause()+' Line Number: '+Ex.getLineNumber());
        }
    }
   
    public static void autoCaseAssign(list<Case> cases)
    {
        List<Case> caseList = new List<Case>();
        try {
            for (Case caseObj : cases) {
                Case updateCase = new Case();
                updateCase.id = caseObj.id;
                if(caseObj.IsEscalated == true) {
                    updateCase.Priority = 'High';
                }
                else {
                    updateCase.Priority = 'Medium';
                }
                caseList.add(updateCase);
                //caseList.add(new Case(id = caseObj.id));
            }
            
            Database.DMLOptions dmo = new Database.DMLOptions();
            dmo.assignmentRuleHeader.useDefaultRule = true;
            Database.update(caseList, dmo);
        }
        catch(Exception Ex)
        {
            System.debug('Exception Ex: '+Ex.getMessage()+' Cause: '+Ex.getCause()+' Line Number: '+Ex.getLineNumber());
        }
    }
    
    public static void caseUpdation(list<Case> cases)
    {
        List<Case> caseList = new List<Case>();
        try {
            for (Case caseObj : cases) {
                Case updateCase = new Case();
                updateCase.id = caseObj.id;
                if(caseObj.IsEscalated == true) {
                    updateCase.Priority = 'High';
                }
                else {
                    updateCase.Priority = 'Medium';
                }
                caseList.add(updateCase);
            }
            
            if(caseList.size() != 0) {
                update caseList;
            }
        }
        catch(Exception Ex)
        {
            System.debug('Exception Ex: '+Ex.getMessage()+' Cause: '+Ex.getCause()+' Line Number: '+Ex.getLineNumber());
        }
    }
    
    public static void autoTaskCreation(list<Case> cases) {
        List<Task> taskList = new List<Task>();
        List<Case> caseList = new List<Case>();
        try {
            for (Case caseObj : cases) {
                System.debug('caseObj Owner: '+caseObj.OwnerId);
                
                Case updateCase = new Case();
                updateCase.id = caseObj.id;
                if(caseObj.IsEscalated == true) {
                    updateCase.Priority = 'High';
                }
                else {
                    updateCase.Priority = 'Medium';
                }
                updateCase.Status = 'Assigned';
                
                caseList.add(updateCase);
                
                Task oneTask = new Task();
                oneTask.WhatId = caseObj.id;
                oneTask.OwnerId = caseObj.OwnerId;
                if(caseObj.Support_Type__c == 'Delivered With Issues' && caseObj.Origin == 'Partner Portal') {
                    oneTask.Subject = 'Generate a Case with customer for After Delivery Follow-UP';
                }
                else If(caseObj.Support_Type__c == 'Deluxing with Issue' && caseObj.Origin == 'Partner Portal'){
                    oneTask.Subject = 'Generate a Case with customer for '+caseObj.Subject;
                }
                else
                {
                    oneTask.Subject = caseObj.Subject;
                }
                oneTask.priority = caseObj.Priority;
                oneTask.status = 'Open';
                oneTask.ActivityDate = date.valueOf(caseObj.LastModifiedDate);
                oneTask.description = caseObj.Description;
                oneTask.IsReminderSet = true;
                
                taskList.add(oneTask);
            }
            
            if(caseList.size() != 0) {
                update caseList;
            }
            
            if(taskList.size() != 0)
            {
             	insert taskList;   
            }
        }
        catch(Exception Ex)
        {
            System.debug('Exception Ex: '+Ex.getMessage()+' Cause: '+Ex.getCause()+' Line Number: '+Ex.getLineNumber());
        }
    }

    public static void checkCaseAccountExistence(List<Case> newCasesList){
        Set<String> caseEmailSet = new  Set<String>();
        for(Case currentCase_i : newCasesList){ 
            if(currentCase_i.origin == 'Web'){
                caseEmailSet.add(currentCase_i.ContactEmail);
            }else{
                caseEmailSet.add(currentCase_i.SuppliedEmail);
            }
        }
        Map<String, Account> emailToAccountMap = new Map<String, Account>();
        for(Account currentAccount_i : [SELECT Id, Email__c, (SELECT Id, AccountId FROM Contacts) FROM Account WHERE Email__c IN :caseEmailSet]){
            emailToAccountMap.put(currentAccount_i.Email__c, currentAccount_i);
        }

        Map<Case, Account> caseToNewAccountMap = new Map<Case, Account> ();
        for(Case currentCase_i : newCasesList){
            String searchEmail = currentCase_i.origin == 'Web' ? currentCase_i.SuppliedEmail : currentCase_i.ContactEmail;
            if(emailToAccountMap.containsKey(searchEmail)){
                currentCase_i.AccountId = emailToAccountMap.get(searchEmail).Id;
                currentCase_i.ContactId = emailToAccountMap.get(searchEmail).Contacts.get(0).Id;
            }else if(currentCase_i.origin == 'Web'){
                caseToNewAccountMap.put(currentCase_i, new Account(Name = currentCase_i.First_Name__c + ' ' + currentCase_i.Last_Name__c, Email__c = currentCase_i.SuppliedEmail, RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId()));
            }
        }

        if(!caseToNewAccountMap.isEmpty()){
            insert caseToNewAccountMap.values();
            for(Case currentCase_i :caseToNewAccountMap.keySet()){
                currentCase_i.AccountId = caseToNewAccountMap.get(currentCase_i).Id;
            }
        }

    }
    
    public static void runFlow(Map<Id, Case> newCaseMap){
        if(isNotFlowRun){
            isNotFlowRun = false;
            runCaseActionsAndMilestonesFlow(newCaseMap.keySet());
        }
    }
    
    @future
    public static void runCaseActionsAndMilestonesFlow(Set<Id> caseIdSet){
        for(Id case_id : caseIdSet){
            Flow.Interview flow = new Flow.Interview.Case_Actions_and_Milestones((new map<String,Object> {'recordId' =>case_id}));
            flow.start();
        }
        
    }
}