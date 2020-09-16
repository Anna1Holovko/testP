public with sharing class ProductsTriggerHandler {
	
	public static void beforeInsert(list<Products__c> newProducts){
		for (Products__c p : newProducts){
			if (p.SKU_1__c != null && p.SKU_1__c != ''){
				updateSkuNameList(p);
			}
		}
	}
	
	public static void beforeUpdate(list<Products__c> newProducts, map<id, Products__c> oldProductsMap){
		for (Products__c p : newProducts){
			if (p.SKU_1__c != null && p.SKU_1__c != ''){
				updateSkuNameList(p);
			}
		}
	}
	
	// public static void afterInsert(List<Products__c> newProductsList) {
	// 	//checkFromBulkExcluding(newProductsList, null);
	// }

	public static void afterUpdate(List<Products__c> newProductsList, Map<id, Products__c> oldProductsMap) {
		checkFromBulkExcluding(newProductsList, oldProductsMap);
	}

	private static void updateSkuNameList(Products__c p){
		list<productInfo> productsInfo = new list<productInfo>();
		for (integer i=1; i<11; i++){
			if (p.get(string.valueof('SKU_' + i + '__c')) == null || p.get(string.valueof('SKU_' + i + '__c')) == '') break;
			system.debug(p.get(string.valueof('SKU_' + i + '__c')));
			productInfo pi = new productInfo();
			pi.sku = string.valueof(p.get(string.valueof('SKU_' + i + '__c')));
			p.put(string.valueof('SKU_' + i + '__c'), '');
			
			if (p.get(string.valueof('SKU_Name_' + i + '__c')) != null && p.get(string.valueof('SKU_Name_' + i + '__c')) != ''){
				pi.name = string.valueof(p.get(string.valueof('SKU_Name_' + i + '__c')));
				p.put(string.valueof('SKU_Name_' + i + '__c'), '');
			}
			else{
				pi.name = '';
			}
			
			if (p.get(string.valueof('SKU_Weight_' + i + '__c')) != null && p.get(string.valueof('SKU_Weight_' + i + '__c')) != ''){
				pi.weight = string.valueof(p.get(string.valueof('SKU_Weight_' + i + '__c')));
				p.put(string.valueof('SKU_Weight_' + i + '__c'), '');
			}
			else{
				pi.weight = '';
			}
			
			if (p.get(string.valueof('SKU_Dimensions_' + i + '__c')) != null && p.get(string.valueof('SKU_Dimensions_' + i + '__c')) != ''){
				pi.dimensions = string.valueof(p.get(string.valueof('SKU_Dimensions_' + i + '__c')));
				p.put(string.valueof('SKU_Dimensions_' + i + '__c'), '');
			}
			else{
				pi.dimensions = '';
			}
			system.debug('pi = ' + pi);
			productsInfo.add(pi);
		}
		system.debug('productsInfo = ' + productsInfo);
		string json = Json.serialize(productsInfo);
		system.debug('json = ' + json);
		p.SKU_and_name_list__c = json;
	}

	static void checkFromBulkExcluding(List<Products__c> newProductList, Map<Id, Products__c> oldProductsMap) {
		List<String> orderStatusValidList = new List<String> {'Processing', 'Need Payment', 'Awaiting Confirmation'};
		Date orderCreateDateLimit = Date.newinstance(2020, 1, 1);
		Set<String> productIdForExcludeSet = new Set<String>();
		Map<String, Products__c> productIdForExcludeMap = new Map<String, Products__c>();
		for(Products__c currentProduct_i : newProductList){
			if((currentProduct_i.Product_Excluded_from_bulk__c != oldProductsMap.get(currentProduct_i.Id).Product_Excluded_from_bulk__c)){
				productIdForExcludeSet.add(currentProduct_i.Id);
				productIdForExcludeMap.put(currentProduct_i.Id, currentProduct_i);
			}
		}
		List<SO_Line_Items__c> OrderItemToExcludeFromBulkList = [SELECT Id, Sales_Order__c, Config_Product__r.Product_Excluded_from_bulk__c, 
																Products__r.Product_Excluded_from_bulk__c, 
																Bundle_Item__r.Product__r.Product_Excluded_from_bulk__c
																FROM SO_Line_Items__c
																WHERE (Config_Product__c IN :productIdForExcludeMap.keySet() OR Products__c IN :productIdForExcludeMap.keySet() 
																	OR Bundle_Item__r.Product__c IN :productIdForExcludeMap.keySet()) 
																	AND Item__c = 'Processing' AND Sales_Order__r.Order_Status__c IN :orderStatusValidList
																	AND Sales_Order__r.CreatedDate > :orderCreateDateLimit];
											
		Map<Id, Sales_Order__c> orderToExcludeFromBulkMap = new Map<Id, Sales_Order__c>();
		for(SO_Line_Items__c curretnOrderItem_i : OrderItemToExcludeFromBulkList) {
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
			if(!orderToExcludeFromBulkMap.containsKey(curretnOrderItem_i.Sales_Order__c)) {
				orderToExcludeFromBulkMap.put(curretnOrderItem_i.Sales_Order__c, new Sales_Order__c(Id = curretnOrderItem_i.Sales_Order__c, Product_Excluded_from_bulk__c = excludeFormBulkFlag));
			}
		}

		if(!OrderItemToExcludeFromBulkList.IsEmpty()) {
			update OrderItemToExcludeFromBulkList;
		}

		if(!orderToExcludeFromBulkMap.isEmpty()) {
			update orderToExcludeFromBulkMap.values();
		}

	}

	
    public class productInfo{
    	public string sku {get; set;}
    	public string name {get; set;}
    	public string weight {get; set;}
    	public string dimensions {get; set;}
    }
}