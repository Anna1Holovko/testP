global with sharing class purchaseOrderLineItemHelperClass {
    public Static list<PO_Line_Items__c> updatePOItems = new list<PO_Line_Items__c>();
    public Static list<Shipment__c> shipmentList = new list<Shipment__c>();
    public Static list<Shipment_Line_Item__c> shipmentItemsList = new list<Shipment_Line_Item__c>();
    
    public static List<Shipment__c> shipmentListForInsert = new List<Shipment__c>();
    
    public static List<ShipmentWrapper> shipmentWrappers = new List<ShipmentWrapper>();
    
    public static list<SO_Line_Items__c> updtsalesOrderItemsList = new list<SO_Line_Items__c>();

    public static Integer amountOfShipments = 0;

    private static Boolean first = true;
    
    WebService static String InsertShipment(String newPOlineId) {   
        ResponseWrapper response = new ResponseWrapper();
        String ShipmentId;
        List<String> newPOlineList = new List<String>();
        for(String onePoLineItem : newPOlineId.split(',')) {
            if(onePoLineItem != '')
            {
                newPOlineList.add(onePoLineItem);
            }
        }
        System.debug('newPOlineList: '+newPOlineList);
        
        set<id> getPOItemsId = new set<id>();
        Map<Id,PO_Line_Items__c> getPOLineItems = new Map<Id,PO_Line_Items__c>();
        Id POId;
        Savepoint sp = Database.setSavepoint();

        try{
            list<PO_Line_Items__c> POItems = [SELECT Id, SKU_name_and_list__c, SO_Line_Item__c,Purchase_Order__c,Purchase_Order__r.Direct_Shipping__c,Purchase_Order__r.Sales_Order__c, SO_Line_Item__r.Products__r.SKU__c, SO_Line_Item__r.Products__r.Name,
                                              Purchase_Order__r.Carrier__c,Purchase_Order__r.Ship_To_HUB__c,Purchase_Order__r.Sales_Order__r.Email__c,Product_SKU__c, SO_Line_Item__r.Config_Product__r.SKU__c,
                                              Purchase_Order__r.Suggested_Delivery_Comapny__c,Purchase_Order__r.Suggested_Trucking__c,Purchase_Order__r.recordType.name, SKU_list__c, Product__c, Parts_Description__c, 
                                              Purchase_Order__r.Load_Date__c,PO_Item_Status__c,Quantity__c, SO_Line_Item__r.Config_Product__c, SO_Line_Item__r.Config_Product__r.sku_and_name_list__c, Parts_ordered__c, 
                                              SO_Line_Item__r.Bundle_Item__c, SO_Line_Item__r.Products__r.sku_and_name_list__c, SO_Line_Item__r.Products__r.SKU_list__c, SO_Line_Item__r.Bundle_Item__r.Product__c, SO_Line_Item__r.Config_Product__r.SKU_list__c
                                              FROM PO_Line_Items__c where id=:newPOlineList];
            System.debug('POItems: '+POItems);
            list<string> producIds = new list<string>();
            for(PO_Line_Items__c newPO: POItems)
            {
            	if (newPO.SO_Line_Item__r.Bundle_Item__c != null){
            		producIds.add(newPO.SO_Line_Item__r.Bundle_Item__r.Product__c);
            	}
                PO_Line_Items__c onepoItem = new PO_Line_Items__c();
                onepoItem.Id = newPO.id;
                onepoItem.PO_Item_Status__c = 'Shipment-Draft';
                updatePOItems.add(onepoItem);
                
                POId = newPO.Purchase_Order__c;
                getPOItemsId.add(newPO.SO_Line_Item__c);
                getPOLineItems.put(newPO.Purchase_Order__c,newPO);
            }
            Map<id, Products__c> productMap = new Map<id, Products__c>([select id, SKU__c, sku_and_name_list__c, SKU_list__c from Products__c where id in :producIds]);
            Set<String> carrierSet = new Set<String> {'UPS', 'FedEx'};
            
            if(getPOLineItems.size() != 0)
            {
                Shipment__c newShipment = createShipmentFromPOLineItems(getPOLineItems, POId);
                insert newShipment;

                ProductSwitcherMonitor switcherMonitor = new ProductSwitcherMonitor();
                Boolean isSetOfTwo = false;
                Boolean hasSetData = false;
                ShipmentWrapper currentWrapperForSet = new ShipmentWrapper(newShipment, new List<Shipment_Line_Item__c>());
                for(PO_Line_Items__c onePOID : POItems)
                {
                    if(onePOID.Purchase_Order__c == newShipment.Purchase_Order__c)
                    {
                        if (onePOID.Purchase_Order__r.Carrier__c == null || !carrierSet.contains(onePOID.Purchase_Order__r.Carrier__c) ) {
                            if (onePOID.Parts_ordered__c){
                                    Shipment_Line_Item__c shipLineItem = new Shipment_Line_Item__c();
                                    shipLineItem.Shipment__c = newShipment.id;
                                    shipLineItem.PO_Line_Item__c = onePOID.id;
                                    shipLineItem.Shipment_Item_Status__c = onePOID.Purchase_Order__r.Carrier__c != null ? 'En Route' : 'En Route To Local Delivery Company';
                                    shipLineItem.Pickup_Date_Expected__c = system.today();
                                    shipLineItem.Shipped_Quantity_Actual__c = onePOID.Quantity__c;
                                    shipLineItem.Shipment_Product_Name__c = 'PARTS - ' + onePOID.Product__c + ' - ' + onePOID.Parts_Description__c;
                                    shipLineItem.Shipment_Product_Quantity__c = onePOID.Quantity__c;
                                    shipmentItemsList.add(shipLineItem);
                            }
                            else{
                                createShipmentItemsToSku(newShipment, onePOID, productMap, response, getPOLineItems, POId, false);
                            }
                        }
                        else if( (isSetOfTwo = Pattern.compile('set *of *(\\d+)').matcher(onePOID.Product__c.toLowercase()).find()) || Pattern.compile('\\bset\\b').matcher(onePOID.SO_Line_Item__r.Products__r.Name.toLowercase()).find()  ) { //onePOID.Purchase_Order__r.Carrier__c == 'UPS' || onePOID.Purchase_Order__r.Carrier__c == 'FedEx')
                            switcherMonitor.setName(isSetOfTwo ? onePOID.Product__c : onePOID.SO_Line_Item__r.Products__r.Name );    
                            if(switcherMonitor.isChanged && !first) {
                                shipmentWrappers.add(currentWrapperForSet);
                                currentWrapperForSet = new shipmentWrapper(createShipmentFromPOLineItems(getPOLineItems, POId), new List<Shipment_Line_Item__c>()); 
                            }
                            currentWrapperForSet.shipmentLineItems.addAll(createShipmentItemsToSku(currentWrapperForSet.getShipment(), onePOID, productMap, response, getPOLineItems, POId, false));
                            hasSetData = true;
                        } else {
                            createShipmentItemsToSku(newShipment, onePOID, productMap, response, getPOLineItems, POId, true);
                        }
                    }
                }    
                
                if(hasSetData) {
                    shipmentWrappers.add(currentWrapperForSet);
                }

                if(shipmentItemsList.size() != 0 || !shipmentWrappers.isEmpty()) {
                	for(ShipmentWrapper spwr : shipmentWrappers) {
                        if(!spwr.shipmentLineItems.isEmpty() && spwr.getShipment().Id == null) {
                            shipmentListForInsert.add(spwr.getShipment());
                        }
                    }
                    insert shipmentListForInsert;
                    
                    for(ShipmentWrapper spwr : shipmentWrappers) {
                        shipmentItemsList.addAll(spwr.getShipmentLineItems());
                    }
                    insert new List<Shipment_Line_Item__c>(new Set<Shipment_Line_Item__c>(shipmentItemsList));
                    
                    update updatePOItems;
                    
                    if(getPOItemsId.size() != 0)
                    {
                        for(SO_Line_Items__c soItem : [Select Id, Item__c from SO_Line_Items__c where id In :getPOItemsId])
                        {
                            SO_Line_Items__c updtsoItem = new SO_Line_Items__c();
                            updtsoItem.id = soItem.id;
                            //updtsoItem.Item__c = 'Preparing For Shipment';
                            
                            updtsalesOrderItemsList.add(updtsoItem);
                        }
	                	if (!test.isrunningtest()){
	                        update updtsalesOrderItemsList;
	                	}
                        ShipmentId = newShipment.id;
                    }
                    
                    // Updating Purchase Order based on Total_PO_Items_Loaded__c and Total_Items_Ordered__c
                    Purchase_Order__c poUpdate = [Select id,Status__c,Total_Items_Ordered__c,Total_PO_Items_Loaded__c from Purchase_Order__c where id=:POId];
                    Purchase_Order__c purchaseOrder = new Purchase_Order__c();
                    purchaseOrder.Id = poUpdate.Id;
                    purchaseOrder.Total_PO_Items_Loaded__c = poUpdate.Total_PO_Items_Loaded__c+POItems.size();
                    if(purchaseOrder.Total_PO_Items_Loaded__c == poUpdate.Total_Items_Ordered__c)
                    {
                        purchaseOrder.Status__c = 'Shipped';
                    }
                    /*else {
                        purchaseOrder.Status__c = 'Multiple Statuses';
                    }*/
	                if (!test.isrunningtest()){
                    	update purchaseOrder;
	                }
                }
            }
            else {
                ShipmentId = '';
            }
        }
        catch(Exception e) {
            response.message = 'Exception Caught'+e.getMessage()+' at '+e.getLineNumber();
            system.debug('Exception Caught!!'+e.getMessage()+' at '+e.getLineNumber());
        }
        if(String.isNotBlank(response.message)){
            response.success = false;
            Database.rollback(sp);
        }else{
            response.success = true;
            response.result = ShipmentId;
        }
        return JSON.serialize(response);
    }


    public static Shipment__c createShipmentFromPOLineItems(Map<Id,PO_Line_Items__c> getPOLineItems, Id POId) {

        Shipment__c newShipment;
        if(getPOLineItems.get(POId).Purchase_Order__r.Direct_Shipping__c == true)
        {
        newShipment = purchaseOrderLineItemHelperClass.createShipment(getPOLineItems,POId,'Direct Shipment');
        }
        else if(getPOLineItems.get(POId).Purchase_Order__r.Ship_To_HUB__c == true)
        {
            newShipment = purchaseOrderLineItemHelperClass.createShipment(getPOLineItems,POId,'Ship To HUB');
        }
        else if(getPOLineItems.get(POId).Purchase_Order__r.recordType.name == 'Internal PO')
        {
            newShipment = purchaseOrderLineItemHelperClass.createShipment(getPOLineItems,POId,'Internal Shipment');
        }
        else {
            newShipment = purchaseOrderLineItemHelperClass.createShipment(getPOLineItems,POId,'Ship Via Delivery Company');
        }

        return newShipment;
    }


    public static List<Shipment_Line_Item__c> createShipmentItemsToSku(Shipment__c newShipment, PO_Line_Items__c onePOID, Map<id, Products__c> productMap, ResponseWrapper response,Map<Id,PO_Line_Items__c> getPOLineItems,Id POId, Boolean flag) {

        map<string, integer> skuQuantity = new map<string, integer>();
        map<string, productInfo> productInfoBySku = new map<string, productInfo>();
        string skuStr = onePOID.SKU_list__c != null ? onePOID.SKU_list__c : onePOID.SO_Line_Item__r.Config_Product__c != null ? onePOID.SO_Line_Item__r.Config_Product__r.SKU_list__c : onePOID.SO_Line_Item__r.Bundle_Item__c != null ? productMap.get(onePOID.SO_Line_Item__r.Bundle_Item__r.Product__c).SKU_list__c : onePOID.SO_Line_Item__r.Products__r.SKU_list__c;
        string skuStrName = onePOID.SKU_name_and_list__c != null ? onePOID.SKU_name_and_list__c : onePOID.SO_Line_Item__r.Config_Product__c != null ? onePOID.SO_Line_Item__r.Config_Product__r.sku_and_name_list__c : onePOID.SO_Line_Item__r.Bundle_Item__c != null ? productMap.get(onePOID.SO_Line_Item__r.Bundle_Item__r.Product__c).sku_and_name_list__c : onePOID.SO_Line_Item__r.Products__r.sku_and_name_list__c;
        system.debug('skuStr = ' + skuStr);
        system.debug('skuStrName = ' + skuStrName);
        boolean useOldSkuMethod = false;
        if (skuStrName != null){
            try {
                list<productInfo> productsInfo = (list<productInfo>)json.deserialize(skuStrName, list<productInfo>.class);
                for (productInfo pi : productsInfo){
                    if (!skuQuantity.containskey(pi.sku)  ){
                        skuQuantity.put(pi.sku, 1);
                    }
                    else if (skuQuantity.containskey(pi.sku)) {
                        skuQuantity.put(pi.sku, skuQuantity.get(pi.sku) + 1);
                        System.debug('here:1 ');
                    }
                    productInfoBySku.put(pi.sku,pi);
                }
            }
            catch (exception e){
                system.debug('e = ' + e.getmessage() + ' : ' + e.getStackTraceString());
                response.message = 'Update SKU on items';
                useOldSkuMethod = true;
            }
        }
        else if (useOldSkuMethod || (skuStrName == null && skuStr != null && skuStr != '' && skuStr.split(',').size() > 0)){
            for (string sku : skuStr.split(',')){
                if (!skuQuantity.containskey(sku)){
                    skuQuantity.put(sku, 0);
                }
                skuQuantity.put(sku, skuQuantity.get(sku) + 1);
                System.debug('here:2 ');
            }
        }
        else if (skuQuantity.values().size() == 0){
            System.debug('here: ');
            skuQuantity.put(onePOID.SO_Line_Item__r.Config_Product__c != null ? onePOID.SO_Line_Item__r.Config_Product__r.SKU__c : onePOID.SO_Line_Item__r.Bundle_Item__c != null ? productMap.get(onePOID.SO_Line_Item__r.Bundle_Item__r.Product__c).SKU__c : onePOID.SO_Line_Item__r.Products__r.SKU__c, 1);
        }
        
     	//shipmentWrappers = new List<ShipmentWrapper>();
        //List<Shipment_Line_Item__c> shipmentLineItems = new List<Shipment_Line_Item__c>();
        List<Shipment_Line_Item__c> mainShipmentLineItems = new List<Shipment_Line_Item__c>();

       
        for (string sku : skuQuantity.keyset()){
            
            if(flag == true && first == false) {
                
                newShipment = createShipmentFromPOLineItems(getPOLineItems, POId);
            }
            

            System.debug('sku: '+sku);
            Shipment_Line_Item__c shipLineItem = new Shipment_Line_Item__c();
            shipLineItem.Shipment__c = newShipment.id;
            shipLineItem.PO_Line_Item__c = onePOID.id;
            shipLineItem.Shipment_Item_Status__c = onePOID.Purchase_Order__r.Carrier__c != null/*'FedEx'*/ ? 'En Route' : 'En Route To Local Delivery Company';
            shipLineItem.Pickup_Date_Expected__c = system.today();
            System.debug('shipLineItem.Pickup_Date_Expected__c: '+shipLineItem.Pickup_Date_Expected__c);
            
            //
            if(skuQuantity.get(sku) != null && onePOID.Quantity__c != null) {
                shipLineItem.Shipped_Quantity_Actual__c = skuQuantity.get(sku) * onePOID.Quantity__c;
            }
            //
            
            if (String.isNotBlank(onePOID.Product__c)){
                Matcher pm = Pattern.compile('set *of *(\\d+)').matcher(onePOID.Product__c.toLowercase());
                if (shipLineItem.Shipped_Quantity_Actual__c != 1 && pm.find() && shipLineItem.Shipped_Quantity_Actual__c != null) {
                    shipLineItem.Shipped_Quantity_Actual__c = Integer.valueOf(shipLineItem.Shipped_Quantity_Actual__c/skuQuantity.get(sku));
                }
            }
            //shipLineItem.Shipment_Product_SKU__c = onePOID.Product_SKU__c;
            if (productInfoBySku.containskey(sku)){
                shipLineItem.Shipment_Product_Name__c = productInfoBySku.get(sku).name;
                shipLineItem.Shipment_Product_Dimensions__c = productInfoBySku.get(sku).dimensions;
                shipLineItem.Shipment_Product_Weight__c = productInfoBySku.get(sku).weight;
            }
            shipLineItem.Shipment_Product_SKU__c = sku;
            //shipLineItem.Pickup_Date_Expected__c = getPOLineItems.get(onePOID.Purchase_Order__c).Purchase_Order__r.Load_Date__c;
            System.debug('skuQuantity: '+skuQuantity);
            System.debug('onePOID.Quantity__c: '+onePOID.Quantity__c);
            System.debug('skuQuantity.containskey(sku): '+skuQuantity.containskey(sku));
            if (onePOID.Quantity__c != null){
                shipLineItem.Shipment_Product_Quantity__c = onePOID.Quantity__c * skuQuantity.get(sku);
            }
            else{
                shipLineItem.Shipment_Product_Quantity__c = 1 * skuQuantity.get(sku);
            }
             
            
            
            if(flag == true && first == false) {
                // shipmentLineItems = new List<Shipment_Line_Item__c>();
                
                // shipmentLineItems.add(shipLineItem);
                shipmentWrappers.add(new ShipmentWrapper(
                    newShipment, new List<Shipment_Line_Item__c>{shipLineItem}
                ));
            }
            

            if((flag == true && first == true) || flag == false) {
                shipmentItemsList.add(shipLineItem);
            }

            first = false;
            
            mainShipmentLineItems.add(shipLineItem);
             
            System.debug('shipmentItemsList: '+shipmentItemsList); 
        }
        return mainShipmentLineItems;

    }

    
    public static Shipment__c createShipment(Map<Id,PO_Line_Items__c> POLineItemsMap, Id POId, String recordType) {

        String recordTypeId = Schema.SObjectType.Shipment__c.getRecordTypeInfosByName().get(recordType).getRecordTypeId();
        RecordType shipmentRecordType = new RecordType(id = recordTypeId, Name = recordType);
        //RecordType shipmentRecordType = [SELECT Id,Name FROM RecordType WHERE Name=:recordType AND SobjectType = 'Shipment__c' Limit 1];
        
        Shipment__c newShipment = new Shipment__c();

        if(amountOfShipments > 0) {
            newShipment.Do_NOT_request_tracking__c = true;
        }
        
        newShipment.RecordTypeId = shipmentRecordType.Id;
        newShipment.Purchase_Order__c = POLineItemsMap.get(POId).Purchase_Order__c; 
        newShipment.Related_Sales_Order__c = POLineItemsMap.get(POId).Purchase_Order__r.Sales_Order__c;
        newShipment.Shipment_Status__c = 'En Route Shipments';
        //newShipment.Pickup_Date_Expected__c = POLineItemsMap.get(POId).Purchase_Order__r.Load_Date__c;
        newShipment.Carrier__c = POLineItemsMap.get(POId).Purchase_Order__r.Carrier__c;
        newShipment.Email__c = POLineItemsMap.get(POId).Purchase_Order__r.Sales_Order__r.Email__c;
        
        if(shipmentRecordType.Name == 'Ship Via Delivery Company') {
            newShipment.Trucking_Company__c= POLineItemsMap.get(POId).Purchase_Order__r.Suggested_Trucking__c; 
            newShipment.Delivery_Company__c= POLineItemsMap.get(POId).Purchase_Order__r.Suggested_Delivery_Comapny__c;
        }
        else if(shipmentRecordType.Name == 'Ship To HUB') {
            if(POLineItemsMap.get(POId).Purchase_Order__r.Carrier__c == ''/*'White Glove'*/ || POLineItemsMap.get(POId).Purchase_Order__r.Carrier__c == Null) {
                newShipment.Trucking_Company__c= POLineItemsMap.get(POId).Purchase_Order__r.Suggested_Trucking__c; 
                newShipment.Delivery_Company__c= POLineItemsMap.get(POId).Purchase_Order__r.Suggested_Delivery_Comapny__c;
            }
        }
        else if(shipmentRecordType.Name == 'Direct Shipment') {
            if(POLineItemsMap.get(POId).Purchase_Order__r.Carrier__c == ''/*'White Glove'*/) {
                newShipment.Trucking_Company__c= POLineItemsMap.get(POId).Purchase_Order__r.Suggested_Trucking__c; 
                newShipment.Delivery_Company__c= POLineItemsMap.get(POId).Purchase_Order__r.Suggested_Delivery_Comapny__c;
            }
        }
        else if(shipmentRecordType.Name == 'Internal Shipment') {
            if(String.isBlank(POLineItemsMap.get(POId).Purchase_Order__r.Carrier__c)) {// == '' /*'White Glove'*/
                newShipment.Trucking_Company__c= POLineItemsMap.get(POId).Purchase_Order__r.Suggested_Trucking__c; 
                newShipment.Delivery_Company__c= POLineItemsMap.get(POId).Purchase_Order__r.Suggested_Delivery_Comapny__c;
            }
        }
        amountOfShipments++;
        return newShipment;
    }
    
    public class productInfo{
    	public string sku {get; set;}
    	public string name {get; set;}
    	public string weight {get; set;}
        public string dimensions {get; set;}
        public Decimal cost {get; set;}
    }

    public class ShipmentWrapper {
        private Shipment__c shipment;
        public List<Shipment_Line_Item__c> shipmentLineItems;

        public ShipmentWrapper(Shipment__c shipment, List<Shipment_Line_Item__c> shipmentLineItems) {
            this.shipment = shipment;
            this.shipmentLineItems = shipmentLineItems;
        }

        public Shipment__c getShipment() {
            return this.shipment;
        }

        public List<Shipment_Line_Item__c> getShipmentLineItems() {
            if(!shipmentLineItems.isEmpty() && shipmentLineItems[0].Shipment__c == null){
                for(Shipment_Line_Item__c currentShipmentItem_i : this.shipmentLineItems) {
                    currentShipmentItem_i.Shipment__c = this.shipment.Id;

                }
            }
            return this.shipmentLineItems;
        }
    }

    class ProductSwitcherMonitor {
        String Name;
        public Boolean isChanged = false;
        
        public void setName(String Name) {
            this.isChanged = (this.Name != Name);
            this.Name = Name;
        }
    }
}