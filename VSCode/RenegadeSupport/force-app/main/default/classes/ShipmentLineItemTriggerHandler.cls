/**
 * @File Name          : ShipmentLineItemTriggerHandler.apxc
 * @Description        : 
 * @Author             : Synebo
 * @Group              : 
 * @Last Modified By   : Synebo
 * @Last Modified On   : 09-15-2020
 * @Modification Log   : 
 *==============================================================================
 * Ver         Date                     Author      		      Modification
 *==============================================================================
 * 1.0    8/15/2019, 1:52:40 PM   nick@bkonect.com     Initial Version
**/
public without sharing class ShipmentLineItemTriggerHandler {
	static Boolean isInventoryNotRun = true;
	static Set<String> retaggedStatusSet = new Set<String>{'Retagged', 'Retag in process'};
	static Set<String> stockStatusSet = new Set<String>{'Hold As Stock', 'Enroute - Pending Hold As Stock'};
	static Set<String> furnitureStatusSet = new Set<String>{'Opened', 'Unopened'};

	public static void beforeInsert(list<Shipment_Line_Item__c> newShipmentli){
		Set<Id> sliToUpdateProductNamePOLIID = new Set<Id>();
		Set<Id> poLineIdSet = new Set<Id>();
		for (Shipment_Line_Item__c sli : newShipmentli){
			if (sli.Shipment_Product_Name__c == null || sli.Shipment_Product_Name__c == '' || sli.Shipment_Product_Name__c == 'null'){
				sliToUpdateProductNamePOLIID.add(sli.PO_Line_Item__c);
			}
			if(sli.PO_Line_Item__c != null){
				poLineIdSet.add(sli.PO_Line_Item__c);
			}
		}
		if (poLineIdSet.size() > 0){
			map<id, PO_Line_Items__c>  poLines = new map<id, PO_Line_Items__c>([select id, Product__c, Originating_Inventory_SHL__c,  Inventory__c, Originating_Inventory_SHL__r.Inventory__c,  Purchase_Order__r.RecordType.DeveloperName from PO_Line_Items__c where id in :poLineIdSet]);
			Set<Id> inventoryIdSet = new Set<Id>();
			for(Id po_id : poLines.keySet()){
				if(poLines.get(po_id).Inventory__c != null) {
					inventoryIdSet.add(poLines.get(po_id).Inventory__c );
				}
			}
			Map<Id, Map<String, List<Id>>> inventoryIdToSKUandShLineIdMap = new Map<Id, Map<String, List<Id>>>();
			for(Shipment_Line_Item__c sl_i: [SELECT Id, Inventory__c, Shipment_Product_SKU__c FROM Shipment_Line_Item__c WHERE Inventory__c IN : inventoryIdSet AND  Shipment_Item_Status__c IN :retaggedStatusSet ]){
				if(!inventoryIdToSKUandShLineIdMap.containsKey(sl_i.Inventory__c)){
					inventoryIdToSKUandShLineIdMap.put(sl_i.Inventory__c, new Map<String, List<Id>>());
				}
				if(!inventoryIdToSKUandShLineIdMap.get(sl_i.Inventory__c).containsKey(sl_i.Shipment_Product_SKU__c)){
					inventoryIdToSKUandShLineIdMap.get(sl_i.Inventory__c).put(sl_i.Shipment_Product_SKU__c, new List<Id>());
				}
				inventoryIdToSKUandShLineIdMap.get(sl_i.Inventory__c).get(sl_i.Shipment_Product_SKU__c).add(sl_i.id);
			}
            System.debug(inventoryIdToSKUandShLineIdMap);
			for (Shipment_Line_Item__c sli : newShipmentli){
				if (sliToUpdateProductNamePOLIID.contains(sli.PO_Line_Item__c) && poLines.containskey(sli.PO_Line_Item__c)){
					sli.Shipment_Product_Name__c = poLines.get(sli.PO_Line_Item__c).Product__c;
				}
                if(poLines.containskey(sli.PO_Line_Item__c) && poLines.get(sli.PO_Line_Item__c).Purchase_Order__r.RecordType.DeveloperName == 'Internal_PO' ){
                    if( poLines.get(sli.PO_Line_Item__c).Originating_Inventory_SHL__c != null){
                        sli.Taken_from_inventory__c = poLines.get(sli.PO_Line_Item__c).Originating_Inventory_SHL__r.Inventory__c;
                    }
                    if(inventoryIdToSKUandShLineIdMap.containsKey( poLines.get(sli.PO_Line_Item__c).Inventory__c) && inventoryIdToSKUandShLineIdMap.get(poLines.get(sli.PO_Line_Item__c).Inventory__c).containskey(sli.Shipment_Product_SKU__c) && inventoryIdToSKUandShLineIdMap.get(poLines.get(sli.PO_Line_Item__c).Inventory__c).get(sli.Shipment_Product_SKU__c).size() > 0){
                        sli.Originating_Inventory_SHL__c = inventoryIdToSKUandShLineIdMap.get(poLines.get(sli.PO_Line_Item__c).Inventory__c).get(sli.Shipment_Product_SKU__c)[0];
                        inventoryIdToSKUandShLineIdMap.get(poLines.get(sli.PO_Line_Item__c).Inventory__c).get(sli.Shipment_Product_SKU__c).remove(0);
                    }
                }
			}
		}
	}

	public static void beforeUpdate(Map<Id, Shipment_Line_Item__c> newShipmentLineItemMap, Map<id, Shipment_Line_Item__c> oldShipmentLineItemMap){
		checkShipmentStatus(newShipmentLineItemMap, oldShipmentLineItemMap);
	}
	
	static Map<String, Inventory_Management__c> obtainInventoryManagementSettings() {
		Map<String, Inventory_Management__c> settings = new Map<String, Inventory_Management__c>();
		for ( Inventory_Management__c currentSetting_i : Inventory_Management__c.getAll().values()) {
			settings.put(currentSetting_i.Stock_Status__c, currentSetting_i);
		}
		return settings;
	}

	static Boolean hasCommonElementInLists(Set<String> firstList, List<String> secondList) {
		return hasCommonElementInLists(firstList, new Set<String> (secondList));
	}

	static Boolean hasCommonElementInLists(Set<String> firstList, Set<String> secondSet) {
		Boolean result = false;
		for(String currentElement_i : firstList) {			
			if(secondSet.contains(currentElement_i)){
				result = true; 
				break;
			}
		}
		return result; 
	}

	public static void afterUpdate(list<Shipment_Line_Item__c> newShipmentli, map<id, Shipment_Line_Item__c> oldShipmentliMap){
		
		list<string> liIdsToUpdateParentsStatus = new list<string>();
		set<string> shipmentIdsToUpdateDropOffDate = new set<string>();
		map<string, Shipment__c> shipmentToUpdate = new map<string, Shipment__c>();
		map<string, list<Shipment_Line_Item__c>> shlInventoryUpdate = new map<string, list<Shipment_Line_Item__c>> ();
		Map<String, Inventory_Management__c> inventoryManagerSetting = obtainInventoryManagementSettings();
		Set<Id> inventoryToRecalQuantityIdSet = new Set<Id>();
		// Inventory_Management__c setting;
		// 	setting = Inventory_Management__c.getAll().containsKey('Inventory')?Inventory_Management__c.getAll().get('Inventory') : new Inventory_Management__c();
			for (Shipment_Line_Item__c sli : newShipmentli){
	            System.debug('Old SHL with ID ' + sli.id + ' status is ' + oldShipmentliMap.get(sli.id).Shipment_Item_Status__c );
	            System.debug('New SHL with ID ' + sli.id + ' status is ' + sli.Shipment_Item_Status__c );
	
				if ((sli.Shipment_Item_Status__c != oldShipmentliMap.get(sli.id).Shipment_Item_Status__c ||
					 sli.Furniture_Condition__c != oldShipmentliMap.get(sli.Id).Furniture_Condition__c ||
					 UserInfo.getFirstName() == 'API')){
	                System.debug('SHL update of ' + sli.Id + ' passed first if statement on line 34 (checking if status was changed)');
					liIdsToUpdateParentsStatus.add(sli.id);
					if ( inventoryManagerSetting.containsKey(sli.Shipment_Item_Status__c) || inventoryManagerSetting.containsKey(oldShipmentliMap.get(sli.id).Shipment_Item_Status__c)/* sli.Shipment_Item_Status__c == setting.Stock_Status__c || oldShipmentliMap.get(sli.id).Shipment_Item_Status__c == setting.Stock_Status__c */ ){
						String furnitureConditionString = '';
						if (inventoryManagerSetting.containsKey(sli.Shipment_Item_Status__c)) {
							furnitureConditionString = inventoryManagerSetting.get(sli.Shipment_Item_Status__c).Furniture_Condition__c;
						}
						else {
							furnitureConditionString = inventoryManagerSetting.get(oldShipmentliMap.get(sli.id).Shipment_Item_Status__c).Furniture_Condition__c;
						}
                        if (string.isNotEmpty(furnitureConditionString)) {
                            List<String> conditionList = furnitureConditionString.split(',');
                            if (conditionList.contains(sli.Furniture_Condition__c) ||
                                conditionList.contains(oldShipmentliMap.get(sli.Id).Furniture_Condition__c)) {
                                    System.debug('SHL update of ' + sli.Id + ' passed second if statement on line 37 (checking if old or new status is Hold As Stock');
                                    if (!shlInventoryUpdate.containskey(sli.PO_Line_Item__c)){
                                        System.debug('SHL update of ' + sli.Id + ' passed third if statement on line 39 (checking if the inventory update map doesn\'t already contain this SHL');
                                        map<string, string> statusBySHL= new map<string, string>();
                                        // statusBySHL.put(shl.Id, shl.Shipment_Item_Status__c);
                                        shlInventoryUpdate.put(sli.PO_Line_Item__c, new list<Shipment_Line_Item__c>());
                                    }
                                    shlInventoryUpdate.get(sli.PO_Line_Item__c).add(sli);
                                }
                        }
					}
					if(sli.Inventory__c != null){
						inventoryToRecalQuantityIdSet.add(sli.Inventory__c);
					}
				}
				if (sli.Drop_Off_Date_Expected__c != oldShipmentliMap.get(sli.id).Drop_Off_Date_Expected__c){
					shipmentIdsToUpdateDropOffDate.add(sli.Shipment__c);
				}
			}
		if (shipmentIdsToUpdateDropOffDate.size() > 0){
			shipmentToUpdate = updateShipmentDropOffDate(shipmentIdsToUpdateDropOffDate);
		}
		system.debug('liIdsToUpdateParentsStatus = ' + liIdsToUpdateParentsStatus);
		/*if (liIdsToUpdateParentsStatus.size() > 0){
			updateShipmentStatus(liIdsToUpdateParentsStatus, shipmentToUpdate);
		}*/
		if (shipmentToUpdate.values().size() > 0){
			update shipmentToUpdate.values();
		}
		if (liIdsToUpdateParentsStatus.size() > 0){
			updateShipmentStatus(liIdsToUpdateParentsStatus);
		}
		if (shlInventoryUpdate.size() > 0 && isInventoryNotRun){
			isInventoryNotRun = false;
            System.debug('SHL Inventory mapp larger than 0');
			createUpdateInventory(shlInventoryUpdate);
		}
		if(inventoryToRecalQuantityIdSet.size() > 0){
			recalcInventoryQuantity(inventoryToRecalQuantityIdSet);
		}
		runCaseFlow(newShipmentli);
	}

	public static void checkShipmentStatus(Map<Id, Shipment_Line_Item__c> newShipmentMap, Map<Id, Shipment_Line_Item__c> oldShipmentMap){
		try{
			Map<String, Shipment_Line_Item_status_settings__c> shipmentLineItemStatusDataMap = Shipment_Line_Item_status_settings__c.getAll();
			List<Group> queueList = new List<Group>();
			Map<String, String> entitlementTemplateNameToIdMap;
			Shipping_line_item_case_setting__c caseSettingData = Shipping_line_item_case_setting__c.getOrgDefaults();
			
			if(!shipmentLineItemStatusDataMap.isEmpty()){
				entitlementTemplateNameToIdMap = obtainEntitlementTemlateMap(shipmentLineItemStatusDataMap);
			}

			if(caseSettingData != null){
				queueList = [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND Name = :caseSettingData.Queue__c];
				//entitlementList = [SELECT Id FROM Entitlement WHERE Name = :caseSettingData.Entitlement_Template__c];
			}
			Map<id, List<Shipment_Line_Item__c>> SOIdToSipmentLineItemList = new Map<id, List<Shipment_Line_Item__c>>();
			for(Shipment_Line_Item__c currentShipment_i : newShipmentMap.values()){
				if(!SOIdToSipmentLineItemList.containsKey(currentShipment_i.Related_Sales_Order__c)){
					SOIdToSipmentLineItemList.put(currentShipment_i.Related_Sales_Order__c, new List<Shipment_Line_Item__c>());
				}

				if(oldShipmentMap.get(currentShipment_i.id).Shipment_Item_Status__c != currentShipment_i.Shipment_Item_Status__c && /*statusSet*/ shipmentLineItemStatusDataMap.containsKey(currentShipment_i.Shipment_Item_Status__c)){
					SOIdToSipmentLineItemList.get(currentShipment_i.Related_Sales_Order__c).add(currentShipment_i);
				}
			}

			boolean isEmptyList = true;
			for(List<Shipment_Line_Item__c> CurrentShipmentLineItemLisct : SOIdToSipmentLineItemList.values()){
				if(CurrentShipmentLineItemLisct.size() > 0){
					isEmptyList = false;
					break;
				}
			}
			if(isEmptyList){
				return;
			}

			Map<Id, Case> soIdToCaseMap = new Map<Id, Case>();
			Map<Id, Set<String>> caseIdToStatusListMap = populateCaseToSoMap(newShipmentMap.values(), SOIdToSipmentLineItemList.keySet(), soIdToCaseMap);
			
			Map<Id, Shipment_Line_Item__c> shipmentLineItemCustomerNameMap = new Map<Id, Shipment_Line_Item__c>(
															[SELECT Id, Shipment__r.Related_Sales_Order__c, Shipment__r.Related_Sales_Order__r.Customer_Name__r.Name
															FROM Shipment_Line_Item__c 
															WHERE Id in :newShipmentMap.values()]
															);

			Map<String, Case> caseToUpdateMap = new Map<String, Case> ();
			Map<Id, Case> soIdToNewCase = new  Map<Id, Case>(); 
			Map<Id, Set<String>> soIdToStatusSetMap = new  Map<Id, Set<String>>(); 
			for(Shipment_Line_Item__c currentShipment_i : newShipmentMap.values()){
				String currentCaseSupportType = shipmentLineItemStatusDataMap.get(currentShipment_i.Shipment_Item_Status__c).Support_Type__c;
				String shipentCustomerName = shipmentLineItemCustomerNameMap.get(currentShipment_i.Id).Shipment__r.Related_Sales_Order__r.Customer_Name__r.Name;
				if(soIdToCaseMap.containsKey(currentShipment_i.Related_Sales_Order__c)){
					Case currentCase = soIdToCaseMap.get(currentShipment_i.Related_Sales_Order__c);
					if(caseIdToStatusListMap.containsKey(currentCase.Id)){
						Set<String> statusesForCurrentCase = caseIdToStatusListMap.get(currentCase.Id).clone();
						statusesForCurrentCase.remove(currentShipment_i.Shipment_Item_Status__c);
						if( statusesForCurrentCase.size() > 0 ){
							currentCase.Subject = shipentCustomerName + ' - Multiple Issues';
							caseToUpdateMap.put(currentCase.Id, currentCase);
						}
					}
					currentShipment_i.Related_Case__c = currentCase.Id;

				}else{
					Id saleOrderId = shipmentLineItemCustomerNameMap.get(currentShipment_i.Id).Shipment__r.Related_Sales_Order__c;
					if(!soIdToStatusSetMap.containsKey(saleOrderId)){
						soIdToStatusSetMap.put(saleOrderId, new Set<String>());
					}
					
					if(!soIdToNewCase.containsKey(saleOrderId)){
						Case newCase = new Case();
						newCase.Support_Type__c = currentCaseSupportType;
						newCase.Subject = shipentCustomerName + ' - ' + currentShipment_i.Shipment_Item_Status__c ;
						newCase.Sales_Order__c = saleOrderId;
						if(!queueList.isEmpty()){
							newCase.OwnerId = queueList.get(0).Id;
						}
						if(entitlementTemplateNameToIdMap.containsKey(shipmentLineItemStatusDataMap.get(currentShipment_i.Shipment_Item_Status__c).Entitlement_Template__c)){
							newCase.EntitlementId = entitlementTemplateNameToIdMap.get(shipmentLineItemStatusDataMap.get(currentShipment_i.Shipment_Item_Status__c).Entitlement_Template__c);
						}
						soIdToNewCase.put(saleOrderId, newCase);
						soIdToStatusSetMap.get(saleOrderId).add(currentShipment_i.Shipment_Item_Status__c);	
					}else if(!soIdToStatusSetMap.get(saleOrderId).contains(currentShipment_i.Shipment_Item_Status__c) ){
						soIdToNewCase.get(saleOrderId).Subject = shipentCustomerName + ' - Multiple Issues';
					}
				}
			}	
			
			if(caseToUpdateMap.size() > 0){
				update caseToUpdateMap.values();
			}
			
			if(soIdToNewCase.size() > 0){
				System.debug('soIdToNewCase: ' + soIdToNewCase.values());
				insert soIdToNewCase.values();
				System.debug('soIdToNewCase after insert: ' + soIdToNewCase.values());
				for(Id salesOrderid_i : soIdToNewCase.keySet()){
					System.debug('soIdToNewCase in loop: ' + soIdToNewCase.values());
					Id CaseId =  soIdToNewCase.get(salesOrderid_i).Id;
					for(Shipment_Line_Item__c currentShipmentLineItem_i : SOIdToSipmentLineItemList.get(salesOrderid_i)){
						newShipmentMap.get(currentShipmentLineItem_i.id).Related_Case__c = CaseId;
					}
				}
			}
		}catch(Exception ex){
			System.debug('ShipmentLineItemTrigerHandler Error : '+ ex.getMessage() +' in line: ' + ex.getLineNumber());
		}
	}

	public static void recalcInventoryQuantity(Set<Id> inventoryToRecalQuantityIdSet){
		List<AggregateResult> maxInventoryQuantityList = [	SELECT MAX(Shipped_Quantity_Actual__c), Inventory__c 
															FROM Shipment_Line_Item__c
															WHERE Inventory__c IN :inventoryToRecalQuantityIdSet AND Furniture_Condition__c IN : furnitureStatusSet AND Shipment_Item_Status__c IN :stockStatusSet  GROUP BY  Inventory__c];
		Map<Id, Decimal> inventoryIdToQuantity = new Map<Id, Decimal>();
		for(AggregateResult result_i : maxInventoryQuantityList){
			inventoryIdToQuantity.put((Id)result_i.get('Inventory__c'), (Decimal)result_i.get('expr0') );
		}				
		List<Inventory__c> inventoryToUpdateList = new List<Inventory__c>();
		for(Id inventory_id : inventoryToRecalQuantityIdSet){
			inventoryToUpdateList.add(new Inventory__c(Id = inventory_id, Quantity__c = (inventoryIdToQuantity.containsKey(inventory_id) ? inventoryIdToQuantity.get(inventory_id) : 0)));
		}		
		update inventoryToUpdateList;							
	}
	
	private static Map<Id, Set<String>> populateCaseToSoMap(List<Shipment_Line_Item__c> newShipmentLineItemList, Set<Id> SOIdSet, Map<Id, Case> soIdToCaseMap){
		Map<Id, Set<String>> caseIdToStatusListMap = new Map<Id, Set<String>>();

		for(Case currentCase_i : [SELECT Id, Sales_Order__c, Status, Shipment__c, (SELECT Shipment_Item_Status__c FROM Shipment_Line_Items__r) FROM Case WHERE Sales_Order__c IN :SOIdSet AND IsClosed = false]){
			soIdToCaseMap.put(currentCase_i.Sales_Order__c, currentCase_i);
			
			for(Shipment_Line_Item__c childShipmentLineItem_i : currentCase_i.Shipment_Line_Items__r){	
				if(!caseIdToStatusListMap.containsKey(currentCase_i.id)){
					caseIdToStatusListMap.put(currentCase_i.id, new Set<String>());
				}
				caseIdToStatusListMap.get(currentCase_i.id).add(childShipmentLineItem_i.Shipment_Item_Status__c);
			}
		}

		for(Shipment_Line_Item__c currentShipment_i : newShipmentLineItemList){
			if(soIdToCaseMap.containsKey(currentShipment_i.Related_Sales_Order__c)){
				Case currentCase = soIdToCaseMap.get(currentShipment_i.Related_Sales_Order__c);
				if(caseIdToStatusListMap.containsKey(currentCase.Id)){
					caseIdToStatusListMap.get(currentCase.Id).add(currentShipment_i.Shipment_Item_Status__c);
				}
			}
		}
		
		return caseIdToStatusListMap;
	}
	
	private static Map<String, String> obtainEntitlementTemlateMap(Map<String, Shipment_Line_Item_status_settings__c> shipmentLineItemStatusDataMap){
		Map<String, String> entitlementTemplateNameToIdMap = new Map<String, String>();
		Set<String> entitlementTemplateNameList = new Set<String>();
		for(Shipment_Line_Item_status_settings__c currentShipmentLineItemStatusData_i : shipmentLineItemStatusDataMap.values()){
			if(currentShipmentLineItemStatusData_i.Entitlement_Template__c != null){
				entitlementTemplateNameList.add(currentShipmentLineItemStatusData_i.Entitlement_Template__c);
			}
		}
		for(Entitlement currentEntitlement_i : [SELECT Id, Name FROM Entitlement WHERE Name in :entitlementTemplateNameList]){
			entitlementTemplateNameToIdMap.put(currentEntitlement_i.Name, currentEntitlement_i.Id);
		}
		return entitlementTemplateNameToIdMap;
	}

	public static void afterInsert(list<Shipment_Line_Item__c> newShipmentli){
		list<string> liIdsToUpdateParentsStatus = new list<string>();
		Set<String> salesOrdersToGenerateInvoice = new Set<String>();
		set<string> shipmentIdsToUpdateDropOffDate = new set<string>();
		map<string, Shipment__c> shipmentToUpdate = new map<string, Shipment__c>();
		Set<Id> inventoryToRecalQuantityIdSet = new Set<Id>();
		
		List<Shipment_Line_Item__c> parentInfo = [SELECT Id, Shipment__c, Shipment_Item_Status__c, Inventory__c FROM Shipment_Line_Item__c WHERE Id IN :newShipmentli];
        Set<String> shipmentIds = new Set<String>();
        for(Shipment_Line_Item__c item_i : parentInfo){
            shipmentIds.add(item_i.Shipment__c);
			liIdsToUpdateParentsStatus.add(item_i.id);
			if(retaggedStatusSet.contains(item_i.Shipment_Item_Status__c) && item_i.Inventory__c != null){
				inventoryToRecalQuantityIdSet.add(item_i.Inventory__c);
			}
        }
        if(inventoryToRecalQuantityIdSet.size() > 0){
			//recalcInventoryQuantity(inventoryToRecalQuantityIdSet);
		}
        //Set<String> soToGenInvoiceIds = validateInvoiceGeneraiton(shipmentIds);
	
		if (shipmentIdsToUpdateDropOffDate.size() > 0){
			shipmentToUpdate = updateShipmentDropOffDate(shipmentIdsToUpdateDropOffDate);
		}
		/*if (liIdsToUpdateParentsStatus.size() > 0){
			updateShipmentStatus(liIdsToUpdateParentsStatus, shipmentToUpdate);
		}*/
		if (shipmentToUpdate.values().size() > 0){
			update shipmentToUpdate.values();
		}
		if (liIdsToUpdateParentsStatus.size() > 0){
			updateShipmentStatus(liIdsToUpdateParentsStatus);
		}
		/*if (soToGenInvoiceIds.size() > 0){
			generateInvoice(soToGenInvoiceIds);
		}*/
		generateInvoiceCheck(newShipmentli);
		runCaseFlow(newShipmentli);
	}

	private static void generateInvoiceCheck(List<Shipment_Line_Item__c> newShipmentItemsList){		

		Set<String> paymentMethodSet = Payment_Methods_for_Automated_Charge__c.getAll().keySet();//new Set<String>{'Credit Card', 'Affirm'};

		List<Shipment_Line_Item__c> shipmentDataList = [SELECT Shipment__r.Related_Sales_Order__c, Shipment__r.Related_Sales_Order__r.Payment_Status__c, PO_Line_Item__r.SO_Line_Item__r.Manufacturer__c 
														FROM Shipment_Line_Item__c 
														WHERE Shipment__r.Related_Sales_Order__r.Payment_Status__c != 'Received' 
														AND Shipment__r.Related_Sales_Order__r.Payment_Method__c IN :paymentMethodSet
														AND PO_Line_Item__r.Purchase_Order__r.Ship_From__r.Automated_Payment_Capture__c = True 
														AND Id in :newShipmentItemsList];
		Set<String> salesOrderIdSet = new Set<String>();
		for(Shipment_Line_Item__c currentShipmentLineItem_i : shipmentDataList){
			salesOrderIdSet.add(currentShipmentLineItem_i.Shipment__r.Related_Sales_Order__c);
		}
		//check if Sales Order has other shipment line items then current ones
		List<AggregateResult> orderIdResultList = [	SELECT Shipment__r.Related_Sales_Order__c orderId 
													FROM Shipment_Line_Item__c 
													WHERE Id NOT IN :shipmentDataList AND Shipment__r.Related_Sales_Order__c IN :salesOrderIdSet 
													GROUP BY Shipment__r.Related_Sales_Order__c
												   ];
		for(AggregateResult result_i : orderIdResultList){										
			salesOrderIdSet.remove((Id) result_i.get('orderId'));											
		}
		if(salesOrderIdSet.size() > 0){
			generateInvoice(new List<String>(salesOrderIdSet));
		}
	}

	@future (callout=true)
	public static void generateInvoice(List<String> salesOrderIdList){
        DateTime currentTimePlusInterval = Datetime.now().addSeconds(15);
        String second = String.valueOf(currentTimePlusInterval.second());
        String minute = String.valueOf(currentTimePlusInterval.minute());
        String hour = String.valueOf(currentTimePlusInterval.hour());
        String day = String.valueOf(currentTimePlusInterval.day());
        String month = String.valueOf(currentTimePlusInterval.month());
        String year = String.valueOf(currentTimePlusInterval.year());
        String strSchedule = second + ' ' + minute + ' ' + hour + ' ' + day + ' ' + month + ' ?' + ' ' + year;
        /*if(!Test.isRunningTest())*/ System.schedule('ShipmentGenerateInvoiceScheduler - ' + currentTimePlusInterval, strSchedule, new ShipmentGenerateInvoiceScheduler(salesOrderIdList));
	}
	
	/*@future (callout=true)
	private static void generateInvoice(Set<String> orderIds){
		List<Sales_Order__c> salesOrderList = [SELECT Id FROM Sales_Order__c WHERE Id IN :orderIds];
		for(Sales_Order__c salesOrder_i : salesOrderList){
			ApexPages.StandardController sc = new ApexPages.StandardController(salesOrder_i);
			CreateInvoicepageController invoiceCtrl = new CreateInvoicepageController(sc);
			invoiceCtrl.submitInvoice();
		}
	}*/
    
    /*private static Set<String> validateInvoiceGeneraiton(set<string> shipmentIds){
		list<string> itemOrdersIds = new list<string>();
		Set<String> salesOrderIds = new Set<String>();
		list<Shipment_Line_Item__c> slis = [select PO_Line_Item__r.SO_Line_Item__c, Shipment__r.Related_Sales_Order__c from Shipment_Line_Item__c where Shipment__c in :shipmentIds];
		for (Shipment_Line_Item__c sli_i : slis){
			itemOrdersIds.add(sli_i.PO_Line_Item__r.SO_Line_Item__c);
			salesOrderIds.add(sli_i.Shipment__r.Related_Sales_Order__c);
		}
		list<SO_Line_Items__c> solis = [select Id, Sales_Order__c from SO_Line_Items__c where Sales_Order__c IN :salesOrderIds and Id not in :itemOrdersIds];
        for(SO_Line_Items__c soli_i : solis){
            if(salesOrderIds.contains(soli_i.Sales_Order__c)){
                salesOrderIds.remove(soli_i.Sales_Order__c);
            }
        }
		return salesOrderIds;
	}*/

	private static map<string, Shipment__c> updateShipmentDropOffDate(set<string> shipmentIds){
		map<string, Shipment__c> ret = new map<string, Shipment__c>();
		list<Shipment__c> shipments = [select id, Shipment_Status__c, Drop_Off_Date_Expected__c, (select Drop_Off_Date_Expected__c from Shipment_Line_Itmes__r) from Shipment__c where id in :shipmentIds];
		for (Shipment__c s : shipments){
			boolean sameDropOffDate = true;
			date dropOffDate = s.Shipment_Line_Itmes__r[0].Drop_Off_Date_Expected__c;
			for (Shipment_Line_Item__c sli : s.Shipment_Line_Itmes__r){
				if (sli.Drop_Off_Date_Expected__c != dropOffDate){
					sameDropOffDate = false;
					break;
				}
				s.Drop_Off_Date_Expected__c = sli.Drop_Off_Date_Expected__c;
			}
			if (sameDropOffDate){
			}
			else{
				s.Drop_Off_Date_Expected__c = null;
			}
			ret.put(s.id, s);
		}
		return ret;
	}
	
	
	private static void updateShipmentStatus(list<string> liIdsToUpdateParentsStatus){
	    Magento_Integration_Setting__c setting = Magento_Integration_Setting__c.getInstance();
		map<id, SO_Line_Items__c> sliToUpdate = new map<id, SO_Line_Items__c>();
		list<Shipment__c> shipmentToUpdate = new list<Shipment__c>();
		list<Purchase_Order__c> poToUpdate = new list<Purchase_Order__c>();
		list<Sales_Order__c> soToUpdate = new list<Sales_Order__c>();
		
		set<id> shipmentIds = new set<id>();
		set<id> poIds = new set<id>();
		set<id> soIds = new set<id>();
		set<id> poWithShipmentIds = new set<id>();
		set<string> statusesNotToBeUpdatedSet = new set<string>();
		
		list<Order_statuses_not_to_be_updated__mdt> statusesNotToBeUpdated = [select Status__c from Order_statuses_not_to_be_updated__mdt];
		for (Order_statuses_not_to_be_updated__mdt os : statusesNotToBeUpdated){
			statusesNotToBeUpdatedSet.add(os.Status__c);
		}
												 
		list<Order_status_map__mdt> statuses = [select Salesforce_status_name__c, Salesforce_shipment_line_status_name__c, Salesforce_item_ordered_status_name__c,
												 Salesforce_purchase_order_status_name__c, Salesforce_sales_order_status_name__c from Order_status_map__mdt];
		map<string, Order_status_map__mdt> statusMapBySLI = getStatusMapBySLI(statuses);
		map<string, Order_status_map__mdt> statusMapByShipment = getStatusMapByShipment(statuses);
		map<string, Order_status_map__mdt> statusMapByPO = getStatusMapByPO(statuses);
		map<string, Order_status_map__mdt> statusMapBySOLine = getStatusMapBySOLine(statuses);
		list<Shipment_Line_Item__c> lis = [select id, Shipment_Item_Status__c, Shipment__r.Purchase_Order__c, Shipment__r.Purchase_Order__r.Sales_Order__c, PO_Line_Item__c,
										   PO_Line_Item__r.SO_Line_Item__c, PO_Line_Item__r.SO_Line_Item__r.Item__c from Shipment_Line_Item__c where id in :liIdsToUpdateParentsStatus];
		string soId = lis[0].Shipment__r.Purchase_Order__r.Sales_Order__c;
		
		Sales_Order__c sor = [select id, Order_Status__c from Sales_Order__c where id = :soId];
		list<Shipment_Line_Item__c> allLis = [select id, Shipment_Item_Status__c, Shipment__r.Purchase_Order__c, Shipment__r.Purchase_Order__r.Sales_Order__c, PO_Line_Item__c,
										   PO_Line_Item__r.SO_Line_Item__c, PO_Line_Item__r.SO_Line_Item__r.Item__c from Shipment_Line_Item__c where Shipment__r.Purchase_Order__r.Sales_Order__c = :soId];
		for (Shipment_Line_Item__c sli : lis){
			if (statusMapBySLI.containskey(sli.Shipment_Item_Status__c)){
				if (sli.PO_Line_Item__r.SO_Line_Item__c != null && !statusesNotToBeUpdatedSet.contains(sli.PO_Line_Item__r.SO_Line_Item__r.Item__c) && sli.PO_Line_Item__r.SO_Line_Item__r.Item__c != statusMapBySLI.get(sli.Shipment_Item_Status__c).Salesforce_item_ordered_status_name__c){
					SO_Line_Items__c soli = new SO_Line_Items__c();
					soli.id = sli.PO_Line_Item__r.SO_Line_Item__c;
					soli.Item__c =  statusMapBySLI.get(sli.Shipment_Item_Status__c).Salesforce_item_ordered_status_name__c;
					sliToUpdate.put(soli.id, soli);
				}
			}
			shipmentIds.add(sli.Shipment__c);
		}
		for (Shipment_Line_Item__c sli : allLis){
			poWithShipmentIds.add(sli.PO_Line_Item__c);
		}
		
		if (sliToUpdate.values().size() > 0){
			update sliToUpdate.values();
		}
		system.debug('shipmentIds = ' + shipmentIds);
		list<Shipment__c> shipments = [select id, Shipment_Status__c, Purchase_Order__c, (select Shipment_Item_Status__c from Shipment_Line_Itmes__r) from Shipment__c where id in :shipmentIds];
		system.debug('shipments = ' + shipments);
		for (Shipment__c s : shipments){
			boolean first = true;
			boolean wasUpdated = false;
			string status = '';
			for (Shipment_Line_Item__c sli : s.Shipment_Line_Itmes__r){
				if (first){
					status = sli.Shipment_Item_Status__c;
					first = false;
				}
				else if (sli.Shipment_Item_Status__c != status){
					wasUpdated = true;
					s.Shipment_Status__c = 'Multiple Statuses';
					shipmentToUpdate.add(s);
					break;
				}
			}
			if (!wasUpdated && statusMapBySLI.containskey(status)){
				s.Shipment_Status__c = statusMapBySLI.get(status).Salesforce_status_name__c;
				shipmentToUpdate.add(s);
			}
			system.debug('shipmentToUpdate = ' + shipmentToUpdate);
			poIds.add(s.Purchase_Order__c);
		}
		
		if (shipmentToUpdate.size() > 0){
			update shipmentToUpdate;
		}
		
		system.debug('poIds = ' + poIds);
		list<Purchase_Order__c> pos = [select id, Status__c, Sales_Order__c, (select Shipment_Status__c from Shipments__r), (select id from PO_Line_Item__r) from Purchase_Order__c where id in :poIds];
		for (Purchase_Order__c po : pos){
			boolean first = true;
			boolean wasUpdated = false;
			string status = '';
			for (Shipment__c s : po.Shipments__r){
				if (first){
					status = s.Shipment_Status__c;
					first = false;
				}
				else if (s.Shipment_Status__c != status){
					wasUpdated = true;
					po.Status__c = 'Multiple Statuses';
					poToUpdate.add(po);
					break;
				}
			}
			if (!wasUpdated && setting.API_User_ID__c != null && !UserInfo.getUserId().contains(setting.API_User_ID__c)){
				for (PO_Line_Items__c pol : po.PO_Line_Item__r){
					if (!poWithShipmentIds.contains(pol.id)){
						wasUpdated = true;
						po.Status__c = 'Multiple Statuses';
						poToUpdate.add(po);
						break;
					}
				}
			}
			if (!wasUpdated && statusMapByShipment.containskey(status)){
				po.Status__c = statusMapByShipment.get(status).Salesforce_purchase_order_status_name__c;
				poToUpdate.add(po);
			}
			soIds.add(po.Sales_Order__c);
		}
		
		if (poToUpdate.size() > 0){
			update poToUpdate;
		}
		system.debug('poToUpdate = ' + poToUpdate);
		system.debug('soIds = ' + soIds);
		
		map<id, Sales_Order__c> sos = new map<id, Sales_Order__c>([select id, Order_Status__c from Sales_Order__c where id in :soIds AND Order_Status__c != 'Disputed' ]);
		list<SO_Line_Items__c> soLines = [select Item__c, Sales_Order__c from SO_Line_Items__c where (Manufacturer__c != 'Protection Plan' OR (Manufacturer__c = 'Protection Plan'  AND ProductSKU__c like '%GD-NW%'))  and Item__c != 'Cancelled' and (Product_Record_Type__c != 'Bundled' or (Product_Record_Type__c = 'Bundled' and Bundle_Item__c != null)) and Sales_Order__c in :sos.keyset()];
		system.debug('sos = ' + sos);
		system.debug('soLines = ' + soLines);
		for (Sales_Order__c so : sos.values()){
			if (statusesNotToBeUpdatedSet.contains(so.Order_Status__c)){
				continue;
			}
			boolean first = true;
			boolean wasUpdated = false;
			string status = '';
			for (SO_Line_Items__c po : soLines){
				if (po.Sales_Order__c != so.id){
					continue;
				}
				if (first){
					status = po.Item__c;
					first = false;
				}
				else if (po.Item__c != status){
					wasUpdated = true;
					so.Order_Status__c = 'Multiple Statuses';
					soToUpdate.add(so);
					break;
				}
			}
			if (!wasUpdated && statusMapBySOLine.containskey(status)){
				so.Order_Status__c = statusMapBySOLine.get(status).Salesforce_sales_order_status_name__c;
				soToUpdate.add(so);
			}
		}
		
		system.debug('soToUpdate = ' + soToUpdate);
		if (soToUpdate.size() > 0){
			update soToUpdate;
		}
	}
    
     private static void createUpdateInventory(map<string, list<Shipment_Line_Item__c>> shlInventoryUpdate){

        // Get the current instance of the SHL custom setting
        // Inventory_Management__c setting = Inventory_Management__c.getAll().containsKey('Inventory')?Inventory_Management__c.getAll().get('Inventory'):new Inventory_Management__c();
        // System.debug('Instance is ' + (Inventory_Management__c.getAll().containsKey('Inventory')?Inventory_Management__c.getAll().get('Inventory'):new Inventory_Management__c()));
		
		Map<String, Inventory_Management__c> inventoryManagerSetting = obtainInventoryManagementSettings();
		List<String> conditionList = new List<String>();
		for (Inventory_Management__c setting_i : inventoryManagerSetting.values()) {
			if (string.isNotEmpty(setting_i.Furniture_Condition__c)) {
				conditionList.addAll(setting_i.Furniture_Condition__c.split(','));
			}
		}

        Id InventoryRecordTypeId = Schema.SObjectType.Inventory__c.getRecordTypeInfosByName().get('Delivery Company Inventory').getRecordTypeId();

         // Initialize lists
		list<Inventory__c> inventoryToUpdate = new list<Inventory__c>();
		list<Shipment_Line_Item__c> SHLsToUpdate = new list<Shipment_Line_Item__c>();

		// Get inventory records which are linked to the POLs linked to the SHLs
        list<Inventory__c> inventoryList = [SELECT Id, Related_POL__c FROM Inventory__c WHERE Related_POL__c in : shlInventoryUpdate.keyset()];
		map<string, Inventory__c> inventoryByPOLMap = new map<string, Inventory__c>();
		for(Inventory__c inv :  inventoryList){
            System.debug('Adding inventory with ID '+inv.Id + ' to list of inventories with POL matching SHL');
			inventoryByPOLMap.put(inv.Related_POL__c, inv);
		}

		// Get POLs which are related to the SHLs
		List<PO_Line_Items__c> POL_list = [SELECT id, Purchase_Order__r.Suggested_Delivery_Comapny__c, SO_Line_Item__r.ProductSKU__c, Quantity__c,
											(SELECT Shipment__r.Delivery_Company__c FROM Shipment_Line_Items__r ORDER BY Shipment__r.Delivery_Company__c NULLS LAST LIMIT 1)
											FROM PO_Line_Items__c WHERE id IN : shlInventoryUpdate.keyset() ];

        map<string, id> ProductByPOL = new map<string, id>();
        set<string> productNames = new set<string>();
		for(PO_Line_Items__c pol :  POL_list){
			productNames.add(pol.SO_Line_Item__r.ProductSKU__c);
		}
		list<Products__c> products = [SELECT id, SKU__c FROM Products__c WHERE SKU__c in :productNames];
		for (Products__c p : products){
			ProductByPOL.put(p.SKU__c, p.id);
		}

		// For each POL related to the SHLs being updated...
		for(PO_Line_Items__c pol :  POL_list){
	
            System.debug('Looking at POL with Id '+ pol.Id);
			// Create a map for SHLs by POL
			Set<string> SHLStatusSet = new Set<string>();
			Set<string> SHLConditionSet = new Set<string>();
            
            
		//	map<string, double> SHLQuantityMap = new map<string, string>();
			
			// Initialize an inventory object
			Inventory__c inv;
            Double SHL_Total_Quantity = 0.0;
			Integer count = 0;
            
          // Id polProduct = [SELECT id FROM Products__c WHERE name =: pol.SO_Line_Item__r.Product_Name__c LIMIT 1].id;

			// Add the SHLs related to the currently iterating POL to a map, along with their status
			for(Shipment_Line_Item__c shl : shlInventoryUpdate.get(pol.Id) ){
                System.debug('Adding SHL with ID '+ shl.Id + ' to SHL inventory map with status '+shl.Shipment_Item_Status__c);
				SHLStatusSet.add(shl.Shipment_Item_Status__c);
				SHLConditionSet.add(shl.Furniture_Condition__c);
                count = count + 1;
                SHL_Total_Quantity += shl.Shipment_Product_Quantity__c != null ? shl.Shipment_Product_Quantity__c : 0;//SHL_Total_Quantity!=null?SHL_Total_Quantity:0 + shl.Shipment_Product_Quantity__c!=null?shl.Shipment_Product_Quantity__c:0;
			//	SHLQuantityMap.put(pol.id, shl.Shipment_Product_Quantity__c);
			}
            

			// if inventory does not exist & the value set of statuses contains 'Hold as stock'...

			Boolean hasCommonStatus = hasCommonElementInLists(SHLStatusSet, inventoryManagerSetting.keySet());
			Boolean hasCommonCondition = hasCommonElementInLists(SHLConditionSet, conditionList);
			if (!inventoryByPOLMap.containskey(pol.Id) &&
				hasCommonStatus &&
				hasCommonCondition /* SHLStatusMap.values().contains(String.valueOf(setting.Stock_Status__c)) */){
				// Add values to inventory record
				String deliveryCompany = pol.Shipment_Line_Items__r != null && pol.Shipment_Line_Items__r.size() > 0 ? pol.Shipment_Line_Items__r.get(0).Shipment__r.Delivery_Company__c : null;
				inv = new Inventory__c(RecordTypeId = InventoryRecordTypeId, Product_Condition__c = 'Resellable', Delivery_Company__c = deliveryCompany/* pol.Purchase_Order__r.Suggested_Delivery_Comapny__c */, Products__c = ProductByPOL.get(pol.SO_Line_Item__r.ProductSKU__c), Quantity__c = pol.Quantity__c, Related_POL__c = pol.Id, Warehouse_Name__c = deliveryCompany/*pol.Purchase_Order__r.Suggested_Delivery_Comapny__c*/);
				
				// Add the new inventory record to the map of inventories by POL
				inventoryByPOLMap.put(pol.Id, inv);
                inventoryToUpdate.add(inv);
                System.debug('Added new inventory to update');

			// if inventory DOES exist...
			} /*else if (inventoryByPOLMap.keyset().contains(pol.Id)){
                System.debug('Found inventory for POL ' + pol.Id);
				// Reset the availability to 'true'
				inv = new Inventory__c(id = inventoryByPOLMap.get(pol.Id).id);
				if((hasCommonStatus && SHLStatusSet.size() > 1) || !hasCommonStatus) {
                	inv.Quantity__c = 0;
				} else if (hasCommonStatus && SHLStatusSet.size() == 1) {
                    inv.Quantity__c = SHL_Total_Quantity/count;
                }
                inventoryToUpdate.add(inv);
                System.debug('Added existing inventory to update');

			}*/
            
            try {
                if (inventoryToUpdate.size() > 0){
                    upsert inventoryToUpdate;
                    System.debug('Inventory upserted');
                }
            }catch(exception e){
	                System.debug('An unexpected error has occurred: ' + e.getMessage() + ' in line number' + e.getLineNumber());
	    	}
        }
            
         list<Inventory__c> upsertedInventory = [SELECT Id, Related_POL__c FROM Inventory__c WHERE Related_POL__c in :  POL_list];
         map<string, Inventory__c> upsertedInvByPol = new  map<string, Inventory__c>();
         // map<string, Inventory__c> upsertedInventory = map<string, Inventory__c>();
         for(Inventory__c inv : upsertedInventory){
             if(!upsertedInvByPol.containsKey(inv.Related_POL__c)){
                 upsertedInvByPol.put(inv.Related_POL__c, inv);
                 System.debug('Added inventory '+ inv.Id + ' to list of upserted invnetory');
             }
         }
         
		for(string pol : upsertedInvByPol.keyset()){
			// Go through each SHL related to the inventory's POL
			for(Shipment_Line_Item__c shl : shlInventoryUpdate.get(pol) ){
			System.debug('now looking at SHL with ID ' + shl.Id + ' associated with POL '+ POL);
				// If the SHL status is 'Hold as stock', add it to the inventory
				if ( inventoryManagerSetting.containsKey(shl.Shipment_Item_Status__c)/*  shl.Shipment_Item_Status__c.equals(setting.Stock_Status__c) */ ){
                    Shipment_Line_Item__c newSHL = new Shipment_Line_Item__c(Id = shl.Id);
                    System.debug('SHL with ID '+ shl.Id + ' has status Hold as stock, and is being added to inventory ' + upsertedInvByPol.get(pol).Id);
					newSHL.Inventory__c = upsertedInvByPol.get(pol).Id;
					SHLsToUpdate.add(newSHL);
				}
			}
        }
		
        System.debug('Size of SHL to update list is '+ SHLsToUpdate.size());
         
        // Re-query the records to be able to update them (since a record is read-only in an after-update)
        //list<Inventory__c> newInventoryList = [SELECT Id FROM Inventory__c WHERE Id in :inventoryToUpdate];
         //ist<Shipment_Line_Item__c> newSHLList = [Select Id FROM Shipment_Line_Item__c WHERE Id in :SHLsToUpdate];

		// Try upserting inventory and updating SHLs
		// 
		System.debug('SHL to update list is ' + SHLsToUpdate.size());
		try {
			if(SHLsToUpdate.size()>0){
				update SHLsToUpdate;
			}
		}catch(exception e){
	                System.debug('An unexpected error has occurred: ' + e.getMessage() + ' in line number' + e.getLineNumber());
	    }
	}
	
	private static void runCaseFlow(list<Shipment_Line_Item__c> newShipmentLinesList){
        Map<Id, Case> caseMap = new Map<Id, Case>();
        for(Shipment_Line_Item__c shl_i : newShipmentLinesList){
            if(shl_i.Related_Case__c !=null){
                caseMap.put(shl_i.Related_Case__c, new Case(Id = shl_i.Related_Case__c));
            }
        }
        if(caseMap.size() > 0){
            autoAssignCaseDepartmentHelper.runFlow(caseMap);
        }
    }

    /*
     private static void createInventory(list<string> liIdsToCheck){
        // Get the current instance of the SHL custom setting
        SHL_Status_Setting__c setting = SHL_Status_Setting__c.getInstance();
        list<Inventory__c> inv_list = new list<Inventory__c>();
        map<Id, Inventory__c> inv_id_map = new map<Id, Inventory__c>([SELECT Id FROM Inventory__c]);
        Set<Id> invIds = inv_id_map.keySet();

        // Get IDs of related records from SHL and which are not already associated with inventory records
        list<Shipment_Line_Item__c> lis = [select id, Shipment_Item_Status__c, Quantity__c, Shipment__r.Purchase_Order__c, Shipment__r.Purchase_Order__r.Sales_Order__c, PO_Line_Item__c,
										   PO_Line_Item__r.SO_Line_Item__c, PO_Line_Item__r.SO_Line_Item__r.Item__c from Shipment_Line_Item__c WHERE id in :liIdsToCheck AND id NOT IN :invIds ];
        
        // For each SHL in the list
        for (Shipment_Line_Item__c sli : lis){
            if(sli.Shipment_Item_Status__c == setting.Status__c){ // The SHL has the right status, i.e. 'Hold as Stock'
                Inventory__c inv = new Inventory__c(Available__c = true, Delivery_Company__c = sli.Shipment__r.Delivery_Company__c, Products__c = sli.PO_Line_Item__r.SO_Line_Item__r.Products__c, Quantity__c = sli.Quantity__c, Related_POL__c = sli.PO_Line_Item__c, Shipment_Item__c = sli.Id, Warehouse_Name__c = sli.Shipment__r.Delivery_Company__c);
                inv_list.add(inv);
            } 
        }

        try{
            insert inv_list;
        } catch(DmlException e) {
            System.debug('The following exception has occurred: ' + e.getMessage());
        }
    }

    private static void updateInventory(list<string> liIdsToCheck){
        // Get the current instance of the SHL custom setting
        SHL_Status_Setting__c setting = SHL_Status_Setting__c.getInstance();

        // Get IDs of related records from SHL and which are associated with inventory records
        list<Inventory__c> inv_list = [SELECT id, Shipment_Item__c, Shipment_Item__r.Shipment_Item_Status__c, Shipment_Item__r.Quantity__c, Quantity__c FROM Inventory__c WHERE Id IN :liIdsToCheck ];
        

        
        // For each SHL in the list
        for (Inventory__c inv : inv_list){
            if(inv.Shipment_Item__r.Shipment_Item_Status__c != setting.Status__c){ // The SHL is no longer held as stock
                inv.Quantity__c = inv.Shipment_Item__r.Quantity__c;
                inv.Available__c = false;
            } 
        }

        try{
            update inv_list;
        } catch(DmlException e) {
            System.debug('The following exception has occurred: ' + e.getMessage());
        }
    
    }
	
	/*private static void updateShipmentStatus(list<string> liIdsToUpdateParentsStatus, map<string, Shipment__c> shipmentToUpdateDropOffDate){
		map<string, Order_status_map__mdt> statusMap = getStatusMap();
		list<Shipment_Line_Item__c> lis = [select id, Shipment_Item_Status__c, Shipment__r.Purchase_Order__c, Shipment__r.Purchase_Order__r.Sales_Order__c, 
										   PO_Line_Item__r.SO_Line_Item__c from Shipment_Line_Item__c where id in :liIdsToUpdateParentsStatus];
		map<id, SO_Line_Items__c> sliToUpdate = new map<id, SO_Line_Items__c>();
		map<string, string> shipmentToUpdateStatusByStatusMap = new map<string, string>();
		map<string, string> poToUpdateStatusByStatusMap = new map<string, string>();
		map<string, string> soToUpdateStatusByStatusMap = new map<string, string>();
		
		system.debug('lis = ' + lis);
		boolean updateSli = false;
		for (Shipment_Line_Item__c sli : lis){
			if (statusMap.containskey(sli.Shipment_Item_Status__c)){
				shipmentToUpdateStatusByStatusMap.put(sli.Shipment_Item_Status__c, sli.Shipment__c);
				poToUpdateStatusByStatusMap.put(sli.Shipment_Item_Status__c, sli.Shipment__r.Purchase_Order__c);
				soToUpdateStatusByStatusMap.put(sli.Shipment_Item_Status__c, sli.Shipment__r.Purchase_Order__r.Sales_Order__c);
				if (sli.PO_Line_Item__r.SO_Line_Item__c != null && !sliToUpdate.containskey(sli.PO_Line_Item__r.SO_Line_Item__c)){
					sliToUpdate.put(sli.PO_Line_Item__r.SO_Line_Item__c, new SO_Line_Items__c(id = sli.PO_Line_Item__r.SO_Line_Item__c, Item__c = statusMap.get(sli.Shipment_Item_Status__c).Salesforce_item_ordered_status_name__c));
					updateSli = true;
				}
			}
		}
		//update order items 
		if (updateSli && sliToUpdate.values().size() > 0){
			update sliToUpdate.values();
		}
		
		system.debug('shipmentToUpdateStatusByStatusMap = ' + shipmentToUpdateStatusByStatusMap);
		system.debug('poToUpdateStatusByStatusMap = ' + poToUpdateStatusByStatusMap);
		system.debug('soToUpdateStatusByStatusMap = ' + soToUpdateStatusByStatusMap);
		
		if (shipmentToUpdateStatusByStatusMap.values().size() == 0) return;
		//update shipments
		list<Shipment_Line_Item__c> shipmentli = [select id, Shipment__r.Purchase_Order__c, Shipment__r.Purchase_Order__r.Sales_Order__c 
												  from Shipment_Line_Item__c where Shipment__c in :shipmentToUpdateStatusByStatusMap.values() and 
												  Shipment_Item_Status__c not in :shipmentToUpdateStatusByStatusMap.keyset()];
		list<Shipment__c> shipmentToUpdate = new list<Shipment__c>();
		
		for (string status : shipmentToUpdateStatusByStatusMap.keyset()){
			Shipment__c newShi;
			if (!shipmentToUpdateDropOffDate.containskey(shipmentToUpdateStatusByStatusMap.get(status))){
				newShi = new Shipment__c(id = shipmentToUpdateStatusByStatusMap.get(status));
				shipmentToUpdateDropOffDate.put(newShi.id, newShi);
			}
			else {
				newShi = shipmentToUpdateDropOffDate.get(shipmentToUpdateStatusByStatusMap.get(status));
			}
			if (shipmentli.size() == 0){
				newShi.Shipment_Status__c = statusMap.get(status).Salesforce_status_name__c;
			}
			else {
				newShi.Shipment_Status__c = 'Multiple Statuses';
			}
			shipmentToUpdate.add(newShi);
		}
		system.debug('shipmentToUpdate = ' + shipmentToUpdate);
		if (shipmentToUpdateDropOffDate.values().size() > 0){
			update shipmentToUpdate;
		}
		if (shipmentToUpdate.size() == 0) return;
		
		//update po
		list<Shipment__c> shipments = [select id from Shipment__c where Purchase_Order__c in :poToUpdateStatusByStatusMap.values() and 
												  Shipment_Status__c != :shipmentToUpdate[0].Shipment_Status__c];
		list<Purchase_Order__c> poToUpdate = new list<Purchase_Order__c>();
		for (string status : shipmentToUpdateStatusByStatusMap.keyset()){
			Purchase_Order__c newpo = new Purchase_Order__c(id = poToUpdateStatusByStatusMap.get(status));
			if (shipments.size() == 0){
				newpo.Status__c = statusMap.get(status).Salesforce_purchase_order_status_name__c;
			}
			else{
				newpo.Status__c = 'Multiple Statuses';
			}
			poToUpdate.add(newpo);
		}
		if (poToUpdate.size() > 0){
			update poToUpdate;
		}
		
		//update so
		list<Purchase_Order__c> pos = [select id from Purchase_Order__c where Sales_Order__c in :soToUpdateStatusByStatusMap.values() and 
												  Status__c != :poToUpdate[0].Status__c];
		list<Sales_Order__c> soToUpdate = new list<Sales_Order__c>();
		for (string status : shipmentToUpdateStatusByStatusMap.keyset()){
			Sales_Order__c newso = new Sales_Order__c(id = soToUpdateStatusByStatusMap.get(status));
			if (pos.size() == 0){
				newso.Order_Status__c = statusMap.get(status).Salesforce_sales_order_status_name__c;
			}
			else{
				newso.Order_Status__c = 'Multiple Statuses';
			}
			soToUpdate.add(newso);
		}
		if (soToUpdate.size() > 0){
			update soToUpdate;
		}
		//update order items
	}*/
	
	private static map<string, Order_status_map__mdt> getStatusMapBySOLine(list<Order_status_map__mdt> statusMap){
		map<string, Order_status_map__mdt> ret = new map<string, Order_status_map__mdt>();
		for (Order_status_map__mdt m : statusMap){
			ret.put(m.Salesforce_item_ordered_status_name__c, m);
		}
		return ret;
	}
	
	private static map<string, Order_status_map__mdt> getStatusMapBySLI(list<Order_status_map__mdt> statusMap){
		map<string, Order_status_map__mdt> ret = new map<string, Order_status_map__mdt>();
		for (Order_status_map__mdt m : statusMap){
			ret.put(m.Salesforce_shipment_line_status_name__c, m);
		}
		return ret;
	}
	
	private static map<string, Order_status_map__mdt> getStatusMapByPO(list<Order_status_map__mdt> statusMap){
		map<string, Order_status_map__mdt> ret = new map<string, Order_status_map__mdt>();
		for (Order_status_map__mdt m : statusMap){
			ret.put(m.Salesforce_purchase_order_status_name__c, m);
		}
		return ret;
	}
	
	private static map<string, Order_status_map__mdt> getStatusMapByShipment(list<Order_status_map__mdt> statusMap){
		map<string, Order_status_map__mdt> ret = new map<string, Order_status_map__mdt>();
		for (Order_status_map__mdt m : statusMap){
			ret.put(m.Salesforce_status_name__c, m);
		}
		return ret;
	}
}