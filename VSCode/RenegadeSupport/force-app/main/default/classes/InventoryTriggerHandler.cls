public with sharing class InventoryTriggerHandler {

	public static void afterUpdate(list<Inventory__c> newInventoryList, map<Id, Inventory__c> oldInventoryMap){
		map<Inventory__c, Integer> inventoryToUpdate = new map<Inventory__c, Integer>();
/*
		for(Inventory__c inventory: newInventoryList) {
			if(inventory.recordtypeid == Schema.SObjectType.Inventory__c.getRecordTypeInfosByName().get('Delivery Company Inventory').getRecordTypeId() && inventory.Quantity__c != oldInventoryMap.get(inventory.Id).Quantity__c) {
				inventoryToUpdate.put(inventory,Integer.valueOf(oldInventoryMap.get(inventory.Id).Quantity__c));
			}
		}


		if (inventoryToUpdate.size() > 0){
			updateInventoryAndSHL(inventoryToUpdate);
		}
*/
		checkProductAvailability(newInventoryList, oldInventoryMap);
	}

	public static void afterInsert(List<Inventory__c> newInventory){
		List<string> shipmentItemIds = new List<string>();
		list<Inventory__c> inventoryToUpdate = new list<Inventory__c>();

		for(Inventory__c inventory: newInventory) {
			if(inventory.Shipment_Item__c != null && inventory.recordtypeid == Schema.SObjectType.Inventory__c.getRecordTypeInfosByName().get('Delivery Company Inventory').getRecordTypeId()) {
				inventoryToUpdate.add(inventory);
				shipmentItemIds.add(inventory.Shipment_Item__c);
			}
		}
		system.debug('shipmentItemIds = ' + shipmentItemIds);
		if (inventoryToUpdate.size() > 0){
			updateInventoryAndPol(inventoryToUpdate, shipmentItemIds);
		}
		checkProductAvailability(newInventory, null);
	}

	/*private static void updateInventoryAndSHL(map<Inventory__c, Integer> inventories){

		list<Shipment_Line_Item__c> SHLsToUpdate = new list<Shipment_Line_Item__c>();
		
		for (Inventory__c inv : inventories.keyset()){
			Integer quantity_taken = inventories.get(inv) - Integer.valueOf(inv.Quantity__c);
			list<Shipment_Line_Item__c> shl_list = [SELECT id, Action_Needed_by_Tech__c, Approval_Status__c, At_Local_Delivery_Company_Date__c, Awaiting_Resolution_from_Customer_Date__c, Awaiting_Resolution_from_Hub_Date__c, Box_Info__c, Cancelled_Date__c, Check_amount__c, Check_date__c, Check_number__c, Claim_Amount_Approved__c, Claim_Dollar_Amount__c, Claim_Status__c, Claim_Support_Filled__c, Condition_of_furniture__c, Consignment_ID_Number__c, Consignment_Schedule_Date__c, Consignment_Status__c, Cubed_Ft__c, Damage_Action__c, Days_in_Damage_Action__c, Delivered_No_Issues_Date__c, Delivery_Date_Actual__c, Delivery_Flag__c, Delivery_Flag_Helper__c, Deluxed_No_Issues_Date__c, Deluxed_With_Issues_Date__c, Description__c, Draft_Date__c, Driver_Call_Date__c, Drop_Off_Date_Actual__c, Drop_Off_Date_Expected__c, En_Route_Date__c, En_Route_To_Local_Delivery_Company_Date__c, Follow_up_date__c, Furniture_Condition__c, Hold_As_Stock_Date__c, Image__c, In_Home_Follow_Up_Date__c, Inventory__c, IsReplacement__c, Deluxing_Issue_Quantity__c, Item_s_Popularity__c, Item_condition__c, Item_status_at_consignment__c, Last_Status_Change__c, Location_Of_Furniture__c, Method_of_Transport__c, Need_to_reorder_furniture__c, No_Fit_Date__c, No_Fit_Status__c, Not_At_Home_Date__c, Magento_Order_No__c, Order_Website__c, Overdue_Scheduling__c, Parts_Are_Shipping__c, Parts_Arrival_Date_Actual__c, Parts_Arrival_Expected__c, Parts_Information__c, Parts_Needed_Date__c, Pickup_Drop_off_Cost__c, Pickup_Date_Actual__c, Pickup_Date_Expected__c, PO_Line_Item__c, Price__c, Product_ID__c, Product_Image_URL__c, Product_Name__c, Product_SKU__c, Quantity__c, Reason_for_Disposed_Donated__c, Received_Reimbursement_Amount__c, Received_reimbursement_from_3rd_party__c, Redelivery_Needed_Date__c, Refused_Delivery_Date__c, Related_Sales_Order__c, Renegade_received_check__c, Repair_Amount__c, Repair_Date__c, Repair_Date_Actual__c, Repair_Date_Expected__c, Repair_With_Parts_Date__c, Replacement_Date__c, Replacement_Drop_off_Date_Actual__c, Replacement_Drop_off_Date_Expected__c, Routing_Date__c, Sales_Commission__c, Scheduled_Delivery_Date__c, Scheduled_Delivery_Date_Updated__c, Send_to_Consignment_Date__c, Sent_Tech_Report__c, Set_or_individual_item__c, Shipment__c, Shipment_Item_Status__c, Shipment_Product_Dimensions__c, Shipment_Product_Name__c, Shipment_Product_Quantity__c, Shipment_Product_SKU__c, Shipment_Product_Weight__c, Shipped_Quantity_Actual__c, Shorted_Date__c, SLI_Number_and_Product_Name__c, Status_Of_Tech_Needed__c, Tech_Appointment_Confirmed__c, Tech_Company__c, Tech_Needed_Create_Date__c, Tech_Scheduled_By__c, Tech_Request_Submitted_Date__c, Time_frame_of_Delivery__c, Time_in_current_status__c, Tracking_Number__c, Weight_Pounds__c, Who_is_claim_against__c
                    FROM Shipment_Line_Item__c WHERE Inventory__c = :inv.Id];
			for(Shipment_Line_Item__c shl : shl_list){
				if (shl.Shipment_Product_Quantity__c > quantity_taken){
					shl.Shipment_Product_Quantity__c = shl.Shipment_Product_Quantity__c - quantity_taken;
					Shipment_Line_Item__c clonedSHL = shl.clone();
					clonedSHL.Shipment_Product_Quantity__c = quantity_taken;
	                clonedSHL.Original_POL__c = shl.PO_Line_Item__c;
					SHLsToUpdate.add(shl);
					SHLsToUpdate.add(clonedSHL);
				}
				else {
					shl.Shipment_Item_Status__c = 'Retagged';
				}
			}
		}
		try{
			upsert SHLsToUpdate;
		}
			catch(DmlException e){
	                System.debug('An unexpected error has occurred: ' + e.getMessage());
	    }

	}*/
	
	
	private static void updateInventoryAndPol(List<Inventory__c> inventoryToUpdate, List<string> shipmentItemIds){
		list<Inventory__c> inventoryToUpdateList = new list<Inventory__c>();
		list<string> polIds = new list<string>();
		list<string> productIds = new list<string>();
		map<id, Shipment_Line_Item__c> sliMap = new map<id, Shipment_Line_Item__c>([select PO_Line_Item__c, Shipment__r.Delivery_Company__c from Shipment_Line_Item__c where id in :shipmentItemIds and Shipment__r.Carrier__c != 'LTL']);
		system.debug('sliMap = ' + sliMap);
		for (Inventory__c i : inventoryToUpdate){
			system.debug('i = ' + i);
			if (sliMap.containskey(i.Shipment_Item__c)){
				Inventory__c inv = new Inventory__c(id = i.id);
				inv.Related_POL__c = sliMap.get(i.Shipment_Item__c).PO_Line_Item__c;
				polIds.add(sliMap.get(i.Shipment_Item__c).PO_Line_Item__c);
				inv.Delivery_Company__c = sliMap.get(i.Shipment_Item__c).Shipment__r.Delivery_Company__c;
				inventoryToUpdateList.add(inv);
				productIds.add(i.Products__c);
			}
		}
		system.debug('inventoryToUpdateList = ' + inventoryToUpdateList);
		if (inventoryToUpdateList.size() > 0){
			update inventoryToUpdateList;
			updateExistedPOL(polIds, productIds);
		}
	}
	
	private static void updateExistedPOL(list<string> polIds, list<string> productIds){
		system.debug('productIds = ' + productIds);
		system.debug('polIds = ' + polIds);
		list<PO_Line_Items__c> pols = [select id, Inventory_with_product__c from PO_Line_Items__c where (PO_Item_Status__c = 'On Order' or PO_Item_Status__c = 'Draft') and ((SO_Line_Item__r.Config_Product__c != null and SO_Line_Item__r.Config_Product__c in :productIds) or (SO_Line_Item__r.Bundle_Item__c != null and SO_Line_Item__r.Bundle_Item__r.Product__c in :productIds) or SO_Line_Item__r.Products__c in :productIds) and id not in :polIds];
		
		system.debug('pols = ' + pols);
		for (PO_Line_Items__c pl : pols){
			pl.Inventory_with_product__c = true;
		}
		if (pols.size() > 0){
			update pols;
		}
	}

	private static void checkProductAvailability(List<Inventory__c> newInventoryList, Map<Id, Inventory__c> oldInventoryMap) {
		List<Inventory__c> inventoryToUpdateList = new List<Inventory__c>();
		Set<String> inventoryProductConditonSet = new Set<String> {'Resellable', 'Unopened'};
		Set<String> proudctIdToCheckAvailability = new Set<String> ();
		for(Inventory__c currentInventory_i : newInventoryList){
			Inventory__c oldInventory = oldInventoryMap != null ? oldInventoryMap.get(currentInventory_i.Id) : null;
			if( (oldInventoryMap == null || currentInventory_i.Update_inventory_on_product__c != oldInventory.Update_inventory_on_product__c 
			 || ( currentInventory_i.Product_Condition__c != oldInventory.Product_Condition__c || ( currentInventory_i.Quantity__c == 0 && oldInventory.Quantity__c > 0) || (currentInventory_i.Quantity__c > 0 && oldInventory.Quantity__c == 0) )  )){
				proudctIdToCheckAvailability.add(currentInventory_i.Products__c);
			}
		}

		List<Products__c> productToUpdateList = new List<Products__c>();
		for(Products__c currentProduct_i : [SELECT Id, Available_Inventory__c, (SELECT Id FROM Inventory__r WHERE Product_Condition__c IN :inventoryProductConditonSet AND Quantity__c > 0 LIMIT 1) 
											FROM Products__c 
											WHERE Id IN :proudctIdToCheckAvailability]){

			currentProduct_i.Available_Inventory__c = (currentProduct_i.Inventory__r != null && !currentProduct_i.Inventory__r.isEmpty());
			productToUpdateList.add(currentProduct_i);			
		}

		if(!productToUpdateList.isEmpty()) {
			update productToUpdateList;
		}

	}
}