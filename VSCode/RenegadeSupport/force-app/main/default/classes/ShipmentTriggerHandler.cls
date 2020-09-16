public without sharing class ShipmentTriggerHandler {
	public static Boolean loopFlag = false;
    public static Boolean doNotUpdate = false;
	public static Boolean checkLoop(){
		Boolean currentLoopStatus = ShipmentTriggerHandler.loopFlag;
		ShipmentTriggerHandler.loopFlag = true;
		return currentLoopStatus;
	}


	public static void beforeInsert(list<Shipment__c> newShipment){
		for (Shipment__c s : newShipment){
			if (s.Shipment_Status__c == 'En Route Shipments'){
				s.Send_to_a_delivery_company__c = true;
			}
		}
		carrierHandler(newShipment);
        checkAndFillOrderNumber(newShipment);
	}
	
	public static void beforeUpdate(list<Shipment__c> newShipment, map<id, Shipment__c> oldShipmentMap){
		for (Shipment__c s : newShipment){
			if (s.Shipment_Status__c != oldShipmentMap.get(s.id).Shipment_Status__c && s.Shipment_Status__c == 'En Route Shipments'){
				s.Send_to_a_delivery_company__c = true;
			}
		}
        checkAndFillOrderNumber(newShipment);
	}
	
	public static void afterInsert(List<Shipment__c> newShipment){
		List<Id> accIdList = new List<Id>();
		list<string> salesOrderIds = new list<string>();

		for(Shipment__c shipment: newShipment) {
			salesOrderIds.add(shipment.Related_Sales_Order__c);
			if(shipment.Delivery_Company__c != null) {
				accIdList.add(shipment.Delivery_Company__c);
			}
		}
		if (salesOrderIds.size() > 0){
			updateSalesOrders(salesOrderIds);
		}
		if(accIdList.size() > 0) {
			//shareRecords(accIdList, newShipment);
			shareSalesOrderProcess(null, newShipment);
		}
		if(!checkLoop()){
			checkUpdateScheduleDate(newShipment, null);
			shipNotificationToAshley(newShipment, null);
		}
		changeSalesOrderSendGuardian(newShipment, null);


	}

	public static void afterUpdate(list<Shipment__c> newShipment, map<id, Shipment__c> oldShipmentMap){
        if (doNotUpdate) {
            return;
        }
		list<Shipment__c> shipmentToUpdate = new list<Shipment__c>();
		list<Shipment__c> updateshipmentstatus = new list<Shipment__c>();
		list<Shipment__c> updateshipmentSharing = new list<Shipment__c>();
		list<string> autoUpdateAshleyOrdersLineItemsList = new list<string>(); 
		list<string> updateshipmentToSend = new list<string>();
		set<id> relatedSO = new set<id>();
		for (Shipment__c s : newShipment){
			// if (s.Auto_Update_Ashley_Orders__c && !oldShipmentMap.get(s.id).Auto_Update_Ashley_Orders__c){
			// 	autoUpdateAshleyOrdersLineItemsList.add(s.id);
			// }
			if (s.Send_to_a_delivery_company__c){
				updateshipmentToSend.add(s.id);
				relatedSO.add(s.Related_Sales_Order__c);
				//send
				Shipment__c ns = new Shipment__c(id = s.id);
				ns.Send_to_a_delivery_company__c = false;
				shipmentToUpdate.add(ns);
			}
            if(s.Shipment_Status__c != oldShipmentMap.get(s.id).Shipment_Status__c && (s.Shipment_Status__c == 'En Route Shipments'|| s.Shipment_Status__c == 'Received By Warehouse' || s.Shipment_Status__c == 'Deluxed No Issues-Waiting On Scheduling'|| s.Shipment_Status__c == 'Scheduled Shipments'|| s.Shipment_Status__c == 'Routing'|| s.Shipment_Status__c == 'Delivered No Issues')){
                updateshipmentstatus.add(s);
            }
			if(s.Delivery_Company__c != oldShipmentMap.get(s.Id).Delivery_Company__c || s.Update_shipment_sharing__c != oldShipmentMap.get(s.Id).Update_shipment_sharing__c)  {
				updateshipmentSharing.add(s);
			}
		}
		if (updateshipmentSharing.size() > 0){
			shareSalesOrderProcess(oldShipmentMap, newShipment);
			//updateSOSharing(newShipment);
		}

		/*if (updateshipmentstatus.size() > 0){
			ShipmentHelperClass.updateStatusforShipmentandPOandSOItemList(updateshipmentstatus);
		}*/
		if (updateshipmentToSend.size() > 0){
			sendToDelivery(updateshipmentToSend, relatedSO, '', false);
		}
		// if (autoUpdateAshleyOrdersLineItemsList.size() > 0){
		// 	autoUpdateAshleyOrdersLineItems(autoUpdateAshleyOrdersLineItemsList);
		// }
		if (shipmentToUpdate.size() > 0){
			update shipmentToUpdate;
		}
		if(!checkLoop()){
			checkUpdateScheduleDate(newShipment, oldShipmentMap);
			shipNotificationToAshley(newShipment, oldShipmentMap);
			
		}
		changeSalesOrderSendGuardian(newShipment, oldShipmentMap);
	}
	// @TestVisible
	// private static void autoUpdateAshleyOrdersLineItems(list<string> autoUpdateAshleyOrdersLineItemsList){
	// 	list<Shipment_Line_Item__c> slis = [select Shipment_Item_Status__c from Shipment_Line_Item__c where Shipment__c in :autoUpdateAshleyOrdersLineItemsList];
	// 	for(Shipment_Line_Item__c sli : slis){
	// 		sli.Shipment_Item_Status__c = 'At Local Delivery Company';
	// 		sli.Drop_Off_Date_Actual__c = system.today();
	// 	}
	// 	if (slis.size() > 0){
	// 		update slis;
	// 	}
	// }

	public static void checkUpdateScheduleDate(List<Shipment__c> newShipmentList, Map<Id, Shipment__c> oldShipmentMap){
		List<String> shipmentIdToUpdateScheduleDate = new List<String> ();
		for(Shipment__c currentShipment_i : newShipmentList){
			if( String.isNotBlank(currentShipment_i.Tracking_Number__c) && (currentShipment_i.Tracking_Number__c.containsIgnoreCase(',') && currentShipment_i.Tracking_Number__c.containsIgnoreCase(';')) && String.isNotBlank(currentShipment_i.Carrier_Name__c) && currentShipment_i.Drop_Off_Date_Expected__c == null &&
				(oldShipmentMap == null || currentShipment_i.Tracking_Number__c != oldShipmentMap.get(currentShipment_i.id).Tracking_Number__c || 
				currentShipment_i.Carrier_Name__c != oldShipmentMap.get(currentShipment_i.id).Carrier_Name__c ) ){
				shipmentIdToUpdateScheduleDate.add(currentShipment_i.Id);
			}
		}
		if(!shipmentIdToUpdateScheduleDate.isEmpty()){
			populateScheduleDate(shipmentIdToUpdateScheduleDate);
		}
	}

	@future(callout=true)
	public static void populateScheduleDate(List<String> shipmentIdList){
		
		List<Shipment__c> shipmentList = [SELECT Tracking_Number__c, Carrier_Name__c, Drop_Off_Date_Expected__c FROM Shipment__c WHERE Id IN :shipmentIdList ];
		for(Shipment__c currentShipment_i : shipmentList){
			Date expectedDate = ShipmentTackingManager.track(currentShipment_i.Tracking_Number__c, 'TrackingService' + currentShipment_i.Carrier_Name__c).scheduleDate;
			currentShipment_i.Drop_Off_Date_Expected__c = expectedDate != null ? expectedDate : currentShipment_i.Drop_Off_Date_Expected__c;
		}
		update shipmentList;
	}

	public static void carrierHandler(List<Shipment__c> newShipment){
		Map<Id, List<Shipment__c>> purchaseOrderIdToShipmentMap = new Map<Id, List<Shipment__c>> ();
		for(Shipment__c shipment_i : newShipment){
			if(shipment_i.Carrier_Name__c == null ){
				if(!purchaseOrderIdToShipmentMap.containsKey(shipment_i.Purchase_Order__c)){
					purchaseOrderIdToShipmentMap.put(shipment_i.Purchase_Order__c, new List<Shipment__c>());
				}
				purchaseOrderIdToShipmentMap.get(shipment_i.Purchase_Order__c).add(shipment_i);
			}
		}
		Set<String> poCarrierValuesToNullSet = new Set<String>{'Shipping TBD', 'Ship on Manufacturer Account'}; 
		List<Purchase_Order__c> purchaseOrderList = [SELECT Id, Carrier__c FROM Purchase_Order__c WHERE Id IN :purchaseOrderIdToShipmentMap.keySet() ];
		for(Purchase_Order__c currentPO_i : purchaseOrderList){
			for(Shipment__c shipment_i : purchaseOrderIdToShipmentMap.get(currentPO_i.id)){
				shipment_i.Carrier__c = currentPO_i.Carrier__c != null ? 'LTL' : null;
				shipment_i.Carrier_Name__c = !poCarrierValuesToNullSet.contains(currentPO_i.Carrier__c) ? currentPO_i.Carrier__c : null; 
			}
		}
	}

	public static void sendToDelivery (list<string> updateshipmentToSendId, set<id> relatedSO, string status, boolean isUpdate){
		status = String.isBlank(status) ? '' : status;
		list<Shipment__c> shipmentToSend = [select id, Related_Sales_Order__c, Related_Sales_Order__r.Delivery_company_status__c, Delivery_Company__r.Fidelitone_hub_number__c, 
											Delivery_Company__r.DispatchTrack_Account_ID__c, Delivery_Company__r.DispatchTrack_business_code__c, Delivery_Company__r.IDS_hub_number__c, 
											Delivery_Company__r.DispatchTrack_location_code__c, Delivery_Company__r.IDLS_hub_number__c, Delivery_Company__r.Deliveright_hub_number__c, 
											Delivery_Company__r.G_G_hub_number__c, Delivery_Company__r.P2P_hub_number__c, Related_Sales_Order__r.Retail_Value_for_Delivery_Company__c,
											Related_Sales_Order__r.Retail_Value_Sent_to_Delivery_Company__c
											from Shipment__c where id in :updateshipmentToSendId and Carrier__c != 'LTL'];
        if (shipmentToSend.size() == 0) {
            return;
        }
        
        AggregateResult[] itemList = [SELECT Count(Id) items, Shipment__c
                                      FROM Shipment_Line_Item__c
                                      WHERE Shipment__c IN :updateshipmentToSendId
                                      GROUP BY Shipment__c];
        if (itemList.isEmpty()) {
            updateReasonOnShipmentList(shipmentToSend, 'No Shipment Lines');
            
            return;            
        }
        else {
            List<Shipment__c> shipmentToUpdate = new List<Shipment__c>();
            
            for (AggregateResult result_i : itemList) {
                Decimal count = Decimal.valueOf(String.valueOf(result_i.get('items')));
                if (count < 1) {
                    String shipmentId = String.valueOf(result_i.get('Shipment__c'));
                    shipmentToUpdate.add(new Shipment__c(Id = shipmentId,
                                                         Reason_it_was_not_sent_to_the_delivery_c__c = 'No Shipment Lines'));
                }
            }
            
            if (!shipmentToUpdate.isEmpty()) {
				doNotUpdate = true;
                update shipmentToUpdate;
                
                return;
            }
        }
        
        if (System.isBatch()) {
            updateReasonOnShipmentList(shipmentToSend, 'Run from batch, cannot send to delivery company');
            
            return;
        }
        
        if (System.isFuture()) {
            updateReasonOnShipmentList(shipmentToSend, 'Run from Future, cannot send to delivery company');
            
            return;
        }

		Map<String, Shipment_statuses_to_determine_Delivery__c> shipmentStatusSetting = Shipment_statuses_to_determine_Delivery__c.getAll();
		Set<String> shipmentStatusSet = new Set<String>();
		for(Shipment_statuses_to_determine_Delivery__c cirrentShipmentSetting_i : shipmentStatusSetting.values()){
			shipmentStatusSet.add(cirrentShipmentSetting_i.Status_value__c);
		} 
		list<Shipment_Line_Item__c> sli = [SELECT PO_Line_Item__r.SO_Line_Item__c, PO_Line_Item__r.Total_shipment_Quantity__c, Shipped_Quantity_Actual__c FROM Shipment_Line_Item__c 
		where PO_Line_Item__r.Purchase_Order__r.Status__c != 'Cancelled' and PO_Line_Item__r.SO_Line_Item__r.Sales_Order__c in :relatedSO 
		and (Shipment__r.Shipment_Status__c  IN : shipmentStatusSet /*= 'En Route Shipments' or Shipment__r.Shipment_Status__c = 'Received By Warehouse' or Shipment__r.Shipment_Status__c = 'Deluxed No Issues-Waiting On Scheduling'*/)];
		list<id> soIds = new list<id>();
		Map <String, Decimal> poLineItemIdToQuantity = new Map <String, Decimal>();
		for (Shipment_Line_Item__c s : sli){
			if(!poLineItemIdToQuantity.containsKey(s.PO_Line_Item__c)){
				poLineItemIdToQuantity.put(s.PO_Line_Item__c, 0);
			}
			poLineItemIdToQuantity.put(s.PO_Line_Item__c, poLineItemIdToQuantity.get(s.PO_Line_Item__c) + s.Shipped_Quantity_Actual__c);

			if( poLineItemIdToQuantity.get(s.PO_Line_Item__c) == s.PO_Line_Item__r.Total_Shipment_Quantity__c){
				soIds.add(s.PO_Line_Item__r.SO_Line_Item__c);
			}
			
		}
		system.debug('sli = ' + sli);
		system.debug('soIds = ' + soIds);
		list<SO_Line_Items__c> itemsWithNoShipment = [select id, Sales_Order__c from SO_Line_Items__c where Sales_Order__c in :relatedSO and id not in :soIds and Products__r.Non_Furniture_Product__c = false and Shipped_with_Fedex__c = false and Item__c != 'Cancelled' and Manufacturer__c != 'Protection Plan' and (Products__r.RecordTypeId != :Schema.SObjectType.Products__c.getRecordTypeInfosByName().get('Bundled').getRecordTypeId() or Bundle_Item__c != null)];// ignore budles 1.25 meeting
		system.debug('itemsWithNoShipment = ' + itemsWithNoShipment);
		
		Map<Id, Sales_Order__c> orderToUpdateMap = new Map<Id, Sales_Order__c>();
		for (Shipment__c s : shipmentToSend){
			system.debug('s = ' + s);
			system.debug('itemsWithNoShipment.size() = ' + itemsWithNoShipment.size());
			system.debug('s.Delivery_Company__r.DispatchTrack_Account_ID__c = ' + s.Delivery_Company__r.DispatchTrack_Account_ID__c);
    		if (s.Delivery_Company__r.DispatchTrack_Account_ID__c != null ){
            	if(!System.isBatch() && !System.isFuture()) DispatchManager.sendShipmentToDispatch(s.id, status != '' ? status == 'On hold' ? true : false : itemsWithNoShipment.size() > 0 ? true : false, s.Delivery_Company__r.DispatchTrack_business_code__c, s.Delivery_Company__r.DispatchTrack_location_code__c, s.Delivery_Company__r.DispatchTrack_Account_ID__c);
            }
    		else if (s.Delivery_Company__r.Fidelitone_hub_number__c != null){
            	if(!System.isBatch() && !System.isFuture()) FidelitoneManager.placeOrder(s.id, status != '' ? status == 'On hold' ? true : false : itemsWithNoShipment.size() > 0 ? true : false, s.Delivery_Company__r.Fidelitone_hub_number__c, isUpdate);
            }
            else if (s.Delivery_Company__r.IDS_hub_number__c != null){
            	if(!System.isBatch() && !System.isFuture()) IDSManager.placeOrder(s.id, status != '' ? status == 'On hold' ? true : false : itemsWithNoShipment.size() > 0 ? true : false, s.Delivery_Company__r.IDS_hub_number__c, isUpdate, true, false, false, false);
            }
            else if (s.Delivery_Company__r.G_G_hub_number__c != null){
            	if(!System.isBatch() && !System.isFuture()) IDSManager.placeOrder(s.id, status != '' ? status == 'On hold' ? true : false : itemsWithNoShipment.size() > 0 ? true : false, string.valueof(s.Delivery_Company__r.G_G_hub_number__c), isUpdate, false, true, false, false);
            }
            else if (s.Delivery_Company__r.Deliveright_hub_number__c != null){
            	if(!System.isBatch() && !System.isFuture()) IDSManager.placeOrder(s.id, status != '' ? status == 'On hold' ? true : false : itemsWithNoShipment.size() > 0 ? true : false, s.Delivery_Company__r.Deliveright_hub_number__c, isUpdate, false, false, true, false);
            }
            else if (s.Delivery_Company__r.P2P_hub_number__c != null){
            	if(!System.isBatch() && !System.isFuture()) IDSManager.placeOrder(s.id, status != '' ? status == 'On hold' ? true : false : itemsWithNoShipment.size() > 0 ? true : false, s.Delivery_Company__r.P2P_hub_number__c, isUpdate, false, false, false, true);
			}
			Sales_Order__c so = new Sales_Order__c();
			if (status == ''){
				so.Id = s.Related_Sales_Order__c;
				so.Delivery_company_status__c = itemsWithNoShipment.size() > 0 ? 'On hold' : 'Ready for delivery';
			}
			if (s.Related_Sales_Order__r.Retail_Value_Sent_to_Delivery_Company__c == null && (status == 'Ready for delivery' || so.Delivery_company_status__c == 'Ready for delivery')){
				so.Id = s.Related_Sales_Order__c;
				so.Retail_Value_Sent_to_Delivery_Company__c = s.Related_Sales_Order__r.Retail_Value_for_Delivery_Company__c;
			}
			if(so.Id != null){
				orderToUpdateMap.put(so.Id, so);
			}

		}
		if(orderToUpdateMap.size() > 0){
			update orderToUpdateMap.values();
		}
		System.debug('sendToDelivery end');
	}

	
	private static void updateSalesOrders(list<string> salesOrderIds){
		list<Sales_Order__c> sos = [select id, First_Shipment_Date__c from Sales_Order__c where id in :salesOrderIds and First_Shipment_Date__c = null];
		if (sos.size() == 0) return;
		for (Sales_Order__c so : sos){
			so.First_Shipment_Date__c = system.now();
		}
		update sos;
	}


	public static void shareSalesOrderProcess(Map<Id, Shipment__c> oldShipmentMap, List<Shipment__c> newShipmentList){
		Map<Id, Set<Id>> accountIdToOrdersIdToShareMap = new Map<Id, Set<Id>>();
		Map<Id, Set<Id>> accountIdToOrdersIdToUnShareMap = new Map<Id, Set<Id>>();
		
		for(Shipment__c shipment_i : newShipmentList){
			if(shipment_i.Delivery_Company__c != null && ( oldShipmentMap == null || oldShipmentMap.get(shipment_i.Id).Delivery_Company__c != shipment_i.Delivery_Company__c)){
				if(!accountIdToOrdersIdToShareMap.containsKey(shipment_i.Delivery_Company__c )){
					accountIdToOrdersIdToShareMap.put(shipment_i.Delivery_Company__c, new Set<Id>());
				}
				accountIdToOrdersIdToShareMap.get(shipment_i.Delivery_Company__c).add(shipment_i.Related_Sales_Order__c );
			}
			if(oldShipmentMap != null && oldShipmentMap.get(shipment_i.Id).Delivery_Company__c != shipment_i.Delivery_Company__c){
				if(!accountIdToOrdersIdToUnShareMap.containsKey(oldShipmentMap.get(shipment_i.Id).Delivery_Company__c  )){
					accountIdToOrdersIdToUnShareMap.put(oldShipmentMap.get(shipment_i.Id).Delivery_Company__c , new Set<Id>());
				}
				accountIdToOrdersIdToUnShareMap.get(oldShipmentMap.get(shipment_i.Id).Delivery_Company__c ).add(shipment_i.Related_Sales_Order__c );
			}
		}

		Set<Id> accountIdSet = new Set<Id>();
		if(accountIdToOrdersIdToShareMap.size() > 0){
			accountIdSet.addAll(accountIdToOrdersIdToShareMap.keySet());
		}
		if(accountIdToOrdersIdToUnShareMap.size() > 0){
			accountIdSet.addAll(accountIdToOrdersIdToUnShareMap.keySet());
		}
		if(accountIdSet.size() > 0){
			for(Account account_i : [SELECT Id, ParentId FROM Account WHERE ID IN :accountIdSet AND ParentId != null]){
				accountIdSet.add(account_i.ParentId);
				if(accountIdToOrdersIdToShareMap.containsKey(account_i.Id)){
					accountIdToOrdersIdToShareMap.put(account_i.ParentId, accountIdToOrdersIdToShareMap.get(account_i.Id));
				}
				if(accountIdToOrdersIdToUnShareMap.containsKey(account_i.Id)){
					accountIdToOrdersIdToUnShareMap.put(account_i.ParentId, accountIdToOrdersIdToUnShareMap.get(account_i.Id));
				}
			}
			List<User> userList = [SELECT Id, AccountId, UserRoleId, UserRole.Name FROM User WHERE AccountId IN :accountIdSet AND UserRoleId != null ];//AND  UserRole.Name LIKE '%executive%'
			Map<Id, Id> accountIdToRoleIdMap = new Map<Id, Id>();
			Set<Id> userRoleIdSet = new Set<Id>();

			Map<Id, Id> accountIdToNotExecutiveRoleIdMap = new Map<Id, Id>();
			for(User user_i : userList){
				if(user_i.UserRole.Name.containsIgnoreCase('executive') ){
					accountIdToRoleIdMap.put(user_i.AccountId, user_i.UserRoleId);
					userRoleIdSet.add(user_i.UserRoleId);
				}else{
					if(!accountIdToNotExecutiveRoleIdMap.containsKey(user_i.AccountId)){
						accountIdToNotExecutiveRoleIdMap.put(user_i.AccountId, user_i.UserRoleId);
					}
				}	
			}
			if(accountIdToNotExecutiveRoleIdMap.size() > 0){
				Map<Id, Id> additionalAccountIdToRoleIdMap = obtainExcecutiveRoles(accountIdToNotExecutiveRoleIdMap);
				if(additionalAccountIdToRoleIdMap.size() > 0){
					accountIdToRoleIdMap.putAll(additionalAccountIdToRoleIdMap);
					userRoleIdSet.addAll(additionalAccountIdToRoleIdMap.values());
				}
			}
			Map<Id, Id> roleIdToGroupIdMap = new Map<Id, Id>();
			if(accountIdToRoleIdMap.size() > 0){
				for(Group group_i : [SELECT Id, Name, RelatedId FROM Group WHERE RelatedId IN :userRoleIdSet and Type = 'RoleAndSubordinates' AND RelatedId != null ]){
					roleIdToGroupIdMap.put(group_i.RelatedId, group_i.Id);
				}
			}
			if(accountIdToOrdersIdToUnShareMap.size() > 0){
				unShareSORecords(accountIdToOrdersIdToUnShareMap, accountIdToRoleIdMap, roleIdToGroupIdMap);
			}
			if(accountIdToOrdersIdToShareMap.size() > 0){
				shareSORecords(accountIdToOrdersIdToShareMap, accountIdToRoleIdMap, roleIdToGroupIdMap);
			}
		}
	}
	static Map<Id, Id> obtainExcecutiveRoles(Map<Id, Id> accountIdToNotExecutiveRoleIdMap){
		Map<Id, Id> accountIdToRoleIdMap = new Map<Id, Id>();
		Map<Id, UserRole> roleMapMap = new Map<Id, UserRole>([SELECT Id, Name, ParentRoleId FROM UserRole]);
		for(Id accountId_i : accountIdToNotExecutiveRoleIdMap.keySet()){
			Id ecxecutiveRoleId = findExecutiveRole(accountIdToNotExecutiveRoleIdMap.get(accountId_i), roleMapMap);
			if(ecxecutiveRoleId != null){
				accountIdToRoleIdMap.put(accountId_i, ecxecutiveRoleId);
			}
		}

		return accountIdToRoleIdMap;
	}

	static Id findExecutiveRole(Id roleId, Map<Id, UserRole> roleMapMap){
		if(roleMapMap.containsKey(roleId)){
			if(roleMapMap.get(roleId).Name.containsIgnoreCase('executive') ){
				return roleId;
			}else if(roleMapMap.get(roleId).ParentRoleId != null){
				return findExecutiveRole(roleMapMap.get(roleId).ParentRoleId, roleMapMap);
			}
		}
		return null;
	}

	static void unShareSORecords(Map<Id, Set<Id>> accountIdToOrdersIdToUnShareMap, Map<Id, Id> accountIdToRoleIdMap, Map<Id, Id> roleIdToGroupIdMap ){
		Set<Id> groupIdSet = new Set<Id>();
		Set<Id> salesOrderIdSet = new Set<Id>();
		Set<String> groupIdToSalesOrderSet = new Set<String>();
		for(Id accountId_i : accountIdToOrdersIdToUnShareMap.keySet()){
			if(accountIdToRoleIdMap.containsKey(accountId_i) && roleIdToGroupIdMap.containsKey(accountIdToRoleIdMap.get(accountId_i))){
				Id accountGroupId = roleIdToGroupIdMap.get(accountIdToRoleIdMap.get(accountId_i));
				groupIdSet.add(accountGroupId);
				for(Id salesOrderId_i : accountIdToOrdersIdToUnShareMap.get(accountId_i)){
					salesOrderIdSet.add(salesOrderId_i);
					String key = accountGroupId + '_' + salesOrderId_i;
					groupIdToSalesOrderSet.add(key);
				}
			}
		}
		List<Sales_Order__Share> sharesToDeleteList = new List<Sales_Order__Share>();
		for(Sales_Order__Share share_i : [SELECT Id, ParentId, UserOrGroupId FROM Sales_Order__Share WHERE ParentId IN :salesOrderIdSet AND UserOrGroupId IN :groupIdSet]){
			String key = share_i.UserOrGroupId + '_' + share_i.ParentId;
			if(groupIdToSalesOrderSet.contains(key)){
				sharesToDeleteList.add(share_i);
			}
		}
		if(sharesToDeleteList.size() > 0){
			delete sharesToDeleteList;
		}
	}
	static void shareSORecords(Map<Id, Set<Id>> accountIdToOrdersIdToShareMap, Map<Id, Id> accountIdToRoleIdMap, Map<Id, Id> roleIdToGroupIdMap){
		List<Sales_Order__Share> sharesToInsertList = new List<Sales_Order__Share>();
		for(Id accountId_i : accountIdToOrdersIdToShareMap.keySet()){
			if(accountIdToRoleIdMap.containsKey(accountId_i) && roleIdToGroupIdMap.containsKey(accountIdToRoleIdMap.get(accountId_i))){
				Id accountGroupId = roleIdToGroupIdMap.get(accountIdToRoleIdMap.get(accountId_i));
				for(Id salesOrderId_i : accountIdToOrdersIdToShareMap.get(accountId_i)){
					Sales_Order__Share orderShare = new Sales_Order__Share();
					orderShare.ParentId = salesOrderId_i;
					orderShare.UserOrGroupId = accountGroupId;
					orderShare.AccessLevel = 'Edit';
					orderShare.RowCause = Schema.Sales_Order__Share.RowCause.Manual;
					sharesToInsertList.add(orderShare);	
				}
			}
		}
		if(sharesToInsertList.size() > 0){
			insert sharesToInsertList;
		}
	}

	static void shipNotificationToAshley(List<Shipment__c> newShipmentList, Map<Id, Shipment__c> oldShipmentMap) {
		Map<Id, Purchase_Order__c> purchaseOrderMap = new Map<Id, Purchase_Order__c>();
		List<String> shipmentIdToCheckAccountList = new List<String> ();
		List<String> populatedTrackingNumberShipmentIdList = new List<String> ();
		
		for (Shipment__c currentShipment_i : newShipmentList) {
			Shipment__c oldShipment = oldShipmentMap != null ? oldShipmentMap.get(currentShipment_i.Id) : null;

			if(( currentShipment_i.Pickup_Date_Actual__c != null && (oldShipment == null || oldShipment.Pickup_Date_Actual__c == null) /* currentShipment_i.Pickup_Date_Actual__c  */) 
			|| (currentShipment_i.Pickup_Date_Expected__c != null && (oldShipment == null || oldShipment.Pickup_Date_Expected__c == null) )  ) {
				shipmentIdToCheckAccountList.add(currentShipment_i.Id);
			}
			if(oldShipmentMap != null && oldShipment.Tracking_Number__c == null && currentShipment_i.Delivery_Company__c == null && currentShipment_i.Carrier_Name__c != null && currentShipment_i.Tracking_Number__c != null ){
				populatedTrackingNumberShipmentIdList.add(currentShipment_i.Id);
			}
		}
		List<Shipment__c> shipmentToUpdateList = new List<Shipment__c>();
		for (Shipment__c currentShipment_i : [SELECT Purchase_Order__c, Delivery_Company__c, Carrier_Name__c, Tracking_Number__c, Purchase_Order__r.Ship_From__c,Purchase_Order__r.Ship_From__r.name
											FROM Shipment__c
											WHERE  Related_Sales_Order__r.Manufacturer__r.Exclude_from_auto_ship_notification__c = false AND 
											(Id IN :shipmentIdToCheckAccountList 
											OR (Id IN :populatedTrackingNumberShipmentIdList AND Purchase_Order__r.Fedex_Non_Tracking_Email__c = true ) )]) {
			
			Purchase_Order__c currentPurchaseOrder = purchaseOrderMap.containsKey(currentShipment_i.Purchase_Order__c) ? purchaseOrderMap.get(currentShipment_i.Purchase_Order__c) : new Purchase_Order__c(Id = currentShipment_i.Purchase_Order__c);
			Boolean validationFlag = false;
			if (String.isNotBlank(currentShipment_i.Delivery_Company__c) && String.isBlank(currentShipment_i.Carrier_Name__c)) {
				currentPurchaseOrder.En_Route_Email__c = true;
				validationFlag = true;
			/*} else if (String.isBlank(currentShipment_i.Delivery_Company__c) && String.isNotBlank(currentShipment_i.Carrier_Name__c) && String.isNotBlank(currentShipment_i.Tracking_Number__c) && currentShipment_i.Purchase_Order__r.Ship_From__c != null && currentShipment_i.Purchase_Order__r.Ship_From__r.name.contains('Ashley')) {
				currentPurchaseOrder.Send_Shipment_Notification_to_Customer__c = true;
				currentShipment_i.Shipment_notification_sent_to_customer__c = DateTime.now();
				shipmentToUpdateList.add(currentShipment_i);
				validationFlag = true;*/
			} else if (String.isBlank(currentShipment_i.Delivery_Company__c) && String.isNotBlank(currentShipment_i.Carrier_Name__c) && String.isNotBlank(currentShipment_i.Tracking_Number__c)) {
				currentPurchaseOrder.Send_Shipment_Notification_in_15_min__c = system.now();
				validationFlag = true;
			} else if (String.isBlank(currentShipment_i.Delivery_Company__c) && String.isNotBlank(currentShipment_i.Carrier_Name__c) && String.isBlank(currentShipment_i.Tracking_Number__c)) {
				currentPurchaseOrder.Fedex_Non_Tracking_Email__c = true;
				validationFlag = true;
			}			
			if(validationFlag) {
				purchaseOrderMap.put(currentPurchaseOrder.Id, currentPurchaseOrder);
			}						
		}
		if (!purchaseOrderMap.isEmpty()){
			update shipmentToUpdateList;
			update purchaseOrderMap.values();
		}

	}
	
	static void changeSalesOrderSendGuardian (List<Shipment__c> newShipmentList, Map<Id, Shipment__c> oldShipmentMap) {
		Boolean isInsert = false;
		Set<String> shipmentStatusSet = new Set<String> {'Received By Warehouse', 'Time and Date Scheduled', 'Delivered No Issues'};
		Map<Id, Sales_Order__c> orderToUpdateMap = new Map<Id, Sales_Order__c>();
		for(Shipment__c currentShipment_i : [SELECT Id, Shipment_Status__c, Related_Sales_Order__c, Related_Sales_Order__r.Guardian_Number__c, Related_Sales_Order__r.Guardian_response__c
											FROM Shipment__c
											WHERE Id IN :newShipmentList AND Related_Sales_Order__r.Plan_code__c != null AND Related_Sales_Order__r.Payment_Status__c != 'Capture-Failed'AND Related_Sales_Order__r.Payment_Status__c != 'Capture-Failed' AND Related_Sales_Order__r.Order_Status__c != 'Canceled' AND Related_Sales_Order__r.Order_Status__c != 'Cancelled - Delivery area' AND Related_Sales_Order__r.Order_Status__c != 'Cancelled - No Payment' AND Related_Sales_Order__r.Order_Status__c != 'Cancelled - Underpriced' AND Related_Sales_Order__r.Protection_Plan_included__c = True AND Related_Sales_Order__r.Guardian_Number__c = null AND (Shipment_Status__c IN :shipmentStatusSet 
											OR (Shipment_Status__c = 'En Route Shipments' AND Carrier__c = 'LTL') )]) {
			if(String.isBlank(currentShipment_i.Related_Sales_Order__r.Guardian_response__c)
			&& String.isBlank(currentShipment_i.Related_Sales_Order__r.Guardian_Number__c)
			&& (shipmentStatusSet.contains(currentShipment_i.Shipment_Status__c) || currentShipment_i.Shipment_Status__c == 'En Route Shipments')
			&& !orderToUpdateMap.containsKey(currentShipment_i.Related_Sales_Order__c)
			&& (oldShipmentMap == null || (oldShipmentMap.get(currentShipment_i.Id).Shipment_Status__c != currentShipment_i.Shipment_Status__c) )) {
				orderToUpdateMap.put(currentShipment_i.Related_Sales_Order__c, new Sales_Order__c(Id = currentShipment_i.Related_Sales_Order__c, Send_Guardian__c = true));
			}
		}
		update orderToUpdateMap.values();
	}
	
	/*private static void shareRecords(List<Id> accIdList, List<Shipment__c> newShipment){
		List<Id> contactIdList = new List<Id>();

		Map<Id, list<id>> accountToContactMap = new Map<Id, list<id>>();
		Map<Id, Id> contactToUserMap = new Map<Id, Id>();
		map<string, string> parentAccountByChildAccountId = new map<string, string>();

		list<Account> parentAccounts = [select id, parentid from account where parentid != null and id in :accIdList];
		for (Account acc : parentAccounts){
			parentAccountByChildAccountId.put(acc.id, acc.parentid);
		}
		
		System.debug('accIdList: ' + accIdList);
		List<Contact> contactList = [SELECT Id, Account.Id FROM Contact WHERE Account.Id IN :accIdList or  Account.Id IN :parentAccountByChildAccountId.values()];
		System.debug('contactList: ' + contactList); 

		for(Contact contact: contactList) {
			contactIdList.add(contact.Id);
			if (!accountToContactMap.containskey(contact.AccountId)){
				accountToContactMap.put(contact.AccountId, new list<id>());
			}
			accountToContactMap.get(contact.AccountId).add(contact.Id);
		}

		List<User> userList = [SELECT Id, ContactId FROM User WHERE ContactId IN :contactIdList and isactive = true];
		System.debug('userList: ' + userList);
		for(User user: userList) {
			contactToUserMap.put(user.ContactId, user.Id);
		}

		List<Sales_Order__Share> shareList = new List<Sales_Order__Share>();
		for(Shipment__c ship : newShipment){
            if(accountToContactMap.get(ship.Delivery_Company__c) != null){
                for (string contactId : accountToContactMap.get(ship.Delivery_Company__c)){
                    System.debug('contactId: ' + contactId);
                    String userId = contactToUserMap.get(contactId);
                    System.debug('userId: ' + userId);
                    if(userId != null && ship.Related_Sales_Order__c != null) {
                        Sales_Order__Share orderShare = new Sales_Order__Share();
                        orderShare.ParentId = ship.Related_Sales_Order__c;
                        orderShare.UserOrGroupId = userId;
                        orderShare.AccessLevel = 'Edit';
                        orderShare.RowCause = Schema.Sales_Order__Share.RowCause.Manual;
                        shareList.add(orderShare);	
                    }
                    if (parentAccountByChildAccountId.containskey(ship.Delivery_Company__c) && accountToContactMap.containskey(parentAccountByChildAccountId.get(ship.Delivery_Company__c))){
                        for (string contactIdStr : accountToContactMap.get(parentAccountByChildAccountId.get(ship.Delivery_Company__c))){
                            if (contactToUserMap.containskey(contactIdStr)){
                                userId = contactToUserMap.get(contactIdStr);
                                if(userId != null) {
                                    Sales_Order__Share orderShare = new Sales_Order__Share();
                                    orderShare.ParentId = ship.Related_Sales_Order__c;
                                    orderShare.UserOrGroupId = userId;
                                    orderShare.AccessLevel = 'Edit';
                                    orderShare.RowCause = Schema.Sales_Order__Share.RowCause.Manual;
                                    shareList.add(orderShare);	
                                }
                            }
                        }
                    }
                }
            }
		}
		insert shareList;
	}

	private static void updateSOSharing(List<Shipment__c> newShipmentList){
		Set<Id> accountIdSet = new Set<Id>(); 
		Set<Id> allAccountIdSet = new Set<Id>(); 
		Set<Id> prevAccountIdSet = new Set<Id>(); 
		Set<Id> salesOrderIdSet = new Set<Id>(); 
		map<string, string> parentAccountByChildAccountId = new map<string, string>();
		for(Shipment__c shipment: newShipmentList) {
			if(shipment.Delivery_Company__c != null){
				allAccountIdSet.add(shipment.Delivery_Company__c);
			}
			if(((Shipment__c)trigger.oldMap.get(shipment.Id)).Delivery_Company__c != null){
				allAccountIdSet.add(((Shipment__c)trigger.oldMap.get(shipment.Id)).Delivery_Company__c);
			}
		}
		system.debug('allAccountIdSet = ' + allAccountIdSet);
		list<Account> parentAccounts = [select id, parentid from account where parentid != null and id in :allAccountIdSet];
		system.debug('parentAccounts = ' + parentAccounts);
		for (Account acc : parentAccounts){
			parentAccountByChildAccountId.put(acc.id, acc.parentid);
		}
		system.debug('parentAccountByChildAccountId = ' + parentAccountByChildAccountId);
		for(Shipment__c shipment: newShipmentList) {
				
				if(shipment.Delivery_Company__c != null){
					system.debug('shipment.Delivery_Company__c = ' + shipment.Delivery_Company__c);
					system.debug('parentAccountByChildAccountId.containskey(shipment.Delivery_Company__c = ' + parentAccountByChildAccountId.containskey(shipment.Delivery_Company__c));
					accountIdSet.add(shipment.Delivery_Company__c);
					if (parentAccountByChildAccountId.containskey(shipment.Delivery_Company__c)){
						accountIdSet.add(parentAccountByChildAccountId.get(shipment.Delivery_Company__c));
					}
				}
				
				if(((Shipment__c)trigger.oldMap.get(shipment.Id)).Delivery_Company__c != null){
					prevAccountIdSet.add(((Shipment__c)trigger.oldMap.get(shipment.Id)).Delivery_Company__c);
					if (parentAccountByChildAccountId.containskey(((Shipment__c)trigger.oldMap.get(shipment.Id)).Delivery_Company__c)){
						prevAccountIdSet.add(parentAccountByChildAccountId.get(((Shipment__c)trigger.oldMap.get(shipment.Id)).Delivery_Company__c));
					}
				}
				if(shipment.Related_Sales_Order__c != null){
					salesOrderIdSet.add(shipment.Related_Sales_Order__c);
				}
		}
		system.debug('accountIdSet = ' + accountIdSet);
		Map<Id, List<Id>> accountIdTouserMap = new Map<Id, List<Id>>();
		Map<Id, List<Id>> prevaccountIdTouserMap = new Map<Id, List<Id>>();
		Set<Id> prevUserIdSet = new Set<Id>();
		Set<Id> parentAccountIdSet = new Set<Id>();
		for(User user_i :  [SELECT Id, Contact.AccountId FROM User WHERE (Contact.AccountId IN :accountIdSet OR Contact.AccountId IN :prevAccountIdSet) AND isactive = true]){
			system.debug('user_i = ' + user_i);
			if(accountIdSet.contains(user_i.Contact.AccountId)){
				if(!accountIdTouserMap.containsKey(user_i.Contact.AccountId)){
					accountIdTouserMap.put(user_i.Contact.AccountId, new List<Id>());
				}
				accountIdTouserMap.get(user_i.Contact.AccountId).add(user_i.Id);
			}else if(prevAccountIdSet.contains(user_i.Contact.AccountId)){
				if(!prevaccountIdTouserMap.containsKey(user_i.Contact.AccountId)){
					prevaccountIdTouserMap.put(user_i.Contact.AccountId, new List<Id>());
				}
				prevaccountIdTouserMap.get(user_i.Contact.AccountId).add(user_i.Id);
				prevUserIdSet.add(user_i.Id);
			}
			
		}
		system.debug('accountIdTouserMap = ' + accountIdTouserMap);
		Map<String, Sales_Order__Share> prevSharingMap = new Map<String, Sales_Order__Share>();
		for(Sales_Order__Share share_i : [SELECT Id, ParentId, UserOrGroupId  FROM Sales_Order__Share WHERE ParentId IN :salesOrderIdSet AND UserOrGroupId IN: prevUserIdSet]){
			String key = share_i.UserOrGroupId +'-'+share_i.ParentId;
			prevSharingMap.put(key, share_i);
		}
		List<Sales_Order__Share> shareToInsertList = new List<Sales_Order__Share>();
		List<Sales_Order__Share> shareToDeleteList = new List<Sales_Order__Share>();

		for(Shipment__c shipment: newShipmentList) {
				
		system.debug('shipment.Delivery_Company__c = ' + shipment.Delivery_Company__c);
		system.debug('shipment.Related_Sales_Order__c = ' + shipment.Related_Sales_Order__c);
		system.debug('accountIdTouserMap.containsKey(shipment.Delivery_Company__c) = ' + accountIdTouserMap.containsKey(shipment.Delivery_Company__c));
		system.debug('accountIdTouserMap = ' + accountIdTouserMap.containskey(parentAccountByChildAccountId.get(shipment.Delivery_Company__c)));
				if(shipment.Delivery_Company__c != null && shipment.Related_Sales_Order__c != null && (accountIdTouserMap.containsKey(shipment.Delivery_Company__c) || accountIdTouserMap.containskey(parentAccountByChildAccountId.get(shipment.Delivery_Company__c)))){
					if(accountIdTouserMap.containsKey(shipment.Delivery_Company__c)){
						for(Id userId_i : accountIdTouserMap.get(shipment.Delivery_Company__c)){
							Sales_Order__Share orderShare = new Sales_Order__Share();
							orderShare.ParentId = shipment.Related_Sales_Order__c;
							orderShare.UserOrGroupId = userId_i;
							orderShare.AccessLevel = 'Edit';
							orderShare.RowCause = Schema.Sales_Order__Share.RowCause.Manual;
							shareToInsertList.add(orderShare);
						}
					}
					if (accountIdTouserMap.containskey(parentAccountByChildAccountId.get(shipment.Delivery_Company__c))){
						for(Id userId_i : accountIdTouserMap.get(parentAccountByChildAccountId.get(shipment.Delivery_Company__c))){
							Sales_Order__Share orderShare = new Sales_Order__Share();
							orderShare.ParentId = shipment.Related_Sales_Order__c;
							orderShare.UserOrGroupId = userId_i;
							orderShare.AccessLevel = 'Edit';
							orderShare.RowCause = Schema.Sales_Order__Share.RowCause.Manual;
							shareToInsertList.add(orderShare);
						}
					}
				if(shipment.Related_Sales_Order__c != null && ((Shipment__c)trigger.oldMap.get(shipment.Id)).Delivery_Company__c != null && (prevaccountIdTouserMap.containsKey(((Shipment__c)trigger.oldMap.get(shipment.Id)).Delivery_Company__c )  || prevaccountIdTouserMap.containskey(parentAccountByChildAccountId.get(((Shipment__c)trigger.oldMap.get(shipment.Id)).Delivery_Company__c)))){
                    if(prevaccountIdTouserMap.containsKey(((Shipment__c)trigger.oldMap.get(shipment.Id)).Delivery_Company__c)){
                        for(Id userId_i : prevaccountIdTouserMap.get(((Shipment__c)trigger.oldMap.get(shipment.Id)).Delivery_Company__c)){
                            String key = userId_i +'-'+shipment.Related_Sales_Order__c;
                            if(prevSharingMap.containsKey(key)){
                                shareToDeleteList.add(prevSharingMap.get(key));
                            }
                        }
                    }
					if (prevaccountIdTouserMap.containskey(parentAccountByChildAccountId.get(((Shipment__c)trigger.oldMap.get(shipment.Id)).Delivery_Company__c))){
						for(Id userId_i : prevaccountIdTouserMap.get(parentAccountByChildAccountId.get(((Shipment__c)trigger.oldMap.get(shipment.Id)).Delivery_Company__c))){
							String key = userId_i +'-'+shipment.Related_Sales_Order__c;
							if(prevSharingMap.containsKey(key)){
								shareToDeleteList.add(prevSharingMap.get(key));
							}
						}
					}
				}
			}
		}
		if(shareToDeleteList.size() > 0){
			delete shareToDeleteList;
		}
		if(shareToInsertList.size() > 0){
			insert shareToInsertList;
		}
	}*/
	private static void checkAndFillOrderNumber(List<Shipment__c> shipmentList) {
        Set<Id> salesOrderIdSet = new Set<Id>();
        
        for (Shipment__c shipment_i : shipmentList) {
            if (string.isEmpty(shipment_i.Magento_Order_Number_Searchable__c) && string.isNotEmpty(shipment_i.Related_Sales_Order__c)) {
                salesOrderIdSet.add(shipment_i.Related_Sales_Order__c);
            }
        }
        if (!salesOrderIdSet.isEmpty()) {
            Map<Id, Sales_Order__c> salesOrderMap = new Map<Id, Sales_Order__c>([SELECT Id, Magento_order_No__c FROM Sales_Order__c WHERE Id IN :salesOrderIdSet]);
            
            for (Shipment__c shipment_i : shipmentList) {
                if (string.isEmpty(shipment_i.Magento_Order_Number_Searchable__c) && salesOrderMap.containsKey(shipment_i.Related_Sales_Order__c)) {
                    shipment_i.Magento_Order_Number_Searchable__c = salesOrderMap.get(shipment_i.Related_Sales_Order__c).Magento_order_No__c;
                }
            }
        }

    }
    
    private static void updateReasonOnShipmentList(List<Shipment__c> shipmentList, String status) {
        for (Shipment__c shipment_i : shipmentList) {
            shipment_i.Reason_it_was_not_sent_to_the_delivery_c__c = status;
        }
        doNotUpdate = true;
        update shipmentList;
    }
}