trigger ShipmentLineItemTrigger on Shipment_Line_Item__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {

	
	/*
		if(Trigger.isAfter && Trigger.isDelete){
		}
		
		if(Trigger.isAfter && Trigger.isUndelete){
		}*/
		
		if(Trigger.isAfter && Trigger.isUpdate){
			ShipmentLineItemTriggerHandler.afterUpdate(trigger.new, trigger.oldmap);
		}
		
		else if (Trigger.isAfter && Trigger.isInsert) {
			ShipmentLineItemTriggerHandler.afterInsert(trigger.new);
		}
		
		if(Trigger.isInsert && Trigger.isBefore){
			ShipmentLineItemTriggerHandler.beforeInsert(trigger.new);
		}
		
		if(Trigger.isBefore && Trigger.isUpdate){
			ShipmentLineItemTriggerHandler.beforeUpdate(Trigger.newMap, Trigger.oldMap);
		}
		/*if (Trigger.isUpdate && Trigger.isBefore) {
			ShipmentTriggerHandler.beforeUpdate(trigger.new, trigger.oldmap);
		}*/
}