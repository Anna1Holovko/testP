/*
*   Author : Vishnu Bijjula | Kairos Tech
*   Class  : autoAssignCaseDepartmentHelper
*   Purpose: This trigger is to assign Case recordType based on Support Type and Order Number
*/
trigger autoAssignCaseDepartment on Case (before insert, before update, after insert,after Update) {
    public list<Case> caseList {get;set;}
    public list<Case> caseOwnerList {get;set;}
    public set<String> caseSalesOrderList {get;set;}
    if(trigger.isBefore){
        if(trigger.isInsert){
            caseList = new list<Case>();
            caseSalesOrderList = new set<String>();
            for(Case oneCase : trigger.new) {
                caseList.add(oneCase);
                caseSalesOrderList.add(oneCase.Order_Number__c);
            }
            autoAssignCaseDepartmentHelper.updateCaseRecordType(caseList,caseSalesOrderList);
            autoAssignCaseDepartmentHelper.checkCaseAccountExistence(Trigger.new);
        }
    }
    
    if(trigger.isAfter) {
        if(trigger.isInsert){
            caseList = new list<Case>();
            
            for(Case oneCase : trigger.new) {
                caseList.add(oneCase);
            }
            System.debug('caseList: '+caseList);
            System.debug('caseList Size: '+caseList.size());
            if(caseList.size() != 0) {
                autoAssignCaseDepartmentHelper.autoCaseAssign(caseList);
            }
        }
        if(trigger.isUpdate){
            caseList = new list<Case>();
            caseOwnerList = new list<Case>();
            Map<Id,user> userIds = new Map<id,user>([select id from user where Profile.UserLicense.Name='Salesforce']);
            System.debug('userIds: '+userIds);
            
            for(Case oneCase : trigger.new) {
                if(oneCase.IsEscalated != trigger.oldmap.get(oneCase.id).IsEscalated) {
                    caseList.add(oneCase);
                }
                if(oneCase.OwnerId != trigger.oldmap.get(oneCase.id).OwnerId && oneCase.RecordType.Name != 'After Care Dept.') {
                    if(userIds.containsKey(oneCase.OwnerId)) {
                        caseOwnerList.add(oneCase);
                    }
                    else {
                        System.debug('Case Owner Id is not a Salesforce License User');
                    }
                }
            }
            System.debug('caseList: '+caseList);
            System.debug('caseList Size: '+caseList.size());
            System.debug('caseOwnerList: '+caseOwnerList);
            System.debug('caseOwnerList Size: '+caseOwnerList.size());
            if(caseList.size() != 0) {
                autoAssignCaseDepartmentHelper.caseUpdation(caseList);
            }
            if(caseOwnerList.size() != 0) {
                autoAssignCaseDepartmentHelper.autoTaskCreation(caseOwnerList);
            }
            
            
            autoAssignCaseDepartmentHelper.runFlow(trigger.newMap);
        }
    }
}