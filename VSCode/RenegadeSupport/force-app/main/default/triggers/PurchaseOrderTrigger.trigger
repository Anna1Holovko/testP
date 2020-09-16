trigger PurchaseOrderTrigger on Purchase_Order__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
	if (Trigger.isInsert && Trigger.isBefore) {
		PurchaseOrderTriggerHandler.beforeInsert(trigger.new);
	}
	
	if (Trigger.isUpdate && Trigger.isBefore) {
		PurchaseOrderTriggerHandler.beforeUpdate(trigger.new, trigger.oldmap);
	}
	
	/*if(Trigger.isAfter && Trigger.isDelete){
	}
	
	if(Trigger.isAfter && Trigger.isUndelete){
	}*/
	
	if(Trigger.isAfter && Trigger.isUpdate){
		PurchaseOrderTriggerHandler.afterUpdate(trigger.new, trigger.oldmap);
	}
	
	if(Trigger.isAfter && Trigger.isInsert){
		PurchaseOrderTriggerHandler.afterInsert(trigger.new);
	}
}