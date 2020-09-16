trigger InventoryTrigger on Inventory__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {

/*	if (Trigger.isInsert && Trigger.isBefore) {
	}

	//if (Trigger.isUpdate && Trigger.isBefore) {

	//}

	if(Trigger.isAfter && Trigger.isDelete){
	}
	
	if(Trigger.isAfter && Trigger.isUndelete){
	}
	*/
	if(Trigger.isAfter && Trigger.isUpdate){
        InventoryTriggerHandler.afterUpdate(trigger.new, trigger.oldMap);
	}
	
	if(Trigger.isAfter && Trigger.isInsert){
		InventoryTriggerHandler.afterInsert(trigger.new);
	}

}