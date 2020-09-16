trigger InvoiceLineItemTrigger on Invoice_Line_Item__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
	/*if (Trigger.isInsert && Trigger.isBefore) {
	}
	
	if (Trigger.isUpdate && Trigger.isBefore) {
	}
	
	if(Trigger.isAfter && Trigger.isDelete){
		AccountTriggerHandler.afterDelete(trigger.old);
	}
	
	if(Trigger.isAfter && Trigger.isUndelete){
		AccountTriggerHandler.afterUnDelete(trigger.new);
	}
	
	if(Trigger.isAfter && Trigger.isUpdate){
	}*/
	
	if(Trigger.isAfter && Trigger.isInsert){
		InvoiceLineItemTriggerHandler.afterInsert(trigger.new);
	}
}