@isTest 
public with sharing class TaskTriggerHandlerTest {

    public static testmethod void TaskTriggerHandlerTest(){
    	
		Account ac = TestUtil.createCustomerAccount(); 
        
        Products__c Pro = TestUtil.createConfigProduct();
        
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, Null, Null);
        
        Purchase_Order__c po = TestUtil.createpurchaseorder(so.id,'Manufacturer PO');
    	
    	
        Task taskVar = new Task();
        taskVar.ownerid = UserInfo.getUserId();
        taskVar.WhatId = so.id;
        taskVar.Subject = 'ETA Confirmation Sent';
        taskVar.description='Manual Order Payment has been created';
        taskVar.Status = 'Open';
        taskVar.ActivityDate = system.today();
        
        insert taskVar;
	}
}