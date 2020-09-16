trigger LogTrigger on Log__c (after delete, after insert, after undelete, 
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
		}*/
		
		if(Trigger.isAfter && Trigger.isUpdate){
			LogTriggerHandler.afterUpdate(trigger.oldmap, trigger.new);
		}
		
		if(Trigger.isAfter && Trigger.isInsert){
			LogTriggerHandler.afterInsert(trigger.new);
		}
}