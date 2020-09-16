trigger ProductsTrigger on Products__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {

	
	/*
	if(Trigger.isAfter && Trigger.isDelete){
	}
	
	if(Trigger.isBefore && Trigger.isUndelete){
	}
	*/

	/* if (Trigger.isAfter && Trigger.isInsert) {
		ProductsTriggerHandler.afterInsert(trigger.new);
	} */

	if(Trigger.isAfter && Trigger.isUpdate){
		ProductsTriggerHandler.afterUpdate(trigger.new, trigger.oldmap);
	}

	if(Trigger.isInsert && Trigger.isBefore){
		ProductsTriggerHandler.beforeInsert(trigger.new);
	}
	
	if (Trigger.isUpdate && Trigger.isBefore) {
		ProductsTriggerHandler.beforeUpdate(trigger.new, trigger.oldmap);
	}
}