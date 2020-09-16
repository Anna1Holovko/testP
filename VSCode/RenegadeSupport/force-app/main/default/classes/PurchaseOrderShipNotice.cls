/**
 * @File Name          : PurchaseOrderShipNotice.cls
 * @Description        : 
 * @Author             : Synebo
 * @Group              : 
 * @Last Modified By   : Synebo
 * @Last Modified On   : 09-03-2020
 * @Modification Log   : 
 * Ver       Date            Author                 Modification
 * 1.0    4/20/2020   Synebo     Initial Version
**/
@RestResource(urlMapping='/ShipNotice/*')
global class PurchaseOrderShipNotice {
    
    static list<string> poNames;

    private static Map<String, String> carrierCodeToCarrierNameMap {
        get {
            if (carrierCodeToCarrierNameMap == null) {
                carrierCodeToCarrierNameMap = new Map<String, String>();
                Map<String, Carrier_code_assigned_by_manufacturer__c> settingMap = Carrier_code_assigned_by_manufacturer__c.getAll();
                for (Carrier_code_assigned_by_manufacturer__c setting_i : settingMap.values()) {
                    carrierCodeToCarrierNameMap.put(setting_i.Carrier_code__c, setting_i.Carrier_name__c);
                }
            } 
            return carrierCodeToCarrierNameMap;
        }
        set;
    }
    
    @HttpPost  
    global static Response getPurchaseOrderShipNotice() {
        string advanceShipNotice = RestContext.request.requestBody.toString();
        System.debug('advanceShipNotice******'+advanceShipNotice);
        list<Purchase_Order__c> pos;
        map<string, Purchase_Order__c> posByNameMap = new map<string, Purchase_Order__c>();
        system.debug('xmlInput = ' + advanceShipNotice);
        Savepoint sp = Database.setSavepoint();
        string document_id = '';
        list<Log__c> logs;
        try{
            Shipment shipment = new Shipment();
            Dom.Document doc = new Dom.Document();
            doc.load(advanceShipNotice);
            for(Dom.XmlNode node :doc.getRootElement().getChildElements()){
                System.debug(node.getName());
                if (node.getName() == 'shipment'){
                    shipment.process(node);
                    system.debug('shipment = ' + shipment);
                    document_id = shipment.document_id;
                }
            }
            logs = [select Object_ID__c, Tries__c, Process__c, Data__c, Status__c, Error__c from Log__c where Process__c = 'Ship Notice' and  Object_ID__c = :document_id];
            if (logs != null && logs.size() > 0 && logs[0].Status__c == 'Succeeded'){
                return new Response(true, '');
            }
            try {
                System.debug('poNames '+poNames);
                pos = [select id, name, Status__c, Load_Date_Actual__c, Direct_Shipping__c, Ship_To_HUB__c, recordType.name, Sales_Order__c, Load_Date__c, Carrier__c, Ship_From__r.Name,
                       Sales_Order__r.Email__c, Suggested_Trucking__c, Suggested_Delivery_Comapny__c, Ship_From__c from Purchase_Order__c where name in :poNames];
            }
            catch(exception ex){
                Log__c log = new Log__c(Object_ID__c = document_id, Process__c = 'Ship Notice', Data__c = advanceShipNotice, Tries__c = 1, Status__c = 'Failed', Error__c = 'Can not find the PO');
                if (logs != null && logs.size() > 0){
                    log.Tries__c = logs[0].Tries__c + 1;
                    log.id = logs[0].id;
                }
                upsert log;
                system.debug('ex.getmessage() = ' + ex.getmessage() + ' ' + ex.getlinenumber());
                return new Response(true, '');
            }
            for (Purchase_Order__c po : pos){
                po.Status__c = 'Shipped';
                po.Load_Date_Actual__c = system.today();
                System.debug('po'+po);
                // if (po.Ship_From__c != null && po.Ship_From__r.Name != null  && po.Ship_From__r.Name.contains('Ashley')){
                //     po.En_Route_Email__c = true;
                // }
                po.Carrier__c = (carrierCodeToCarrierNameMap.containsKey(po.Carrier__c)) ? carrierCodeToCarrierNameMap.get(po.Carrier__c) : po.Carrier__c;
                posByNameMap.put(po.name, po);
            }
            update pos;
            createShipment(shipment, posByNameMap);
        }
        catch (exception e){
            Database.rollback(sp);
            Log__c log = new Log__c(Object_ID__c = document_id, Process__c = 'Ship Notice', Data__c = advanceShipNotice, Tries__c = 1, Status__c = 'Failed', Error__c = e.getmessage() + ' ' + e.getlinenumber());
            if (logs != null && logs.size() > 0){
                log.Tries__c = logs[0].Tries__c + 1;
                log.id = logs[0].id;
            }
            upsert log;
            system.debug('e.getmessage() = ' + e.getmessage() + ' ' + e.getlinenumber());
            return new Response(false, e.getmessage() + ' ' + e.getlinenumber());
        }
        Log__c log = new Log__c(Object_ID__c = document_id, Process__c = 'Ship Notice', Data__c = advanceShipNotice, Tries__c = 1, Status__c = 'Succeeded');
        if (logs != null && logs.size() > 0){
            log.Tries__c = logs[0].Tries__c + 1;
            log.id = logs[0].id;
        }
        upsert log;
        return new Response(true, '');
    }
   
    global static void createShipment(Shipment shipment, map<string, Purchase_Order__c> posByNameMap){
        map<string, Shipment__c> shipmentByTrackingIdMap = new map<string, Shipment__c>();
        map<string, Shipment_Line_Item__c> shipLineItemByTrackingIdMap = new map<string, Shipment_Line_Item__c>();
        Map<String, productInfoHelper> productHelperMap = new  Map<String, productInfoHelper>();
        system.debug('shipment = ' + shipment);
        system.debug('shipment.orders = ' + shipment.orders);
        system.debug('posByNameMap = ' + posByNameMap);
        Map<String, Tracking_companies_by_manufacturer__c> trackingCompanyToIdSettingMap = Tracking_companies_by_manufacturer__c.getAll();
        
        for (Order o : shipment.orders){
            string poName = o.referenceNumberValue;
            system.debug('poName = ' + poName);
            system.debug('posByNameMap.containskey(poName) = ' + posByNameMap.containskey(poName));
            if (!posByNameMap.containskey(poName)){
                continue;
            }
            Purchase_Order__c po = posByNameMap.get(poName);
            system.debug('o.items = ' + o.items);
            for (Item item : o.items){
                system.debug('item.truckingIds = ' + item.truckingIds);
                system.debug('poName = ' + poName);
                if (item.truckingIds != null && item.truckingIds.size() > 0){
                    for (Reference ref: item.truckingIds){
                        if (!shipmentByTrackingIdMap.containskey(ref.value)){
                            buildShipment(po, shipment, ref, trackingCompanyToIdSettingMap, shipmentByTrackingIdMap, null);
                        }
                    }
                }
                else if (!shipmentByTrackingIdMap.containskey(poName)){
                    buildShipment(po, shipment, null, trackingCompanyToIdSettingMap, shipmentByTrackingIdMap, poName);
                }
                
            }
        }
        
        system.debug('shipmentByTrackingIdMap = ' + shipmentByTrackingIdMap);
        if (shipmentByTrackingIdMap.values().size() > 0){
            insert shipmentByTrackingIdMap.values();
            
            set<string> poIds = new set<string>();
            for (Order o : shipment.orders){
                string poName = o.referenceNumberValue;
                if (!posByNameMap.containskey(poName)){
                    continue;
                }
                for (Item item : o.items){
                    if (item.pieceIdentificationNumbers != null && item.pieceIdentificationNumbers.size() > 0){
                        if (item.pieceIdentificationNumbers[0].length() > 18){
                            poIds.add(item.pieceIdentificationNumbers[0].substring(0, 18));
                        }
                    }
                }
            }
            system.debug('poIds: ' + poIds);
            map<id, PO_Line_Items__c> POItems = new map<id, PO_Line_Items__c>([SELECT Id, Product__c, SO_Line_Item__c,Purchase_Order__c,Purchase_Order__r.Direct_Shipping__c,Purchase_Order__r.Sales_Order__c, SO_Line_Item__r.Products__r.SKU__c,
                                                                               Purchase_Order__r.Carrier__c,Purchase_Order__r.Ship_To_HUB__c,Purchase_Order__r.Sales_Order__r.Email__c,Product_SKU__c, SO_Line_Item__r.Config_Product__r.SKU__c,
                                                                               Purchase_Order__r.Suggested_Delivery_Comapny__c,Purchase_Order__r.Suggested_Trucking__c,Purchase_Order__r.recordType.name, SKU_name_and_list__c,
                                                                               Purchase_Order__r.Load_Date__c,PO_Item_Status__c,Quantity__c, SO_Line_Item__r.Config_Product__c, SO_Line_Item__r.Config_Product__r.SKU_List__c, 
                                                                               SO_Line_Item__r.Bundle_Item__c, SO_Line_Item__r.Products__r.SKU_List__c, SO_Line_Item__r.Bundle_Item__r.Product__c,
                                                                               SO_Line_Item__r.Config_Product__r.sku_and_name_list__c, SO_Line_Item__r.Products__r.sku_and_name_list__c, SO_Line_Item__r.Products__r.Name
                                                                               FROM PO_Line_Items__c where id in :poIds]);
            
            system.debug('POItems = ' + POItems);
            set<string> producIds = new set<string>();
            for(PO_Line_Items__c newPO: POItems.values())
            {
                if (newPO.SO_Line_Item__r.Bundle_Item__c != null){
                    producIds.add(newPO.SO_Line_Item__r.Bundle_Item__r.Product__c);
                }
            }
            map<id, Products__c> productMap = new map<id, Products__c>([select id, SKU__c, SKU_List__c, sku_and_name_list__c from Products__c where id in :producIds]);
            
            for (Order o : shipment.orders){
                string poName = o.referenceNumberValue;
                if (!posByNameMap.containskey(poName)){
                    continue;
                }
                Set<String> allAddedSkuSet = new Set<String>();
                map<string, string> lineItemIdBySku = new map<string, string>();
                for (Item item : o.items){
                    string shipmentId;
                    string shipmentLIStatus;
                    system.debug('shipmentLIStatus = ' + shipmentLIStatus);
                    if (item.pieceIdentificationNumbers.size() > 0 && (item.pieceIdentificationNumbers[0].contains('a0D') || (item.itemIdentifiers != null && item.itemIdentifiers.size() > 0 && lineItemIdBySku != null && lineItemIdBySku.size() > 0 &&  lineItemIdBySku.containskey(item.itemIdentifiers[0].value)))){
                        string poLiId = item.pieceIdentificationNumbers[0].contains('a0D') ? item.pieceIdentificationNumbers[0].substring(0, 18) : lineItemIdBySku.get(item.itemIdentifiers[0].value);
                        Integer quantityOfShipmentItem = posByNameMap.get(poName).Ship_From__r.Name.contains('Ashley')? item.pieceIdentificationNumbers.size() : Integer.valueOf(item.value);
                        String productName = null;
                        if (POItems.containskey(poLiId)){
                            string skuStrName = POItems.get(poLiId).SKU_name_and_list__c != null ? POItems.get(poLiId).SKU_name_and_list__c : POItems.get(poLiId).SO_Line_Item__r.Config_Product__c != null ? POItems.get(poLiId).SO_Line_Item__r.Config_Product__r.sku_and_name_list__c : POItems.get(poLiId).SO_Line_Item__r.Bundle_Item__c != null ? productMap.get(POItems.get(poLiId).SO_Line_Item__r.Bundle_Item__r.Product__c).sku_and_name_list__c : POItems.get(poLiId).SO_Line_Item__r.Products__r.sku_and_name_list__c;
                            productName = POItems.get(poLiId).Product__c!=null ? POItems.get(poLiId).Product__c : null;
                                /*skuStrName = skuStrName.replaceall('"W', '\'W');
                                skuStrName = skuStrName.replaceall('"D', '\'D');
                                skuStrName = skuStrName.replaceall('"H', '\'H');*/
                                system.debug('skuStrName = ' + skuStrName);
                            list<productInfo> productsInfo = (list<productInfo>)json.deserialize(skuStrName, list<productInfo>.class);
                            map<string, integer> skuInProduct = new map<string, integer>();
                            for (productInfo pi : productsInfo){
                                if (!lineItemIdBySku.containskey(pi.sku)){
                                    lineItemIdBySku.put(pi.sku, poLiId);
                                }
                                if (!skuInProduct.containskey(pi.sku) && productName != null && productName.contains('Set')){
                                    skuInProduct.put(pi.sku, 1);
                                }
                                else if (skuInProduct.containskey(pi.sku)) {
                                    skuInProduct.put(pi.sku, skuInProduct.get(pi.sku) + 1);
                                }
                            }
                            Map<String, String> setProductKeyToSkuMap = new Map<String, String>();
                            for (productInfo pi : productsInfo){
                                if (item.itemIdentifiers != null && item.itemIdentifiers.size() > 0  && pi.sku == item.itemIdentifiers[0].value){
                                    if (item.truckingIds != null && item.truckingIds.size() > 0){
                                        for (integer i = 0; i < item.truckingIds.size(); i ++){ 
                                            Reference ref = item.truckingIds[i];
                                            shipmentId = shipmentByTrackingIdMap.get(ref.value).id;
                                            shipmentLIStatus = shipmentByTrackingIdMap.get(ref.value).Carrier__c != null ? 'En Route' : 'En Route to Local Delivery Company';
                                            if (shipLineItemByTrackingIdMap.containskey(pi.sku + poLiId + ref.value)){
                                                shipLineItemByTrackingIdMap.get(pi.sku + poLiId + ref.value).Shipped_Quantity_Actual__c = (shipLineItemByTrackingIdMap.get(pi.sku + poLiId + ref.value).Shipped_Quantity_Actual__c + 1) ;
                                                if(skuInProduct.containskey(pi.sku) && !setProductKeyToSkuMap.containsKey(pi.sku + poLiId + ref.value)){
                                                    setProductKeyToSkuMap.put(pi.sku + poLiId + ref.value, pi.sku);
                                                    //shipLineItemByTrackingIdMap.get(pi.sku + poLiId + ref.value).Shipped_Quantity_Actual__c = shipLineItemByTrackingIdMap.get(pi.sku + poLiId + ref.value).Shipped_Quantity_Actual__c / skuInProduct.get(pi.sku);
                                                }
                                                shipLineItemByTrackingIdMap.get(pi.sku + poLiId + ref.value).Shipment_Product_Quantity__c = shipLineItemByTrackingIdMap.get(pi.sku + poLiId + ref.value).Shipment_Product_Quantity__c + 1;
                                                continue; 
                                            }
                                            Shipment_Line_Item__c shipLineItem = createShiomentLineItem(shipmentId, poLiId, shipmentLIStatus, pi.sku, 1, 1, pi.name, pi.weight, pi.dimensions, shipment);
                                            shipmentByTrackingIdMap.get(ref.value).Pickup_Date_Actual__c = shipment.shipDate;
                                            shipmentByTrackingIdMap.get(ref.value).Pickup_Date_Expected__c = shipment.shipDate;
                                            shipLineItemByTrackingIdMap.put(pi.sku + poLiId + ref.value, shipLineItem);
                                            productHelperMap.put(pi.sku + poLiId + ref.value, new productInfoHelper(productName, item.unitOfMeasure, skuInProduct.get(pi.sku) != null ? skuInProduct.get(pi.sku) : 1));
                                        }
                                    }
                                    else{
                                        shipmentId = shipmentByTrackingIdMap.get(string.valueof(poName)).id;
                                        shipmentLIStatus = shipmentByTrackingIdMap.get(string.valueof(poName)).Carrier__c != null ? 'En Route' : 'En Route to Local Delivery Company';
                                        Shipment_Line_Item__c shipLineItem;
                                        if (pi.sku != null && skuInProduct.containskey(pi.sku)){
                                            setProductKeyToSkuMap.put(item.itemIdentifiers[0].value + poLiId, pi.sku);
                                            shipLineItem = createShiomentLineItem(shipmentId, poLiId, shipmentLIStatus, pi.sku, quantityOfShipmentItem, quantityOfShipmentItem/* / skuInProduct.get(pi.sku) */, pi.name, pi.weight, pi.dimensions, shipment);
                                        }
                                        else {
                                            shipLineItem = createShiomentLineItem(shipmentId, poLiId, shipmentLIStatus, pi.sku, quantityOfShipmentItem, quantityOfShipmentItem, pi.name, pi.weight, pi.dimensions, shipment);
                                        }
                                        shipLineItemByTrackingIdMap.put(item.itemIdentifiers[0].value + poLiId, shipLineItem);
                                        shipmentByTrackingIdMap.get(string.valueof(poName)).Pickup_Date_Actual__c = shipment.shipDate;
                                        shipmentByTrackingIdMap.get(string.valueof(poName)).Pickup_Date_Expected__c = shipment.shipDate;
                                        productHelperMap.put(item.itemIdentifiers[0].value + poLiId, new productInfoHelper(productName, item.unitOfMeasure, skuInProduct.get(pi.sku) != null ? skuInProduct.get(pi.sku) : 1 ));
                                    }
                                    break;
                                }
                            }

                            // for(String key_i : setProductKeyToSkuMap.keySet()) {
                            //         shipLineItemByTrackingIdMap.get(key_i).Shipped_Quantity_Actual__c /= skuInProduct.get(setProductKeyToSkuMap.get(key_i));
                            // }
                        }
                        else {
                            Shipment_Line_Item__c shipLineItem = createShiomentLineItem(shipmentId, poLiId, shipmentLIStatus, (item.itemIdentifiers != null && item.itemIdentifiers.size() > 0 ? item.itemIdentifiers[0].value: '' ), quantityOfShipmentItem, quantityOfShipmentItem, shipment);
                            shipLineItemByTrackingIdMap.put((item.itemIdentifiers != null && item.itemIdentifiers.size() > 0  ? item.itemIdentifiers[0].value : '') + poLiId , shipLineItem);
                            productHelperMap.put((item.itemIdentifiers != null && item.itemIdentifiers.size() > 0  ? item.itemIdentifiers[0].value : '') + poLiId , new productInfoHelper(productName, item.unitOfMeasure, 1));
                        }
                    }
                }
            }
            system.debug('shipLineItemByTrackingIdMap = ' + shipLineItemByTrackingIdMap);
            if (shipLineItemByTrackingIdMap.values().size() > 0){
                try{
                    additionalCalculations(shipLineItemByTrackingIdMap, productHelperMap );
                    insert shipLineItemByTrackingIdMap.values();
                    ShipmentTriggerHandler.loopFlag = false;
                    update shipmentByTrackingIdMap.values();
                }
                catch (exception e){
                    delete shipmentByTrackingIdMap.values();
                    throw new FailedInsertShipmentLinesException('' + e.getmessage() + ' ' + e.getlinenumber() );
                }
            }
        }
    }
    static void buildShipment(Purchase_Order__c po, Shipment shipment, Reference ref, Map<String, Tracking_companies_by_manufacturer__c> trackingCompanyToIdSettingMap, map<string, Shipment__c> shipmentByTrackingIdMap, String poName ){
        Shipment__c s = new Shipment__c();
        s.RecordTypeId = po.Direct_Shipping__c ? Schema.SObjectType.Shipment__c.getRecordTypeInfosByName().get('Direct Shipment').getRecordTypeId() : po.Ship_To_HUB__c ? Schema.SObjectType.Shipment__c.getRecordTypeInfosByName().get('Ship To HUB').getRecordTypeId() : po.recordType.name == 'Internal PO' ? Schema.SObjectType.Shipment__c.getRecordTypeInfosByName().get('Internal Shipment').getRecordTypeId() : Schema.SObjectType.Shipment__c.getRecordTypeInfosByName().get('Ship Via Delivery Company').getRecordTypeId();
        s.Purchase_Order__c = po.id;
        s.Related_Sales_Order__c = po.Sales_Order__c;
        s.Shipment_Status__c = 'En Route Shipments';
        s.Trip_Number__c = shipment.document_id;
        //s.Pickup_Date_Actual__c = shipment.shipDate;
        //s.Pickup_Date_Expected__c = shipment.shipDate;
        if(ref != null){
            if (po.Carrier__c != null){
                s.Carrier__c = 'LTL';
                s.Carrier_Name__c = po.Carrier__c;
            }
            if(carrierCodeToCarrierNameMap.containsKey(shipment.carrierPartyIdentifierCode)){
                s.Carrier_Name__c = carrierCodeToCarrierNameMap.get(shipment.carrierPartyIdentifierCode);
                s.Carrier__c = 'LTL';
            }
            s.Tracking_Number__c = ref != null ? ref.value : null;
        }
        s.Email__c = po.Sales_Order__r.Email__c;
        if (s.RecordTypeId == Schema.SObjectType.Shipment__c.getRecordTypeInfosByName().get('Ship Via Delivery Company').getRecordTypeId() || po.Carrier__c == '' || (po.Ship_To_HUB__c && po.Carrier__c == null)){
            s.Trucking_Company__c= po.Suggested_Trucking__c; 
            s.Delivery_Company__c= po.Suggested_Delivery_Comapny__c;
            if(s.Trucking_Company__c == null && shipment.carrierPartyIdentifierCode != null  && trackingCompanyToIdSettingMap.containsKey(shipment.carrierPartyIdentifierCode)){
                s.Trucking_Company__c = trackingCompanyToIdSettingMap.get(shipment.carrierPartyIdentifierCode).Tracking_Company_Id__c;
            }
        }
        if (po.Carrier__c == null && po.Ship_From__c != null && po.Ship_From__r.Name != null  && po.Ship_From__r.Name.contains('Ashley')){
            s.Drop_Off_Date_Expected__c = shipment.shipDate;
        }
        shipmentByTrackingIdMap.put(ref != null ? ref.value : poName, s);
    }
    
    private static Shipment_Line_Item__c createShiomentLineItem(String shipmentId, 
                                                                String poli, 
                                                                String status, 
                                                                String Shipment_Product_SKU, 
                                                                Integer Shipped_Quantity_Actual, 
                                                                Integer Shipment_Product_Quantity, 
                                                                Shipment shipment){
        Shipment_Line_Item__c sli = new Shipment_Line_Item__c();
        sli.Shipment__c = shipmentId;
        sli.PO_Line_Item__c = poli;
        sli.Shipment_Item_Status__c = status;
        sli.Shipment_Product_SKU__c = Shipment_Product_SKU;
        sli.Shipment_Product_Quantity__c = Shipment_Product_Quantity;
        sli.Pickup_Date_Actual__c =  shipment.shipDate;
        sli.Pickup_Date_Expected__c = shipment.shipDate; 
        sli.Drop_Off_Date_Expected__c = shipment.shipDate;
        sli.Shipped_Quantity_Actual__c   =   Shipped_Quantity_Actual;//: reCalcShippedQuantityActual(Shipped_Quantity_Actual, productName, unitOfMeasure);                                                         
        return sli;
    }
    
    private static Shipment_Line_Item__c createShiomentLineItem(String shipmentId, 
                                                                String poli, 
                                                                String status, 
                                                                String Shipment_Product_SKU, 
                                                                Integer Shipped_Quantity_Actual, 
                                                                Integer Shipment_Product_Quantity, 
                                                                String name, 
                                                                String weight, 
                                                                String dimensions, 
                                                                Shipment shipment){
        Shipment_Line_Item__c sli = createShiomentLineItem(shipmentId, poli, status, Shipment_Product_SKU, Shipped_Quantity_Actual, Shipment_Product_Quantity, shipment);
        sli.Shipment_Product_Name__c = name;
        sli.Shipment_Product_Weight__c = weight;
        sli.Shipment_Product_Dimensions__c = dimensions;
        return sli;
    }

    private static Integer reCalcShippedQuantityActual(Integer Shipped_Quantity_Actual, productInfoHelper productInfo){
        if(String.isNotBlank(productInfo.name)){
            Matcher pm = Pattern.compile('set *of *(\\d+)').matcher(productInfo.name.toLowercase());
            if(productInfo.unitOfMeasure != 'Cartons' && Shipped_Quantity_Actual != 1 && pm.find()){
                Shipped_Quantity_Actual = Integer.valueOf(Shipped_Quantity_Actual/productInfo.skuQuantity);
            }
        }
        return Shipped_Quantity_Actual;
    }

    private static void additionalCalculations(Map<String, Shipment_Line_Item__c> shipLineItemByTrackingIdMap, Map<String, productInfoHelper> productHelperMap ){
        if(shipLineItemByTrackingIdMap != null && shipLineItemByTrackingIdMap.size() > 0){
            for(String key_i : shipLineItemByTrackingIdMap.keySet()){
                productInfoHelper productInfo = productHelperMap.get(key_i);
                shipLineItemByTrackingIdMap.get(key_i).Shipped_Quantity_Actual__c = reCalcShippedQuantityActual((Integer)shipLineItemByTrackingIdMap.get(key_i).Shipped_Quantity_Actual__c, productInfo );
            }
        }

    }
    
    global class Shipment{
        
        public string document_id {get; set;}
        public string type {get; set;}
        public date creationDateAndTime {get; set;}
        public string documentStructureQualifier {get; set;}
        public list<Reference> shipmentReferenceNumbers {get; set;}
        public string shipDateQualifier {get; set;}
        public date shipDate {get; set;}
        public Party buyerParty {get; set;}
        public string sellerPartyIdentifierCode {get; set;}
        public string sellerPartyIdentifierQualifierCode {get; set;}
        public string carrierPartyIdentifierCode {get; set;}
        public string carrierPartyIdentifierQualifierCode {get; set;}
        public string transitTimeUnitOfMeasure {get; set;}
        public string transitTimeValue {get; set;}
        public Party shipToParty {get; set;}
        public string shipTo_id {get; set;}
        public list<SystemReference> shipmentSystemReferences {get; set;}
        public list<Order> orders {get; set;}
        
        public void process(Dom.XmlNode inNode){
            shipmentSystemReferences = new list<SystemReference>();
            orders = new list<Order>();
            for(Dom.XmlNode innerNode :inNode.getChildElements()){
                system.debug('innerNode.getName() = ' + innerNode.getName());
                if(innerNode.getName() == 'document'){
                    document_id = innerNode.getAttributeValue('id', null);
                    type = innerNode.getAttributeValue('type', null);
                    creationDateAndTime = date.valueof(innerNode.getChildElements()[0].getText() + ' ' + innerNode.getChildElements()[1].getText());
                }
                else if(innerNode.getName() == 'documentStructure'){
                    documentStructureQualifier = innerNode.getAttributeValue('documentStructureQualifier', null);
                }
                else if(innerNode.getName() == 'shipmentReferenceNumber'){
                    Reference ref = new Reference(innerNode.getAttributeValue('referenceNumberValue', null), innerNode.getAttributeValue('referenceNumberQualifier', null));
                    if (shipmentReferenceNumbers == null){
                        shipmentReferenceNumbers = new list<Reference>();
                    }
                    shipmentReferenceNumbers.add(ref);
                }
                else if(innerNode.getName() == 'shipDate'){
                    shipDateQualifier = innerNode.getAttributeValue('shipDateQualifier', null);
                    shipDate = date.valueof(innerNode.getAttributeValue('shipDate', null));
                }
                else if(innerNode.getName() == 'buyer'){
                    buyerParty = createPartyObjFromXml(innerNode);
                }
                else if(innerNode.getName() == 'seller'){
                    sellerPartyIdentifierCode = innerNode.getChildElements()[0].getChildElements()[0].getAttributeValue('partyIdentifierCode', null);
                    sellerPartyIdentifierQualifierCode = innerNode.getChildElements()[0].getChildElements()[0].getAttributeValue('partyIdentifierQualifierCode', null);
                }
                else if(innerNode.getName() == 'carrier'){
                    carrierPartyIdentifierCode = innerNode.getChildElements()[0].getChildElements()[0].getAttributeValue('partyIdentifierCode', null);
                    carrierPartyIdentifierQualifierCode = innerNode.getChildElements()[0].getChildElements()[0].getAttributeValue('partyIdentifierQualifierCode', null);
                    if(innerNode.getChildElements().size()>1){
                    transitTimeUnitOfMeasure = innerNode.getChildElements()[1].getAttributeValue('unitOfMeasure', null);
                    transitTimeValue = innerNode.getChildElements()[1].getAttributeValue('value', null);
                    }
                }
                else if(innerNode.getName() == 'shipTo'){
                    //shipTo_id = innerNode.getAttributeValue('id', null);
                    shipToParty = createPartyObjFromXml(innerNode);
                }
                else if(innerNode.getName() == 'shipmentSystemReference'){
                    SystemReference sr = new SystemReference();
                    for(Dom.XmlNode inInnerNode :innerNode.getChildElements()){
                        if(inInnerNode.getName() == 'systemReferenceDescription'){
                            sr.systemReferenceDescription = inInnerNode.getText();
                        }
                        else if(inInnerNode.getName() == 'systemReferenceValue'){
                            sr.systemReferenceValue = inInnerNode.getText();
                        }
                    }
                    shipmentSystemReferences.add(sr);
                }
                else if(innerNode.getName() == 'order'){
                    if (poNames == null){
                        poNames = new list<string>();
                    }
                    Order o = new Order();
                    o.items = new list<Item>();
                    boolean first = true;
                    for(Dom.XmlNode inInnerNode :innerNode.getChildElements()){
                        if(inInnerNode.getName() == 'orderReferenceNumber'){
                            system.debug('innerNode.getAttributeValue(referenceNumberValue, null) ' + inInnerNode.getAttributeValue('referenceNumberValue', null) + ' ' + first);
                            if (first){
                                try {
                                    o.referenceNumberValue = inInnerNode.getAttributeValue('referenceNumberValue', null).split(' ')[1];
                                    poNames.add(o.referenceNumberValue);
                                }
                                catch (exception e){
                                    
                                    o.referenceNumberValue = inInnerNode.getAttributeValue('referenceNumberValue', null);
                                    poNames.add(o.referenceNumberValue);
                                    continue;
                                }
                                o.referenceNumberQualifier = inInnerNode.getAttributeValue('referenceNumberQualifier', null);
                                first = false;
                            }
                            else {
                                o.referenceNumberValue2 = inInnerNode.getAttributeValue('referenceNumberValue', null);
                                o.referenceNumberQualifier2 = inInnerNode.getAttributeValue('referenceNumberQualifier', null);
                                first = true;
                            }
                        }
                        else if(inInnerNode.getName() == 'item'){
                            Item item = new Item();
                            item.itemReferenceNumbers = new list<Reference>();
                            item.pieceIdentificationNumbers = new list<string>();
                            item.serialNumbers = new list<Reference>();
                            item.truckingIds = new list<Reference>();
                            for(Dom.XmlNode inInInnerNode :inInnerNode.getChildElements()){
                                if(inInInnerNode.getName() == 'itemInformation'){
                                    item.itemIdentifiers = new list<Reference>();
                                    for (Dom.XmlNode inInInInnerNode : inInInnerNode.getChildElements()){
                                        if (inInInInnerNode.getName() == 'itemIdentifier'){
                                            if (inInInInnerNode.getAttributeValue('itemNumberQualifier', null) == 'BuyerAssigned')
                                                item.itemIdentifiers.add(new Reference(inInInInnerNode.getAttributeValue('itemNumber', null), inInInInnerNode.getAttributeValue('itemNumberQualifier', null)));
                                        }
                                    }
                                    /*item.itemDescriptionQualifier = inInInnerNode.getChildElements()[2].getAttributeValue('descriptionValue', null);
item.itemDescriptionQualifier = inInInnerNode.getChildElements()[2].getAttributeValue('itemDescriptionQualifier', null);*/
                                }
                                else if(inInInnerNode.getName() == 'itemReferenceNumber'){
                                    if (inInInnerNode.getAttributeValue('referenceNumberQualifier', null) == 'SerialNumber'){
                                        item.serialNumbers.add(new Reference(inInInnerNode.getAttributeValue('referenceNumberValue', null), inInInnerNode.getAttributeValue('referenceNumberQualifier', null)));
                                    }
                                    else if (inInInnerNode.getAttributeValue('referenceNumberQualifier', null) == 'TrackingID'){
                                        item.truckingIds.add(new Reference(inInInnerNode.getAttributeValue('referenceNumberValue', null), inInInnerNode.getAttributeValue('referenceNumberQualifier', null)));
                                    }
                                    else {
                                        item.itemReferenceNumbers.add(new Reference(inInInnerNode.getAttributeValue('referenceNumberValue', null), inInInnerNode.getAttributeValue('referenceNumberQualifier', null)));
                                    }
                                }
                                else if(inInInnerNode.getName() == 'itemQuantity'){
                                    item.unitOfMeasure = inInInnerNode.getChildElements()[0].getAttributeValue('unitOfMeasure', null);
                                    item.value = inInInnerNode.getChildElements()[0].getAttributeValue('value', null);
                                    item.assignment = inInInnerNode.getChildElements()[0].getChildElements()[0].getAttributeValue('assignment', null);
                                    for (Dom.XmlNode inInInInnerNode : inInInnerNode.getChildElements()[0].getChildElements()[0].getChildElements()){
                                        if (inInInInnerNode.getText().length() > 18 )
                                            item.pieceIdentificationNumbers.add(inInInInnerNode.getText());
                                    }
                                }
                            }
                            o.items.add(item);
                        }
                    }
                    orders.add(o);
                }
            }
        }

        Party createPartyObjFromXml(Dom.XmlNode innerNode){
            return new Party(innerNode.getChildElements()[0].getAttributeValue('partyIdentifierCode', null), 
                                            innerNode.getChildElements()[0].getAttributeValue('partyIdentifierQualifierCode', null),
                                            innerNode.getChildElements().size() == 8 ? innerNode.getChildElements()[1].getText() : '', 
                                            innerNode.getChildElements().size() == 8 ? innerNode.getChildElements()[2].getText() : innerNode.getChildElements()[1].getText(), 
                                            innerNode.getChildElements().size() == 8 ? innerNode.getChildElements()[3].getText() : innerNode.getChildElements()[2].getText(), 
                                            innerNode.getChildElements().size() == 8 ? innerNode.getChildElements()[4].getText() : innerNode.getChildElements()[3].getText(), 
                                            innerNode.getChildElements().size() == 8 ? innerNode.getChildElements()[5].getText() : innerNode.getChildElements()[4].getText(), 
                                            innerNode.getChildElements().size() == 8 ? innerNode.getChildElements()[6].getText() : innerNode.getChildElements()[5].getText(), 
                                            innerNode.getChildElements().size() == 8 ? innerNode.getChildElements()[7].getText() : innerNode.getChildElements()[6].getText());      
        }

    }
    
    global class Order{
        public string referenceNumberValue {get; set;}
        public string referenceNumberQualifier {get; set;}
        public string referenceNumberValue2 {get; set;}
        public string referenceNumberQualifier2 {get; set;}
        public list<Item> items {get; set;}
    }
    
    global class Item{
        public list<Reference> itemIdentifiers {get; set;}
        public string descriptionValue {get; set;}
        public string itemDescriptionQualifier {get; set;}
        public list<Reference> serialNumbers {get; set;}
        public list<Reference> truckingIds {get; set;}
        public list<Reference> itemReferenceNumbers {get; set;}
        public string unitOfMeasure {get; set;}
        public string value {get; set;}
        public string assignment {get; set;}
        public list<string> pieceIdentificationNumbers {get; set;}
        
    }
    
    global class Reference{
        public string value {get; set;}
        public string qualifier {get; set;}
        
        public Reference(string value, string qualifier){
            this.value = value;
            this.qualifier = qualifier;
        }
    }
    
    global class SystemReference{
        public string systemReferenceDescription {get; set;}
        public string systemReferenceValue {get; set;}
    }
    
    global class Party{
        public string partyIdentifierCode {get; set;}
        public string partyIdentifierQualifierCode {get; set;}
        public string partyName {get; set;}
        public string addressLine2 {get; set;}
        public string addressLine {get; set;}
        public string city {get; set;}
        public string stateOrProvince {get; set;}
        public string country {get; set;}
        public string postalCode {get; set;}
        
        public Party(){}
        public Party(string partyIdentifierCode, string partyIdentifierQualifierCode, string partyName, string addressLine2, string addressLine, string city, string stateOrProvince, string country, string postalCod){
            this.partyIdentifierCode = partyIdentifierCode;
            this.partyIdentifierQualifierCode = partyIdentifierQualifierCode;
            this.partyName = partyName;
            this.addressLine2 = addressLine2;
            this.addressLine = addressLine;
            this.city = city;
            this.stateOrProvince = stateOrProvince;
            this.country = country;
            this.postalCode = postalCode;
        }
    }
    
    global class Response{
        public boolean success {get; set;}
        public string message {get; set;}
        
        public Response(){
            
        }
        
        public Response(boolean success, string message){
            this.success = success;
            this.message = message;
        }
    }
    
    public class productInfo{
        public string sku {get; set;}
        public string name {get; set;}
        public string weight {get; set;}
        public string dimensions {get; set;}
        public Decimal cost {get; set;}
    }

    public class productInfoHelper{
        public String name {get; set;}
        public String unitOfMeasure {get; set;}
        public Integer skuQuantity {get; set;}
        public productInfoHelper(String name, String unitOfMeasure, Integer skuQuantity){
            this.name = name;
            this.unitOfMeasure = unitOfMeasure;
            this.skuQuantity = skuQuantity;
        }
    }
    
    public class FailedInsertShipmentLinesException extends Exception {}    
}