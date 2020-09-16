trigger POLineItemTrigger on PO_Line_Items__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {

	if (Trigger.isInsert && Trigger.isBefore) {
		POLineItemTriggerHandler.beforeInsert(trigger.new);
	}
	
	/*if (Trigger.isUpdate && Trigger.isBefore) {
	}
	
	if(Trigger.isAfter && Trigger.isDelete){
	}
	
	if(Trigger.isAfter && Trigger.isUndelete){
	}
	
	if(Trigger.isAfter && Trigger.isUpdate){
	}*/
	
	if(Trigger.isAfter && Trigger.isInsert){
		POLineItemTriggerHandler.afterInsert(trigger.new);
	}
}