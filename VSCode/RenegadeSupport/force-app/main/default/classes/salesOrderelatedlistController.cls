/*
*   Author : Sowdhanya Karri And Vishnu Bijjula | Kairos Tech
*   Class  : salesOrderelatedlistController
*   Purpose: This class is to get the list of particular Sales Order line Items and to create a purchase Order.
*/
global with sharing class salesOrderelatedlistController {
    public map<string,SOItemsWrapper> soRelatedList{get;set;}
    public Map<String, SOItemsWrapper> soRelatedCancelledList { get; set; }
    public Integer cancelledItemsCount { get { return soRelatedCancelledList.size(); } } 
    
    public Sales_Order__c SO_Obj {get; set;}
    public list<ItemsorderInvWrapper> soInvRelatedList {set;get;}
    Recordtype prodSimple;
    Id prodSimpleId;
    Recordtype prodBundledType;
    
    public set<id> ManufactureId {set;get;}
    public static list<string> listOfAutoComplete = new List<String>();
    public static List<string> getListOfAutoComplete(){
        return listOfAutoComplete;
    }
    public static Set<String> shipmentItemStatusSet = new Set<String>{'Hold As Stock', 'Enroute - Pending Hold As Stock'};
    private String libertyHub;
    private Boolean isSetLibertyHub = false;
    
    // The Below Variables is used to calculate updated qyt.
    list<ItemsorderWrapper> selectedMFSOItem; 
    list<SO_Line_Items__c> selectedMFSOItemList;
    map<SO_Line_Items__c,string> getqtyinv;
    map<SO_Line_Items__c,string> getWeight;
    map<SO_Line_Items__c,string> getTruckingId;
    map<SO_Line_Items__c,string> getDeliveryId;
    map<SO_Line_Items__c,Boolean> getUsecarrier;
    map<SO_Line_Items__c,string> getCarrier;
    map<string,list<Inventory__c>> inventory_Map;
    map<string,list<Shipment_Line_Item__c>> ShipmentLineItemsByinventory_Map;
    //map<string,list<Inventory__c>> deliveryInventory_Map;
    //list<Inventory__c> Inventory_list;
    //list<Inventory__c> deliveryInventory_list;
    list<SO_Line_Items__c> bundledSOItemQtyList;
    map<String,String> getsoitemQty_Map;
    
    // The Below Variables is used to calculate updated qty for Inventory.
    list<ItemsorderInvWrapper> selectedInvSOItem; 
    list<SO_Line_Items__c> selectedInvSOItemList; 
    map<SO_Line_Items__c,string> getqtyinv1;
    map<SO_Line_Items__c,string> getWeight1;
    map<SO_Line_Items__c,string> getTruckingId1;
    map<SO_Line_Items__c,string> getDeliveryId1;
    map<SO_Line_Items__c,Boolean> getUsecarrier1;
    map<SO_Line_Items__c,string> getCarrier1;
    
    public Integer inventoryQty {get;set;}
    public Integer Quantity {get;set;}
    public Boolean isBundeled {get;set;}
    public string soItem1Id {get;set;} 
    public Inventory__c inventory1 {get;set;}
    public string inventoryId {get;set;} 
    
    public Boolean isDirectShipping {get;set;}
    public Boolean isShiptoHub {get;set;}
    
    public List<ItemsorderWrapper> selectedOrderwrapper {get;set;}
    public List<SO_Line_Items__c> selectedOrder {get;set;}
    
    // Source var for the iFrame
    public String iframeSource { get; set; }
    public Decimal totalWeight {get;set;}
    public String orderCommunicationType {get;set;}
    public String websiteURL {get;set;}
    
    public String trackingnumberId {get;set;}
    public boolean displayPopup {get; set;} 
    public string errorStyle {get;set;}
    public String manufacturerName {get;set;}
    Public String deliveryName {get;set;}
    public String originName {get; set;}
    public String truckingNote {get;set;}
    
    public Boolean isRedirect {get;set;}
    public Boolean stockAvailable {get;set;}
    public Boolean doNotUpdateManufacturer {get;set;}
    Set<Id> productIds;
    
    global static Purchase_Order__c POFielddisplay = new Purchase_Order__c();
    public static Purchase_Order__c getPOFielddisplay(){
        return POFielddisplay;
    }
    public static void setPOFielddisplay(Purchase_Order__c value){
        POFielddisplay = value;
    }
    public List<Purchase_Order__c> poList {get;set;}
    public integer submitOrder {get;set;}
    
    public pageReference pr {get;set;}
    public list<PO_Line_Items__c> PLI_list {get;set;}
    public list<SO_Line_Items__c> soMainbundleItems {get;set;}
    public String poStatus {get;set;}
    
    Public Boolean isButtonVisible {set;get;}
    
    public String selectedETA {get;set;}
    
    public boolean stockdisplayPopup {get; set;} 
    public SO_Line_Items__c protectionSOitems;
    
    public string Carrier {get;set;}
    
    Public Boolean isreqField {get;set;}
    Public String styleVar {get;set;}
    
    public String soitemId {get;set;}
    
    public boolean haveMultipleLocation {get;set;}
    public boolean isBunbleExist {get;set;}
    //r
    //public list<inventoryWrapper> iwList1 {get;set;}
    public static Map<ID,List<Shipment_Line_Item__c>> shipLineItem1 {get;set;}
    public static String inventoryIdShip{get;set;}
    public static List<Shipment_Line_Item__c> shipLineItem123 {get;set;}
    Map<String, Purchase_Order_Carrier_notes_settings__c> carrierNotesMap = Purchase_Order_Carrier_notes_settings__c.getAll();

    private static boolean isPopulatedAutocompleteList = false;
    global static List<String> matchAutoCompleteList = new List<String>();
    global static List<String> getMatchAutoCompleteList(){
        return matchAutoCompleteList;
    }

    Set<String> retaggedStatusSet = new Set<String>{'Retagged', 'Retag in process'};
    
    @RemoteAction
    global static String updateNotes(String value) {
        POFielddisplay.Notes__c = value;
        clearAutocompleteList();
        return POFielddisplay.Notes__c;
    }

    @RemoteAction
    global static String clearAutocompleteList() {
        matchAutoCompleteList = new List<String>();
        return '';
    }

    public List<selectoption> getSelect(Schema.DescribeFieldResult fieldResult) {
        List<selectoption> selectOption = new List<selectoption>();
        selectOption.add(new SelectOption('none', '--None--'));      
        for( Schema.PicklistEntry f : fieldResult.getPicklistValues()) {
            selectOption.add(new SelectOption(f.getLabel(), f.getValue()));
        }
        return selectOption;
    }

    public list<selectoption> getSelectCarrieroption() {
        return getSelect(Purchase_Order__c.Carrier__c.getDescribe());
    }

    public list<selectoption> getSelectLocations() {
        return getSelect(Purchase_Order__c.Liberty_Hub__c.getDescribe());
    }
    
    public list<selectoption> getSelectETAoption() {
        return getSelect(Sales_Order__c.Order_ETA__c.getDescribe());
    }

    static void populateAutocompleteList(){
        for(Auto_Complete_Data__c a: [SELECT id, Name From Auto_Complete_Data__c]){
            listOfAutoComplete.add(a.name);
        }
    }

    public static void notesAutocomplete(){
        if(!isPopulatedAutocompleteList){
            populateAutocompleteList();
            isPopulatedAutocompleteList = true;
        }
        if(String.isNotBlank(POFielddisplay.Notes__c)){
            populateMatchAutoCOmpleteList();
        }
    }

    static void populateMatchAutoCOmpleteList(){
        matchAutoCompleteList = new List<String>();
        for(String currentValue_i : listOfAutoComplete){
            if(currentValue_i.toLowerCase().contains(POFielddisplay.Notes__c.toLowerCase())){
                matchAutoCompleteList.add(currentValue_i);
            }
        }
    }

    public salesOrderelatedlistController(ApexPages.StandardController controller) {
        doNotUpdateManufacturer = false;
        isBunbleExist = false;
        selectedETA = 'none';
        trackingnumberId = '';
        isRedirect = false;
        stockAvailable = false;
        isBundeled = true;
        bundledSOItemQtyList = new list<SO_Line_Items__c>();
        getsoitemQty_Map = new map<String,String>();
        
        list<Inventory__c> Inventory_list = new list<Inventory__c>();
        SO_Obj = new Sales_Order__c();
        selectedOrder = new List<SO_Line_Items__c>();
        
        POFielddisplay = new Purchase_Order__c();
        
        try {
            SO_Obj = (Sales_Order__c)controller.getrecord();
            
            SO_Obj = [  select  id,name,Bill_To__c, (SELECT id FROM SO_Line_Items__r),Payment_Status__c,Order_Status__c,Promotion__r.Name,Promotion__c,Customer_shipping_Address__c, Customer_shipping_Address__r.Zip_Postal_Code__c,
                                Total_Quantity_Ordered__c,Order_Date__c,Sales_Representative__r.name,Customer_Name__r.name,Customer_Name__r.Phone,Shipping_Address__c,Order_ETA__c,
                                Customer_Name__c,Email__c,Ship_to__c, Shipping_City__c,Shipping_Handle__c,Mobile__c,Delivery_Companies_Distance__c,Sales_Rep__c, Magento_Order_ID__c,
                                Billing_City__c,Billing_Phone__c,Billing_State__c,Billing_Street__c,Billing_ZipCode__c,Shipping_State__c,Shipping_Street__c,Shipping_ZipCode__c, Magento_order_No__c,
                                Billing_Address__c,Shipping_Phone__c,Shipping_Mobile__c,Order_Type__c,Delivery_Company__c,Delivery_Company__r.Name,(SELECT id FROM Invoice__r), Manufacturer__c, Manufacturer__r.Name,
                                IsFedexable__c, Default_Carrier__c, Suggested_Trucking_Company__c
                       from Sales_Order__c where id=:SO_Obj.id];

            deliveryName = SO_Obj.Delivery_Company__r.Name;
            Id productBundledTypeID = Schema.SObjectType.Products__c.getRecordTypeInfosByDeveloperName().get('Bundled').getRecordTypeId(); 

            bundledSOItemQtyList = [SELECT Bundle_Item__c,Image__c, Config_Product__c,CreatedById,CreatedDate,Custom_Price__c,DiscountAmount__c, Unit_Price__c,
                                    Id,IncludeInPricing__c,TaxAmount__c,Tax_Percent__c,UnitPrice__c,Manufacturer__c,Name,OriginalPrice__c,Price__c,ProductSKU__c,Products__c,
                                    Product_Brand__c,Product_Name__c,Product_Url__c,Promotion_Brand__c,Quantity_Invoiced__c, ProductImageUrl__c, FedExable__c, 
                                    Quantity__c,Quantity_Refunded__c,Row_Total__c,Sales_Commission_Hidden__c,Sales_Commission__c,Sales_Order__c,Sub_Total__c
                                    FROM SO_Line_Items__c WHERE Sales_Order__c = :SO_Obj.id AND (Bundle_Item__c = Null AND Config_Product__c = Null AND (Products__c != Null AND Products__r.RecordTypeId = :productBundledTypeID))];//prodBundledType.id
            System.debug('bundledSOItemQtyList: '+bundledSOItemQtyList);
            
            if(bundledSOItemQtyList.size() != 0)
            {
                for(SO_Line_Items__c oneBundleQty : bundledSOItemQtyList) {
                    getsoitemQty_Map.put(oneBundleQty.Products__c,String.valueof(oneBundleQty.Quantity__c));
                }
            }
            
            productIds = new Set<Id>();
            list<SO_Line_Items__c> BundelSOitems=[select Products__r.Non_Furniture_Product__c, Cancelled_Status__c, Quantity_Refunded__c, Price_For_Credit_Memo__c, DiscountAmount_For_Credit_Memo__c, Tax_Amount_For_Credit_Memo__c, Parent_Item_Ordered__c, id,Unit_Price__c, Product_Cost__c, FedExable__c,Products__r.Select_Manufacturer__r.name,Products__r.recordtype.name,Products__r.recordtypeid,Custom_Price__c,TaxAmount__c,Sub_Total__c,Price__c,name,Products__c,Products__r.Image__c,Products__r.name,Manufacturer__c,OriginalPrice__c,Product_Brand__c,Tax_Amount__c,
                                                  Products__r.Select_Manufacturer__r.Direct_Shipping__c,Promotion_Brand__c,Quantity__c,DiscountAmount__c,Row_Total__c,Quantity_Invoiced__c,Sales_Order__c,Tax_Percent__c,UnitPrice__c,Bundle_Item__r.Product__c,Bundle_Item__c,Config_Product__c,Product_Name__c,ProductSKU__c,Product_Url__c,Total_Weight_Pounds__c, ProductImageUrl__c,
                                                  Products__r.Select_Manufacturer__r.Ship_To_HUB__c,Products__r.Select_Manufacturer__r.Order_Communication_Type__c,Products__r.Select_Manufacturer__r.Website,Item__c, Image__c from SO_Line_Items__c where Bundle_Item__c != null and Sales_Order__c =: SO_Obj.id order by Bundle_Item__r.Order__c];
            
            for (SO_Line_Items__c sli : BundelSOitems){
            	if (sli.Config_Product__c != null){
            		productIds.add(sli.Config_Product__c);
            	}
            	else if (sli.Bundle_Item__c != null){
            		productIds.add(sli.Bundle_Item__r.Product__c);
            	}
            	
            }
            list<SO_Line_Items__c> SoiItems = [select Products__r.Non_Furniture_Product__c, Cancelled_Status__c, Price_For_Credit_Memo__c, DiscountAmount_For_Credit_Memo__c, Tax_Amount_For_Credit_Memo__c, Row_Total_For_Credit_Memo__c, ProductImageUrl__c, id, Product_Cost__c, FedExable__c,Products__r.RecordType.Name,Products__r.recordtypeid,TaxAmount__c,Sub_Total__c,Price__c,Unit_Price__c, name,Products__c,Products__r.Image__c,Products__r.name,Manufacturer__c,OriginalPrice__c,Product_Brand__c,Quantity_Refunded__c,Total_Weight_Pounds__c,Products__r.Select_Manufacturer__r.Order_Communication_Type__c,Products__r.Select_Manufacturer__r.Website,Bundle_Item__r.Product__c,Products__r.Select_Manufacturer__r.Ship_To_HUB__c,Tax_Amount__c,
                                           Products__r.Select_Manufacturer__r.Direct_Shipping__c,Products__r.Select_Manufacturer__c,Promotion_Brand__c,Quantity__c,DiscountAmount__c,Row_Total__c,Custom_Price__c, Quantity_Invoiced__c,Sales_Order__c,Sales_Order__r.Order_Status__c,Tax_Percent__c,UnitPrice__c,Bundle_Item__c,Config_Product__c,Product_Name__c,ProductSKU__c,Product_Url__c,Item__c, Image__c from SO_Line_Items__c where Sales_Order__c =: SO_Obj.id and Bundle_Item__c = null ORDER BY ProductSKU__c DESC];
            System.debug('getsoitemQty_Map: '+getsoitemQty_Map);
            for (SO_Line_Items__c sli : SoiItems){
            	productIds.add(sli.Products__c);
            }
            
            prodSimpleId = Schema.SObjectType.Products__c.getRecordTypeInfosByDeveloperName().get('Simple').getRecordTypeId(); 

            Inventory_list = [  SELECT RecordType.Name, Description__c,Id,Manage_Stock__c,Minimum_Quantity__c, Delivery_Company__c, Name,Products__c,Quantity__c,RecordTypeId, Shipment_Item__r.Shipment__r.Related_Sales_Order__r.Magento_order_No__c,
                                    Warehouse_Location__c,Warehouse_Name__c,Warehouse_Name__r.Name, Delivery_Company_Name__c, Shipment_Item__r.Furniture_Condition__c, Shipment_Item__r.Magento_Order_No__c, Shipment_Item__r.Shipment__r.Related_Sales_Order__r.Id,
                                    (SELECT Shipment_Item_Status__c, Product_SKU__c, Shipment_Product_Name__c, 
                                        Quantity__c, Product_Name__c,Shipment_Product_SKU__c, 
                                        Item_condition__c, Shipment__c, Furniture_Condition__c, Magento_Order_No__c, Shipment__r.Related_Sales_Order__r.Id, Shipment__r.Related_Sales_Order__r.Magento_order_No__c
                                    FROM Shipment_Line_Items__r WHERE Shipment_Item_Status__c NOT IN :retaggedStatusSet ) 
                                FROM Inventory__c 
                                WHERE (Products__c != null AND Warehouse_Name__c != null)   AND Products__c in :productIds
                                AND (Quantity__c > 0 AND (Product_Condition__c='Unopened' OR Product_Condition__c='Resellable')) 
                                AND (RecordType.Name='Own Inventory' or RecordType.Name='Delivery Company Inventory')];

            inventory_Map = new map<string,list<Inventory__c>>();
            ShipmentLineItemsByinventory_Map = new map<string,list<Shipment_Line_Item__c>>();
            set<string> shipmentIds = new set<string>();
            map<string, string> inventoryIdByShlId = new map<string, string>();
            Map<String, Inventory__c> validInventoryMap = new Map<String, Inventory__c>();
            for(Inventory__c inv : Inventory_list) {
                Boolean hasDamage = false;
                if(inv.RecordType.Name == 'Own Inventory'){
                    validInventoryMap.put(inv.Id, inv);
                }
            	for (Shipment_Line_Item__c sli : inv.Shipment_Line_Items__r){
                    if(sli.Furniture_Condition__c == 'Damaged'){
                        hasDamage = true;
                        break;
                    }
            		if (shipmentItemStatusSet.contains(sli.Shipment_Item_Status__c)){
            			inventoryIdByShlId.put(sli.Product_SKU__c, inv.id);
                        shipmentIds.add(sli.Shipment__c);
                        if(!validInventoryMap.containsKey(inv.Id)){
                            validInventoryMap.put(inv.Id, inv);
                        }
                    } 
                }
                if(hasDamage && validInventoryMap.containsKey(inv.Id)){
                    validInventoryMap.remove(inv.Id);
                }
                if(validInventoryMap.containsKey(inv.Id)){
                    if (!inventory_Map.containskey(inv.Products__c)){
                        inventory_Map.put(inv.Products__c, new list<Inventory__c>());
                    }
                    inventory_Map.get(inv.Products__c).add(inv);
                }
            }
            List<Shipment_Line_Item__c> shipmentLines = [SELECT Shipment_Item_Status__c, Shipment_Product_Name__c, Product_SKU__c, Quantity__c, Product_Name__c,
                                                            Shipment_Product_SKU__c, Item_condition__c, Shipment__c, Furniture_Condition__c, Magento_Order_No__c, Shipment__r.Related_Sales_Order__r.Magento_order_No__c, Shipment__r.Related_Sales_Order__r.Id
                                                        FROM Shipment_Line_Item__c 
                                                        WHERE Shipment__c IN :shipmentIds AND Product_SKU__c IN :inventoryIdByShlId.keySet()];
            
            Map<String, List<Shipment_Line_Item__c>> shipmentLinesMap = new Map <String, List<Shipment_Line_Item__c>>();

            for(Shipment_Line_Item__c sli : shipmentLines){
                if(!validInventoryMap.containsKey(inventoryIdByShlId.get(sli.Product_SKU__c))){
                    continue;
                }

                Inventory__c currentInventory = validInventoryMap.get(inventoryIdByShlId.get(sli.Product_SKU__c));

                if (!ShipmentLineItemsByinventory_Map.containsKey(currentInventory.Id)){
                    ShipmentLineItemsByinventory_Map.put(currentInventory.Id, new List<Shipment_Line_Item__c>());
                }
                ShipmentLineItemsByinventory_Map.get(currentInventory.Id).add(sli);
                
            }
            
            System.debug('inventory_Map: '+inventory_Map);
            System.debug('ShipmentLineItemsByinventory_Map: '+ShipmentLineItemsByinventory_Map);
            
            soRelatedList = new map<string,SOItemsWrapper>();
            soRelatedCancelledList = new Map<String, SOItemsWrapper>();
            
            for(SO_Line_Items__c SoiItem: SoiItems)
            {
                if(SoiItem.Products__r.recordtype.name=='Bundled')
                {
                    isBunbleExist = true;
                    list<SO_Line_Items__c> BundelSOitemstemp = new list<SO_Line_Items__c>();
                    for(SO_Line_Items__c BundelItem: BundelSOitems)
                    { 
                        if(SoiItem.Products__c == BundelItem.Products__c && (BundelItem.Parent_Item_Ordered__c == null || BundelItem.Parent_Item_Ordered__c == SoiItem.id))
                        {                        
                            BundelSOitemstemp.add(BundelItem);
                        }
                    }
                    system.debug('BundelSOitemstemp ' +BundelSOitemstemp); 
                    if(BundelSOitemstemp.size()>0)
                    {
                        soRelatedList.put(SoiItem.Manufacturer__c+SoiItem.id,new SOItemsWrapper(false,SoiItem,BundelSOitemstemp));
                    }
                    else
                    {  
                        soRelatedList.put(SoiItem.Manufacturer__c+SoiItem.id,new SOItemsWrapper(false,SoiItem,new list<SO_Line_Items__c>()));
                    }
                }
                else
                {                                
                    soRelatedList.put(SoiItem.Manufacturer__c+SoiItem.id,new SOItemsWrapper(false,SoiItem,new list<SO_Line_Items__c>()));                
                } 
            }
            System.debug('soRelatedList: '+soRelatedList);
            
            for (String so_i : soRelatedList.keySet())
                if (soRelatedList.get(so_i).SoItem.Item__c == 'Cancelled'){
                    soRelatedCancelledList.put(so_i, soRelatedList.get(so_i));
                    soRelatedList.remove(so_i);
                }
            
            if(soRelatedList.size() == 0) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,'No Sales Order Items are found.'));  
            }
            
        }
        catch(exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.error,e.getMessage()+' '+e.getCause()+' '+e.getLineNumber()));  
        }
    }
    
    public void onChange()
    {
        continuetoNextpage();
    }
    
    public pageReference submitOnChange()
    {
        Carrier =  (SO_Obj.IsFedexable__c && String.isNotBlank(SO_Obj.Default_Carrier__c)) ? SO_Obj.Default_Carrier__c : 'FedEx';//'FedEx';
        if(SO_Obj.Suggested_Trucking_Company__c != null){
            POFielddisplay.Suggested_Trucking__c = SO_Obj.Suggested_Trucking_Company__c;
        }
        pageReference pr;
            for(SOItemsWrapper wrapOrderObj : soRelatedList.values()) 
            {
                if(wrapOrderObj.selected == true && wrapOrderObj.SoItem.Item__c == 'Processing') 
                {
                        system.debug('aaa wrapOrderObj = ' + wrapOrderObj);
                    if (wrapOrderObj.SoItem.FedExable__c == 'No' && wrapOrderObj.SoItem.Manufacturer__c != 'Protection Plan'){
                        Carrier = 'none';
                    }
                }
            }
        onCarrierchange();
        pr = new pageReference('/apex/poInitiationpage?id='+SO_Obj.Id);
        pr.setRedirect(false);
        return pr;
    }
    
    public void addMessage(String message) {
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, message));
    }

    public void checkCarrier() {
        if(POFielddisplay.Suggested_Trucking__c == null && haveMultipleLocation == false) {
            addMessage('Please select Suggest Trucking Company');
        }
        if(SO_Obj.Delivery_Company__c == null) {
            addMessage('Please select Suggest Delivery Company');
        }
    }  

    public void checkShipping() {
        if(isShiptoHub == true || isDirectShipping == true) {
            if(Carrier == 'White Glove') {
                checkCarrier();
            }
            else if(isDirectShipping == false && Carrier == 'none' && SO_Obj.Delivery_Company__c == null) {
                addMessage('Please select Suggest Delivery');
            }
        }
        else if((POFielddisplay.Suggested_Trucking__c == null && haveMultipleLocation == false) && (Carrier == 'none' || Carrier == 'White Glove')) {
            addMessage('Please select Suggest Trucking Company');
            if(SO_Obj.Delivery_Company__c == null) {
                addMessage('Please select Suggest Delivery Company');
            }
        }
        else if(SO_Obj.Delivery_Company__c == null && (Carrier == 'none' || Carrier == 'White Glove')) {
            addMessage('Please select Suggest Delivery Company');
        }
    }

    public void onDeliveryChange()
    {
        for(Sales_Order__c SO:[Select Delivery_Company__r.Name from Sales_Order__c where Delivery_Company__c=:SO_Obj.Delivery_Company__c]) {
            deliveryName = SO.Delivery_Company__r.Name;
        }

        if(Carrier != 'White Glove')
        {
            truckingNote = salesOrderelatedlistController.truckingNote(SO_Obj.Delivery_Company__c, ManufactureId);
            String truckingId = salesOrderelatedlistController.truckingAutoId(SO_Obj.Delivery_Company__c, ManufactureId, Integer.valueOf(totalWeight));
            if(truckingId != Null)
            {
                POFielddisplay.Suggested_Trucking__c = truckingId;
            }                        
        }
        
        checkShipping();

    	soItem1Id = '1';
    	sendManufacturer();
    }

    public static String truckingNote(Id deleveryId, set<Id> manufacturerId)
    {
        String truckNote;
        try
        {
            for(Trucking_Rule__c TR : [Select id,Truking_Selection_Note__c from Trucking_Rule__c where Selected_Delivery__c=:deleveryId AND Selected_Manufacturer__c In :manufacturerId LIMIT 1])
            {
                truckNote = TR.Truking_Selection_Note__c;
                System.debug('truckNote: '+truckNote);
            }
        }
        catch(exception e)
        {
            System.debug('Error: '+e.getMessage()+', Cause: '+e.getCause()+', Linenumber: '+e.getLineNumber()+', '+e.getStackTraceString());  
        }
        return truckNote;
    }
    
    //public static String truckingNote;
    public static String truckingAutoId(Id deleveryId, set<Id> manufacturerId, Integer totalWeight)
    {
        String gettruckingId;
        try
        {
            String truckingNote;
            list<String> truckingwithWeightList = new list<String>();
            list<String> truckingList = new list<String>();
            list<String> WeightList = new list<String>();    
            String truckingname;
            for(Trucking_Rule__c TR : [Select id,Truking_Selection_Note__c from Trucking_Rule__c where Selected_Delivery__c=:deleveryId AND Selected_Manufacturer__c In :manufacturerId LIMIT 1])
            {
                truckingNote = TR.Truking_Selection_Note__c;
                System.debug('truckingNote: '+truckingNote);
            }
            if(truckingNote != Null)
            {
                if(truckingNote.contains(','))
                {
                    for(String truckingWeight : truckingNote.split(','))
                    {
                        system.debug('truckingWeight: '+truckingWeight);
                        for(String truckingSplitWeight : truckingWeight.split(' - ')) {
                            system.debug('truckingSplitWeight: '+truckingSplitWeight);
                            truckingwithWeightList.add(truckingSplitWeight);
                        }
                    }
                }
                else {
                    truckingname = truckingNote;
                }
                system.debug('truckingwithWeightList: '+truckingwithWeightList);
                system.debug('truckingwithWeightList Size: '+truckingwithWeightList.size());
                for(Integer i=0;i<truckingwithWeightList.size();i++)
                {
                    truckingList.add(truckingwithWeightList[i+1]);
                    i++;
                }
                system.debug('truckingList: '+truckingList);
                for(Integer i=0;i<truckingwithWeightList.size();i++)
                {
                    WeightList.add(truckingwithWeightList[i]);
                    i++;
                }
                system.debug('WeightList: '+WeightList);
                system.debug('totalWeight: '+totalWeight);
                for(String truckingweight : WeightList)
                {
                    if(truckingweight.contains(' to '))
                    {
                        System.debug('truckingweight.contains to : '+truckingweight.contains(' to '));
                        //for(String splitnumber : truckingweight.split(' to ')) {
                        System.debug('truckingweight : '+truckingweight);
                        String s2 = truckingweight.substringAfterLast('to ');
                        System.debug('truckingweight.contains after to : '+s2);
                        if(totalWeight <= integer.valueOf(s2)) {
                            System.debug('truckingweight : '+truckingweight);
                            truckingname = truckingList[0];
                        }
                        //  }
                    }
                    else {
                        if(totalWeight >= integer.valueOf(truckingweight)) {
                            System.debug('truckingweight : '+truckingweight);
                            System.debug('totalWeight : '+totalWeight);
                            truckingname = truckingList[1];
                        }
                    }
                }
                System.debug('truckingname: '+truckingname);
                
                if(truckingname != Null)
                {
                    list<Account> acc = [Select Id from Account where RecordType.Name = 'Trucking Company' and name Like :('%'+truckingname+'%') Limit 1];
                    if (acc.size() > 0){
                        gettruckingId = acc[0].id;
                    }
                }
                System.debug('gettruckingId: '+gettruckingId);
            }
        }
        catch(exception e)
        {
            System.debug('Error: '+e.getMessage()+', Cause: '+e.getCause()+', Linenumber: '+e.getLineNumber()+', '+e.getStackTraceString());  
        }
        return gettruckingId;
    }
    
    public void onTruckingChange() 
    {
        checkShipping();
    }
    
    public void onCarrierchange()
    {
        System.debug('Carrier: '+Carrier);
        if(Carrier == 'White Glove') {
            POFielddisplay.Suggested_Trucking__c = Null;
            SO_Obj.Delivery_Company__c = Null;
        }
        if(SO_Obj.Suggested_Trucking_Company__c != null && Carrier == 'none' ){
            POFielddisplay.Suggested_Trucking__c = SO_Obj.Suggested_Trucking_Company__c;
        }
        POFielddisplay.Carrier_Info__c = carrierNotesMap.containsKey(Carrier) ? carrierNotesMap.get(Carrier).Notes__c : null;
    }
    
    public void onETAchange()
    {
        System.debug('selectedETA: '+selectedETA);
        If(selectedETA == 'none') {
            errorStyle = 'text-align:center;border-color: #d74c3b;border-width: medium;';
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,'Please Select Purchase Order ETA'));  
            if(POFielddisplay.Load_Date__c == null) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,'Please Enter a Load Date'));
            }
        }
        else if(POFielddisplay.Load_Date__c == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,'Please Enter a Load Date'));
        }
        else {
            errorStyle = 'text-align:None';
        }
    }
    
    public void continuetoNextpage()    {
        haveMultipleLocation = false;
        isreqField = false;
        styleVar = Null;
        Carrier = 'FedEx';
        totalWeight = 0;
        submitOrder = 0;
        selectedOrder = new List<SO_Line_Items__c>();
        selectedOrderwrapper = new List<ItemsorderWrapper>();
        soInvRelatedList = new list<ItemsorderInvWrapper>(); 
        
        soMainbundleItems = new List<SO_Line_Items__c>();
        
        ManufactureId = new set<id>();
        
        System.debug('soRelatedList: '+soRelatedList);
        try 
        {
            for(SOItemsWrapper wrapOrderObj : soRelatedList.values()) 
            {
                if(wrapOrderObj.selected == true && wrapOrderObj.SoItem.Item__c == 'Processing') 
                {
                        system.debug('aaa wrapOrderObj = ' + wrapOrderObj);
                    if (wrapOrderObj.SoItem.FedExable__c == 'No' && wrapOrderObj.SoItem.Manufacturer__c != 'Protection Plan'){
                        Carrier = 'none';
                    }
                    System.debug('ManufactureId: '+wrapOrderObj.SoItem.Products__r.Select_Manufacturer__c);
                    ManufactureId.add(wrapOrderObj.SoItem.Products__r.Select_Manufacturer__c);
                    selectedOrder.add(wrapOrderObj.SoItem);
                }
            }
            System.debug('ManufactureId: '+ManufactureId);
            System.debug('ManufactureId: '+ManufactureId.size());
            System.debug('selectedOrder: '+selectedOrder);
            
            if(selectedOrder.size() != 0)
            {
                if(ManufactureId.size() == 1)
                {
                    selectedOrder = new List<SO_Line_Items__c>();
                    for(SOItemsWrapper wrapOrderObj : soRelatedList.values()) 
                    {
                        if(wrapOrderObj.selected == true) 
                        {
                            if(wrapOrderObj.SoItem.Products__r.RecordType.Name == 'Bundled')
                            {
                                soMainbundleItems.add(wrapOrderObj.SoItem);
                                for(SO_Line_Items__c bundle : wrapOrderObj.bundleList) 
                                {
                                    if(bundle.Products__c == wrapOrderObj.SoItem.Products__c)
                                    { 
                                        if(getsoitemQty_Map.size() != 0 && getsoitemQty_Map.get(bundle.Products__c) != Null) {
                                            System.debug('Inner Quantity: '+Quantity);
                                            System.debug('getsoitemQty_Map.get(soLine.Products__c): '+getsoitemQty_Map.get(bundle.Products__c));
                                            Quantity = integer.valueOf(getsoitemQty_Map.get(bundle.Products__c)) * integer.valueOf(bundle.Quantity__c);
                                            System.debug('Inner Quantity1: '+Quantity);
                                        }
                                        else {
                                            Quantity = integer.valueOf(bundle.Quantity__c);
                                            System.debug('Else Inner Quantity: '+Quantity);
                                        }
                                        System.debug('Quantity: '+Quantity);
                                        
                                        manufacturerName = bundle.Manufacturer__c;
                                        System.debug('manufacturerName: '+manufacturerName);
                                        
                                        Integer totWeight = Integer.valueOf(bundle.Total_Weight_Pounds__c);
                                        totalWeight += totWeight;
                                        System.debug('totalWeight: '+totalWeight);
                                        isDirectShipping = bundle.Products__r.Select_Manufacturer__r.Direct_Shipping__c;
                                        isShiptoHub = bundle.Products__r.Select_Manufacturer__r.Ship_To_HUB__c;
                                        orderCommunicationType = bundle.Products__r.Select_Manufacturer__r.Order_Communication_Type__c;
                                        System.debug('inner websiteURL: '+bundle.Products__r.Select_Manufacturer__r.Website);
                                        websiteURL = bundle.Products__r.Select_Manufacturer__r.Website;
                                        selectedOrder.add(bundle);
                                        isButtonVisible = false;
                                        if (inventory_Map.containsKey(bundle.Config_Product__c)){
                                            addSelectedOrderWrapper(ShipmentLineItemsByinventory_Map, inventory_Map, bundle.Config_Product__c, selectedOrderwrapper, bundle, Quantity , bundle.Products__r.Select_Manufacturer__c);
                                        }
                                        else if(inventory_Map.containsKey(bundle.Bundle_Item__r.Product__c)) {
                                            addSelectedOrderWrapper(ShipmentLineItemsByinventory_Map, inventory_Map, bundle.Bundle_Item__r.Product__c, selectedOrderwrapper, bundle, Quantity, bundle.Products__r.Select_Manufacturer__c);
                                        }
                                        else {
                                            System.debug('Quantity: '+Quantity+'<='+'0 :inventoryQty');
                                            if(Quantity <= 0) {
                                                isButtonVisible = true;
                                            }
                                            else {
                                                isButtonVisible = false;
                                            }
                                            System.debug('isButtonVisible: '+isButtonVisible);
                                            selectedOrderwrapper.add(new ItemsorderWrapper(true,bundle,String.valueOf(Quantity),String.valueOf(Quantity),'0',bundle.Products__r.Select_Manufacturer__c,null,String.valueOf(bundle.Total_Weight_Pounds__c),isButtonVisible));
                                            System.debug('Else selectedOrderwrapper: '+selectedOrderwrapper);
                                        }
                                    }
                                }
                            }
                            else
                            {
                                if(getsoitemQty_Map.size() != 0 && getsoitemQty_Map.get(wrapOrderObj.SoItem.Products__c) != Null) {
                                    System.debug('Inner Quantity: '+Quantity);
                                    System.debug('getsoitemQty_Map.get(soLine.Products__c): '+getsoitemQty_Map.get(wrapOrderObj.SoItem.Products__c));
                                    Quantity = integer.valueOf(getsoitemQty_Map.get(wrapOrderObj.SoItem.Products__c)) * integer.valueOf(wrapOrderObj.SoItem.Quantity__c);
                                    System.debug('Inner Quantity1: '+Quantity);
                                }
                                else {
                                    Quantity = integer.valueOf(wrapOrderObj.SoItem.Quantity__c);
                                    System.debug('Else Inner Quantity: '+Quantity);
                                }
                                System.debug('Quantity: '+Quantity);
                                
                                manufacturerName = wrapOrderObj.SoItem.Manufacturer__c;
                                System.debug('manufacturerName: '+manufacturerName);
                                Integer totWeight = Integer.valueOf(wrapOrderObj.SoItem.Total_Weight_Pounds__c);
                                totalWeight += totWeight;
                                System.debug('totalWeight: '+totalWeight);
                                isDirectShipping = wrapOrderObj.SoItem.Products__r.Select_Manufacturer__r.Direct_Shipping__c;
                                isShiptoHub = wrapOrderObj.SoItem.Products__r.Select_Manufacturer__r.Ship_To_HUB__c;
                                orderCommunicationType = wrapOrderObj.SoItem.Products__r.Select_Manufacturer__r.Order_Communication_Type__c;
                                System.debug('inner websiteURL: '+wrapOrderObj.SoItem.Products__r.Select_Manufacturer__r.Website);
                                websiteURL = wrapOrderObj.SoItem.Products__r.Select_Manufacturer__r.Website;
                                selectedOrder.add(wrapOrderObj.SoItem);
                                
                                System.debug('inventory_Map: '+inventory_Map);
            					System.debug('ShipmentLineItemsByinventory_Map: '+ShipmentLineItemsByinventory_Map);
                                System.debug('wrapOrderObj.SoItem.Products__c: '+wrapOrderObj.SoItem.Products__c);
                                System.debug('wrapOrderObj.SoItem.Products__c: '+inventory_Map.containsKey(wrapOrderObj.SoItem.Products__c));
                                if(inventory_Map.containsKey(wrapOrderObj.SoItem.Config_Product__c)) {
                                    addSelectedOrderWrapper(ShipmentLineItemsByinventory_Map, inventory_Map, wrapOrderObj.SoItem.Config_Product__c, selectedOrderwrapper, wrapOrderObj.SoItem, Quantity, wrapOrderObj.SoItem.Products__r.Select_Manufacturer__c);
                                }
                                else if(inventory_Map.containsKey(wrapOrderObj.SoItem.Products__c)) {
                                    addSelectedOrderWrapper(ShipmentLineItemsByinventory_Map, inventory_Map, wrapOrderObj.SoItem.Products__c, selectedOrderwrapper, wrapOrderObj.SoItem, Quantity, wrapOrderObj.SoItem.Products__r.Select_Manufacturer__c);
                                }
                                else {
                                    System.debug('Quantity: '+Quantity+'<='+'0 :inventoryQty');
                                    if(Quantity <= 0) {
                                        isButtonVisible = true;
                                    }
                                    else {
                                        isButtonVisible = false;
                                    }
                                    System.debug('isButtonVisible: '+isButtonVisible);
                                    selectedOrderwrapper.add(new ItemsorderWrapper(true,wrapOrderObj.SoItem,String.valueOf(Quantity),String.valueOf(Quantity),'0',wrapOrderObj.SoItem.Products__r.Select_Manufacturer__c,null,String.valueOf(wrapOrderObj.SoItem.Total_Weight_Pounds__c),isButtonVisible));
                                    System.debug('Else selectedOrderwrapper: '+selectedOrderwrapper);
                                }
                            }
                        }
                    }
                    System.debug('selectedOrder: '+selectedOrder);
                    System.debug('selectedOrderwrapper: '+selectedOrderwrapper);
                    System.debug('Delivery ID: '+SO_Obj.Delivery_Company__c);
                    System.debug('isDirectShipping: '+isDirectShipping);
                    System.debug('selectedOrder: '+selectedOrder);
                    System.debug('selectedOrderwrapper: '+selectedOrderwrapper);
                    System.debug('websiteURL: '+websiteURL);
                    System.debug('ManufactureId: '+ManufactureId);
                    System.debug('soMainbundleItems: '+soMainbundleItems);
                    
                    if(SO_Obj.Delivery_Company__c != null && ManufactureId != null)
                    {
                        System.debug('Delevery Id: '+SO_Obj.Delivery_Company__c);
                        System.debug('ManufactureId: '+ManufactureId);
                        System.debug('totalWeight: '+totalWeight);
                        if(Carrier != 'White Glove'){
                            truckingNote = salesOrderelatedlistController.truckingNote(SO_Obj.Delivery_Company__c, ManufactureId);
                            String truckingId = salesOrderelatedlistController.truckingAutoId(SO_Obj.Delivery_Company__c, ManufactureId, Integer.valueOf(totalWeight));
                            if(truckingId != Null)
                            {
                                POFielddisplay.Suggested_Trucking__c = truckingId;
                            }                        
                        }
                    }
                    else{
                        truckingNote = '';
                    }
                    System.debug('truckingNote: '+truckingNote);
                    if(isDirectShipping != true){
                        iframeSource = 'apex/NearerDeliveryCompaniesVF?id='+SO_Obj.Id;
                    }
                    
                    if(manufacturerName != null) {
                        List<Account> naufactureList = [Select id,Multiple_Locations__c From Account where name=:manufacturerName];
                        if(naufactureList.size() > 0){
                            haveMultipleLocation = naufactureList.get(0).Multiple_Locations__c;
                        }

                        //haveMultipleLocation = [Select id,Multiple_Locations__c From Account where name=:manufacturerName].Multiple_Locations__c;
                    }
                }
                else 
                {
                    Apexpages.addMessage(new ApexPages.message(apexpages.Severity.WARNING,'Please choose the products from same Manufacturer.'));
                }
            }
            System.debug('commType: '+orderCommunicationType);
        }
        catch(exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.error,e.getMessage()+', Cause: '+e.getCause()+', Linenumber: '+e.getLineNumber()+', '+e.getStackTraceString()));  
        }
    }
    
    public void sendInventory(){
        System.debug('soItem1Id: '+soItem1Id);
        System.debug('inventory1: '+inventory1);
        inventory1 = [select id, Quantity__c, Products__c, Warehouse_Name__c,
                      Warehouse_Name__r.Name, Delivery_Company_Name__c, Shipment_Item__r.Furniture_Condition__c, Shipment_Item__r.Magento_Order_No__c, Shipment_Item__r.Shipment__r.Related_Sales_Order__r.Id, Shipment_Item__r.Shipment__r.Related_Sales_Order__r.Magento_order_No__c
                      FROM Inventory__c where id = :inventoryId
                     ];
        isBundeled = true;
        System.debug('soItem1Id: '+soItem1Id);
        System.debug('inventory1: '+inventory1);
        
        map<id,id> mfItemap = new map<id,id>();
        integer m=0;
        integer f;  
        try {
            System.debug('selectedOrderwrapper: '+ selectedOrderwrapper);
            for(ItemsorderWrapper oneItem: selectedOrderwrapper){
                if(oneItem.SoItem.id == soItem1Id && (oneItem.inventoryQty != '0')) {
                    f=m;
                    System.debug('f: '+f);
                    totalWeight = totalWeight - Decimal.valueOf(oneItem.weight);
                    System.debug('totalWeight: '+totalWeight);
                    
                    System.debug('Delevery Id: '+SO_Obj.Delivery_Company__c);
                    System.debug('ManufactureId: '+ManufactureId);
                    System.debug('totalWeight: '+totalWeight);
                    if(Carrier != 'White Glove'){
                        String truckingId = salesOrderelatedlistController.truckingAutoId(SO_Obj.Delivery_Company__c, ManufactureId, Integer.valueOf(totalWeight));
                        if(truckingId != Null){
                            POFielddisplay.Suggested_Trucking__c = truckingId;
                        }                        
                    }
                    System.debug(oneItem.Quantity);
                    System.debug(oneItem.inventoryQty);
                    System.debug(oneItem.qty);
                    if(Integer.valueOf(oneItem.Quantity) < inventory1.Quantity__c){
                        oneItem.Quantity = '0';
                    }else{
                        oneItem.Quantity = '' + (Integer.valueOf(oneItem.Quantity) - inventory1.Quantity__c);
                        oneItem.isLessinventorythanquantity = false;
                    }
                }
                else if(oneItem.SoItem.id != soItem1Id){
                    mfItemap.put(oneItem.SoItem.id,oneItem.SoItem.id); 
                }
                m++;
            }
            
            if (Integer.valueOf(selectedOrderwrapper[f].Quantity) <= 0){//(!selectedOrderwrapper[f].isLessinventorythanquantity){
            	selectedOrderwrapper.remove(f);
            }
            /*else {
            	selectedOrderwrapper[f].Quantity = string.valueof(integer.valueof(selectedOrderwrapper[f].Quantity) - integer.valueof(selectedOrderwrapper[f].inventoryQty));
            }*/
            selectedOrderwrapper = selectedOrderwrapper;
            System.debug('mfItemap: '+mfItemap.keySet());
            
            map<id,id> invItemap = new map<id,id>();
            if(soItem1Id != Null) {
                for(ItemsorderInvWrapper oneItem: soInvRelatedList){
                    invItemap.put(oneItem.SoItem1.id,oneItem.SoItem1.id); 
                }
            }
            for(SO_Line_Items__c soLine1 : [select Products__r.Non_Furniture_Product__c, id,name,Unit_Price__c, Products__c,DiscountAmount__c, 
                                            Manufacturer__c,Product_Brand__c,Promotion_Brand__c,Quantity__c,Sales_Order__c,
                                            Products__r.Select_Manufacturer__c,Bundle_Item__r.Bundle__c,Config_Product__c,Total_Weight_Pounds__c,
                                            Products__r.Select_Manufacturer__r.Order_Communication_Type__c,ProductSKU__c,Products__r.recordtype.name,
                                            FedExable__c, Sales_Order__r.Delivery_Company__c,Products__r.Select_Manufacturer__r.Direct_Shipping__c,
                                            Bundle_Item__r.Product__c,Bundle_Item__c,Product_Name__c,Product_Url__c, ProductImageUrl__c, Image__c 
                                            from SO_Line_Items__c 
                                            where Sales_Order__c =: SO_Obj.id 
                                            AND id = :soItem1Id 
                                            and (Config_Product__c != Null OR Bundle_Item__c != Null 
                                                 OR (Products__c != Null AND Products__r.RecordTypeId =:prodSimpleId)
                                                ) ORDER BY Manufacturer__c
                                           ]) { //prodSimple.id
                if(getsoitemQty_Map.size() != 0 && getsoitemQty_Map.get(soLine1.Products__c) != Null) {
                    Quantity = integer.valueOf(getsoitemQty_Map.get(soLine1.Products__c)) * integer.valueOf(soLine1.Quantity__c);
                }
                else {
                    Quantity = integer.valueOf(soLine1.Quantity__c);
                }
                if(inventory1.Products__c == soLine1.Config_Product__c && integer.valueOf(inventory1.Quantity__c) != 0) {
                    inventoryQty = integer.valueOf(inventory1.Quantity__c);
                    if(inventoryQty >= Quantity && (soLine1.id == soItem1Id && !invItemap.containsKey(soLine1.id))) {
                        soInvRelatedList.add(new ItemsorderInvWrapper(soLine1,String.valueOf(Quantity),String.valueOf(Quantity),String.valueOf(inventoryQty),inventory1.ID,inventory1.Warehouse_Name__c,inventory1.Warehouse_Name__r.Name,String.valueOf(soLine1.Total_Weight_Pounds__c)));
                    }
                    else if((soLine1.id == soItem1Id && !invItemap.containsKey(soLine1.id))) {
                        soInvRelatedList.add(new ItemsorderInvWrapper(soLine1,String.valueOf(inventoryQty),String.valueOf(inventoryQty),String.valueOf(inventoryQty),inventory1.ID,inventory1.Warehouse_Name__c,inventory1.Warehouse_Name__r.Name,String.valueOf(soLine1.Total_Weight_Pounds__c)));
                    }
                }
                else if(inventory1.Products__c == soLine1.Bundle_Item__r.Product__c && integer.valueOf(inventory1.Quantity__c) != 0) {
                    inventoryQty = integer.valueOf(inventory1.Quantity__c);
                    if(inventoryQty >= Quantity && (soLine1.id == soItem1Id && !invItemap.containsKey(soLine1.id))) {
                        soInvRelatedList.add(new ItemsorderInvWrapper(soLine1,String.valueOf(Quantity),String.valueOf(Quantity),String.valueOf(inventoryQty),inventory1.ID, inventory1.Warehouse_Name__c, inventory1.Warehouse_Name__r.Name,String.valueOf(soLine1.Total_Weight_Pounds__c)));
                    }
                    else if((soLine1.id == soItem1Id && !invItemap.containsKey(soLine1.id))) {
                        soInvRelatedList.add(new ItemsorderInvWrapper(soLine1,String.valueOf(inventoryQty),String.valueOf(inventoryQty),String.valueOf(inventoryQty),inventory1.ID, inventory1.Warehouse_Name__c, inventory1.Warehouse_Name__r.Name,String.valueOf(soLine1.Total_Weight_Pounds__c)));
                    }
                }
                else if(inventory1.Products__c == soLine1.Products__c && integer.valueOf(inventory1.Quantity__c) != 0) {
                    inventoryQty = integer.valueOf(inventory1.Quantity__c);
                    if(inventoryQty >= Quantity && (soLine1.id == soItem1Id && !invItemap.containsKey(soLine1.id))) {
                        soInvRelatedList.add(new ItemsorderInvWrapper(soLine1,String.valueOf(Quantity),String.valueOf(Quantity),String.valueOf(inventoryQty), inventory1.Id,inventory1.Warehouse_Name__c, inventory1.Warehouse_Name__r.Name,String.valueOf(soLine1.Total_Weight_Pounds__c)));
                    }
                    else if((soLine1.id == soItem1Id && !invItemap.containsKey(soLine1.id))) {
                        soInvRelatedList.add(new ItemsorderInvWrapper(soLine1,String.valueOf(inventoryQty),String.valueOf(inventoryQty),String.valueOf(inventoryQty), inventory1.Id,inventory1.Warehouse_Name__c, inventory1.Warehouse_Name__r.Name,String.valueOf(soLine1.Total_Weight_Pounds__c)));
                    }
                }
            }
            System.debug('selectedOrderwrapper: '+JSON.serializePretty(selectedOrderwrapper));
            System.debug('soInvRelatedList: '+soInvRelatedList);
        }
        catch(exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.error,e.getMessage()+' '+e.getCause()+' '+e.getLineNumber()));  
        }
    } 
    
    public void sendManufacturer(){
        isBundeled = true;
        System.debug('soItem1Id: '+soItem1Id);
        system.debug('soInvRelatedList Wrapper :' + soInvRelatedList);
        try {
            map<id,id> invItemap = new map<id,id>();
            integer i=0;
            integer k;
            for(ItemsorderInvWrapper oneItem: soInvRelatedList) 
            {
                if(oneItem.SoItem1.id == soItem1Id || soItem1Id == '1')
                {
                    k=i;
                    System.debug('k: '+k);
                    totalWeight = totalWeight + Decimal.valueOf(oneItem.weight);
                    System.debug('totalWeight: '+totalWeight);
                    System.debug('Delevery Id: '+SO_Obj.Delivery_Company__c);
                    System.debug('ManufactureId: '+ManufactureId);
                    System.debug('totalWeight: '+totalWeight);
                    System.debug('@@@ Carrier : '+ Carrier);
                    if(Carrier != 'White Glove'){
                        String truckingId = salesOrderelatedlistController.truckingAutoId(SO_Obj.Delivery_Company__c, ManufactureId, Integer.valueOf(totalWeight));
                        system.debug('$$$$$truckingId ' + truckingId);
                        if(truckingId != Null){
                            POFielddisplay.Suggested_Trucking__c = truckingId;
                        }                        
                    }
                }
                else if(oneItem.SoItem1.id != soItem1Id){
                    invItemap.put(oneItem.SoItem1.id,oneItem.SoItem1.id); 
                }
                i++;
                system.debug('!!! invItemap'+ invItemap);
            }
            soInvRelatedList.remove(k);
            System.debug('invItemap: '+invItemap.keySet());
            System.debug('invItemap: '+soInvRelatedList);
            
            map<id,id> mfItemap = new map<id,id>();
            integer m=0;
            integer f; 
            
            for(ItemsorderWrapper oneItem: selectedOrderwrapper){
                if(oneItem.SoItem.id == soItem1Id){
                    f=m;
                    System.debug('f: '+f);
                }
                else if(oneItem.SoItem.id != soItem1Id){
                    mfItemap.put(oneItem.SoItem.id,oneItem.SoItem.id); 
                }
                m++;
            }
            
            for(SO_Line_Items__c soLine : [select Products__r.Non_Furniture_Product__c, id, FedExable__c, Unit_Price__c, name,Products__c,DiscountAmount__c,
                                           Manufacturer__c,Product_Brand__c,Promotion_Brand__c,Quantity__c,Sales_Order__c,Products__r.Select_Manufacturer__c,
                                           Bundle_Item__r.Bundle__c,Config_Product__c,Total_Weight_Pounds__c,Products__r.Select_Manufacturer__r.Order_Communication_Type__c,
                                           ProductSKU__c,Products__r.recordtype.name, Sales_Order__r.Delivery_Company__c,Products__r.Select_Manufacturer__r.Direct_Shipping__c,
                                           Bundle_Item__r.Product__c,Bundle_Item__c,Product_Name__c,Product_Url__c, ProductImageUrl__c, Image__c from SO_Line_Items__c 
                                           where Sales_Order__c =: SO_Obj.id 
                                           AND id = :soItem1Id 
                                           and (Config_Product__c != Null 
                                                OR Bundle_Item__c != Null 
                                                OR (Products__c != Null 
                                                    AND Products__r.RecordTypeId =:prodSimpleId
                                                   )
                                               ) ORDER BY Manufacturer__c
                                          ]){ //prodSimple.id
                                              if(getsoitemQty_Map.size() != 0 && getsoitemQty_Map.get(soLine.Products__c) != Null) {
                                                  Quantity = integer.valueOf(getsoitemQty_Map.get(soLine.Products__c)) * integer.valueOf(soLine.Quantity__c);
                                                  System.debug('If Quantity: '+Quantity);
                                              }
                                              else {
                                                  Quantity = integer.valueOf(soLine.Quantity__c);
                                                  System.debug('Else Quantity: '+Quantity);
                                              }
                                              System.debug('Quantity: '+Quantity);
                                              if(inventory_Map.containsKey(soLine.Config_Product__c)){
                                                  addSelectedOrderWrapper(ShipmentLineItemsByinventory_Map, inventory_Map, soLine.Config_Product__c, selectedOrderwrapper, soLine, Quantity, soLine.Products__r.Select_Manufacturer__c);
                                              }
                                              else if(inventory_Map.containsKey(soLine.Bundle_Item__r.Product__c)){
                                                  addSelectedOrderWrapper(ShipmentLineItemsByinventory_Map, inventory_Map, soLine.Bundle_Item__r.Product__c, selectedOrderwrapper, soLine, Quantity, soLine.Products__r.Select_Manufacturer__c);
                                              }
                                              else if(inventory_Map.containsKey(soLine.Products__c)){
                                                  addSelectedOrderWrapper(ShipmentLineItemsByinventory_Map, inventory_Map, soLine.Products__c, selectedOrderwrapper, soLine, Quantity, soLine.Products__r.Select_Manufacturer__c);
                                              }
                                          }
            System.debug('selectedOrderwrapper................: '+selectedOrderwrapper);            
        }
        catch(exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.error,e.getMessage()+' '+e.getCause()+' '+e.getLineNumber()));  
        }
    }
    
    public void updateitemPurchaseorder() {
        // Creating Instant memory for adding Manufacture items. 
        selectedMFSOItem = new list<ItemsorderWrapper>(); 
        selectedMFSOItemList = new list<SO_Line_Items__c>();  
        getqtyinv = new map<SO_Line_Items__c,String>();
        getWeight = new map<SO_Line_Items__c,String>();
        
        try {
            // Filtering from Manufacture Section in vf Page which qty not qual to zero
            for(ItemsorderWrapper oneItem: selectedOrderwrapper) {
                if(oneItem.qty != '0') {
                    selectedMFSOItem.add(oneItem);
                    selectedMFSOItemList.add(oneItem.SoItem);
                    getqtyinv.put(oneItem.SoItem,oneItem.qty);
                    getWeight.put(oneItem.SoItem,oneItem.weight);
                }
            }
            System.debug('selectedMFSOItem: '+selectedMFSOItem);
            System.debug('selectedMFSOItem: '+selectedMFSOItem.size());
            System.debug('*********************************************************');
            System.debug('getqtyinv Keys: '+getqtyinv.keySet());
            System.debug('getqtyinv Values: '+getqtyinv.values());
            System.debug('getWeight Values: '+getWeight.values());
            
            System.debug('selectedOrderwrapper: '+selectedOrderwrapper);
            
            // Creating Instant memory for adding Manufacture items. 
            selectedInvSOItem = new list<ItemsorderInvWrapper>(); 
            selectedInvSOItemList = new list<SO_Line_Items__c>();  
            getqtyinv1 = new map<SO_Line_Items__c,String>();
            getWeight1 = new map<SO_Line_Items__c,String>();
            
            // Filtering from Manufacture Section in vf Page which qty not qual to zero
            for(ItemsorderInvWrapper oneItem: soInvRelatedList) {
                if(oneItem.qtyInv != '0') {
                    selectedInvSOItem.add(oneItem);
                    selectedInvSOItemList.add(oneItem.SoItem1);
                    getqtyinv1.put(oneItem.SoItem1,oneItem.qtyInv);
                    getWeight1.put(oneItem.SoItem1,oneItem.weight);
                }
            }
            
            System.debug('selectedInvSOItem: '+selectedInvSOItem);
            System.debug('selectedInvSOItem: '+selectedInvSOItem.size());
            System.debug('*********************************************************');
            System.debug('getqtyinv1 Keys: '+getqtyinv1.keySet());
            System.debug('getqtyinv1 Values: '+getqtyinv1.values());
            System.debug('getWeight1 Values: '+getWeight1.values());
            System.debug('soInvRelatedList: '+soInvRelatedList);
        }
        Catch(Exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.error,e.getMessage()+' Cause: '+e.getCause()+' Line Number: '+e.getLineNumber()+' Trace Message: '+e.getStackTraceString()));  
        }
    }
    
    public PageReference submitPO()
    {
        System.debug('Enter into Submit method.');
        errorStyle = 'text-align:center;';
        submitOrder = 0;
        
        List<SO_Line_Items__c> validateSO = new List<SO_Line_Items__c>();
        List<SO_Line_Items__c> getSOList = new List<SO_Line_Items__c>();
        
        try {
            if(selectedOrderwrapper.size() > 0) {
                for(ItemsorderWrapper oneItem: selectedOrderwrapper) {
                    getSOList.add(oneItem.SoItem);
                }
            }
            else if(soInvRelatedList.size() > 0) {
                for(ItemsorderInvWrapper invSoItem : soInvRelatedList) {
                    getSOList.add(invSoItem.SoItem1);
                }
            }
            
            if(getSOList.size() > 0) {
                for(SO_Line_Items__c soItem : [Select id,Item__c from SO_Line_Items__c where id IN :getSOList AND Item__c='Processing']) {
                    validateSO.add(soItem);
                }
            }
            
            if(validateSO.size() > 0)
            {
                if(selectedOrderwrapper.size() > 0) {
                    if(POFielddisplay.Requested_delivery_date__c == null) {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please select Requested Arrival Date'));
                    }
	                else if (haveMultipleLocation && manufacturerName == 'Liberty' && (POFielddisplay.Liberty_Hub__c == null || POFielddisplay.Liberty_Hub__c == 'none')){
	                	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.error,'Please add location')); 
	                }
                    else if(isShiptoHub == true) {
                        if(Carrier == 'White Glove') {
                            If(POFielddisplay.Suggested_Trucking__c == null && haveMultipleLocation == false) {
                                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please select Suggest Trucking Company'));
                                if(SO_Obj.Delivery_Company__c == null) {
                                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please select Suggest Delivery Company'));
                                }
                            }
                            else If(SO_Obj.Delivery_Company__c == null) {
                                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please select Suggest Delivery Company'));
                            }
                            else {
                                validateBeforeInsertPO();
                            }
                        }
                        else if(Carrier == 'none') {
                            validateBeforeInsertPO();
                        }
                        else {
                            validateBeforeInsertPO();
                        }
                    }
                    else if(isDirectShipping == true) {
                        if(Carrier == 'White Glove') {
                            If(POFielddisplay.Suggested_Trucking__c == null && haveMultipleLocation == false) {
                                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please select Suggest Trucking Company'));
                                if(SO_Obj.Delivery_Company__c == null) {
                                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please select Suggest Delivery Company'));
                                }
                            }
                            else If(SO_Obj.Delivery_Company__c == null) {
                                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please select Suggest Delivery Company'));
                            }
                            else {
                                validateBeforeInsertPO();
                            }
                        }
                        else {
                            validateBeforeInsertPO();
                        }
                    }
                    else If((isShiptoHub == false && isDirectShipping == false) && ((POFielddisplay.Suggested_Trucking__c == null && haveMultipleLocation == false) && (Carrier == 'none' || Carrier == 'White Glove'))) {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please select Suggest Trucking Company'));
                        if(SO_Obj.Delivery_Company__c == null) {
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please select Suggest Delivery Company'));
                        }
                    }
                    else If((isShiptoHub == false && isDirectShipping == false) && (SO_Obj.Delivery_Company__c == null && (Carrier == 'none' || Carrier == 'White Glove'))) {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please select Suggest Delivery Company'));
                    }
                    else
                    {
                        validateBeforeInsertPO();
                    }
                }
                else
                {
                    submitOrder = 1;
                    insertPO();
                    System.debug('Inserting a record:');
                }
            }
            else {                
                Set<Id> POIds = new Set<Id>();
                for(PO_Line_Items__c onePOItems : [Select id,Purchase_Order__c from PO_Line_Items__c where SO_Line_Item__c IN :getSOList])
                {
                    POIds.add(onePOItems.Purchase_Order__c);
                }
                
                ApexPages.Message errorMsg = new ApexPages.Message(ApexPages.Severity.Info,'Duplicate Purchase Order Found.');
                ApexPages.addMessage(errorMsg);
                for(Purchase_Order__c PO : [Select id,name from Purchase_Order__c where id IN :POIds]) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info,'Purchase Order Number: '+PO.name));
                }
            }
        }
        Catch(Exception e)
        {
            pr = null;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.error,e.getMessage()+' Cause: '+e.getCause()+' Line Number: '+e.getLineNumber()+' Trace Message: '+e.getStackTraceString()));  
        }
        return pr;
    }
    
    public void validateBeforeInsertPO() 
    {
        isreqField = false;
        styleVar = Null;
        
        if(orderCommunicationType != 'Website(SSO)')
        {
            System.debug('Inserting PO if it is not Website(SSO)');
            poStatus = 'Draft';
        }
        
        if(POFielddisplay.Requested_delivery_date__c == null) {
            return;
        }
        else if(trackingnumberId == '' && stockAvailable == false)
        {
            stockshowPopup();
        }
        else If(selectedETA == 'none') {
            errorStyle = 'text-align:center;border-color: #d74c3b;border-width: medium;';
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,'Please Select Purchase Order ETA'));
            if(POFielddisplay.Load_Date__c == null) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,'Please Enter a Load Date'));
            }
        }
        else if(selectedETA == 'Not Available') {
            if(POFielddisplay.Load_Date__c != null) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,'ETA is not Available, Please Don\'t Select the Load Date'));
            }
            else {
                submitOrder = 1;
                insertPO();
                System.debug('Inserting a record:');
            }
        }
        else if(POFielddisplay.Load_Date__c == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,'Please Enter a Load Date'));
        }
        else {
            submitOrder = 1;
            insertPO();
            System.debug('Inserting a record:');
        }
    }
    
    public void insertPO()
    {
        String truckingId;
        //Inventory_Management__c setting = Inventory_Management__c.getAll().containsKey('Inventory') ? Inventory_Management__c.getAll().get('Inventory') : new Inventory_Management__c();
        
        Map<String, Inventory_Management__c> settings = new Map<String, Inventory_Management__c>();
		for ( Inventory_Management__c currentSetting_i : Inventory_Management__c.getAll().values()) {
			settings.put(currentSetting_i.Stock_Status__c, currentSetting_i);
		}

        System.debug('submitOrder: '+submitOrder);
        if(submitOrder == 1)
        {
            closePopup();
            System.debug('Getting into Inserting Method.');
            updateitemPurchaseorder();
            
            list<SO_Line_Items__c> So_inv_list = new list<SO_Line_Items__c>();
            map<id, SO_Line_Items__c> updatesoItemsStatus = new map<id, SO_Line_Items__c>();
            
            map<SO_Line_Items__c,string> So_mf_list=new map<SO_Line_Items__c,string>(); 
            
            inventory_Map = new map<string,list<Inventory__c>>();
            Map<String,String> inventoryMap = new Map<String,String>();
            ManufactureId = new set<id>();
            for(ItemsorderWrapper PO:selectedOrderwrapper) {
                inventoryMap.put(PO.inventoryId,PO.qty);
                ManufactureId.add(PO.Manufacture);
            }
            System.debug('inventoryMap: '+inventoryMap);
            System.debug('ManufactureId: '+ManufactureId);
            
            //gets the inventory id from filtered Inventory Section list.
            Map<String,String> inventoryMap1 = new Map<String,String>();
            set<id> ManufactureIdforInv = new set<id>();
            if(!soInvRelatedList.isEmpty()) {
                for(ItemsorderInvWrapper PO:soInvRelatedList) {
                    inventoryMap1.put(PO.inventoryId,PO.Quantity);
                    ManufactureId.add(PO.inventoryWarehouseId);
                }
            }
            
            System.debug('inventoryMap Keys'+inventoryMap.keyset());
            System.debug('inventoryMap Values'+inventoryMap.values());
            System.debug('inventoryMap1 Keys'+inventoryMap1.keyset());
            System.debug('inventoryMap1 Values'+inventoryMap1.values());
            
            System.debug('ManufactureId: '+ManufactureId);
            
            list<Inventory__c> invUpdtlist = new list<Inventory__c>();
            list<Shipment_Line_Item__c> SHLsToUpdate = new list<Shipment_Line_Item__c>();
            map<Id, list<Shipment_Line_Item__c>> SHLsByInventory = new map<Id, list<Shipment_Line_Item__c>>();
            map<Id, list<Shipment_Line_Item__c>> clonedSHLs = new map<Id, list<Shipment_Line_Item__c>>();
            System.debug('I made it to line 1205');
            Savepoint sp = Database.setSavepoint();
            try
            {  
                List<Inventory__c> Inventory_list = [   SELECT RecordType.Name, Description__c,Id,Manage_Stock__c,Minimum_Quantity__c, Delivery_Company__c, Name,Products__c,Quantity__c,RecordTypeId, Shipment_Item__r.Shipment__r.Related_Sales_Order__r.Magento_order_No__c,
                                                                Warehouse_Location__c,Warehouse_Name__c,Warehouse_Name__r.Name, Delivery_Company_Name__c, Shipment_Item__r.Furniture_Condition__c, Shipment_Item__r.Magento_Order_No__c, Shipment_Item__r.Shipment__r.Related_Sales_Order__r.Id
                                                            
                                                        FROM Inventory__c 
                                                        WHERE (Products__c != null AND Warehouse_Name__c != null)  AND Products__c in :productIds
                                                        AND (Quantity__c > 0 AND (Product_Condition__c='Unopened' OR Product_Condition__c='Resellable')) 
                                                        AND (RecordType.Name='Own Inventory' or RecordType.Name='Delivery Company Inventory')];

                list<Shipment_Line_Item__c> shl_list = [SELECT id, Original_SHL__c,Originating_Inventory_SHL__c, Shipment__r.Related_Sales_Order__r.Magento_order_No__c, Shipment__r.Related_Sales_Order__r.Id, Action_Needed_by_Tech__c, Approval_Status__c, At_Local_Delivery_Company_Date__c, Awaiting_Resolution_from_Customer_Date__c, Awaiting_Resolution_from_Hub_Date__c, Box_Info__c, Cancelled_Date__c, Check_amount__c, Check_date__c, Check_number__c, Claim_Amount_Approved__c, Claim_Dollar_Amount__c, Claim_Status__c, Claim_Support_Filled__c, Condition_of_furniture__c, Consignment_ID_Number__c, Consignment_Schedule_Date__c, Consignment_Status__c, Cubed_Ft__c, Damage_Action__c, Days_in_Damage_Action__c, Delivered_No_Issues_Date__c, Delivery_Date_Actual__c, Delivery_Flag__c, Delivery_Flag_Helper__c, Deluxed_No_Issues_Date__c, Deluxed_With_Issues_Date__c, Description__c, Draft_Date__c, Driver_Call_Date__c, Drop_Off_Date_Actual__c, Drop_Off_Date_Expected__c, En_Route_Date__c, En_Route_To_Local_Delivery_Company_Date__c, Follow_up_date__c, Furniture_Condition__c, Hold_As_Stock_Date__c, Image__c, In_Home_Follow_Up_Date__c, Inventory__c, IsReplacement__c, Deluxing_Issue_Quantity__c, Item_s_Popularity__c, Item_condition__c, Item_status_at_consignment__c, Last_Status_Change__c, Location_Of_Furniture__c, Method_of_Transport__c, Need_to_reorder_furniture__c, No_Fit_Date__c, No_Fit_Status__c, Not_At_Home_Date__c, Magento_Order_No__c, Order_Website__c, Overdue_Scheduling__c, Parts_Are_Shipping__c, Parts_Arrival_Date_Actual__c, Parts_Arrival_Expected__c, Parts_Information__c, Parts_Needed_Date__c, Pickup_Drop_off_Cost__c, Pickup_Date_Actual__c, Pickup_Date_Expected__c, PO_Line_Item__c, Price__c, Product_ID__c, Product_Image_URL__c, Product_Name__c, Product_SKU__c, Quantity__c, Reason_for_Disposed_Donated__c, Received_Reimbursement_Amount__c, Received_reimbursement_from_3rd_party__c, Redelivery_Needed_Date__c, Refused_Delivery_Date__c, Related_Sales_Order__c, Renegade_received_check__c, Repair_Amount__c, Repair_Date__c, Repair_Date_Actual__c, Repair_Date_Expected__c, Repair_With_Parts_Date__c, Replacement_Date__c, Replacement_Drop_off_Date_Actual__c, Replacement_Drop_off_Date_Expected__c, Routing_Date__c, Sales_Commission__c, Scheduled_Delivery_Date__c, Scheduled_Delivery_Date_Updated__c, Send_to_Consignment_Date__c, Sent_Tech_Report__c, Set_or_individual_item__c, Shipment__c, Shipment_Item_Status__c, Shipment_Product_Dimensions__c, Shipment_Product_Name__c, Shipment_Product_Quantity__c, Shipment_Product_SKU__c, Shipment_Product_Weight__c, Shipped_Quantity_Actual__c, Shorted_Date__c, SLI_Number_and_Product_Name__c, Status_Of_Tech_Needed__c, Tech_Appointment_Confirmed__c, Tech_Company__c, Tech_Needed_Create_Date__c, Tech_Scheduled_By__c, Tech_Request_Submitted_Date__c, Time_frame_of_Delivery__c, Time_in_current_status__c, Tracking_Number__c, Weight_Pounds__c, Who_is_claim_against__c
                    FROM Shipment_Line_Item__c WHERE Inventory__c in :Inventory_list AND Shipment_Item_Status__c NOT IN :retaggedStatusSet];
                System.debug('SHL list: '+ shl_list);
                
                for (Shipment_Line_Item__c shl : shl_list){
                    if(!SHLsByInventory.containsKey(shl.Inventory__c)){
                        list<Shipment_Line_Item__c> temp_shl = new list<Shipment_Line_Item__c>();
                        SHLsByInventory.put(shl.Inventory__c, temp_shl);
                    }
                    SHLsByInventory.get(shl.Inventory__c).add(shl);
                }
                System.debug('SHLsByInventory:' + SHLsByInventory);
                
                Map<Id, Id> inventoryToSHL = new Map<Id, Id>();
                for(Inventory__c oneInventory:Inventory_list) 
                {
                    if(inventoryMap1.containsKey(oneInventory.id)) 
                    {
                        Double qty_taken = Decimal.valueOf(inventoryMap1.get(oneInventory.id));
                        Decimal qtyInv = oneInventory.Quantity__c - qty_taken;
                        oneInventory.Quantity__c = qtyInv;
                        
                        invUpdtlist.add(oneInventory);
                        ManufactureId.add(oneInventory.Warehouse_Name__c);
                        if (SHLsByInventory.containskey(oneInventory.Id)){
	                        for (Shipment_Line_Item__c shl : SHLsByInventory.get(oneInventory.Id)){
	                            if(settings.containsKey(shl.Shipment_Item_Status__c) /* shl.Shipment_Item_Status__c.equals(setting.Stock_Status__c) */){
	                            	if (shl.Shipped_Quantity_Actual__c > qty_taken){
		                            	shl.Shipped_Quantity_Actual__c = shl.Shipped_Quantity_Actual__c - qty_taken;
		                            	Shipment_Line_Item__c clonedSHL = shl.clone();
		                            	clonedSHL.Shipped_Quantity_Actual__c = qty_taken;
		                            	clonedSHL.Original_POL__c = shl.PO_Line_Item__c;
                                        clonedSHL.Shipment_Item_Status__c = settings.get(shl.Shipment_Item_Status__c).Retagged_Status__c;                               
                                        if(shl.Original_SHL__c != null) {
                                            clonedSHL.Original_SHL__c = shl.Original_SHL__c;
                                        }
                                        else {
                                            clonedSHL.Original_SHL__c = shl.id;
                                        }
                                        clonedSHL.Taken_from_inventory__c = oneInventory.Id;
		                                if(!clonedSHLs.containsKey(oneInventory.Id)){
		                                    clonedSHLs.put(oneInventory.Id, new list<Shipment_Line_Item__c>());
		                                }
		                           		clonedSHLs.get(oneInventory.Id).add(clonedSHL);
	                            	}
	                            	else {
	                            		shl.Shipment_Item_Status__c = 'Retag in process';
	                            	}
                                    inventoryToSHL.put(oneInventory.Id, shl.Id);
		                            SHLsToUpdate.add(shl);
	                        	}
	                        }
	                        System.debug('clonedSHLs:'+clonedSHLs);
                        }
                    }
                                                        
                }

                System.debug('invUpdtlist: '+invUpdtlist);
                System.debug('ManufactureId: '+ManufactureId);

                poList = new List<Purchase_Order__c>();
                if(ManufactureId.size() != 0) {

                    Set<String> fieldSet = new Set<String>();
                      
                    Map<Id ,String> accountIdToEtaGroupMap = new Map<Id ,String>();
                    for(Account account_i : [SELECT Id, ETA_group__c FROM Account WHERE Id IN: ManufactureId]){
                        if(account_i.ETA_group__c != null){
                            accountIdToEtaGroupMap.put(account_i.Id, account_i.ETA_group__c);
                            fieldSet.add(account_i.ETA_group__c);
                        }
                    } 
                    List<Shipping_Zip_Codes__c > shippingZipCodesList = new List<Shipping_Zip_Codes__c>();
                    String zipCode = SO_Obj.Shipping_ZipCode__c;
                    if(zipCode != null && zipCode.length() > 5 ){
                        zipCode = zipCode.substring(0,5);
                    }
                    if(fieldSet.size() > 0 ){
                        String query = 'SELECT Id , ' + String.join(new List<String>(fieldSet), ', ') + ' FROM Shipping_Zip_Codes__c  WHERE Zip_Code__c =\'' + zipCode + '\'' ; 
                        shippingZipCodesList = (List<Shipping_Zip_Codes__c>) DataBase.query(query);
                    } 
                    Map<String, Purchase_Order_Carrier_notes_settings__c> settingMap = Purchase_Order_Carrier_notes_settings__c.getAll();

                    for(Id manfID : ManufactureId) {
                        Purchase_Order__c PO = new Purchase_Order__c();
                        PO.Sales_Order__c = SO_Obj.id;
                        PO.Do_not_notify_manufacturer__c = doNotUpdateManufacturer;
                        PO.Ship_From__c = manfID;
                        PO.Load_Date__c = POFielddisplay.Load_Date__c;
                        if (haveMultipleLocation && manufacturerName == 'Liberty'){
                            if (POFielddisplay.Liberty_Hub__c != null && POFielddisplay.Liberty_Hub__c != 'none'){
                                PO.Liberty_Hub__c = POFielddisplay.Liberty_Hub__c;
                            }
                        }
                        PO.ETA_Is_Given__c = POFielddisplay.ETA_Is_Given__c;
                        PO.Shipping_To_Customer__c = SO_Obj.Customer_shipping_Address__c;
                        PO.Requested_delivery_date__c = POFielddisplay.Requested_delivery_date__c;
                        PO.Carrier_Info__c = POFielddisplay.Carrier_Info__c;
                        if(String.isNotBlank(Carrier) && Carrier != 'none'){//Carrier == 'FedEx'
                            po.Manufacturer_ETA_Group__c = (settingMap.containsKey(Carrier) && settingMap.get(Carrier).Default_ETA_group__c != null) ? settingMap.get(Carrier).Default_ETA_group__c :  '1 Week';
                        }else if(shippingZipCodesList.size() > 0){
                            Shipping_Zip_Codes__c currentShipZipCode = shippingZipCodesList.get(0);
                            system.debug('currentShipZipCode  = ' + currentShipZipCode);
                            system.debug('manfID  = ' + manfID);
                            system.debug('accountIdToEtaGroupMap  = ' + accountIdToEtaGroupMap);
                            if(manfID != null && currentShipZipCode != null && accountIdToEtaGroupMap.containskey(manfID) && currentShipZipCode.get(accountIdToEtaGroupMap.get(manfID)) != null ){
                                po.Manufacturer_ETA_Group__c = String.valueOf(currentShipZipCode.get(accountIdToEtaGroupMap.get(manfID)) );//shippingZipCodesList.get(0).Ashley_ETA_Group__c ; 
                            }
                        }
                        
                        
                        System.debug('isDirectShipping: '+isDirectShipping);
                        System.debug('isShiptoHub: '+isShiptoHub);
                        System.debug('SO_Obj.Customer_shipping_Address__c: '+SO_Obj.Customer_shipping_Address__c);
                        if(isDirectShipping == true) {
                            if(Carrier == 'White Glove') {
                                PO.Suggested_Delivery_Comapny__c = SO_Obj.Delivery_Company__c;
                                PO.Suggested_Trucking__c = POFielddisplay.Suggested_Trucking__c;
                            }
                            else {
                                System.debug('Customer Shipping Address Id if it is Direct Shipping: '+SO_Obj.Customer_shipping_Address__c);
                                PO.Shipping_To_Customer__c = SO_Obj.Customer_shipping_Address__c;
                            }
                        }
                        else if(isShiptoHub == true) {
                            if(Carrier == 'White Glove' || Carrier == 'none') {
                                PO.Suggested_Delivery_Comapny__c = SO_Obj.Delivery_Company__c;
                                if(Carrier == 'White Glove')
                                    PO.Suggested_Trucking__c = POFielddisplay.Suggested_Trucking__c;
                            }
                        }
                        else if(isDirectShipping != true && isShiptoHub != true)
                        {
                            System.debug('Enter into via Trucking if it is not Direct Shipping and Ship to Hub');
                            //PO.Suggested_Trucking__c = truckingId;
                            if(Carrier == 'none' || Carrier == 'White Glove') {
                                PO.Suggested_Delivery_Comapny__c = SO_Obj.Delivery_Company__c;
                                PO.Suggested_Trucking__c = POFielddisplay.Suggested_Trucking__c;
                            }
                            else {
                                PO.Carrier__c = Carrier;
                            }
                        }
                        
                        poList.add(PO);
                    }
                }
                System.debug('poList: '+poList);
                Map<Id, Shipment_Line_Item__c> poLIneToOriginatingSHLMap = new  Map<Id, Shipment_Line_Item__c>();
                if(poList.size() != 0) {
                    System.debug('Inserting Purchased Order.');
                    if(isSetLibertyHub && libertyHub != poList[0].Liberty_Hub__c) {
                        PurchaseOrderTriggerHandler.isChangedOnView = true;
                    }
                    insert poList;
                    System.debug('After Inserting Purchased Order.'+poList);
                    System.debug('selectedOrderwrapper = '+selectedOrderwrapper);
                    System.debug('selectedMFSOItem'+selectedMFSOItem);
                    
                    PLI_list = new list<PO_Line_Items__c>();
                    set<Purchase_Order__c> poupdateList = new set<Purchase_Order__c>();
                    for(ItemsorderWrapper powrapper:selectedOrderwrapper) 
                    {
                        for(Purchase_Order__c PO:poList) 
                        {
                            if(powrapper.Manufacture == PO.Ship_From__c) 
                            {
                                PO.Notes__c = POFielddisplay.Notes__c;
                                PO.Order_Communication_Type__c = orderCommunicationType;
                                
                                If(Carrier != 'none') {
                                    PO.Carrier__c = Carrier;
                                }
                                
                                System.debug('trackingnumberId: '+trackingnumberId);
                                PO.Tracking_Number__c = trackingnumberId;
                                if(selectedETA != 'none') {
                                    PO.Purchase_Order_ETA__c = selectedETA;
                                }
                                PO.RecordTypeId = Schema.SObjectType.Purchase_Order__c.getRecordTypeInfosByDeveloperName().get('Manufacturer_PO').getRecordTypeId();
                                //[SELECT DeveloperName,Id,Name,SobjectType FROM RecordType WHERE SobjectType = 'Purchase_Order__c' And Name = 'Manufacturer PO'].id;
                                
                                PO_Line_Items__c PLI = new PO_Line_Items__c();
                                PLI.SO_Line_Item__c = powrapper.SoItem.id;
                                PLI.Purchase_Order__c = PO.id;
                                PLI.Quantity__c = Decimal.valueOf(powrapper.Quantity);
                                PLI.Weight_Pounds__c = Decimal.valueof(powrapper.weight);
                                PLI.Inventory__c = powrapper.inventoryId;
                                
                                SO_Line_Items__c soLine = new SO_Line_Items__c();
                                
                                soLine.id = powrapper.SoItem.id;
                                System.debug('poStatus: '+poStatus);
                                if(poStatus == 'On Order')
                                {
                                    PO.Status__c = poStatus;
                                    PLI.PO_Item_Status__c = poStatus;
                                    soLine.Item__c = 'Order From Manufacturer';
                                }
                                else if(poStatus == 'Draft') {
                                    PO.Status__c = poStatus;
                                    PLI.PO_Item_Status__c = poStatus;
                                    soLine.Item__c = 'PO-Draft';
                                }
                                
                                updatesoItemsStatus.put(soLine.id, soLine);
                                
                                PLI_list.add(PLI);
                                poupdateList.add(PO);
                            }
                        }
                    }
                    
                    if(!soInvRelatedList.isEmpty()) {
                        for(ItemsorderInvWrapper powrapper:soInvRelatedList) 
                        {
                            for(Purchase_Order__c PO:poList) 
                            {
                                if(powrapper.inventoryWarehouseId == PO.Ship_From__c) 
                                {
                                    PO.ETA_Is_Given__c = false;
                                    PO.Tracking_Number__c = '';
                                    PO.Shipping_To_Customer__c = SO_Obj.Customer_shipping_Address__c;
                                    
                                    PO.Load_Date__c = null;
                                    PO.ETA_Is_Given__c = false;
                                    PO.Suggested_Delivery_Comapny__c = Null;
                                    PO.Suggested_Trucking__c = Null;
                                    PO.RecordTypeId = Schema.SObjectType.Purchase_Order__c.getRecordTypeInfosByDeveloperName().get('Internal_PO').getRecordTypeId();
                                    //[SELECT DeveloperName,Id,Name,SobjectType FROM RecordType WHERE SobjectType = 'Purchase_Order__c' And Name = 'Internal PO'].id;
                                    PO.Suggested_Delivery_Comapny__c = SO_Obj.Delivery_Company__c;
                                    //PO.Suggested_Trucking__c = POFielddisplay.Suggested_Trucking__c;
                                    
                                    PO_Line_Items__c PLI = new PO_Line_Items__c();
                                    PLI.SO_Line_Item__c = powrapper.SoItem1.id;
                                    PLI.Purchase_Order__c = PO.id;
                                    PLI.Quantity__c = Decimal.valueOf(powrapper.qtyInv);
                                    PLI.Weight_Pounds__c = Decimal.valueof(powrapper.weight);
                                    PLI.Inventory__c = powrapper.inventoryId;
                                    PLI.Originating_Inventory_SHL__c = inventoryToSHL.get(powrapper.inventoryId);
                                    PLI_list.add(PLI);
                                    poupdateList.add(PO);
                                    
                                    SO_Line_Items__c soLine = new SO_Line_Items__c();
                                    
                                    soLine.id = powrapper.SoItem1.id;
                                    soLine.Item__c = 'Order From Warehouse';
                                    updatesoItemsStatus.put(soLine.id, soLine);
                                }
                            }
                        }
                    }
                    
                    if(PLI_list.size() != 0) 
                    {
                        System.debug('poupdateList: '+poupdateList);
                        System.debug('PLI_list: '+PLI_list);
                        System.debug('invUpdtlist: '+invUpdtlist);
                        Database.SaveResult[] insertedPLIs = Database.insert(PLI_list);
                        System.debug('InsertedPLIs:' + insertedPLIs);
                        list<Purchase_Order__c> poupdateListtemp = new list<Purchase_Order__c>(poupdateList);
                        update poupdateListtemp;
                        update invUpdtlist;
                        
                        /*if(SO_Obj.Order_Status__c == 'Processing') {
                            Sales_Order__c updateSO = new Sales_Order__c();
                            updateSO.id = SO_Obj.id;
                            updateSO.Order_Status__c = 'Multiple Statuses';
                            
                            update updateSO;
                        }*/
                        
                        // Updating bundle Item Status to avoid Duplication. 
                        if(soMainbundleItems.size() != 0)
                        {
                            for(SO_Line_Items__c oneSoLine : soMainbundleItems)
                            {
                                SO_Line_Items__c soLine = new SO_Line_Items__c();
                                
                                soLine.id = oneSoLine.id;
                                soLine.Item__c = 'Order From Warehouse';                            
                                updatesoItemsStatus.put(soLine.id, soLine);
                            }
                        }
                        if(updatesoItemsStatus.values().size() != 0)
                        {
                            update updatesoItemsStatus.values();
                        }
                        if(insertedPLIs.size()!=0){
                            list<Id> PLI_Id_List = new list<Id>();
                            for(Database.SaveResult sr: insertedPLIs){
                                PLI_Id_list.add(sr.getId());
                            }
                            list<PO_Line_Items__c> PLI_list = [SELECT Id, Inventory__c FROM PO_Line_Items__c WHERE Id in : PLI_Id_list ];
                            for(PO_Line_Items__c PLI_with_shl: PLI_List){
                                if(PLI_with_shl.Inventory__c != null && clonedSHLs.containskey(PLI_with_shl.Inventory__c)){
                                    for(Shipment_Line_Item__c shl2: clonedSHLs.get(PLI_with_shl.Inventory__c)){
                                            shl2.PO_Line_Item__c = PLI_with_shl.Id;
                                        	SHLsToUpdate.add(shl2);
                                    }
                                }
                            }
                         }
                        
                        pr = new pageReference('/'+SO_Obj.id);
                    }
                    else {
                        System.debug('poupdateList: '+poupdateList);
                        System.debug('PLI_list: '+PLI_list);
                        System.debug('invUpdtlist: '+invUpdtlist);
                        Delete poList;
                    }
                }
                
                if(SHLsToUpdate.size()>0){
                    upsert SHLsToUpdate;
                    for(PO_Line_Items__c PLI_with_shl: PLI_List){
                        if(PLI_with_shl.Inventory__c != null && clonedSHLs.containskey(PLI_with_shl.Inventory__c)){
                            PLI_with_shl.Originating_Inventory_SHL__c = clonedSHLs.get(PLI_with_shl.Inventory__c)[0].Id;
                        }
                    }
                    update PLI_List;
                }
                map<id, Sales_Order__c> ret = new map<id, Sales_Order__c>();
        
                map<id, Sales_Order__c> sos = new map<id, Sales_Order__c>([select id, Order_Status__c from Sales_Order__c where id = :SO_Obj.id]);
                list<SO_Line_Items__c> soLines = [select Item__c, Sales_Order__c from SO_Line_Items__c where Manufacturer__c != 'Protection Plan' and (Product_Record_Type__c != 'Bundled' or (Product_Record_Type__c = 'Bundled' and Bundle_Item__c != null)) and Sales_Order__c in :sos.keyset()];
                system.debug('sos = ' + sos);
                for (Sales_Order__c so : sos.values()){
                    boolean first = true;
                    boolean wasUpdated = false;
                    string status = '';
                    for (SO_Line_Items__c po : soLines){
                        if (po.Sales_Order__c != so.id){
                            continue;
                        }
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
                if (ret.values().size() > 0){
                    update ret.values();
                }
            }
            Catch(Exception e)
            {   
                pr = null;
                Database.rollback(sp);
                System.debug('catch: '+e.getMessage()+' '+e.getCause()+' '+e.getLineNumber());
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.error,e.getMessage()+' '+e.getCause()+' '+e.getLineNumber()));  
            }
        }
    }    
    
    public pageReference updateNow() 
    {
        System.debug('trackingnumberId: '+trackingnumberId);
        errorStyle = 'text-align:center;';
        if(trackingnumberId != '')
        {
            System.debug('trackingId Not empty');
            if(orderCommunicationType != 'Email') {
                closePopup();
                stockAvailable = true;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,'Please Suggest ETA.')); 
            }
            else {
                stockAvailable = false;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,'You cannot have Acknowledgement number for Email Communication type.'));  
            }
        }
        else 
        {
            System.debug('Acknowledgement Not empty');
            errorStyle = 'text-align:center;border-color: #d74c3b;border-width: medium;';
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,'Please enter Acknowledgement Number.'));  
        } 
        return pr;
    }
    
    public void addLater()
    {
        poStatus = 'Draft';
        trackingnumberId = '';
        stockAvailable = true;
        closePopup();
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,'Please Suggest ETA.')); 
    }
    
    public pageReference stockAvailable() 
    {
        poStatus = 'On Order';
        stockclosePopup();
        if(trackingnumberId == '')
        {
            showPopup();
        }
        return pr;
    }
    
    public pageReference stocknotAvailable()
    {
        stockAvailable = false;
        submitOrder = 1;
        poStatus = 'Draft';
        stockclosePopup();
        insertPO();
        return pr;
    }
    
    public void closePopup() 
    {        
        displayPopup = false;    
        stockdisplayPopup = false;
    }     
    
    public void showPopup() 
    {        
        displayPopup = true;    
    }
    
    public void stockclosePopup() 
    {        
        stockdisplayPopup = false;    
    }     
    
    public void stockshowPopup() 
    {        
        stockdisplayPopup = true;    
    }
    
    public pageReference redirect() 
    {
        System.debug('soitemId: '+soitemId);
        pageReference pr = new pageReference('/'+soitemId);
        pr.setRedirect(true);
        return pr;
    }
    
    public class SOItemsWrapper
    {
        public Boolean selected {get; set;}
        public SO_Line_Items__c SoItem {get; set;}
        public list<SO_Line_Items__c> bundleList{get; set;}  
        
        public SOItemsWrapper(Boolean Sel,SO_Line_Items__c so,list<SO_Line_Items__c> bundle)
        {
            selected=Sel;
            SoItem=so;
            bundleList=bundle;
        }
    }
    
    private static void addSelectedOrderWrapper(map<string,list<Shipment_Line_Item__c>> ShipmentLineItemsByinventory_Map, map<string,list<Inventory__c>> inventory_Map, string productId, List<ItemsorderWrapper> selectedOrderwrapper, SO_Line_Items__c soLineItem, integer Quantity, string manufacturer){
        list<Inventory__c> inventories = new list<Inventory__c>();
        Inventory__c inventory;//dfdfd
        boolean isButtonVisible = false;
        if (inventory_Map.containskey(productId)){
            for (Inventory__c inv : inventory_Map.get(productId)){
                integer inventoryQty = integer.valueOf(inv.Quantity__c);
                System.debug('Quantity: '+Quantity+'<='+inventoryQty+' :inventoryQty');
                //if(Quantity <= inventoryQty) {
                    isButtonVisible = true;
                    inventories.add(inv);
                //}
            }
        }
        if (inventories.size() == 1){
            inventory = inventories[0];
        }
        System.debug('isButtonVisible: '+isButtonVisible);
        Boolean needToCreateNew = true;
        for(ItemsorderWrapper selected_i : selectedOrderwrapper){
            if(selected_i.SoItem.Id == soLineItem.Id){
                selected_i.Quantity = '' + Quantity;
                needToCreateNew = false;
                selected_i.isLessinventorythanquantity = true;
            }
        }
        if(needToCreateNew){
            selectedOrderwrapper.add(new ItemsorderWrapper(ShipmentLineItemsByinventory_Map, true, soLineItem, manufacturer, inventory, isButtonVisible, inventories, Quantity));
        }
        
        
        System.debug(' Bundled selectedOrderwrapper: '+selectedOrderwrapper);
    }
    
    public class inventoryWrapper
    {
        public Inventory__c inventory {get;set;}
        public boolean allItemsAsStack{get;set;}
        public List<Shipment_Line_Item__c> shipLineItem {get;set;}
        
        public inventoryWrapper (Inventory__c inventory, boolean allItemsAsStack, List<Shipment_Line_Item__c> shipLineItems ){
            this.inventory = inventory;
            this.allItemsAsStack = allItemsAsStack;
            system.debug('22shipLineItem = ' + shipLineItems);
            this.shipLineItem = shipLineItems;
            system.debug('22shipLineItem = ' + shipLineItem);
        }
    }
    
    public class ItemsorderWrapper
    {
        public Boolean selected {get; set;}
        public SO_Line_Items__c SoItem {get; set;}
        public string Quantity {get; set;}
        public string qty {get; set;}
        public String inventoryQty {get;set;}
        public String Manufacture {get;set;}
        public String inventoryId {get;set;}
        //public String inventoryRecordType {get;set;}
        public Inventory__c inventory {get;set;}
        public list<Inventory__c> inventories {get;set;}
        public Boolean showPopInv { get; set; }
        public string weight {get;set;}
        public boolean isLessinventorythanquantity {get;set;}
        public boolean showPopup {get;set;}
        public inventoryWrapper iw {get;set;}
        public list<inventoryWrapper> iwList {get;set;}
        
        //public ItemsorderWrapper(Boolean sel,SO_Line_Items__c So) 
        public ItemsorderWrapper(map<string,list<Shipment_Line_Item__c>> ShipmentLineItemsByinventory_Map, Boolean selected, SO_Line_Items__c SoLineItem, String manf, Inventory__c inventory, Boolean isbuttonVisible, list<Inventory__c> inventories, integer quantityOrdered){
            showPopInv = false;
            this.selected = selected;
            SoItem = soLineItem;
            Manufacture = manf;
            this.inventory = inventory;
            weight = string.valueof(SoItem.Total_Weight_Pounds__c);
            this.inventories = inventories;
            Quantity = string.valueof(quantityOrdered);
            if (inventory != null){
                inventoryQty = qty = string.valueof(inventory.Quantity__c);
                boolean isTheSameStatus = true;
                system.debug('ShipmentLineItemsByinventory_Map.get(inventory.id) = '+ShipmentLineItemsByinventory_Map.get(inventory.id));
                if (ShipmentLineItemsByinventory_Map.containskey(inventory.id)){
	                for(Shipment_Line_Item__c shli : ShipmentLineItemsByinventory_Map.get(inventory.id)){
	                    if( !shipmentItemStatusSet.contains(shli.Shipment_Item_Status__c) && shli.Shipment_Item_Status__c != 'Retagged' && shli.Shipment_Item_Status__c !=  'Retag in process' ){
	                        isTheSameStatus  = false;
	                        //break;
	                    }
	                }
                }
                iw = new inventoryWrapper (inventory, isTheSameStatus,ShipmentLineItemsByinventory_Map.get(inventory.id));
                 system.debug('r**iw**'+iw);
            }
            else if (inventory == null && inventories != null && inventories.size() > 0){
                iwList = new list<inventoryWrapper>();
                for (Inventory__c inv: inventories){
                    boolean isTheSameStatus = true;
	                    if (ShipmentLineItemsByinventory_Map.containskey(inv.id)){
	                    for(Shipment_Line_Item__c shli : ShipmentLineItemsByinventory_Map.get(inv.id)){
	                        if( !shipmentItemStatusSet.contains(shli.Shipment_Item_Status__c) && shli.Shipment_Item_Status__c != 'Retagged' && shli.Shipment_Item_Status__c !=  'Retag in process' ){
	                            isTheSameStatus  = false;
	                        }
	                    }
                    }
                    iwList.add(new inventoryWrapper (inv, isTheSameStatus,ShipmentLineItemsByinventory_Map.get(inv.id)));
                }
            	system.debug('iwList = ' + iwList);
            }
            isLessinventorythanquantity = isbuttonVisible;
            //inventoryRecordType = inventory.recordtype.name;
            showPopup = false;
        }
        
        public ItemsorderWrapper(Boolean sel, SO_Line_Items__c So, String Quant, string qt, String inv, String manf, String invId, String weigh, Boolean isbuttonVisible) 
        {
            showPopInv = false;
            selected = sel;
            SoItem = So; 
            Quantity = Quant;
            qty = qt;
            inventoryQty = inv;
            Manufacture = manf;
            inventoryId = invId;
            weight = weigh;
            isLessinventorythanquantity = isbuttonVisible;
            showPopup = false;
        }
    }
    
    global class ItemsorderInvWrapper
    {
        public SO_Line_Items__c SoItem1 {get; set;}
        public string Quantity {get; set;}
        public string qtyInv {get; set;}
        public String inventoryQty {get;set;}
        public String inventoryId {get;set;}
        public String inventoryWarehouseId {get;set;}
        public String inventoryWarehouseName {get;set;}
        public string weight {get;set;}
        
        public ItemsorderInvWrapper(SO_Line_Items__c So,String qtty,string qt,String inv,String invId,String invWId,String invWname,String weigh) 
        {
            SoItem1 = So; 
            Quantity = qtty;
            qtyInv = qt;
            inventoryQty = inv;
            inventoryId = invId;
            inventoryWarehouseId = invWId;
            inventoryWarehouseName = invWname;
            weight = weigh;
        }
    }
    
    public void init(){
        Map<String, String> stateToHubMap = new Map<String, String>();
        for(Manufacturer_hubs_locations_by_state__mdt setting_i : [ SELECT Id, LibertyHubLocation__c, State__c 
                                                                    FROM Manufacturer_hubs_locations_by_state__mdt]){
            stateToHubMap.put(setting_i.State__c, setting_i.LibertyHubLocation__c);                                                            
        }    
        if(selectedOrderwrapper != null){
            for (itemsOrderwrapper iow : selectedOrderwrapper) {
                    iow.showPopInv = false;
            }
        }
        if(SO_Obj != null && SO_Obj.Manufacturer__c != null && SO_Obj.Manufacturer__r.Name.equalsIgnoreCase('Liberty') && stateToHubMap.containsKey(SO_Obj.Shipping_State__c) ){
            POFielddisplay.Liberty_Hub__c = stateToHubMap.get(SO_Obj.Shipping_State__c);
            libertyHub = POFielddisplay.Liberty_Hub__c ;
            isSetLibertyHub = true;
        }
    }
    public void showPopInvSec() {
        String itemrem = ApexPages.currentPage().getparameters().get('itemrem');
        /*for (ItemsorderWrapper iw : selectedOrderwrapper){
            if (iw.SoItem.id == soItem1Id){
                iw.showPopup = true;
                return;
            }
        }*/
        for (ItemSOrderWrapper iw_i : selectedOrderWrapper) {
            iw_i.showPopInv = iw_i.Soitem.id == itemrem;
        }
        //showPopInv = true;
    }
    
    public static void renderItem(){    
		shipLineItem1 = new Map<ID,List<Shipment_Line_Item__c>>();
        List<Inventory__c> inlist = [SELECT Shipment_Item__r.Furniture_Condition__c,Shipment_Item__r.Shipment__r.Related_Sales_Order__r.Id, Shipment_Item__r.Shipment__r.Related_Sales_Order__r.Magento_order_No__c, 
        Shipment_Item__r.Magento_Order_No__c, RecordType.Name, Description__c,Id,Manage_Stock__c,Minimum_Quantity__c,Delivery_Company__c, 
        Name,Products__c,Quantity__c,RecordTypeId,Warehouse_Location__c,Warehouse_Name__c,Warehouse_Name__r.Name, Delivery_Company_Name__c, 
        (SELECT Shipment_Item_Status__c, Product_SKU__c, Shipment_Product_Name__c, Quantity__c, Product_Name__c,Shipment_Product_SKU__c, Item_condition__c, Furniture_Condition__c, Magento_Order_No__c
         FROM Shipment_Line_Items__r) 
        FROM Inventory__c];
        
        
        
        map<string,list<Inventory__c>> inventory_Map = new map<string,list<Inventory__c>>();
        map<string,list<Shipment_Line_Item__c>>    ShipmentLineItemsByinventory_Map = new map<string,list<Shipment_Line_Item__c>>();
            map<string, string> inventoryIdByShlId = new map<string, string>();
            map<string, string> shipmentIds = new map<string, string>();
            for(Inventory__c inv:inlist) {
            	for (Shipment_Line_Item__c sli : inv.Shipment_Line_Items__r){
            		if (shipmentItemStatusSet.contains(sli.Shipment_Item_Status__c)){
            			shipmentIds.put(sli.Shipment__c, inv.id);
            			inventoryIdByShlId.put(sli.Product_SKU__c, inv.id);
            		}
            	}
            }
	        list<Shipment_Line_Item__c> shipmentLines = [select Shipment__r.Related_Sales_Order__r.Magento_order_No__c, Shipment__r.Related_Sales_Order__r.Id, Furniture_Condition__c, Magento_Order_No__c, Shipment_Item_Status__c, Shipment_Product_Name__c, Product_SKU__c, Quantity__c, Product_Name__c,Shipment_Product_SKU__c, Item_condition__c, Shipment__c from Shipment_Line_Item__c where Shipment__c in :shipmentIds.keyset()];
            for(Inventory__c inv:inlist) {
            	boolean hasProducts = false;
            	for (Shipment_Line_Item__c sli : inv.Shipment_Line_Items__r){
            		if (shipmentItemStatusSet.contains(sli.Shipment_Item_Status__c)){
            			hasProducts = true;
            		}
            	}
            	system.debug('shipmentIds = ' + shipmentIds);
            	if (hasProducts){
	                if (!inventory_Map.containskey(inv.Products__c)){
	                    inventory_Map.put(inv.Products__c, new list<Inventory__c>());
	                }
	                inventory_Map.get(inv.Products__c).add(inv);
	                system.debug('shipmentLines = ' + shipmentLines.size());
	                for (Shipment_Line_Item__c sli : shipmentLines){
	                	if (inv.id == shipmentIds.get(sli.Product_SKU__c)){
		                	if (!ShipmentLineItemsByinventory_Map.containskey(shipmentIds.get(sli.Product_SKU__c))){
		                		ShipmentLineItemsByinventory_Map.put(shipmentIds.get(sli.Product_SKU__c), new list<Shipment_Line_Item__c>());
		                	}
		                	ShipmentLineItemsByinventory_Map.get(shipmentIds.get(sli.Product_SKU__c)).add(sli);
	                	}
	                }
            	}
            }
         
        
        
        for (Inventory__c inv: inlist ){
			shipLineItem1.put(inv.id,ShipmentLineItemsByinventory_Map.get(inv.id));
        }
     
     system.debug('## Method called.................. ' + shipLineItem1);
        shipLineItem123 = shipLineItem1.get(inventoryIdShip);
        system.debug('###Shipment Lineitem :  ' + shipLineItem123);
       // return null;
    }
}