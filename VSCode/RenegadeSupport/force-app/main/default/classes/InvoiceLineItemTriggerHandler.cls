public with sharing class InvoiceLineItemTriggerHandler {
	
	public static void afterInsert(list<Invoice_Line_Item__c> newLineItems){
		map<string, string> inventoryItemIdBySoItemId = new map<string, string>();
		for (Invoice_Line_Item__c ili :newLineItems){
			if (ili.Items_invoiced__c != null){
				inventoryItemIdBySoItemId.put(ili.Items_invoiced__c, ili.id);
			}
		}
		if (inventoryItemIdBySoItemId.size() > 0){
			updateLookUpFields(inventoryItemIdBySoItemId);
		}
	}
	
	private static void updateLookUpFields (map<string, string> inventoryItemIdBySoItemId){
		list<Invoice_Line_Item__c> invLinesToUpdate = new list<Invoice_Line_Item__c>();
    	list<Shipment_Line_Item__c> slis = [select PO_Line_Item__r.SO_Line_Item__c, PO_Line_Item__r.SO_Line_Item__r.Uncancelled_Items_Ordered__c from Shipment_Line_Item__c where PO_Line_Item__r.SO_Line_Item__c in :inventoryItemIdBySoItemId.keyset()];
    	list<PO_Line_Items__c> plis = [select SO_Line_Item__c, SO_Line_Item__r.Uncancelled_Items_Ordered__c from PO_Line_Items__c where SO_Line_Item__c in :inventoryItemIdBySoItemId.keyset()];
    	map<string, string> soiWithShipment = new map<string, string>();
    	map<string, string> soiWithPo = new map<string, string>();
    	for (Shipment_Line_Item__c sli : slis){
    		soiWithShipment.put(sli.PO_Line_Item__r.SO_Line_Item__c, sli.id);
    	}
    	for (PO_Line_Items__c pli : plis){
    		soiWithPo.put(pli.SO_Line_Item__c, pli.id);
    	}
    	for (string str : inventoryItemIdBySoItemId.keyset()){
    		if (soiWithPo.containskey(str)){
    			Invoice_Line_Item__c ili = new Invoice_Line_Item__c(id = inventoryItemIdBySoItemId.get(str));
    			ili.PO_Line_Item__c = soiWithPo.get(str);
    			if (soiWithShipment.containskey(str)){
    				ili.Shipment_Line_Item__c = soiWithShipment.get(str);
    			}
    			invLinesToUpdate.add(ili);
    		}
    	}
    	if (invLinesToUpdate.size() > 0){
    		update invLinesToUpdate;
    	}
	}
}