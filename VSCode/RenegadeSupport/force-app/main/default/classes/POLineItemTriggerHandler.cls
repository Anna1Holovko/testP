/**
 * @File Name          : POLineItemTriggerHandler.cls
 * @Description        : 
 * @Author             : Synebo
 * @Group              : 
 * @Last Modified By   : Synebo
 * @Last Modified On   : 4/21/2020, 8:46:20 AM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    4/21/2020   Synebo     Initial Version
**/
public with sharing class POLineItemTriggerHandler {

    public static void afterInsert (list<PO_Line_Items__c> poliNewList){
    	set<id> poIds = new set<id>();
    	for (PO_Line_Items__c li : poliNewList){
    		poIds.add(li.Purchase_Order__c);
    	}
    	updateSoItemShippedWithFedex (poIds);
    }
    public static void updateSoItemShippedWithFedex (set<id> poIds){
    	map<id, Purchase_Order__c> pos = new map<id, Purchase_Order__c>([select id from Purchase_Order__c where id in:poIds]);
    	PurchaseOrderTriggerHandler.updateSoItemShippedWithFedex(pos.keyset());
    }
    public static void beforeInsert (list<PO_Line_Items__c> poliNewList){
    	list<PO_Line_Items__c> poliToUpdateSkuName = new list<PO_Line_Items__c>();
    	list<string> soliToUpdateSkuName = new list<string>();
    	for (PO_Line_Items__c li : poliNewList){
    		if (li.SKU_name_and_list__c == null || li.SKU_name_and_list__c == '' || li.SKU_List__c == null || li.SKU_List__c == ''){
    			poliToUpdateSkuName.add(li);
    			soliToUpdateSkuName.add(li.SO_Line_Item__c);
    		}
    	}
    	if (poliToUpdateSkuName.size() > 0){
    		updatePoliSkuName(poliToUpdateSkuName, soliToUpdateSkuName);
    	}
    }
    public static void updatePoliSkuName(list<PO_Line_Items__c> poliToUpdateSkuName, list<string> soliToUpdateSkuName){
		map<id, SO_Line_Items__c> soItems = new map<id, SO_Line_Items__c>([SELECT Id, Products__r.sku_and_name_list__c, Products__r.SKU_List__c, Products__r.SKU__c, Bundle_Item__r.Product__r.sku_and_name_list__c, Bundle_Item__r.Product__r.SKU_List__c, 
                                                                           Bundle_Item__r.Product__r.SKU__c, Bundle_Item__c, Config_Product__c, Config_Product__r.sku_and_name_list__c, Config_Product__r.SKU_List__c, Config_Product__r.SKU__c 
                                                                           FROM SO_Line_Items__c 
                                                                           WHERE Id in :soliToUpdateSkuName]);
        system.debug('soItems: ' + soItems);
        system.debug('poliToUpdateSkuName: ' + poliToUpdateSkuName);
        system.debug('soliToUpdateSkuName: ' + soliToUpdateSkuName);
        for (PO_Line_Items__c li : poliToUpdateSkuName){
            if (soItems.containsKey(li.SO_Line_Item__c)) {
                SO_Line_Items__c sl = soItems.get(li.SO_Line_Item__c);
                string skuStr = sl.Config_Product__c != null ? sl.Config_Product__r.sku_and_name_list__c : sl.Bundle_Item__c != null ? sl.Bundle_Item__r.Product__r.sku_and_name_list__c : sl.Products__r.sku_and_name_list__c;
                li.SKU_name_and_list__c = skuStr;
                try {
                    list<productInfo> productsInfo = (list<productInfo>)json.deserialize(skuStr, list<productInfo>.class);
                    for (productInfo pi : productsInfo){
                        if (li.SKU_List__c == null){
                            li.SKU_List__c = pi.sku;
                        }
                        else {
                            li.SKU_List__c = li.SKU_List__c + ', ' + pi.sku;
                        }
                    }
                }
                catch (exception e){
                    system.debug('e ' + e.getmessage());
                }
                if (li.SKU_List__c == null || li.SKU_List__c == ''){
                    string skuList = sl.Config_Product__c != null ? sl.Config_Product__r.SKU_List__c : sl.Bundle_Item__c != null ? sl.Bundle_Item__r.Product__r.SKU_List__c : sl.Products__r.SKU_List__c;
                    li.SKU_List__c = skuList;
                }
            }
        }
    }
    
    public class productInfo{
    	public string sku {get; set;}
    	public string name {get; set;}
    	public string weight {get; set;}
    	public string dimensions {get; set;}
    }
}