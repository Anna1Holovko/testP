/**
 * @File Name          : PurchaseOrderTriggerHandler.cls
 * @Description        : 
 * @Author             : Synebo
 * @Group              : 
 * @Last Modified By   : Synebo
 * @Last Modified On   : 09-14-2020
 * @Modification Log   : 
 * Ver       Date            Author                 Modification
 * 1.0    4/21/2020   Synebo     Initial Version
**/
public with sharing class PurchaseOrderTriggerHandler {

    public static boolean isChangedOnView = false;
    
    public static void beforeInsert (list<Purchase_Order__c> newPurchaseOrder){
        set<string> accountIds = new set<string>();
        for(Purchase_Order__c newPO: newPurchaseOrder) {
            if(newPO.Ship_From__c != null) {
                accountIds.add(newPO.Ship_From__c);
            }
        }
        if (accountIds.size() > 0){
            copyEmailFromAccount(accountIds, newPurchaseOrder);
        }
        system.debug('newPurchaseOrder0 = ' + newPurchaseOrder);
        popuateShippingTime(newPurchaseOrder);
        system.debug('newPurchaseOrder = ' + newPurchaseOrder);
        defaultLibertyHub(newPurchaseOrder);
        checkAndFillOrderNumber(newPurchaseOrder);
    }
    
    public static void beforeUpdate (list<Purchase_Order__c> newPurchaseOrder, map<id, Purchase_Order__c> oldPurchaseOrder){
        //set<string> ediManufacturers = getEdiManufacturers();
        set<id> exludedDeliveryCompanies = getExludedDeliveryCompanies(newPurchaseOrder);
        set<string> accountIds = new set<string>();
        set<id> manufactureId = new set<id>();
        for(Purchase_Order__c newPO: newPurchaseOrder) {
            System.debug('newPO.Status__c: '+newPO.Status__c);
            if(((newPO.Tracking_Number__c != oldPurchaseOrder.get(newPO.Id).Tracking_Number__c && newPO.Load_Date__c != null) || (newPO.Load_Date__c != null && oldPurchaseOrder.get(newPO.Id).Load_Date__c == null && newPO.Tracking_Number__c != null)) && newPO.Status__c == 'Draft') {
                newPO.Status__c = 'On Order';
            }
            if(oldPurchaseOrder.get(newPO.Id).Load_Date__c != null && oldPurchaseOrder.get(newPO.Id).Load_Date__c != newPO.Load_Date__c){
                newPO.Expected_load_date_changed__c = true;
            }
            if (newPO.Ship_From__c != oldPurchaseOrder.get(newPO.Id).Ship_From__c || newPO.Email__c == null){// && newPO.Order_Communication_Type__c == 'Email'){
                System.debug('newPO.Ship_From__c: '+newPO.Ship_From__c);
                if (newPO.Ship_From__c != null){
                    accountIds.add(newPO.Ship_From__c);
                }
                else {
                    newPO.Email__c = '';
                    newPO.Additional_email_1__c = '';
                    newPO.Additional_email_2__c = '';
                }
            }
            /*if (newPO.Suggested_Delivery_Comapny__c != null && exludedDeliveryCompanies.contains(string.valueof(newPO.Suggested_Delivery_Comapny__c).substring(0,15))){
                    newPO.Order_Communication_Type__c = 'Email';
                    system.debug('22newPO.Order_Communication_Type__c = ' + newPO.Order_Communication_Type__c);
            }*/
        }
        if (accountIds.size() > 0){
            copyEmailFromAccount(accountIds, newPurchaseOrder);
        }
        system.debug('newPurchaseOrder = ' + newPurchaseOrder);
        checkAndFillOrderNumber(newPurchaseOrder);
    }
    
    public static void copyEmailFromAccount(set<string> accountIds, list<Purchase_Order__c> newPurchaseOrder){
        set<string> ediManufacturers = getEdiManufacturers();
        set<id> exludedDeliveryCompanies = getExludedDeliveryCompanies(newPurchaseOrder);
        map<string,Account> accountMap = new map<string,Account>();
        for(Account acc : [Select id,Email__c,Partner_Email__c, Additional_email_1__c, Additional_email_2__c, Order_Communication_Type__c from Account where id=:accountIds]) {
            accountMap.put(string.valueof(acc.id).substring(0,15),acc);
        }
        for(Purchase_Order__c newPO: newPurchaseOrder) {
            
            if(newPO.Ship_From__c != null && accountMap.containskey(string.valueof(newPO.Ship_From__c).substring(0,15)) && accountMap.get(string.valueof(newPO.Ship_From__c).substring(0,15)).Order_Communication_Type__c == 'EDI' && ediManufacturers.contains(string.valueof(newPO.Ship_From__c).substring(0,15)) && (newPO.Suggested_Delivery_Comapny__c == null || !exludedDeliveryCompanies.contains(string.valueof(newPO.Suggested_Delivery_Comapny__c).substring(0,15)))) {
                newPO.Order_Communication_Type__c = 'EDI';
            }
            else if(newPO.Ship_From__c != null){// if (newPO.Suggested_Delivery_Comapny__c != null && exludedDeliveryCompanies.contains(string.valueof(newPO.Suggested_Delivery_Comapny__c).substring(0,15))){
                newPO.Order_Communication_Type__c = 'Email';
            }else{
                newPO.Order_Communication_Type__c = null;
            }
            
            if(newPO.Order_Communication_Type__c == 'Email' && newPO.Ship_From__c != null && accountMap.containskey(string.valueof(newPO.Ship_From__c).substring(0,15))) {
                newPO.Email__c = accountMap.get(string.valueof(newPO.Ship_From__c).substring(0,15)).Partner_Email__c;
                newPO.Additional_email_1__c = accountMap.get(string.valueof(newPO.Ship_From__c).substring(0,15)).Additional_email_1__c;
                newPO.Additional_email_2__c = accountMap.get(string.valueof(newPO.Ship_From__c).substring(0,15)).Additional_email_2__c;
            }
        }
        system.debug('newPurchaseOrder 2 ' + newPurchaseOrder);
    }
    
    public static void afterUpdate (list<Purchase_Order__c> newPurchaseOrder, map<id, Purchase_Order__c> oldPurchaseOrder){
        
        list<Purchase_Order__c> updateStatusforPoLIneList = new list<Purchase_Order__c>();
        map<id, Purchase_Order__c> poToUpdate = new map<id, Purchase_Order__c>();
        set<id> poIds = new set<id>();
        set<id> poIdsToUpdateShipmentThatTheNotificationWasSent = new set<id>();

 
        List<Purchase_Order__c> poListChangedToShipped = new List<Purchase_Order__c>();
        for (Purchase_Order__c po : newPurchaseOrder){
        	if (po.Send_Shipment_Notification_to_Customer__c && !oldPurchaseOrder.get(po.id).Send_Shipment_Notification_to_Customer__c && oldPurchaseOrder.get(po.id).Send_Shipment_Notification_in_15_min__c != null){
        		poIdsToUpdateShipmentThatTheNotificationWasSent.add(po.id);
        	}
            if (po.Customer_Email__c != oldPurchaseOrder.get(po.id).Customer_Email__c){
                Purchase_Order__c pon = new Purchase_Order__c(id = po.id, Customer_Email_initial__c = po.Customer_Email__c);
                poToUpdate.put(pon.id, pon);
            }
            if(po.Status__c != oldPurchaseOrder.get(po.Id).Status__c && po.Status__c == 'On Order')
            {
                updateStatusforPoLIneList.add(po);
            }
            if(po.Tracking_Number__c != oldPurchaseOrder.get(po.Id).Tracking_Number__c && po.Status__c == 'Draft' && po.Load_Date__c != null && po.Load_Date__c != null) {
                po.Status__c = 'On Order';
                updateStatusforPoLIneList.add(po);
            }
            if(po.Ship_From__c != oldPurchaseOrder.get(po.id).Ship_From__c && po.Ship_From__r.Multiple_Locations__c == false) {
                set<id> MfId = new set<id>();
                MfId.add(po.Ship_From__c);
                Purchase_Order__c pon;
                if (poToUpdate.containskey(po.id)){
                    pon = poToUpdate.get(po.id);
                }
                else{
                    pon = new Purchase_Order__c(id = po.id);
                }
                pon.Suggested_Trucking__c = salesOrderelatedlistController.truckingAutoId(po.Suggested_Delivery_Comapny__c , MfId, Integer.valueOf(po.Total_Weight_Pounds__c));
                poToUpdate.put(pon.id, pon);
            }
            System.debug('po.Order_Communication_Type__c'+po.Order_Communication_Type__c);
            System.debug('po.Resend__c'+po.Resend__c);
            System.debug('oldPurchaseOrder.get(po.id).Resend__c'+oldPurchaseOrder.get(po.id).Resend__c);
            if (po.Order_Communication_Type__c == 'EDI' && po.Resend__c != oldPurchaseOrder.get(po.id).Resend__c && !po.Do_not_notify_manufacturer__c){
                generateForm(po.id);
            }
            if (po.Carrier__c != oldPurchaseOrder.get(po.id).Carrier__c){
                poIds.add(po.id);
            }
            if(po.Status__c != oldPurchaseOrder.get(po.id).Status__c && po.Status__c == 'Shipped') {
                poListChangedToShipped.add(po);
            }
        }
        if(updateStatusforPoLIneList.size() > 0)
        {
            PurchaseOrderHelperClass.updateStatusforPoLIne(updateStatusforPoLIneList);
            System.debug('updateStatusforPoLIneList'+updateStatusforPoLIneList);
        }
        if (poToUpdate.values().size() > 0){
            update poToUpdate.values();
        }
        if (poIds.size() > 0){
            updateSoItemShippedWithFedex(poIds);
        }
        if (poIdsToUpdateShipmentThatTheNotificationWasSent.size() > 0){
            updateShipmentThatTheNotificationWasSent(poIdsToUpdateShipmentThatTheNotificationWasSent);
        }    
        if(poListChangedToShipped.size() > 0){
            updateRetaggedShipmentLines(poListChangedToShipped);
        }
        
        //updateSalesOrderStatus(newPurchaseOrder, oldPurchaseOrder);
        
    }

    static void updateRetaggedShipmentLines(List<Purchase_Order__c> poListChangedToShipped){
        
        
        List<Shipment_Line_Item__c> shlToUpdateList = new List<Shipment_Line_Item__c>();
        for(Shipment_Line_Item__c sl_i : [SELECT Id, Originating_Inventory_SHL__c FROM Shipment_Line_Item__c WHERE PO_Line_Item__r.Purchase_Order__c IN :poListChangedToShipped AND PO_Line_Item__r.Purchase_Order__r.Recordtype.Name = 'Internal PO' AND Originating_Inventory_SHL__r.Shipment_Item_Status__c = 'Retag in process']){
            shlToUpdateList.add(new Shipment_Line_Item__c(Id = sl_i.Originating_Inventory_SHL__c, Shipment_Item_Status__c = 'Retagged' ));             
        }
        update shlToUpdateList;
    }
    public static void afterInsert (list<Purchase_Order__c> newPurchaseOrder){
        //set<id> salesOrderIds = new set<id>();
        map<id, Sales_Order__c> soToUpdate = new map<id, Sales_Order__c>();
        map<id, Purchase_Order__c> poToUpdate = new map<id, Purchase_Order__c>();
        Set<Id> partsSoIdSet = new Set<Id>();
        Set<Id> replaceSoIdSet = new Set<Id>();
        //set<id> poIds = new set<id>(); 
        for (Purchase_Order__c po : newPurchaseOrder){
            //salesOrderIds.add(po.Sales_Order__c);
            if (po.Customer_Email__c != null){
                Purchase_Order__c pon = new Purchase_Order__c(id = po.id, Customer_Email_initial__c = po.Customer_Email__c);
                poToUpdate.put(pon.id, pon);
            }
            if (po.Order_Communication_Type__c == 'EDI' && !po.Do_not_notify_manufacturer__c && !po.Created_In_Bulk__c){
                generateForm(po.id);
            }
            if(po.Parts_PO__c){
                partsSoIdSet.add(po.Sales_Order__c);
            }
            if(po.Replacement_PO__c){
                replaceSoIdSet.add(po.Sales_Order__c);
            }



            /*if (po.Carrier__c == 'FedEx'){
                poIds.add(po.id);
            }*/
        }
        /*if (salesOrderIds.size() > 0){
            soToUpdate = updateOrdersStatus(salesOrderIds, soToUpdate);
        }*/
        if (soToUpdate.values().size() > 0){
            update soToUpdate.values();
        }
        if (poToUpdate.values().size() > 0){
            update poToUpdate.values();
        }
        if (partsSoIdSet.size() > 0){
            updatePartsSHL(partsSoIdSet);
        }
        if (replaceSoIdSet.size() > 0){
            updateReplaceSHL(replaceSoIdSet);
        }
        /*if (poIds.size() > 0){
            updateSoItemShippedWithFedex(poIds);
        }*/
    }

    private static void defaultLibertyHub(List<Purchase_Order__c> newPurchaseOrder){
        Set<Id> soIdSet = new Set<Id>();
        for(Purchase_Order__c po_i: newPurchaseOrder) {
            if(String.isBlank(po_i.Liberty_Hub__c) && po_i.Sales_Order__c != null && !isChangedOnView) {
                soIdSet.add(po_i.Sales_Order__c);
            }
        }
        if(!soIdSet.isEmpty()){
            List<Manufacturer_hubs_locations_by_state__mdt> hubsLocationsStateMDList = [
            SELECT Id, LibertyHubLocation__c, State__c 
            FROM Manufacturer_hubs_locations_by_state__mdt];

            Map<Id, Sales_Order__c> soMap = new Map<Id, Sales_Order__c>(
                [SELECT Id, Manufacturer__c, Manufacturer__r.Name, Manufacturer__r.Multiple_Locations__c, Shipping_State__c 
                FROM Sales_Order__c 
                WHERE ID IN: soIdSet AND Manufacturer__r.Multiple_Locations__c = true]
            );
            for(Purchase_Order__c po_i: newPurchaseOrder) {
                if(String.isBlank(po_i.Liberty_Hub__c) && po_i.Sales_Order__c != null && !isChangedOnView
                    && soMap.containsKey(po_i.Sales_Order__c) && soMap.get(po_i.Sales_Order__c).Manufacturer__c != null
                    && 'Liberty'.equalsIgnoreCase(soMap.get(po_i.Sales_Order__c).Manufacturer__r.Name)) {
                        for(Manufacturer_hubs_locations_by_state__mdt mdt_i : hubsLocationsStateMDList) {
                            if(mdt_i.State__c.equalsIgnoreCase(soMap.get(po_i.Sales_Order__c).Shipping_State__c)) {
                                po_i.Liberty_Hub__c = mdt_i.LibertyHubLocation__c ;
                            }
                        }
                }
            }
        }
    }

    private static void updatePartsSHL(Set<Id> partsSoIdSet){
        List<Shipment_Line_Item__c> itemList = [SELECT Id, Parts_PO__c, Shipment__r.Purchase_Order__c FROM Shipment_Line_Item__c 
                                                        WHERE Shipment__c IN (SELECT Id FROM Shipment__c WHERE Related_Sales_Order__c IN :partsSoIdSet)];
        for(Shipment_Line_Item__c item_i : itemList){
            item_i.Parts_PO__c = item_i.Shipment__r.Purchase_Order__c;
        }
        update itemList;
    }

    private static void updateReplaceSHL(Set<Id> replaceSoIdSet){
        List<Shipment_Line_Item__c> itemList = [SELECT Id, Replacement_PO__c, Shipment__r.Purchase_Order__c FROM Shipment_Line_Item__c 
                                                        WHERE Shipment__c IN (SELECT Id FROM Shipment__c WHERE Related_Sales_Order__c IN :replaceSoIdSet)];
        for(Shipment_Line_Item__c item_i : itemList){
            item_i.Replacement_PO__c = item_i.Shipment__r.Purchase_Order__c;
        }
        update itemList;
    }
    
    
    public static void updateShipmentThatTheNotificationWasSent(set<id> poIds){
    	list<Shipment__c> shipments = [select Shipment_notification_sent_to_customer__c from Shipment__c where Shipment_notification_sent_to_customer__c = null 
    									and Purchase_Order__c in :poIds and Carrier_Name__c != null and Tracking_Number__c != null];
    	if (shipments.size() == 0) return;
    	for (Shipment__c s : shipments){
    		s.Shipment_notification_sent_to_customer__c = system.now();
    	}
    	update shipments;
    }
    
     
    public static void updateSoItemShippedWithFedex(set<id> poIds){
        set<id> polIdsToAvoidDuplicates = new set<id>();
        list<SO_Line_Items__c> soItemsToUpdate = new list<SO_Line_Items__c>();
        list<PO_Line_Items__c>  pols = [select Purchase_Order__r.Carrier__c, SO_Line_Item__c from PO_Line_Items__c where Purchase_Order__c in :poIds and SO_Line_Item__c != null];
        for (PO_Line_Items__c pol :pols){
            if (polIdsToAvoidDuplicates.contains(pol.SO_Line_Item__c)) continue;
            polIdsToAvoidDuplicates.add(pol.SO_Line_Item__c);
            SO_Line_Items__c soi = new SO_Line_Items__c(id = pol.SO_Line_Item__c);
            if(pol.Purchase_Order__r.Carrier__c != null){
                soi.Shipped_with_Fedex__c = true;
            }
            else{
                soi.Shipped_with_Fedex__c = false;
            }
            soItemsToUpdate.add(soi);
        }
        if (soItemsToUpdate.size() > 0){
            update soItemsToUpdate;
        }
    }
    
    
    private static void generateForm(string poId){
        PurchaseOrderOutboundFrom.sendForm(poId);
    }
    
    private static set<id> getExludedDeliveryCompanies (list<Purchase_Order__c> newPurchaseOrder){
        list<string> sdIds = new list<string>();
        for (Purchase_Order__c po : newPurchaseOrder){
            if (po.Suggested_Delivery_Comapny__c != null){
                sdIds.add(po.Suggested_Delivery_Comapny__c);
            }
        }
        map <id,Account> accounts = new map<id,Account>([select id from Account where id in :sdIds and Ashley_Ship_to_ID__c != null and Ashley_Ship_to_ID__c != '' and Ashley_Ship_to_ID__c = 'EXCLUDE']);
        return accounts.keyset();
    }
    
    private static set<string> getEdiManufacturers (){
        set<string> ret = new set<string>();
        list<EDI_Map__mdt> ediSetting = [select Manufacturer_ID__c from EDI_Map__mdt where Inactive__c = false];
        for (EDI_Map__mdt e : ediSetting){
            ret.add(e.Manufacturer_ID__c);
        }
        return ret;
    }
    
   /* private static map<id, Sales_Order__c> updateOrdersStatus (set<id> salesOrderIds, map<id, Sales_Order__c> soToUpdate){
        map<id, Sales_Order__c> ret = soToUpdate;
        
        list<Sales_Order__c> sos = [select id, Order_Status__c, (select Item__c from SO_Line_Items__r where Manufacturer__c != 'Protection Plan') from Sales_Order__c where id in :salesOrderIds];
        system.debug('sos = ' + sos);
        for (Sales_Order__c so : sos){
            boolean first = true;
            boolean wasUpdated = false;
            string status = '';
            for (SO_Line_Items__c po : so.SO_Line_Items__r){
                system.debug('first = ' + first);
                system.debug('po.Item__c = ' + po.Item__c);
                system.debug('status = ' + status);
                if (first){
                    status = po.Item__c;
                    first = false;
                }
                else if (po.Item__c != status){
                    wasUpdated = true;
                    so.Order_Status__c = 'Multiple Statuses';
                    break;
                }
            }
            system.debug('wasUpdated = ' + wasUpdated);
            if (!wasUpdated){
                so.Order_Status__c = 'Ordered from Manufacturer';
            }
            system.debug('so.Order_Status__c = ' + so.Order_Status__c);
            ret.put(so.id, so);
        }
        return ret;
    }*/
    
    /*private static void updateSalesOrderStatus(List<Purchase_Order__c> purchaseOrderNewList, Map<Id, Purchase_Order__c> purchaseOrderOldMap){
        
        Set<Id> salesOrderIdSet = new Set<Id>();
        for(Purchase_Order__c purchaseOrder_i : purchaseOrderNewList){
            if(purchaseOrder_i.Status__c != purchaseOrderOldMap.get(purchaseOrder_i.Id).Status__c && purchaseOrder_i.Status__c == 'Shipped'){
                salesOrderIdSet.add(purchaseOrder_i.Sales_Order__c);
            }
        }
        if(salesOrderIdSet.size() > 0){
            List<Purchase_Order__c> allPurchaseOrderList = [SELECT Id, Status__c, Sales_Order__c, Carrier__c FROM Purchase_Order__c WHERE Sales_Order__c IN :salesOrderIdSet  ];
            Map<Id, List<Purchase_Order__c>> salesOrderIdToPurchaseOrdersMap = new Map<Id, List<Purchase_Order__c>>();
            
            for(Purchase_Order__c purchaseOrder_i: [SELECT Id, Status__c, Sales_Order__c, Carrier__c FROM Purchase_Order__c WHERE Sales_Order__c IN :salesOrderIdSet  ]){
                if(!salesOrderIdToPurchaseOrdersMap.containsKey(purchaseOrder_i.Sales_Order__c)){
                    salesOrderIdToPurchaseOrdersMap.put(purchaseOrder_i.Sales_Order__c, new List<Purchase_Order__c>());
                }
                salesOrderIdToPurchaseOrdersMap.get(purchaseOrder_i.Sales_Order__c).add(purchaseOrder_i);
            }
            
            Map<Id, Boolean> isShippedSOMap = new Map<Id, Boolean>();
            
            Map<Id, Boolean> isMultiTypleCarrierMap = new Map<Id, Boolean>();
            
            Map<Id, String> soIdTOCarrierMap = new Map<Id, String>();
            
            for(Id id_i : salesOrderIdToPurchaseOrdersMap.keySet()){
                isShippedSOMap.put(id_i, true); 
                isMultiTypleCarrierMap.put(id_i, true);
                String carrier = salesOrderIdToPurchaseOrdersMap.get(id_i).get(0).Carrier__c;
                for(Purchase_Order__c purchaseOrder_i : salesOrderIdToPurchaseOrdersMap.get(id_i)){
                    if(purchaseOrder_i.Status__c != 'Shipped' ){
                        isShippedSOMap.put(id_i, false);  
                        
                    }
                    if(carrier != purchaseOrder_i.Carrier__c){
                        isMultiTypleCarrierMap.put(id_i, false);
                    }
                    carrier = purchaseOrder_i.Carrier__c;
                }
                
                soIdTOCarrierMap.put(id_i, carrier);
            }
            List<Sales_Order__c> salesOrderToUpdateList = new List<Sales_Order__c>();
            for(Id id_i : isShippedSOMap.keySet()){
                Sales_Order__c soToUpdate = new Sales_Order__c(Id = id_i);
                if(isShippedSOMap.get(id_i)){
                    if(isMultiTypleCarrierMap.get(id_i)){
                        if(soIdTOCarrierMap.get(id_i) == 'FedEx'){
                            soToUpdate.Order_Status__c = 'Routing';
                        }else{
                            soToUpdate.Order_Status__c = 'En Route to Delivery Company';
                        }
                    }else{
                        soToUpdate.Order_Status__c = 'Multiple Statuses';
                    }
                }else{
                    soToUpdate.Order_Status__c = 'Multiple Statuses';
                }
                salesOrderToUpdateList.add(soToUpdate);
            }
            if(salesOrderToUpdateList.size() > 0){
                update salesOrderToUpdateList;
            }
        }
    }*/
    
    private static void popuateShippingTime(List<Purchase_Order__c> newPurchaseOrder){
        Set<Id> salesOrderIdSet = new Set<Id>();
        
        Set<Id> manufactureIdSet = new Set<Id>();
        Set<Id> deliveryIdSet = new Set<Id>();
        
        for(Purchase_Order__c po_i : newPurchaseOrder){
            if(po_i.Ship_From__c != null){
                manufactureIdSet.add(po_i.Ship_From__c);
            }
            if(po_i.Suggested_Delivery_Comapny__c != null){
                deliveryIdSet.add(po_i.Suggested_Delivery_Comapny__c );
            }
        }
        Map<String, String> shippingTimeMap = new Map<String, String>();
        for(Trucking_Rule__c rule_i : [SELECT Selected_Delivery__c, Selected_Manufacturer__c, Shipping_Time__c  FROM Trucking_Rule__c WHERE Selected_Delivery__c IN :deliveryIdSet AND Selected_Manufacturer__c IN :manufactureIdSet ]){
            shippingTimeMap.put(rule_i.Selected_Manufacturer__c + '-' + rule_i.Selected_Delivery__c, rule_i.Shipping_Time__c);
        }
        for(Purchase_Order__c po_i : newPurchaseOrder){
            if(po_i.Ship_From__c != null && po_i.Suggested_Delivery_Comapny__c != null){
                String key = po_i.Ship_From__c + '-' + po_i.Suggested_Delivery_Comapny__c;
                if(shippingTimeMap.containsKey(key)){
                    po_i.Shipping_Time__c = shippingTimeMap.get(key);
                }
            }
        }
    }

    private static void checkAndFillOrderNumber(List<Purchase_Order__c> orderList) {
        for (Purchase_Order__c order_i : orderList) {
            if (string.isEmpty(order_i.Magento_Order_Number_Searchable__c)) {
                order_i.Magento_Order_Number_Searchable__c = order_i.Magento_order_No__c;
            }
        }
    }
}