public with sharing class SO_Line_ItemTriggerHandler {
	static Boolean inLoop = false;

	public static void beforeInsert (Map<Id, SO_Line_Items__c> soNewMap){
	}

    public static void beforeUpdate (Map<Id, SO_Line_Items__c> soNewMap, Map<id, SO_Line_Items__c> soOldMap){
    	for (SO_Line_Items__c item_i : soNewMap.values()){
            item_i.Total_Weight_Pounds_For_Rollup__c = item_i.Total_Weight_Pounds__c;
		}
	}
	
	public static Boolean isRunTaxCalc = true;

    public static void afterInsert (list<SO_Line_Items__c> soNewList, Map<Id, SO_Line_Items__c> soNewMap){
    	//list<Sales_Order__c> soToUpdate = new list<Sales_Order__c>();
        //Magento_Integration_Setting__c setting = Magento_Integration_Setting__c.getInstance();
    	set<ID> soIds = new set<ID>();
    	set<string> salesOrderItemsIdsToUpdateCancelStatus = new set<string>();
    	map<string, string> salesOrderItemsIdsToUpdateCancelStatusByUncacleItemId = new map<string, string>();
    	map<string, string> BundleProductBySoItemId = new map<string, string>();
    	map<string, string> salesOrderIdBySoItemId = new map<string, string>();
    	set<string> salesOrderIdsToUpdateRetailPrice = new set<string>();
    	for (SO_Line_Items__c soli : soNewList){
    		//if (setting.API_User_ID__c == null || !UserInfo.getUserId().contains(setting.API_User_ID__c)){
    			soIds.add(soli.Sales_Order__c);
    		//}
    		if (soli.Item__c == 'Cancelled'){
    			salesOrderItemsIdsToUpdateCancelStatus.add(soli.id);
    			if (soli.Uncancelled_Items_Ordered__c != null){
    				salesOrderItemsIdsToUpdateCancelStatusByUncacleItemId.put(soli.id, soli.Uncancelled_Items_Ordered__c);
    			}
    		}
    		if (soli.Bundle_Item__c != null && soli.Parent_Item_Ordered__c == null){
    			BundleProductBySoItemId.put(soli.id, soli.Products__c);
    			salesOrderIdBySoItemId.put(soli.id, soli.Sales_Order__c);
    		}
    		if (soli.Item__c != 'Cancelled' && soli.Bundle_Item__c == null && !soli.Shipped_with_Fedex__c){
    			salesOrderIdsToUpdateRetailPrice.add(soli.Sales_Order__c);
    		}
    		
    	}
    	if (soIds.size() > 0){
    		claculateTax(soIds, soNewList);
    	}
    	if (salesOrderItemsIdsToUpdateCancelStatus.size() > 0){
    		updateCancelStatus(salesOrderItemsIdsToUpdateCancelStatus, salesOrderItemsIdsToUpdateCancelStatusByUncacleItemId);
    	}
    	if (BundleProductBySoItemId.values().size() > 0){
    		updateParent(BundleProductBySoItemId, salesOrderIdBySoItemId);
		}
		if(soIds.size() > 0){
			setSOManufacturer(soIds);
		}
    	//soToUpdate.addall(setSOManufacturer(soIds));
    	/*if (soToUpdate.size() > 0){
    		update soToUpdate;
    	}*/
    	if (salesOrderIdsToUpdateRetailPrice.size() > 0){
    		try {
    			updateSoRetailValue(salesOrderIdsToUpdateRetailPrice);
    		}
    		catch (exception e){
    			system.debug(e.getmessage() + ' ' + e.getlinenumber());
    		}
		}
		checkBulkExcluding(soNewList, null);
    }
    
    public static void updateParent (map<string, string> BundleProductBySoItemId, map<string, string> salesOrderIdBySoItemId){
    	list<SO_Line_Items__c> soItemBundle = [select id, Products__c, Sales_Order__c, Bundle_Item_Relative_Discount_Amount__c from SO_Line_Items__c where Bundle_Item__c = null and Sales_Order__c in :salesOrderIdBySoItemId.values() and Products__c in :BundleProductBySoItemId.values()];
    	map<string, map<string, string>> bundleItemIdByProductBySo = new map<string, map<string, string>>();
    	for (SO_Line_Items__c sli : soItemBundle){
    		if (!bundleItemIdByProductBySo.containskey(sli.Sales_Order__c)){
    			bundleItemIdByProductBySo.put(sli.Sales_Order__c, new map<string, string>());
    		}
    		if (!bundleItemIdByProductBySo.get(sli.Sales_Order__c).containskey(sli.Products__c)){
    			bundleItemIdByProductBySo.get(sli.Sales_Order__c).put(sli.Products__c, sli.id);
    		}
    	}
    	list<SO_Line_Items__c> soToUpdateParent = new list<SO_Line_Items__c>();
    	for (string str :salesOrderIdBySoItemId.keyset()){
    		if (bundleItemIdByProductBySo.containskey(salesOrderIdBySoItemId.get(str)) && bundleItemIdByProductBySo.get(salesOrderIdBySoItemId.get(str)).containskey(BundleProductBySoItemId.get(str))){
    			SO_Line_Items__c s = new SO_Line_Items__c(id = str);
    			s.Parent_Item_Ordered__c = bundleItemIdByProductBySo.get(salesOrderIdBySoItemId.get(str)).get(BundleProductBySoItemId.get(str));
    			soToUpdateParent.add(s);
    		}
    	}
    	if (soToUpdateParent.size() > 0){
    		update soToUpdateParent;
    	}
    }
    
    public static void afterUpdate (Map<Id, SO_Line_Items__c> soNewMap, map<id, SO_Line_Items__c> soOldMap){
		list<SO_Line_Items__c> soNewList = soNewMap.values();
    	set<string> salesOrderIdsToVoidGuardian = new set<string>();
    	set<string> salesOrderIdsToUpdateRetailPrice = new set<string>();
    	set<string> salesOrderItemsIdsToUpdateCancelStatus = new set<string>();
    	map<string, string> salesOrderItemsIdsToUpdateCancelStatusByUncacleItemId = new map<string, string>();
    	for (SO_Line_Items__c sol : soNewList){
    		if (sol.Item__c == 'Cancelled' && soOldMap.get(sol.id).Item__c != 'Cancelled' && sol.Product_Name__c.contains('Protection Plan')){
    			salesOrderIdsToVoidGuardian.add(sol.Sales_Order__c);
    		}
    		if (sol.Item__c == 'Cancelled' && soOldMap.get(sol.id).Item__c != 'Cancelled'){
    			salesOrderItemsIdsToUpdateCancelStatus.add(sol.id);
    			if (sol.Uncancelled_Items_Ordered__c != null){
    				salesOrderItemsIdsToUpdateCancelStatusByUncacleItemId.put(sol.id, sol.Uncancelled_Items_Ordered__c);
    			}
    		}
    		if (((sol.Item__c == 'Cancelled' && soOldMap.get(sol.id).Item__c != 'Cancelled') || (sol.Item__c != 'Cancelled' && soOldMap.get(sol.id).Item__c == 'Cancelled') || soOldMap.get(sol.id).Bundle_Item__c != null || sol.Shipped_with_Fedex__c != soOldMap.get(sol.id).Shipped_with_Fedex__c || sol.Sub_Total__c != soOldMap.get(sol.id).Sub_Total__c || sol.DiscountAmount__c != soOldMap.get(sol.id).DiscountAmount__c) && sol.Bundle_Item__c == null){
    			salesOrderIdsToUpdateRetailPrice.add(sol.Sales_Order__c);
    		}
    	}
    	if (salesOrderItemsIdsToUpdateCancelStatus.size() > 0){
    		updateCancelStatus(salesOrderItemsIdsToUpdateCancelStatus, salesOrderItemsIdsToUpdateCancelStatusByUncacleItemId);
    	}
    	if (salesOrderIdsToVoidGuardian.size() > 0){
    		voidGuardian(salesOrderIdsToVoidGuardian);
    	}
    	if (salesOrderIdsToUpdateRetailPrice.size() > 0){
    		try{
    			updateSoRetailValue(salesOrderIdsToUpdateRetailPrice);
    		}
    		catch (exception e){
    			system.debug(e.getmessage() + ' ' + e.getlinenumber());
    		}
		}
		checkBulkExcluding(soNewList, soOldMap);
    }
    
    @future
    public static void updateSoRetailValue (set<string> orderIds){
    	List<Sales_Order__c> ordersToUpdate = [SELECT Id, Sum_of_Retail_Value__c FROM Sales_Order__c WHERE Id IN :orderIds FOR UPDATE ];
    	boolean updateOrders = false;
        Map<Id, Decimal> orderValueMap = new Map<Id, Decimal>();
        for (SO_Line_Items__c item_i : [SELECT Sales_Order__c, Retail_Value_for_Delivery_Company__c FROM SO_Line_Items__c WHERE Sales_Order__c IN :orderIds FOR UPDATE]) {
            if (!orderValueMap.containsKey(item_i.Sales_Order__c) && item_i.Retail_Value_for_Delivery_Company__c != null) {
                orderValueMap.put(item_i.Sales_Order__c, 0);
            }
            if (item_i.Sales_Order__c != null && item_i.Retail_Value_for_Delivery_Company__c != null) {
                Decimal value = orderValueMap.get(item_i.Sales_Order__c) + (Decimal)item_i.Retail_Value_for_Delivery_Company__c;
                orderValueMap.put(item_i.Sales_Order__c, value);
            }
        }
        for (Sales_Order__c order_i : ordersToUpdate) {
        	if (orderValueMap.containskey(order_i.ID) && order_i.Sum_of_Retail_Value__c != orderValueMap.get(order_i.ID)){
		        order_i.Sum_of_Retail_Value__c = orderValueMap.get(order_i.ID);
				updateOrders = true;
        	}
        }
    	if (ordersToUpdate.size () > 0 && updateOrders){
    		update ordersToUpdate;
    	}
    }
    
    private static void updateCancelStatus (set<string> salesOrderItemsIdsToUpdateCancelStatus, map<string, string> salesOrderItemsIdsToUpdateCancelStatusByUncacleItemId){
    	list<Shipment_Line_Item__c> slis = [select PO_Line_Item__r.SO_Line_Item__c, PO_Line_Item__r.SO_Line_Item__r.Uncancelled_Items_Ordered__c, PO_Line_Item__r.SO_Line_Item__r.Parent_Item_Ordered__c from Shipment_Line_Item__c where PO_Line_Item__r.SO_Line_Item__c in :salesOrderItemsIdsToUpdateCancelStatus or PO_Line_Item__r.SO_Line_Item__c in :salesOrderItemsIdsToUpdateCancelStatusByUncacleItemId.values() or PO_Line_Item__r.SO_Line_Item__r.Parent_Item_Ordered__c in :salesOrderItemsIdsToUpdateCancelStatus or PO_Line_Item__r.SO_Line_Item__r.Parent_Item_Ordered__c in :salesOrderItemsIdsToUpdateCancelStatusByUncacleItemId.values()];
    	list<PO_Line_Items__c> plis = [select SO_Line_Item__c, SO_Line_Item__r.Uncancelled_Items_Ordered__c, SO_Line_Item__r.Parent_Item_Ordered__c from PO_Line_Items__c where SO_Line_Item__c in :salesOrderItemsIdsToUpdateCancelStatus or SO_Line_Item__c in :salesOrderItemsIdsToUpdateCancelStatusByUncacleItemId.values() or SO_Line_Item__r.Parent_Item_Ordered__c in :salesOrderItemsIdsToUpdateCancelStatus or SO_Line_Item__r.Parent_Item_Ordered__c in :salesOrderItemsIdsToUpdateCancelStatusByUncacleItemId.values()];
    	set<string> soiWithShipment = new set<string>();
    	set<string> soiWithPo = new set<string>();
    	for (Shipment_Line_Item__c sli : slis){
    		soiWithShipment.add(sli.PO_Line_Item__r.SO_Line_Item__c);
    		if (sli.PO_Line_Item__r.SO_Line_Item__r.Parent_Item_Ordered__c != null){
    			soiWithShipment.add(sli.PO_Line_Item__r.SO_Line_Item__r.Parent_Item_Ordered__c);
    		}
    	}
    	for (PO_Line_Items__c pli : plis){
    		soiWithPo.add(pli.SO_Line_Item__c);
    		if (pli.SO_Line_Item__r.Parent_Item_Ordered__c != null){
    			soiWithPo.add(pli.SO_Line_Item__r.Parent_Item_Ordered__c);
    		}
    	}
    	list<SO_Line_Items__c> sliToUpdate = new list<SO_Line_Items__c>();
    	for(string str : salesOrderItemsIdsToUpdateCancelStatus){
    		SO_Line_Items__c newSli = new SO_Line_Items__c(id = str);
    		if (soiWithShipment.contains(str) || (salesOrderItemsIdsToUpdateCancelStatusByUncacleItemId.containskey(str) && soiWithShipment.contains(salesOrderItemsIdsToUpdateCancelStatusByUncacleItemId.get(str)))){
    			newSli.Cancelled_Status__c = 'After Shipment';
    		}
    		else if (soiWithPo.contains(str) || (salesOrderItemsIdsToUpdateCancelStatusByUncacleItemId.containskey(str) && soiWithPo.contains(salesOrderItemsIdsToUpdateCancelStatusByUncacleItemId.get(str)))){
    			newSli.Cancelled_Status__c = 'Before Shipment';
    		}
    		else{
    			newSli.Cancelled_Status__c = 'Before PO';
    		}
    		sliToUpdate.add(newSli);
    	}
    	if (sliToUpdate.size() > 0){
    		update sliToUpdate;
    	}
    }
    
    
    private static void voidGuardian (set<string> salesOrderIdsToVoidGuardian){
    	list<Sales_Order__c> salesOrders = [select id, Void_Guardian__c, Is_Protection_Plan_Registered__c from Sales_Order__c where id in: salesOrderIdsToVoidGuardian ];//and Is_Protection_Plan_Registered__c = true
    	if (salesOrders == null || salesOrders.size() == 0) return;
    	for (Sales_Order__c so : salesOrders){
			if(so.Is_Protection_Plan_Registered__c){
				so.Void_Guardian__c = !so.Void_Guardian__c;
			}
            else{
				so.Protection_Plan_included__c = false;
            }
    	}
    	update salesOrders;
    }
    
    private static void claculateTax(set<ID> soIds, list<SO_Line_Items__c> soNewList){
	    Magento_Integration_Setting__c setting = Magento_Integration_Setting__c.getInstance();
    	list<SO_Line_Items__c> sliToUpdate = new list<SO_Line_Items__c>();
    	list<string> zipCodeList = new list<string>();
    	list<Sales_Order__c> SOs = [select id, Shipping_ZipCode__c, Do_not_charge_tax__c from Sales_Order__c where id in :soIds];
    	map<id, Sales_Order__c> zipCodeBySO = new map<id, Sales_Order__c>();
    	for (Sales_Order__c so : SOs){
    		zipCodeBySO.put(so.id, so);
    		zipCodeList.add(so.Shipping_ZipCode__c);
    	}
    	map<string, Shipping_Zip_Codes__c> taxByZipcode = new map<string, Shipping_Zip_Codes__c>();
    	list<Shipping_Zip_Codes__c> zipCodes = [select TaxJar_Sales_Tax__c, Zip_Code__c from Shipping_Zip_Codes__c where Zip_Code__c in :zipCodeList];
    	for (Shipping_Zip_Codes__c szc : zipCodes){
    		taxByZipcode.put(szc.Zip_Code__c, szc);
		}
		
		String ordersString = '\'' + String.join((List<String>)JSON.deserialize(JSON.serialize(zipCodeBySO.keyset()), List<String>.class), '\' ,\'') + '\'';
		String querySOItems = 'select Sales_Order__r.Tax_Percentage__c,  Tax_Percent__c, Sales_Order__r.Shipping_ZipCode__c, Sales_Order__r.Do_not_charge_tax__c, Discount_Amount__c, Sub_Total__c, Tax_Amount__c, Bundle_Item__c, Bundle_Item_Relative_Discount_Amount__c from SO_Line_Items__c where Sales_Order__c in ('+ ordersString + ')';
		if(!isRunTaxCalc){
			querySOItems += ' AND Bundle_Item__c != null';
		}

    	list<SO_Line_Items__c> soliToUpdate = Database.query(querySOItems);//[select Sales_Order__r.Tax_Percentage__c,  Tax_Percent__c, Sales_Order__r.Shipping_ZipCode__c, Sales_Order__r.Do_not_charge_tax__c, Discount_Amount__c, Sub_Total__c, Tax_Amount__c, Bundle_Item__c, Bundle_Item_Relative_Discount_Amount__c from SO_Line_Items__c where Sales_Order__c in :zipCodeBySO.keyset()];
    	system.debug('soliToUpdate = ' + soliToUpdate);
    	for(SO_Line_Items__c sli : soliToUpdate){
    		SO_Line_Items__c newsli = new SO_Line_Items__c(id = sli.id);
    		system.debug('sli.Sales_Order__r.Do_not_charge_tax__c = ' + sli.Sales_Order__r.Do_not_charge_tax__c);
    		system.debug('taxByZipcode = ' + taxByZipcode);
    		system.debug('zipCodeBySO = ' + zipCodeBySO);
    		// first check if so has tax precentage and take it from there
    		if (sli.Sales_Order__r.Tax_Percentage__c != null){
    			newsli.Tax_Percent__c = sli.Sales_Order__r.Tax_Percentage__c;
            	if (sli.Bundle_Item__c != null && sli.Bundle_Item_Relative_Discount_Amount__c != null){
                    newsli.Tax_Amount__c = (sli.Sub_Total__c - sli.Bundle_Item_Relative_Discount_Amount__c) * newsli.Tax_Percent__c/100;
            	}
    			else if (sli.Discount_Amount__c != null){
    				newsli.Tax_Amount__c = (sli.Sub_Total__c - sli.Discount_Amount__c) * newsli.Tax_Percent__c/100;
				}
				else{
					newsli.Tax_Amount__c = sli.Sub_Total__c * newsli.Tax_Percent__c/100;
				}
    		}
    		else if (taxByZipcode.containskey(zipCodeBySO.get(sli.Sales_Order__c).Shipping_ZipCode__c) && taxByZipcode.get(zipCodeBySO.get(sli.Sales_Order__c).Shipping_ZipCode__c).TaxJar_Sales_Tax__c != null && !zipCodeBySO.get(sli.Sales_Order__c).Do_not_charge_tax__c){
    			if (sli.Sub_Total__c != null && (setting.API_User_ID__c == null || !UserInfo.getUserId().contains(setting.API_User_ID__c))){
    				newsli.Tax_Percent__c = taxByZipcode.get(zipCodeBySO.get(sli.Sales_Order__c).Shipping_ZipCode__c).TaxJar_Sales_Tax__c;
                	if (sli.Bundle_Item__c != null && sli.Bundle_Item_Relative_Discount_Amount__c != null){
                        newsli.Tax_Amount__c = (sli.Sub_Total__c - sli.Bundle_Item_Relative_Discount_Amount__c) * newsli.Tax_Percent__c/100;
                	}
    				if (sli.Discount_Amount__c != null){
    					newsli.Tax_Amount__c = (sli.Sub_Total__c - sli.Discount_Amount__c) * newsli.Tax_Percent__c/100;
    				}
    				else{
    					newsli.Tax_Amount__c = sli.Sub_Total__c * newsli.Tax_Percent__c/100;
    				}
    			}
    		}
    		else if (setting.API_User_ID__c == null || !UserInfo.getUserId().contains(setting.API_User_ID__c)){
    			newsli.Tax_Percent__c = 0;
    			newsli.Tax_Amount__c = 0;
    		}
    		system.debug('newsli.Tax_Percent__c = ' + newsli.Tax_Percent__c);
    		sliToUpdate.add(newsli);
    	}
    	if (sliToUpdate.size() > 0){
    		update sliToUpdate;
    	}
    }
    
    public static void setSOManufacturer (Set<Id> soIds){
    	List<Sales_Order__c> salesOrderList = [SELECT Id, Manufacturer__c, (SELECT Products__r.Select_Manufacturer__r.Default_Carrier__c, Products__r.Select_Manufacturer__r.Name ,Products__r.Select_Manufacturer__c from SO_Line_Items__r) FROM Sales_Order__c WHERE Id IN :soIds];
    	for (Sales_Order__c so_i : salesOrderList){
			Id manufacturerId = null;
			String defaultCarrier = null;
			Boolean isOnlyProtectionPlan = false;
			if(so_i.SO_Line_Items__r != null){
				if(so_i.SO_Line_Items__r.size() == 1){
					manufacturerId = so_i.SO_Line_Items__r[0].Products__r.Select_Manufacturer__c;
					defaultCarrier = (so_i.SO_Line_Items__r[0].Products__r.Select_Manufacturer__c != null && so_i.SO_Line_Items__r[0].Products__r.Select_Manufacturer__r.Default_Carrier__c != null) ? so_i.SO_Line_Items__r[0].Products__r.Select_Manufacturer__r.Default_Carrier__c : null;
					isOnlyProtectionPlan = (so_i.SO_Line_Items__r.size() == 1 && so_i.SO_Line_Items__r[0].Products__r.Select_Manufacturer__r.Name == 'Protection Plan') ? true : false;
				}else{
					for (SO_Line_Items__c soItem_i : so_i.SO_Line_Items__r){
						if(soItem_i.Products__r.Select_Manufacturer__r.Name != 'Protection Plan'){
							if(manufacturerId != null && manufacturerId != soItem_i.Products__r.Select_Manufacturer__c){
								manufacturerId = null;
								break;
							}
							manufacturerId = soItem_i.Products__r.Select_Manufacturer__c;
							defaultCarrier = (soItem_i.Products__r.Select_Manufacturer__c != null && soItem_i.Products__r.Select_Manufacturer__r.Default_Carrier__c != null) ? soItem_i.Products__r.Select_Manufacturer__r.Default_Carrier__c : null;
						}
					}
				}
			}
			so_i.Manufacturer__c = manufacturerId;
			if(manufacturerId != null && defaultCarrier != null ) so_i.Carrier__c = defaultCarrier;
			so_i.Protection_Plan_Only__c = isOnlyProtectionPlan;
			so_i.IsManufacturerSet__c = true;
		}
		if(salesOrderList.size() > 0){
			update salesOrderList;
		}
	}
	
	static void checkBulkExcluding(List<SO_Line_Items__c> orderItemList, Map<id, SO_Line_Items__c> orderItemOldMap){
		list<SO_Line_Items__c> orderItemListToUpdate = new list<SO_Line_Items__c>();
		for (SO_Line_Items__c sli : orderItemList){
			if (orderItemOldMap == null){
				orderItemListToUpdate.add(sli);
			}
			else if (sli.Config_Product__r != orderItemOldMap.get(sli.id).Config_Product__r || sli.Bundle_Item__c != orderItemOldMap.get(sli.id).Bundle_Item__c){
				SO_Line_ItemTriggerHandler.inLoop = false;
				orderItemListToUpdate.add(sli);
			}
		}
		if(checkLoop() && orderItemListToUpdate.size() == 0){
			return;
		}

		Map<Id, Sales_Order__c> orderToExcludeFromBulkMap = new Map<Id, Sales_Order__c>();
		Map<Id, SO_Line_Items__c> itemOrderToExcludeFromBulkMap = new Map<Id, SO_Line_Items__c>();
		for(SO_Line_Items__c curretnOrderItem_i : [SELECT Id, Config_Product__r.Product_Excluded_from_bulk__c, Products__r.Product_Excluded_from_bulk__c, 
													Bundle_Item__r.Product__r.Product_Excluded_from_bulk__c, Sales_Order__c, Product_Excluded_from_bulk__c
													FROM  SO_Line_Items__c 
													WHERE Id IN :orderItemListToUpdate]) {
			
			Boolean excludeFormBulkFlag = false;
			if(curretnOrderItem_i.Config_Product__r != null ) {
				excludeFormBulkFlag = curretnOrderItem_i.Config_Product__r.Product_Excluded_from_bulk__c;
			}
			if(!excludeFormBulkFlag && curretnOrderItem_i.Bundle_Item__r != null) {
				excludeFormBulkFlag = curretnOrderItem_i.Bundle_Item__r.Product__r.Product_Excluded_from_bulk__c;
			}
			if (!excludeFormBulkFlag){
				excludeFormBulkFlag = curretnOrderItem_i.Products__r.Product_Excluded_from_bulk__c;
			}
			
			
			curretnOrderItem_i.Product_Excluded_from_bulk__c = excludeFormBulkFlag;
			if (excludeFormBulkFlag){
				itemOrderToExcludeFromBulkMap.put(curretnOrderItem_i.id, curretnOrderItem_i);
				
				if(!orderToExcludeFromBulkMap.containsKey(curretnOrderItem_i.Sales_Order__c)) {
					orderToExcludeFromBulkMap.put(curretnOrderItem_i.Sales_Order__c, new Sales_Order__c(Id = curretnOrderItem_i.Sales_Order__c, Product_Excluded_from_bulk__c = excludeFormBulkFlag));
				}
			}
		}

		if(!itemOrderToExcludeFromBulkMap.IsEmpty()) {
			update itemOrderToExcludeFromBulkMap.values();
		}

		if(!orderToExcludeFromBulkMap.isEmpty()) {
			update orderToExcludeFromBulkMap.values();
		}

	}	

	static Boolean checkLoop(){
		Boolean result = SO_Line_ItemTriggerHandler.inLoop;
		SO_Line_ItemTriggerHandler.inLoop = true;
		return result;
	}
}