public with sharing class PurchaseOrderCreationHelper {
    static Map<String, Purchase_Order_Carrier_notes_settings__c> carrierNotesMap = Purchase_Order_Carrier_notes_settings__c.getAll();
    static List<Shipping_Zip_Codes__c > shippingZipCodesList = new List<Shipping_Zip_Codes__c>();
    static Map<Id ,String> accountIdToEtaGroupMap = new Map<Id ,String>();


    public static Set<Id> accountIdSet = new Set<Id>();

    
    public static Map<Id, List<SoLineWrapper>>  obtainSOItems(Set<Id> salesOrderIdSet){
        List<SO_Line_Items__c> bundelSOitemList = [ SELECT  Id,
                                                   Products__r.Non_Furniture_Product__c, 
                                                   Cancelled_Status__c, 
                                                   Quantity_Refunded__c, 
                                                   Price_For_Credit_Memo__c, 
                                                   DiscountAmount_For_Credit_Memo__c, 
                                                   Tax_Amount_For_Credit_Memo__c, 
                                                   Parent_Item_Ordered__c, 
                                                   Unit_Price__c, 
                                                   Product_Cost__c, 
                                                   FedExable__c,
                                                   Products__r.Select_Manufacturer__r.name,
                                                   Products__r.recordtype.name,
                                                   Products__r.recordtypeid,
                                                   Custom_Price__c,
                                                   TaxAmount__c,
                                                   Sub_Total__c,Price__c,
                                                   name,
                                                   Products__c,
                                                   Products__r.Image__c,Products__r.name,
                                                   Manufacturer__c,
                                                   OriginalPrice__c,
                                                   Product_Brand__c,
                                                   Tax_Amount__c,
                                                   Products__r.Select_Manufacturer__r.Direct_Shipping__c,
                                                   Promotion_Brand__c,
                                                   Quantity__c,
                                                   DiscountAmount__c,
                                                   Row_Total__c,
                                                   Quantity_Invoiced__c,
                                                   Sales_Order__c,
                                                   Sales_Order__r.IsFedexable__c,
                                                   Tax_Percent__c,
                                                   UnitPrice__c,
                                                   Bundle_Item__r.Product__c,
                                                   Bundle_Item__c,
                                                   Config_Product__c,
                                                   Product_Name__c,
                                                   ProductSKU__c,
                                                   Product_Url__c,
                                                   Total_Weight_Pounds__c, 
                                                   ProductImageUrl__c,
                                                   Products__r.Select_Manufacturer__r.Ship_To_HUB__c,
                                                   Products__r.Select_Manufacturer__r.Order_Communication_Type__c,
                                                   Products__r.Select_Manufacturer__r.Website,Item__c, 
                                                   Image__c 
                                                   FROM        SO_Line_Items__c 
                                                   WHERE       Bundle_Item__c != null AND Sales_Order__c IN :salesOrderIdSet AND Manufacturer__c != 'Protection Plan' ORDER BY Bundle_Item__r.Order__c];
        
        Map<String, List<SO_Line_Items__c>> productToSOitemsMap = new Map<String, List<SO_Line_Items__c>>();
        
        for(SO_Line_Items__c soLine_i : bundelSOitemList){
            String key = soLine_i.Products__c + '_' + soLine_i.Parent_Item_Ordered__c;
            if(!productToSOitemsMap.containsKey(key)){
                productToSOitemsMap.put(key, new List<SO_Line_Items__c>());
            }
            productToSOitemsMap.get(key).add(soLine_i);
            
            
        }                                        
        
        List<SO_Line_Items__c> soItemList = [   SELECT  Id,
                                             Products__r.Non_Furniture_Product__c, 
                                             Parent_Item_Ordered__c,
                                             Cancelled_Status__c, 
                                             Price_For_Credit_Memo__c, 
                                             DiscountAmount_For_Credit_Memo__c, 
                                             Tax_Amount_For_Credit_Memo__c,
                                             Row_Total_For_Credit_Memo__c, 
                                             ProductImageUrl__c, 
                                             Product_Cost__c, 
                                             FedExable__c,
                                             Products__r.RecordType.Name,
                                             Products__r.recordtypeid,
                                             TaxAmount__c,
                                             Sub_Total__c,
                                             Price__c,
                                             Unit_Price__c, 
                                             name,
                                             Products__c,
                                             Products__r.Image__c,
                                             Products__r.name,
                                             Manufacturer__c,
                                             OriginalPrice__c,
                                             Product_Brand__c,
                                             Quantity_Refunded__c,
                                             Total_Weight_Pounds__c,
                                             Products__r.Select_Manufacturer__r.Order_Communication_Type__c,
                                             Products__r.Select_Manufacturer__r.Website,Bundle_Item__r.Product__c,Products__r.Select_Manufacturer__r.Ship_To_HUB__c,
                                             Tax_Amount__c,
                                             Products__r.Select_Manufacturer__r.Direct_Shipping__c,
                                             Products__r.Select_Manufacturer__c,
                                             Promotion_Brand__c,
                                             Quantity__c,
                                             DiscountAmount__c,
                                             Row_Total__c,
                                             Custom_Price__c, 
                                             Quantity_Invoiced__c,
                                             Sales_Order__c,
                                             Sales_Order__r.Order_Status__c,
                                             Sales_Order__r.IsFedexable__c,
                                             Tax_Percent__c,
                                             UnitPrice__c,
                                             Bundle_Item__c,
                                             Config_Product__c,
                                             Product_Name__c,
                                             ProductSKU__c,
                                             Product_Url__c,
                                             Item__c, 
                                             Image__c 
                                             FROM    SO_Line_Items__c 
                                             WHERE Sales_Order__c IN :salesOrderIdSet AND Bundle_Item__c = null AND Item__c != 'Cancelled' AND Manufacturer__c != 'Protection Plan' ORDER BY ProductSKU__c DESC];
        
        
        Map<Id, List<SoLineWrapper>> salesOrderIdToItemsMap = new Map<Id, List<SoLineWrapper>>();
        for(SO_Line_Items__c soLine_i : soItemList){
            SoLineWrapper lineWrapper = new SoLineWrapper();
            lineWrapper.line = soLine_i;
            lineWrapper.bundleList = new List<SO_Line_Items__c>();
            String keyWithParent = soLine_i.Products__c + '_' + soLine_i.Id;
            String keyWithoutParent = soLine_i.Products__c + '_' + null;
            if(productToSOitemsMap.containsKey(keyWithParent)){
                lineWrapper.bundleList.addAll(productToSOitemsMap.get(keyWithParent));
            }
            if(productToSOitemsMap.containsKey(keyWithoutParent)){
                lineWrapper.bundleList.addAll(productToSOitemsMap.get(keyWithoutParent));
            }
            if(!salesOrderIdToItemsMap.containsKey(soLine_i.Sales_Order__c)){
                salesOrderIdToItemsMap.put(soLine_i.Sales_Order__c, new List<SoLineWrapper>());
            }
            salesOrderIdToItemsMap.get(soLine_i.Sales_Order__c).add(lineWrapper);
        }
        return salesOrderIdToItemsMap;             
    }   
    
    public static Map<Purchase_Order__c, List<PO_Line_Items__c>> createPoAndItems(Map<Id, List<SoLineWrapper>> salesOrderIdToItemsMap, Map<Id, Sales_Order__c> salesOrderMap) {
        getShippingZipCodesList(salesOrderMap.values());

        Map<Purchase_Order__c, List<PO_Line_Items__c>> poToItemsMap = new  Map<Purchase_Order__c, List<PO_Line_Items__c>>();
        
        
        for(Id so_id : salesOrderIdToItemsMap.keySet()){
            Integer totalWeight = 0;
            Sales_Order__c salesOrder = salesOrderMap.get(so_id);
            Purchase_Order__c purcheseOrder = buildPurchaseOrder(salesOrder);
            List<PO_Line_Items__c> poItemList = new List<PO_Line_Items__c>();
            
            
            for(SoLineWrapper lineWrapper_i : salesOrderIdToItemsMap.get(so_id)){
                if(lineWrapper_i.line.Products__r.RecordType.Name == 'Bundled'){
                    for(SO_Line_Items__c bundle : lineWrapper_i.bundleList){
                        if(bundle.Products__c == lineWrapper_i.line.Products__c){
                            Decimal quantity = lineWrapper_i.line.Quantity__c * bundle.Quantity__c;
                            PO_Line_Items__c poItem = buildPurchaseOrderLineItem(bundle, quantity);
                            poItemList.add(poItem);
                        }
                    }
                }else{
                    PO_Line_Items__c poItem = buildPurchaseOrderLineItem(lineWrapper_i.line, lineWrapper_i.line.Quantity__c);
                    poItemList.add(poItem);  
                }
            }
            poToItemsMap.put(purcheseOrder, poItemList);
        }
        
        return poToItemsMap;
    }
    
    public static void insertPoAndItems(Map<Purchase_Order__c, List<PO_Line_Items__c>> poToItemsMap){
        if(poToItemsMap.size() > 0){
            List<Purchase_Order__c> poToInsert = new List<Purchase_Order__c>();
            Map<Integer, List<PO_Line_Items__c>> indexToItemsMap = new Map<Integer, List<PO_Line_Items__c>>();
            Integer index = 0;
            for(Purchase_Order__c po_i : poToItemsMap.keySet()){
                poToInsert.add(po_i);
                indexToItemsMap.put(index, poToItemsMap.get(po_i));
                index++;
            }
            Database.SaveResult[] srList = Database.insert(poToInsert, false);
            Map<Integer, String> poIdToErrorMap = parseSaveResult(srList);
            List<Sales_Order__c> salesOrderToUpdateList = new List<Sales_Order__c>();
            Map<Id, SO_Line_Items__c> salesOrderItemsToUpdateMap = new Map<Id, SO_Line_Items__c>();
            List<PO_Line_Items__c> poItemToInsert = new List<PO_Line_Items__c>();
            index = 0;
            for(Purchase_Order__c po_i : poToItemsMap.keySet()){
                Sales_Order__c salesOrder = new Sales_Order__c(Id = po_i.Sales_Order__c);
                salesOrder.PO_created_in_bulk__c = true;
                salesOrder.Create_PO__c = false;  
                if(po_i.Id != null){
                    salesOrder.Order_Status__c = 'Ordered from Manufacturer';
                    for(PO_Line_Items__c poItem_i : indexToItemsMap.get(index)){
                        poItem_i.Purchase_Order__c = po_i.Id;
                        poItemToInsert.add(poItem_i);
                        SO_Line_Items__c soItem = new SO_Line_Items__c(Id = poItem_i.SO_Line_Item__c);
                        soItem.Item__c = 'Order From Manufacturer';  
                        salesOrderItemsToUpdateMap.put(soItem.Id, soItem);
                        if(poItem_i.SO_Line_Item__r.Parent_Item_Ordered__c!= null){
                            SO_Line_Items__c soParentItem = new SO_Line_Items__c(Id = poItem_i.SO_Line_Item__r.Parent_Item_Ordered__c);
                            soParentItem.Item__c = 'Order From Manufacturer';  
                            salesOrderItemsToUpdateMap.put(soParentItem.Id, soParentItem);
                        }
                    }
                }else{
                    salesOrder.Failed_to_update_in_bulk_reason__c = poIdToErrorMap.get(index);
                    salesOrder.Failed_to_update_in_bulk__c = true;
                }
                salesOrderToUpdateList.add(salesOrder);
                index++;
            }
            if(poItemToInsert.size() > 0){
                DataBase.insert(poItemToInsert, false);
            }
            if(salesOrderToUpdateList.size() > 0){
                DataBase.update(salesOrderToUpdateList, false);
            }
            if(salesOrderItemsToUpdateMap.size() > 0){
                DataBase.update(salesOrderItemsToUpdateMap.values(), false);
            }
        }
        
    }
    
    public static Map<Integer, String> parseSaveResult(Database.SaveResult[] srList){
        Map<Integer, String> poIdToErrorMap = new Map<Integer, String>();
        Integer index = 0;
        for(Database.SaveResult result_i : srList){
            String error = '';
            if (!result_i.isSuccess()) {
                error = JSON.serialize(result_i.getErrors());
            }
            poIdToErrorMap.put(index, error);
            index++;
        }
        return poIdToErrorMap;
    }
    
    static Purchase_Order__c buildPurchaseOrder(Sales_Order__c salesOrder){
                       
        Purchase_Order__c purcheseOrder = new Purchase_Order__c();
        purcheseOrder.Sales_Order__c = salesOrder.Id;
        purcheseOrder.Shipping_To_Customer__c = salesOrder.Customer_shipping_Address__c;
        purcheseOrder.Carrier__c = salesOrder.Carrier__c;
        purcheseOrder.Requested_delivery_date__c  = salesOrder.Requested_Arrival_Date__c;
        purcheseOrder.Carrier_Info__c = carrierNotesMap.containsKey(purcheseOrder.Carrier__c) ? carrierNotesMap.get(purcheseOrder.Carrier__c).Notes__c : null;
        purcheseOrder.Manufacturer_ETA_Group__c = '1 Week';
        purcheseOrder.Status__c = 'Draft';
        purcheseOrder.Ship_From__c = salesOrder.Manufacturer__c;//orderItToManifactureIdMap.get(salesOrder.Id);
        purcheseOrder.Created_In_Bulk__c = true;
        if(salesOrder.IsFedexable__c == false){
            purcheseOrder.Carrier__c = null;
            purcheseOrder.Carrier_Info__c = null;
            purcheseOrder.Suggested_delivery_Comapny__c = salesOrder.Delivery_Company__c;
            purcheseOrder.Nearest_Delivery_Company__c = salesOrder.Nearest_Delivery_Company__c; 
            purcheseOrder.Manufacturer_ETA_Group__c = getManufactuterETA(salesOrder);
            purcheseOrder.Suggested_Trucking__c = salesOrder.Suggested_Trucking_Company__c;
        }
        return purcheseOrder;
    }
    
    private static void getShippingZipCodesList(List<Sales_Order__c>salesOrderList){
        Set<String> fieldSet = new Set<String>();
        for(Account account_i : [SELECT Id, ETA_group__c FROM Account WHERE Id IN: accountIdSet]){
            if(account_i.ETA_group__c != null){
                accountIdToEtaGroupMap.put(account_i.Id, account_i.ETA_group__c);
                fieldSet.add(account_i.ETA_group__c);
            }
        } 
        List<String> zipCodesList = new List<String>();
        for(Sales_Order__c SO_Obj : salesOrderList){
            String zipCode = SO_Obj.Shipping_ZipCode__c;
            if(zipCode != null && zipCode.length() > 5 ){
                zipCode = zipCode.substring(0,5);
            }
            zipCodesList.add(zipCode);
        }
        if(fieldSet.size() > 0 ){
            String query = 'SELECT Id , Zip_Code__c,' + String.join(new List<String>(fieldSet), ', ') + ' FROM Shipping_Zip_Codes__c  WHERE Zip_Code__c IN: zipCodesList' ; 
            shippingZipCodesList = (List<Shipping_Zip_Codes__c>) DataBase.query(query);
        }
        
    }
    
    private static String  getManufactuterETA(Sales_Order__c salesOrder){
        String zipCode = salesOrder.Shipping_ZipCode__c;
        if(zipCode != null && zipCode.length() > 5 ){
            zipCode = zipCode.substring(0,5);
        }       
        String Carrier = salesOrder.Default_Carrier__c;
        String manfID = salesOrder.Manufacturer__c;////orderItToManifactureIdMap.get(salesOrder.Id);
        String manufacturerETA = null;
        if(String.isNotBlank(Carrier) && Carrier != 'none'){//Carrier == 'FedEx'
            manufacturerETA = (carrierNotesMap.containsKey(Carrier) && carrierNotesMap.get(Carrier).Default_ETA_group__c != null) ? (carrierNotesMap.get(Carrier).Default_ETA_group__c + 'Week') :  '1 Week';
        }else if(shippingZipCodesList.size() > 0){
             Shipping_Zip_Codes__c currentShipZipCode = null;
            for(Shipping_Zip_Codes__c zc: shippingZipCodesList){
                if(zc.Zip_Code__c == zipCode){
                    currentShipZipCode = zc;
                }
            }
            system.debug('currentShipZipCode  = ' + currentShipZipCode);
            system.debug('manfID  = ' + manfID);
            system.debug('accountIdToEtaGroupMap  = ' + accountIdToEtaGroupMap);
            if(manfID != null && currentShipZipCode != null && accountIdToEtaGroupMap.containskey(manfID) && currentShipZipCode.get(accountIdToEtaGroupMap.get(manfID)) != null ){
                manufacturerETA = String.valueOf(currentShipZipCode.get(accountIdToEtaGroupMap.get(manfID)) );
            }     
            //  */ 
        }
        return manufacturerETA;
    }
    
    static PO_Line_Items__c buildPurchaseOrderLineItem(SO_Line_Items__c soItem, Decimal quantity){
        PO_Line_Items__c poItem = new PO_Line_Items__c();
        poItem.SO_Line_Item__c = soItem.Id;
        poItem.SO_Line_Item__r = soItem;
        poItem.Quantity__c = quantity;
        poItem.Weight_Pounds__c = soItem.Total_Weight_Pounds__c;
        poItem.PO_Item_Status__c = 'Draft';
        return poItem;
    } 
    
    
    public class SoLineWrapper{
        public SO_Line_Items__c line { get; set; }
        public List<SO_Line_Items__c> bundleList { get; set; }
    }
}