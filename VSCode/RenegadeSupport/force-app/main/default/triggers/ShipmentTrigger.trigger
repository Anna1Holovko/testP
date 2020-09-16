trigger ShipmentTrigger on Shipment__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
	
	if (Trigger.isAfter && Trigger.isInsert) {
			ShipmentTriggerHandler.afterInsert(trigger.new);
		}
		
	/*if(Trigger.isInsert && Trigger.isDelete){
	}
	
	if(Trigger.isInsert && Trigger.isUndelete){
	}*/
	
	if(Trigger.isAfter && Trigger.isUpdate){
		ShipmentTriggerHandler.afterUpdate(trigger.new, trigger.oldmap);
	}
	
	if(Trigger.isInsert && Trigger.isBefore){
		ShipmentTriggerHandler.beforeInsert(trigger.new);
	}
	
	if (Trigger.isUpdate && Trigger.isBefore) {
		ShipmentTriggerHandler.beforeUpdate(trigger.new, trigger.oldmap);
	}
	
}