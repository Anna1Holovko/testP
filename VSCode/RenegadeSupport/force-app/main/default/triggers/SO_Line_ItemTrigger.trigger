trigger SO_Line_ItemTrigger on SO_Line_Items__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
	
	    if (Trigger.isInsert && Trigger.isBefore) {
			SO_Line_ItemTriggerHandler.beforeInsert(Trigger.newMap);
		}
		

		if (Trigger.isUpdate && Trigger.isBefore) {
			SO_Line_ItemTriggerHandler.beforeUpdate(Trigger.newMap, Trigger.oldMap);
		}
		
		/*if(Trigger.isAfter && Trigger.isDelete){
		}
		
		if(Trigger.isAfter && Trigger.isUndelete){
		}*/
		
		if(Trigger.isAfter && Trigger.isUpdate){
			SO_Line_ItemTriggerHandler.afterUpdate(Trigger.newMap, Trigger.oldMap);
		}
		
		if(Trigger.isAfter && Trigger.isInsert){
			System.debug('after insert');
			SO_Line_ItemTriggerHandler.afterInsert(Trigger.new, Trigger.newMap);
		}

}