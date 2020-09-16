/**
 * @File Name          : ReplacePurchaseOrderCtrl.cls
 * @Description        : 
 * @Author             : Vladimir Zhutenko
 * @Group              : 
 * @Last Modified By   : Vladimir Zhutenko
 * @Last Modified On   : 4/3/2020, 5:20:09 PM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    4/3/2020   Vladimir Zhutenko     Initial Version
**/
global with sharing class ReplacePurchaseOrderCtrl {

    public map<string,SOItemsWrapper> soRelatedList{get;set;}
    
    public Sales_Order__c SO_Obj {set;get;}
    public list<poLineItem> poItems {set;get;}
    public list<ItemsorderInvWrapper> soInvRelatedList {set;get;}
    Recordtype prodSimple;
    Recordtype prodBundledType;
    
    public set<id> ManufactureId {set;get;}
    
    // The Below Variables is used to calculate updated qyt.
    list<ItemsorderWrapper> selectedMFSOItem; 
    list<SO_Line_Items__c> selectedMFSOItemList;
    map<SO_Line_Items__c,string> getqtyinv;
    map<SO_Line_Items__c,string> getWeight;
    map<SO_Line_Items__c,string> getTruckingId;
    map<SO_Line_Items__c,string> getDeliveryId;
    map<SO_Line_Items__c,Boolean> getUsecarrier;
    map<SO_Line_Items__c,string> getCarrier;
    map<string,Inventory__c> inventory_Map;
    list<Inventory__c> Inventory_list;
    
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
    public integer Quantity {get;set;}
    public string itemQuantity {get;set;}
    public Boolean isBundeled {get;set;}
    public string soItem1Id {get;set;} 
    
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
    Public String manufacturerName {get;set;}
    Public String deliveryName {get;set;}
    Public String truckingNote {get;set;}
    
    public Boolean isRedirect {get;set;}
    public Boolean stockAvailable {get;set;}
    public Boolean doNotUpdateManufacturer {get;set;}
    
    public Purchase_Order__c POFielddisplay {get;set;}
    public List<Purchase_Order__c> poList {get;set;}
    public integer submitOrder {get;set;}
    
    public pageReference pr {get;set;}
    public list<PO_Line_Items__c> PLI_list {get;set;}
    public list<SO_Line_Items__c> soMainbundleItems {get;set;}
    public list<Shipment_Line_Item__c> shipmetlineItems{get;set;}
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
    Map<String, Purchase_Order_Carrier_notes_settings__c> carrierNotesMap = Purchase_Order_Carrier_notes_settings__c.getAll();

    public list<selectoption> getSelectCarrieroption() {
        list<selectoption> selectCarrieroption = new list<selectoption>();
        
        Schema.DescribeFieldResult fieldResult = Purchase_Order__c.Carrier__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        selectCarrieroption.add(new SelectOption('none', '--None--'));
        for( Schema.PicklistEntry f : ple)
        {
            selectCarrieroption.add(new SelectOption(f.getLabel(), f.getValue()));
        }
        return selectCarrieroption;
    }
    
    public list<selectoption> getSelectETAoption() {
        list<selectoption> selectETAoption = new list<selectoption>();
        
        Schema.DescribeFieldResult fieldResult = Sales_Order__c.Order_ETA__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        selectETAoption.add(new SelectOption('none', '--None--'));
        for( Schema.PicklistEntry f : ple)
        {
            selectETAoption.add(new SelectOption(f.getLabel(), f.getValue()));
        }
        return selectETAoption;
    }
    
    public ReplacePurchaseOrderCtrl(ApexPages.StandardController controller)
    {
    	itemQuantity = '1';
    	doNotUpdateManufacturer = false;
        isBunbleExist = false;
        //Carrier = 'FedEx';
        selectedETA = 'none';
        trackingnumberId = '';
        isRedirect = false;
        stockAvailable = false;
        isBundeled = true;
        bundledSOItemQtyList = new list<SO_Line_Items__c>();
        getsoitemQty_Map = new map<String,String>();
        poItems = new list<poLineItem>();
        
        Inventory_list = new list<Inventory__c>();
        SO_Obj = new Sales_Order__c();
        selectedOrder = new List<SO_Line_Items__c>();
        
        POFielddisplay = new Purchase_Order__c();
        
        list<string> soItemIds = new list<string>();
        try {
            System.debug(ApexPages.currentPage().getParameters().get('solids'));
        	list<string> shipmetlineItemIds = ApexPages.currentPage().getParameters().get('solids')!=null?  EncodingUtil.urlDecode(ApexPages.currentPage().getParameters().get('solids'), 'UTF-8').split(',') : new list<string>() ;
        		system.debug('shipmetlineItemIds = ' + shipmetlineItemIds);
        	shipmetlineItems = [select Shipment_Product_SKU__c, PO_Line_Item__r.SO_Line_Item__c, PO_Line_Item__r.SO_Line_Item__r.Sales_Order__c from Shipment_Line_Item__c where id in :shipmetlineItemIds];
        	if (shipmetlineItems.size() == 0) return;
        		system.debug('shipmetlineItems.size() = ' + shipmetlineItems.size());
        	string soId = shipmetlineItems[0].PO_Line_Item__r.SO_Line_Item__r.Sales_Order__c;
        	for (Shipment_Line_Item__c sli : shipmetlineItems){
        		system.debug('sli.PO_Line_Item__r.SO_Line_Item__c = ' + sli.PO_Line_Item__r.SO_Line_Item__c);
        		soItemIds.add(sli.PO_Line_Item__r.SO_Line_Item__c);
        	}
        	system.debug('soItemIds = ' + soItemIds);
            
            SO_Obj = (Sales_Order__c)controller.getrecord();
            
            SO_Obj = [select id,name,Bill_To__c, (SELECT id FROM SO_Line_Items__r),Payment_Status__c,Order_Status__c,Promotion__r.Name,Promotion__c,Customer_shipping_Address__c, Customer_shipping_Address__r.Zip_Postal_Code__c,
                      Total_Quantity_Ordered__c,Order_Date__c,Sales_Representative__r.name,Customer_Name__r.name,Customer_Name__r.Phone,Shipping_Address__c,Order_ETA__c,
                      Customer_Name__c,Email__c,Ship_to__c, Shipping_City__c,Shipping_Handle__c,Mobile__c,Delivery_Companies_Distance__c,Sales_Rep__c, Magento_Order_ID__c,
                      Billing_City__c,Billing_Phone__c,Billing_State__c,Billing_Street__c,Billing_ZipCode__c,Shipping_State__c,Shipping_Street__c,Shipping_ZipCode__c, Magento_order_No__c,
                      Billing_Address__c,Shipping_Phone__c,Shipping_Mobile__c,Order_Type__c,Delivery_Company__c,Delivery_Company__r.Name,(SELECT id FROM Invoice__r) from Sales_Order__c where id=:SO_Obj.id];
            System.debug('SO_Obj: '+SO_Obj); 
            deliveryName = SO_Obj.Delivery_Company__r.Name;
            
            prodBundledType = [SELECT DeveloperName,Id,SobjectType FROM RecordType WHERE SobjectType = 'Products__c' AND DeveloperName = 'Bundled'];
            bundledSOItemQtyList = [SELECT Bundle_Item__c,Image__c, Config_Product__c,CreatedById,CreatedDate,Custom_Price__c,DiscountAmount__c, Unit_Price__c,
                                    Id,IncludeInPricing__c,TaxAmount__c,Tax_Percent__c,UnitPrice__c,Manufacturer__c,Name,OriginalPrice__c,Price__c,ProductSKU__c,Products__c,
                                    Product_Brand__c,Product_Name__c,Product_Url__c,Promotion_Brand__c,Quantity_Invoiced__c, ProductImageUrl__c, FedExable__c, 
                                    Quantity__c,Quantity_Refunded__c,Row_Total__c,Sales_Commission_Hidden__c,Sales_Commission__c,Sales_Order__c,Sub_Total__c
                                    FROM SO_Line_Items__c WHERE id in :soItemIds AND (Bundle_Item__c = Null AND Config_Product__c = Null AND (Products__c != Null AND Products__r.RecordTypeId =:prodBundledType.id))];
            System.debug('bundledSOItemQtyList: '+bundledSOItemQtyList);
            
            if(bundledSOItemQtyList.size() != 0)
            {
                for(SO_Line_Items__c oneBundleQty:bundledSOItemQtyList) {
                    getsoitemQty_Map.put(oneBundleQty.Products__c,String.valueof(oneBundleQty.Quantity__c));
                }
            }
            
            System.debug('getsoitemQty_Map: '+getsoitemQty_Map);
            
            prodSimple = [SELECT DeveloperName,Id,SobjectType FROM RecordType WHERE SobjectType = 'Products__c' AND DeveloperName = 'Simple']; 
            
            Inventory_list = [SELECT Description__c,Id,Manage_Stock__c,Minimum_Quantity__c,Name,Products__c,Quantity__c,RecordTypeId,Warehouse_Location__c,Warehouse_Name__c,Warehouse_Name__r.Name FROM Inventory__c WHERE (Products__c != null AND Warehouse_Name__c != null) AND (Quantity__c > 0 AND (Product_Condition__c='Unopened' OR Product_Condition__c='Resellable')) AND RecordType.Name='Own Inventory'];
            
            inventory_Map = new map<string,Inventory__c>();
            for(Inventory__c inv:Inventory_list) {
                inventory_Map.put(inv.Products__c,inv);
            }
            System.debug('inventory_Map: '+inventory_Map);
            
            soRelatedList = new map<string,SOItemsWrapper>();
            
            list<SO_Line_Items__c> BundelSOitems=[select Parent_Item_Ordered__c, id,Unit_Price__c, Product_Cost__c, FedExable__c,Products__r.Select_Manufacturer__r.name,Products__r.recordtype.name,Products__r.recordtypeid,Custom_Price__c,TaxAmount__c,Sub_Total__c,Price__c,name,Products__c,Products__r.Image__c,Products__r.name,Manufacturer__c,OriginalPrice__c,Product_Brand__c,Tax_Amount__c,
                                                  Products__r.Select_Manufacturer__r.Direct_Shipping__c,Promotion_Brand__c,Quantity__c,DiscountAmount__c,Row_Total__c,Quantity_Invoiced__c,Sales_Order__c,Tax_Percent__c,UnitPrice__c,Bundle_Item__r.Product__c,Bundle_Item__c,Config_Product__c,Product_Name__c,ProductSKU__c,Product_Url__c,Total_Weight_Pounds__c, ProductImageUrl__c,
                                                  Products__r.Select_Manufacturer__r.Ship_To_HUB__c,
                                                  Products__r.Select_Manufacturer__r.Order_Communication_Type__c,Products__r.Select_Manufacturer__r.Website,Item__c, Image__c from SO_Line_Items__c where Bundle_Item__c != null and id in :soItemIds order by Bundle_Item__r.Order__c];
            
            System.debug('BundelSOitems = '+BundelSOitems);
        	selectedOrderwrapper = new List<ItemsorderWrapper>();
            for(SO_Line_Items__c SoiItem: [select ProductImageUrl__c, id, Product_Cost__c, FedExable__c,Products__r.RecordType.Name,Products__r.recordtypeid,TaxAmount__c,Sub_Total__c,Price__c,Unit_Price__c, name,Products__c,Products__r.Image__c,Products__r.name,Manufacturer__c,OriginalPrice__c,Product_Brand__c,Quantity_Refunded__c,Total_Weight_Pounds__c,Products__r.Select_Manufacturer__r.Website,Bundle_Item__r.Product__c,Tax_Amount__c,
                                           Products__r.Select_Manufacturer__r.Direct_Shipping__c,Products__r.Select_Manufacturer__c, Products__r.Select_Manufacturer__r.Ship_To_HUB__c, Products__r.Select_Manufacturer__r.Order_Communication_Type__c,
                                           Promotion_Brand__c,Quantity__c,DiscountAmount__c,Row_Total__c,Custom_Price__c, Quantity_Invoiced__c,Sales_Order__c,Sales_Order__r.Order_Status__c,Tax_Percent__c,UnitPrice__c,Bundle_Item__c,Config_Product__c,Product_Name__c,ProductSKU__c,Product_Url__c,Item__c, Image__c from SO_Line_Items__c where id in :soItemIds ORDER BY ProductSKU__c DESC])
            {
            	if (SoiItem.FedExable__c == 'No' && SoiItem.Manufacturer__c != 'Protection Plan'){
    				Carrier = 'none';
            	}
            	else{
        			Carrier = 'FedEx';
            	}
            	System.debug('SoiItem = ' + SoiItem);
            	inventoryQty = inventory_Map.containskey(SoiItem.Products__c) ? integer.valueOf(inventory_Map.get(SoiItem.Products__c).Quantity__c) : 0;
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
	                    isDirectShipping = SoiItem.Products__r.Select_Manufacturer__r.Direct_Shipping__c;
	                    isShiptoHub = SoiItem.Products__r.Select_Manufacturer__r.Ship_To_HUB__c;
	                    orderCommunicationType = SoiItem.Products__r.Select_Manufacturer__r.Order_Communication_Type__c;
                    }
                    else
                    {  
                        soRelatedList.put(SoiItem.Manufacturer__c+SoiItem.id,new SOItemsWrapper(false,SoiItem,new list<SO_Line_Items__c>()));
	                    isDirectShipping = SoiItem.Products__r.Select_Manufacturer__r.Direct_Shipping__c;
	                    isShiptoHub = SoiItem.Products__r.Select_Manufacturer__r.Ship_To_HUB__c;
	                    orderCommunicationType = SoiItem.Products__r.Select_Manufacturer__r.Order_Communication_Type__c;
                    }
                    
                    system.debug('inventoryQty ' +inventoryQty); 
                    system.debug('SoiItem.Products__r.Select_Manufacturer__c ' +SoiItem.Products__r.Select_Manufacturer__c); 
                    system.debug('SoiItem.Total_Weight_Pounds__c ' +SoiItem.Total_Weight_Pounds__c); 
                    system.debug('isButtonVisible ' +isButtonVisible); 
                    system.debug('selectedOrderwrapper ' +selectedOrderwrapper); 
                    selectedOrderwrapper.add(new ItemsorderWrapper(true,SoiItem,'1','1',String.valueOf(inventoryQty),SoiItem.Products__r.Select_Manufacturer__c,'0',String.valueOf(SoiItem.Total_Weight_Pounds__c),isButtonVisible));   
                }
                else
                {                      
                    isDirectShipping = SoiItem.Products__r.Select_Manufacturer__r.Direct_Shipping__c;
                    isShiptoHub = SoiItem.Products__r.Select_Manufacturer__r.Ship_To_HUB__c;
                    orderCommunicationType = SoiItem.Products__r.Select_Manufacturer__r.Order_Communication_Type__c;          
                    soRelatedList.put(SoiItem.Manufacturer__c+SoiItem.id,new SOItemsWrapper(false,SoiItem,new list<SO_Line_Items__c>()));    
                    selectedOrderwrapper.add(new ItemsorderWrapper(false,SoiItem,'1','1',String.valueOf(inventoryQty),SoiItem.Products__r.Select_Manufacturer__c,'0',String.valueOf(SoiItem.Total_Weight_Pounds__c),isButtonVisible));       
                    //selectedOrderwrapper.add(new ItemsorderWrapper(true,bundle,String.valueOf(Quantity),String.valueOf(Quantity),String.valueOf(inventoryQty),bundle.Products__r.Select_Manufacturer__c,inventory_Map.get(bundle.Config_Product__c).ID,String.valueOf(bundle.Total_Weight_Pounds__c),isButtonVisible));            
                	
                } 
            }
            System.debug('soRelatedList: '+soRelatedList);
            if(soRelatedList.size() == 0) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,'No Sales Order Items are found.'));  
            }
            
            System.debug('manufacturerName: '+manufacturerName);
            System.debug('selectedOrderwrapper: '+selectedOrderwrapper);
            System.debug('commType: '+orderCommunicationType);
            System.debug('soInvRelatedList: '+soInvRelatedList);
        }
        catch(exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.error,e.getMessage()+' '+e.getCause()+' '+e.getLineNumber()));  
        }
        
        onCarrierchange();
        //create list for parts
        
        map<id, SO_Line_Items__c> soItems = new map<id, SO_Line_Items__c>([select id, ProductImageUrl__c, Products__r.sku_and_name_list__c, Products__r.SKU__c, Bundle_Item__r.Product__r.sku_and_name_list__c, 
					Bundle_Item__r.Product__r.SKU__c, Bundle_Item__c, Config_Product__c, Config_Product__r.sku_and_name_list__c, 
					Config_Product__r.SKU__c from SO_Line_Items__c where id in :soItemIds]);
		if (selectedOrderwrapper != null && selectedOrderwrapper.size() > 0){
           	Set<String> soItemIdForEditQunatitySet = new Set<String>();
	        for(ItemsorderWrapper powrapper:selectedOrderwrapper) 
	        {
	            SO_Line_Items__c sl = soItems.get(powrapper.SoItem.id);
				string skuStr = sl.Config_Product__c != null ? sl.Config_Product__r.sku_and_name_list__c : sl.Bundle_Item__c != null ? sl.Bundle_Item__r.Product__r.sku_and_name_list__c : sl.Products__r.sku_and_name_list__c;
				list<productInfo> newSkuName = new list<productInfo>();
				system.debug('skuStr = ' + skuStr);
				if (skuStr != null && skuStr != ''){
					try {
						list<productInfo> productsInfo = (list<productInfo>)json.deserialize(skuStr, list<productInfo>.class);
						for (productInfo pi : productsInfo){
							for (Shipment_Line_Item__c sli : shipmetlineItems){
                                system.debug('sli.Shipment_Product_SKU__c = ' + sli.Shipment_Product_SKU__c);
								if (sli.Shipment_Product_SKU__c == pi.sku){
									poLineItem pli = new poLineItem();
									pli.image = sl.ProductImageUrl__c;
									pli.quantity = powrapper.Quantity;
									pli.sku = pi.sku;
									pli.name = pi.name;
									pli.weight = pi.weight;
                                    pli.displayQuantity = false;
                                    pli.soLineItemId = powrapper.SoItem.id;
                                    if(!soItemIdForEditQunatitySet.contains(powrapper.SoItem.id)){
                                        pli.displayQuantity  = true; 
                                        soItemIdForEditQunatitySet.add(powrapper.SoItem.id);
                                    }
									poItems.add(pli);
								}
							}
							system.debug('shipmetlineItems = ' + shipmetlineItems);
						}
					}
					catch (exception e){
	                	system.debug('e = ' + e.getmessage() + e.getlinenumber());
					}
	            }
	        }
			system.debug('poItems = ' + poItems);
		}
    }
    
    public void onChange()
    {
        continuetoNextpage();
    }
    
    public pageReference submitOnChange()
    {
        Carrier = 'FedEx';
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
        
        pr = new pageReference('/apex/poInitiationpage?id='+SO_Obj.Id);
        pr.setRedirect(false);
        return pr;
    }
    
    public void ondeliveryChange()
    {
        System.debug('Delivery Id: '+SO_Obj.Delivery_Company__c);
        for(Sales_Order__c SO:[Select Delivery_Company__r.Name from Sales_Order__c where Delivery_Company__c=:SO_Obj.Delivery_Company__c])
        {
            deliveryName = SO.Delivery_Company__r.Name;
        }
        System.debug('Delivery Name: '+SO_Obj.Delivery_Company__c);
        System.debug('ManufactureId: '+ManufactureId);
        System.debug('Delevery Id: '+SO_Obj.Delivery_Company__c);
        System.debug('ManufactureId: '+ManufactureId);
        System.debug('totalWeight: '+totalWeight);
        if(Carrier != 'White Glove')
        {
            truckingNote = salesOrderelatedlistController.truckingNote(SO_Obj.Delivery_Company__c, ManufactureId);
            String truckingId = salesOrderelatedlistController.truckingAutoId(SO_Obj.Delivery_Company__c, ManufactureId, Integer.valueOf(totalWeight));
            if(truckingId != Null)
            {
                POFielddisplay.Suggested_Trucking__c = truckingId;
            }                        
        }
        
        if(isShiptoHub == true) {
            if(Carrier == 'White Glove') {
                If(POFielddisplay.Suggested_Trucking__c == null && haveMultipleLocation == false) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,'Please select Suggest Trucking Company'));
                    if(SO_Obj.Delivery_Company__c == null) {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,'Please select Suggest Delivery Company'));
                    }
                }
                else If(SO_Obj.Delivery_Company__c == null) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,'Please select Suggest Delivery Company'));
                }
            }
            else if(Carrier == 'none' && SO_Obj.Delivery_Company__c == null) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,'Please select Suggest Delivery'));
            }
            
        }
        else if(isDirectShipping == true) {
            if(Carrier == 'White Glove') {
                If(POFielddisplay.Suggested_Trucking__c == null && haveMultipleLocation == false) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,'Please select Suggest Trucking Company'));
                    if(SO_Obj.Delivery_Company__c == null) {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,'Please select Suggest Delivery Company'));
                    }
                }
                else If(SO_Obj.Delivery_Company__c == null) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,'Please select Suggest Delivery Company'));
                }
            }
        }
        else If((isShiptoHub == false && isDirectShipping == false) && ((POFielddisplay.Suggested_Trucking__c == null && haveMultipleLocation == false) && (Carrier == 'none' || Carrier == 'White Glove'))) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,'Please select Suggest Trucking Company'));
            if(SO_Obj.Delivery_Company__c == null) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,'Please select Suggest Delivery Company'));
            }
        }
        else If((isShiptoHub == false && isDirectShipping == false) && (SO_Obj.Delivery_Company__c == null && (Carrier == 'none' || Carrier == 'White Glove'))) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,'Please select Suggest Delivery Company'));
        }
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
                    gettruckingId = [Select Id from Account where RecordType.Name = 'Trucking Company' and name Like :('%'+truckingname+'%') Limit 1].id;
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
        if(isShiptoHub == true) {
            if(Carrier == 'White Glove') {
                If(POFielddisplay.Suggested_Trucking__c == null && haveMultipleLocation == false) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,'Please select Suggest Trucking Company'));
                    if(SO_Obj.Delivery_Company__c == null) {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,'Please select Suggest Delivery Company'));
                    }
                }
                else If(SO_Obj.Delivery_Company__c == null) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,'Please select Suggest Delivery Company'));
                }
            }
            else if(Carrier == 'none' && SO_Obj.Delivery_Company__c == null) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,'Please select Suggest Delivery'));
            }
            
        }
        else if(isDirectShipping == true) {
            if(Carrier == 'White Glove') {
                If(POFielddisplay.Suggested_Trucking__c == null && haveMultipleLocation == false) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,'Please select Suggest Trucking Company'));
                    if(SO_Obj.Delivery_Company__c == null) {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,'Please select Suggest Delivery Company'));
                    }
                }
                else If(SO_Obj.Delivery_Company__c == null) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,'Please select Suggest Delivery Company'));
                }
            }
        }
        else If((isShiptoHub == false && isDirectShipping == false) && ((POFielddisplay.Suggested_Trucking__c == null && haveMultipleLocation == false) && (Carrier == 'none' || Carrier == 'White Glove'))) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,'Please select Suggest Trucking Company'));
            if(SO_Obj.Delivery_Company__c == null) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,'Please select Suggest Delivery Company'));
            }
        }
        else If((isShiptoHub == false && isDirectShipping == false) && (SO_Obj.Delivery_Company__c == null && (Carrier == 'none' || Carrier == 'White Glove'))) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,'Please select Suggest Delivery Company'));
        }
    }
    
    public void onCarrierchange()
    {
        System.debug('Carrier: '+Carrier);
        if(Carrier == 'White Glove') {
            POFielddisplay.Suggested_Trucking__c = Null;
            SO_Obj.Delivery_Company__c = Null;
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
    
    public void continuetoNextpage()
    {
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
                                        if (inventory_Map.containsKey(bundle.Config_Product__c)){
                                            inventoryQty = integer.valueOf(inventory_Map.get(bundle.Config_Product__c).Quantity__c);
                                            System.debug('Quantity: '+Quantity+'<='+inventoryQty+' :inventoryQty');
                                            if(Quantity <= inventoryQty) {
                                                isButtonVisible = true;
                                            }
                                            else {
                                                isButtonVisible = false;
                                            }
                                            System.debug('isButtonVisible: '+isButtonVisible);
                                            selectedOrderwrapper.add(new ItemsorderWrapper(true,bundle,String.valueOf(Quantity),String.valueOf(Quantity),String.valueOf(inventoryQty),bundle.Products__r.Select_Manufacturer__c,inventory_Map.get(bundle.Config_Product__c).ID,String.valueOf(bundle.Total_Weight_Pounds__c),isButtonVisible));
                                            System.debug(' Bundled selectedOrderwrapper: '+selectedOrderwrapper);
                                        }
                                        else if(inventory_Map.containsKey(bundle.Bundle_Item__r.Product__c)) {
                                            inventoryQty = integer.valueOf(inventory_Map.get(bundle.Bundle_Item__r.Product__c).Quantity__c);
                                            System.debug('Quantity: '+Quantity+'<='+inventoryQty+' :inventoryQty');
                                            if(Quantity <= inventoryQty) {
                                                isButtonVisible = true;
                                            }
                                            else {
                                                isButtonVisible = false;
                                            }
                                            System.debug('isButtonVisible: '+isButtonVisible);
                                            selectedOrderwrapper.add(new ItemsorderWrapper(true,bundle,String.valueOf(Quantity),String.valueOf(Quantity),String.valueOf(inventoryQty),bundle.Products__r.Select_Manufacturer__c,inventory_Map.get(bundle.Bundle_Item__r.Product__c).ID,String.valueOf(bundle.Total_Weight_Pounds__c),isButtonVisible));
                                            System.debug(' Bundled selectedOrderwrapper: '+selectedOrderwrapper);
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
                                
                                if(inventory_Map.containsKey(wrapOrderObj.SoItem.Config_Product__c)) {
                                    inventoryQty = integer.valueOf(inventory_Map.get(wrapOrderObj.SoItem.Config_Product__c).Quantity__c);
                                    System.debug('Quantity: '+Quantity+'<='+inventoryQty+' :inventoryQty');
                                    if(Quantity <= inventoryQty) {
                                        isButtonVisible = true;
                                    }
                                    else {
                                        isButtonVisible = false;
                                    }
                                    System.debug('isButtonVisible: '+isButtonVisible);
                                    selectedOrderwrapper.add(new ItemsorderWrapper(true,wrapOrderObj.SoItem,String.valueOf(Quantity),String.valueOf(Quantity),String.valueOf(inventoryQty),wrapOrderObj.SoItem.Products__r.Select_Manufacturer__c,inventory_Map.get(wrapOrderObj.SoItem.Config_Product__c).ID,String.valueOf(wrapOrderObj.SoItem.Total_Weight_Pounds__c),isButtonVisible));
                                    System.debug('Config selectedOrderwrapper: '+selectedOrderwrapper);
                                }
                                else if(inventory_Map.containsKey(wrapOrderObj.SoItem.Products__c)) {
                                    inventoryQty = integer.valueOf(inventory_Map.get(wrapOrderObj.SoItem.Products__c).Quantity__c);
                                    System.debug('Quantity: '+Quantity+'<='+inventoryQty+' :inventoryQty');
                                    if(Quantity <= inventoryQty) {
                                        isButtonVisible = true;
                                    }
                                    else {
                                        isButtonVisible = false;
                                    }
                                    System.debug('isButtonVisible: '+isButtonVisible);
                                    selectedOrderwrapper.add(new ItemsorderWrapper(true,wrapOrderObj.SoItem,String.valueOf(Quantity),String.valueOf(Quantity),String.valueOf(inventoryQty),wrapOrderObj.SoItem.Products__r.Select_Manufacturer__c,inventory_Map.get(wrapOrderObj.SoItem.Products__c).Id,String.valueOf(wrapOrderObj.SoItem.Total_Weight_Pounds__c),isButtonVisible));
                                    System.debug('Product selectedOrderwrapper: '+selectedOrderwrapper);
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
                        if(Carrier != 'White Glove')
                        {
                            truckingNote = salesOrderelatedlistController.truckingNote(SO_Obj.Delivery_Company__c, ManufactureId);
                            String truckingId = salesOrderelatedlistController.truckingAutoId(SO_Obj.Delivery_Company__c, ManufactureId, Integer.valueOf(totalWeight));
                            if(truckingId != Null)
                            {
                                POFielddisplay.Suggested_Trucking__c = truckingId;
                            }                        
                        }
                    }
                    else
                    {
                        truckingNote = '';
                    }
                    System.debug('truckingNote: '+truckingNote);
                    if(isDirectShipping != true)
                    {
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
    
    public void sendInventory() 
    {
        isBundeled = true;
        System.debug('soItem1Id: '+soItem1Id);
        
        map<id,id> mfItemap = new map<id,id>();
        integer m=0;
        integer f;  
        try {
            System.debug('selectedOrderwrapper: '+selectedOrderwrapper);
            for(ItemsorderWrapper oneItem: selectedOrderwrapper) 
            {
                if(oneItem.SoItem.id == soItem1Id && (oneItem.inventoryQty != '0'))
                {
                    f=m;
                    System.debug('f: '+f);
                    totalWeight = totalWeight - Decimal.valueOf(oneItem.weight);
                    System.debug('totalWeight: '+totalWeight);
                    
                    System.debug('Delevery Id: '+SO_Obj.Delivery_Company__c);
                    System.debug('ManufactureId: '+ManufactureId);
                    System.debug('totalWeight: '+totalWeight);
                    if(Carrier != 'White Glove')
                    {
                        String truckingId = salesOrderelatedlistController.truckingAutoId(SO_Obj.Delivery_Company__c, ManufactureId, Integer.valueOf(totalWeight));
                        if(truckingId != Null)
                        {
                            POFielddisplay.Suggested_Trucking__c = truckingId;
                        }                        
                    }
                }
                else if(oneItem.SoItem.id != soItem1Id) 
                {
                    mfItemap.put(oneItem.SoItem.id,oneItem.SoItem.id); 
                }
                m++;
            }
            selectedOrderwrapper.remove(f);
            System.debug('mfItemap: '+mfItemap.keySet());
            
            map<id,id> invItemap = new map<id,id>();
            if(soItem1Id != Null) {
                for(ItemsorderInvWrapper oneItem: soInvRelatedList) 
                {
                    invItemap.put(oneItem.SoItem1.id,oneItem.SoItem1.id); 
                }
            }
            for(SO_Line_Items__c soLine1 : [select id,name,Unit_Price__c, Products__c,DiscountAmount__c,Manufacturer__c,Product_Brand__c,Promotion_Brand__c,Quantity__c,Sales_Order__c,Products__r.Select_Manufacturer__c,Bundle_Item__r.Bundle__c,Config_Product__c,Total_Weight_Pounds__c,Products__r.Select_Manufacturer__r.Order_Communication_Type__c,ProductSKU__c,Products__r.recordtype.name, FedExable__c,
                                            Sales_Order__r.Delivery_Company__c,Products__r.Select_Manufacturer__r.Direct_Shipping__c,Bundle_Item__r.Product__c,Bundle_Item__c,Product_Name__c,Product_Url__c, ProductImageUrl__c, Image__c from SO_Line_Items__c where Sales_Order__c =: SO_Obj.id AND (Config_Product__c != Null OR Bundle_Item__c != Null OR (Products__c != Null AND Products__r.RecordTypeId =:prodSimple.id)) ORDER BY Manufacturer__c]) 
            {
                if(getsoitemQty_Map.size() != 0 && getsoitemQty_Map.get(soLine1.Products__c) != Null) {
                    Quantity = integer.valueOf(getsoitemQty_Map.get(soLine1.Products__c)) * integer.valueOf(soLine1.Quantity__c);
                }
                else {
                    Quantity = integer.valueOf(soLine1.Quantity__c);
                }
                if(inventory_Map.containsKey(soLine1.Config_Product__c) && integer.valueOf(inventory_Map.get(soLine1.Config_Product__c).Quantity__c) != 0) {
                    inventoryQty = integer.valueOf(inventory_Map.get(soLine1.Config_Product__c).Quantity__c);
                    if(inventoryQty >= Quantity && (soLine1.id == soItem1Id && !invItemap.containsKey(soLine1.id))) {
                        soInvRelatedList.add(new ItemsorderInvWrapper(soLine1,String.valueOf(Quantity),String.valueOf(Quantity),String.valueOf(inventoryQty),inventory_Map.get(soLine1.Config_Product__c).ID,inventory_Map.get(soLine1.Config_Product__c).Warehouse_Name__c,inventory_Map.get(soLine1.Config_Product__c).Warehouse_Name__r.Name,String.valueOf(soLine1.Total_Weight_Pounds__c)));
                    }
                }
                else if(inventory_Map.containsKey(soLine1.Bundle_Item__r.Product__c) && integer.valueOf(inventory_Map.get(soLine1.Bundle_Item__r.Product__c).Quantity__c) != 0) {
                    inventoryQty = integer.valueOf(inventory_Map.get(soLine1.Bundle_Item__r.Product__c).Quantity__c);
                    if(inventoryQty >= Quantity && (soLine1.id == soItem1Id && !invItemap.containsKey(soLine1.id))) {
                        soInvRelatedList.add(new ItemsorderInvWrapper(soLine1,String.valueOf(Quantity),String.valueOf(Quantity),String.valueOf(inventoryQty),inventory_Map.get(soLine1.Bundle_Item__r.Product__c).ID,inventory_Map.get(soLine1.Bundle_Item__r.Product__c).Warehouse_Name__c,inventory_Map.get(soLine1.Bundle_Item__r.Product__c).Warehouse_Name__r.Name,String.valueOf(soLine1.Total_Weight_Pounds__c)));
                    }
                }
                else if(inventory_Map.containsKey(soLine1.Products__c) && integer.valueOf(inventory_Map.get(soLine1.Products__c).Quantity__c) != 0) {
                    inventoryQty = integer.valueOf(inventory_Map.get(soLine1.Products__c).Quantity__c);
                    if(inventoryQty >= Quantity && (soLine1.id == soItem1Id && !invItemap.containsKey(soLine1.id))) {
                        soInvRelatedList.add(new ItemsorderInvWrapper(soLine1,String.valueOf(Quantity),String.valueOf(Quantity),String.valueOf(inventoryQty),inventory_Map.get(soLine1.Products__c).Id,inventory_Map.get(soLine1.Products__c).Warehouse_Name__c,inventory_Map.get(soLine1.Products__c).Warehouse_Name__r.Name,String.valueOf(soLine1.Total_Weight_Pounds__c)));
                    }
                }
            }
            System.debug('selectedOrderwrapper: '+selectedOrderwrapper);
            System.debug('soInvRelatedList: '+soInvRelatedList);
        }
        catch(exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.error,e.getMessage()+' '+e.getCause()+' '+e.getLineNumber()));  
        }
    } 
    
    public void sendManufacturer() 
    {
        isBundeled = true;
        System.debug('soItem1Id: '+soItem1Id);
        
        try {
            map<id,id> invItemap = new map<id,id>();
            integer i=0;
            integer k;
            for(ItemsorderInvWrapper oneItem: soInvRelatedList) 
            {
                if(oneItem.SoItem1.id == soItem1Id)
                {
                    k=i;
                    System.debug('k: '+k);
                    totalWeight = totalWeight + Decimal.valueOf(oneItem.weight);
                    System.debug('totalWeight: '+totalWeight);
                    System.debug('Delevery Id: '+SO_Obj.Delivery_Company__c);
                    System.debug('ManufactureId: '+ManufactureId);
                    System.debug('totalWeight: '+totalWeight);
                    if(Carrier != 'White Glove')
                    {
                        String truckingId = salesOrderelatedlistController.truckingAutoId(SO_Obj.Delivery_Company__c, ManufactureId, Integer.valueOf(totalWeight));
                        if(truckingId != Null)
                        {
                            POFielddisplay.Suggested_Trucking__c = truckingId;
                        }                        
                    }
                }
                else if(oneItem.SoItem1.id != soItem1Id) 
                {
                    invItemap.put(oneItem.SoItem1.id,oneItem.SoItem1.id); 
                }
                i++;
            }
            soInvRelatedList.remove(k);
            System.debug('invItemap: '+invItemap.keySet());
            System.debug('soInvRelatedList: '+soInvRelatedList);
            
            map<id,id> mfItemap = new map<id,id>();
            integer m=0;
            integer f; 
            
            for(ItemsorderWrapper oneItem: selectedOrderwrapper) 
            {
                if(oneItem.SoItem.id == soItem1Id)
                {
                    f=m;
                    System.debug('f: '+f);
                }
                else if(oneItem.SoItem.id != soItem1Id) 
                {
                    mfItemap.put(oneItem.SoItem.id,oneItem.SoItem.id); 
                }
                m++;
            }
            
            for(SO_Line_Items__c soLine : [select id, FedExable__c, Unit_Price__c, name,Products__c,DiscountAmount__c,Manufacturer__c,Product_Brand__c,Promotion_Brand__c,Quantity__c,Sales_Order__c,Products__r.Select_Manufacturer__c,Bundle_Item__r.Bundle__c,Config_Product__c,Total_Weight_Pounds__c,Products__r.Select_Manufacturer__r.Order_Communication_Type__c,ProductSKU__c,Products__r.recordtype.name,
                                           Sales_Order__r.Delivery_Company__c,Products__r.Select_Manufacturer__r.Direct_Shipping__c,Bundle_Item__r.Product__c,Bundle_Item__c,Product_Name__c,Product_Url__c, ProductImageUrl__c, Image__c from SO_Line_Items__c where Sales_Order__c =: SO_Obj.id AND (Config_Product__c != Null OR Bundle_Item__c != Null OR (Products__c != Null AND Products__r.RecordTypeId =:prodSimple.id)) ORDER BY Manufacturer__c]) 
            {
                if(getsoitemQty_Map.size() != 0 && getsoitemQty_Map.get(soLine.Products__c) != Null) {
                    Quantity = integer.valueOf(getsoitemQty_Map.get(soLine.Products__c)) * integer.valueOf(soLine.Quantity__c);
                    System.debug('If Quantity: '+Quantity);
                }
                else {
                    Quantity = integer.valueOf(soLine.Quantity__c);
                    System.debug('Else Quantity: '+Quantity);
                }
                System.debug('Quantity: '+Quantity);
                if(inventory_Map.containsKey(soLine.Config_Product__c)) 
                {
                    System.debug('*************Config***********');
                    inventoryQty = integer.valueOf(inventory_Map.get(soLine.Config_Product__c).Quantity__c);
                    if(inventoryQty >= Quantity && (soLine.id == soItem1Id && !invItemap.containsKey(soLine.id))) {
                        if(Quantity <= inventoryQty)
                        {
                            isButtonVisible = true;
                        }
                        else {
                            isButtonVisible = false;
                        }
                        selectedOrderwrapper.add(new ItemsorderWrapper(true,soLine,String.valueOf(Quantity),String.valueOf(Quantity),String.valueOf(inventoryQty),soLine.Products__r.Select_Manufacturer__c,inventory_Map.get(soLine.Config_Product__c).ID,String.valueOf(soLine.Total_Weight_Pounds__c),isButtonVisible));
                    }
                }
                else if(inventory_Map.containsKey(soLine.Bundle_Item__r.Product__c)) 
                {
                    System.debug('*************Bundle***********');
                    inventoryQty = integer.valueOf(inventory_Map.get(soLine.Bundle_Item__r.Product__c).Quantity__c);
                    if(Quantity <= inventoryQty)
                    {
                        isButtonVisible = true;
                    }
                    else {
                        isButtonVisible = false;
                    }
                    if(inventoryQty >= Quantity && (soLine.id == soItem1Id && !invItemap.containsKey(soLine.id))) {
                        selectedOrderwrapper.add(new ItemsorderWrapper(true,soLine,String.valueOf(Quantity),String.valueOf(Quantity),String.valueOf(inventoryQty),soLine.Products__r.Select_Manufacturer__c,inventory_Map.get(soLine.Bundle_Item__r.Product__c).ID,String.valueOf(soLine.Total_Weight_Pounds__c),isButtonVisible));
                    }
                }
                else if(inventory_Map.containsKey(soLine.Products__c)) 
                {
                    System.debug('*************Products***********');
                    inventoryQty = integer.valueOf(inventory_Map.get(soLine.Products__c).Quantity__c);
                    if(Quantity <= inventoryQty)
                    {
                        isButtonVisible = true;
                    }
                    else {
                        isButtonVisible = false;
                    }
                    if(inventoryQty >= Quantity && (soLine.id == soItem1Id && !invItemap.containsKey(soLine.id))) {
                        selectedOrderwrapper.add(new ItemsorderWrapper(true,soLine,String.valueOf(Quantity),String.valueOf(Quantity),String.valueOf(inventoryQty),soLine.Products__r.Select_Manufacturer__c,inventory_Map.get(soLine.Products__c).ID,String.valueOf(soLine.Total_Weight_Pounds__c),isButtonVisible));
                    }
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
                    if(soLine.id == soItem1Id) {
                        selectedOrderwrapper.add(new ItemsorderWrapper(true,soLine,String.valueOf(Quantity),String.valueOf(Quantity),'0',soLine.Products__r.Select_Manufacturer__c,Null,String.valueOf(soLine.Total_Weight_Pounds__c),isButtonVisible));
                    }
                    System.debug('Else soRelatedList: '+soRelatedList);
                } 
            }
            System.debug('selectedOrderwrapper: '+selectedOrderwrapper);            
        }
        catch(exception e)
        {
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
        System.debug(selectedOrderwrapper);
        System.debug(poItems);
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
                if(selectedOrderwrapper.size() > 0) {
			        if(POFielddisplay.Requested_delivery_date__c == null) {
			        	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please select Requested Arrival Date'));
			        }
                    if(isShiptoHub == true) {
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
        Catch(Exception e)
        {
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
        System.debug('submitOrder: '+submitOrder);
        if(submitOrder == 1)
        {
            closePopup();
            System.debug('Getting into Inserting Method.');
            updateitemPurchaseorder();
            
            list<SO_Line_Items__c> So_inv_list = new list<SO_Line_Items__c>();
            list<SO_Line_Items__c> updatesoItemsStatus = new list<SO_Line_Items__c>();
            
            map<SO_Line_Items__c,string> So_mf_list=new map<SO_Line_Items__c,string>(); 
            
            inventory_Map = new map<string,Inventory__c>();
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
            if(soInvRelatedList != null && !soInvRelatedList.isEmpty()) {
                for(ItemsorderInvWrapper PO:soInvRelatedList) {
                    inventoryMap1.put(PO.inventoryId,PO.qtyInv);
                    ManufactureId.add(PO.inventoryWarehouseId);
                }
            }
            
            System.debug('inventoryMap Keys'+inventoryMap.keyset());
            System.debug('inventoryMap Values'+inventoryMap.values());
            System.debug('inventoryMap1 Keys'+inventoryMap1.keyset());
            System.debug('inventoryMap1 Values'+inventoryMap1.values());
            
            System.debug('ManufactureId: '+ManufactureId);
            
            list<Inventory__c> invUpdtlist = new list<Inventory__c>();
            try
            {  
                for(Inventory__c oneInventory:Inventory_list) 
                {
                    if(inventoryMap1.containsKey(oneInventory.id)) 
                    {
                        Decimal qtyInv = oneInventory.Quantity__c - Decimal.valueOf(inventoryMap1.get(oneInventory.id));
                        System.debug('Quantity Update in Inventory: '+qtyInv);
                        oneInventory.Quantity__c = qtyInv;
                        
                        invUpdtlist.add(oneInventory);
                        ManufactureId.add(oneInventory.Warehouse_Name__c);
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
                        PO.ETA_Is_Given__c = POFielddisplay.ETA_Is_Given__c;
                        PO.Shipping_To_Customer__c = SO_Obj.Customer_shipping_Address__c;
                        PO.Requested_delivery_date__c = POFielddisplay.Requested_delivery_date__c;
                        PO.Replacement_PO__c = TRUE;
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
                
                if(poList.size() != 0) {
                    System.debug('Inserting Purchased Order.');
                    insert poList;
                    System.debug('After Inserting Purchased Order.'+poList);
                    System.debug('selectedOrderwrapper = '+selectedOrderwrapper);
                    System.debug('selectedMFSOItem'+selectedMFSOItem);
                    
                    PLI_list = new list<PO_Line_Items__c>();
                    set<Purchase_Order__c> poupdateList = new set<Purchase_Order__c>();
                    
                    list<string> soItemIds = new list<string>();
                    for(ItemsorderWrapper powrapper:selectedOrderwrapper) 
                    {
                        for(Purchase_Order__c PO:poList) 
                        {
                        	soItemIds.add(powrapper.SoItem.id);
                        }
                    }
                    map<id, SO_Line_Items__c> soItems = new map<id, SO_Line_Items__c>([select id, Products__r.sku_and_name_list__c, Products__r.SKU__c, Bundle_Item__r.Product__r.sku_and_name_list__c, 
								Bundle_Item__r.Product__r.SKU__c, Bundle_Item__c, Config_Product__c, Config_Product__r.sku_and_name_list__c, 
								Config_Product__r.SKU__c from SO_Line_Items__c where id in :soItemIds]);
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
                                PO.RecordTypeId = [SELECT DeveloperName,Id,Name,SobjectType FROM RecordType WHERE SobjectType = 'Purchase_Order__c' And Name = 'Manufacturer PO'].id;
                                
                                PO_Line_Items__c PLI = new PO_Line_Items__c();
                                PLI.SO_Line_Item__c = powrapper.SoItem.id;
                                PLI.Purchase_Order__c = PO.id;
                                System.debug('itemQuantity: '+itemQuantity);
                                System.debug('selectedOrderwrapper[0]: '+selectedOrderwrapper[0]);
                                System.debug('selectedOrderwrapper[0].Quantity: '+selectedOrderwrapper[0].Quantity);
                                PLI.Quantity__c = Decimal.valueOf(powrapper.Quantity);
                                PLI.Weight_Pounds__c = Decimal.valueof(powrapper.weight);
                                SO_Line_Items__c sl = soItems.get(powrapper.SoItem.id);
                                System.debug(sl.Config_Product__c);
                                System.debug( sl.Config_Product__c != null ?sl.Config_Product__r.sku_and_name_list__c: 'empty');
                                System.debug(sl.Bundle_Item__c);
                                System.debug(sl.id);
                                 System.debug(sl.Products__r.sku_and_name_list__c);
                                System.debug(sl.Bundle_Item__c!= null ?sl.Bundle_Item__r.Product__r.sku_and_name_list__c:'empty');
								string skuStr = sl.Config_Product__c != null ? sl.Config_Product__r.sku_and_name_list__c : sl.Bundle_Item__c != null ? sl.Bundle_Item__r.Product__r.sku_and_name_list__c : sl.Products__r.sku_and_name_list__c;
								list<productInfo> newSkuName = new list<productInfo>();
								system.debug('skuStr = ' + skuStr);
								if (skuStr != null && skuStr != ''){
									try {
										list<productInfo> productsInfo = (list<productInfo>)json.deserialize(skuStr, list<productInfo>.class);
										for (productInfo pi : productsInfo){
											boolean found = false;
											for (poLineItem poi : poItems){
									system.debug('poi.quantity = ' + poi.quantity);
												if (poi.sku == pi.sku && poi.displayQuantity && poi.soLineItemId == powrapper.SoItem.id){
													PLI.Quantity__c = Decimal.valueOf(poi.quantity);
												}
											}
											for (Shipment_Line_Item__c sli : shipmetlineItems){
									system.debug('sli.Shipment_Product_SKU__c = ' + sli.Shipment_Product_SKU__c);
									system.debug('pi.sku = ' + pi.sku);
												if (sli.Shipment_Product_SKU__c == pi.sku){
													newSkuName.add(new productInfo(pi.sku, pi.name, pi.weight, pi.dimensions, pi.cost));
													found = true;
													PLI.SKU_list__c = PLI.SKU_list__c != '' && PLI.SKU_list__c != null ? PLI.SKU_list__c + ', ' + pi.sku : pi.sku;
												}
											}
											if (!found){
												PLI.Partial_product_ordered__c = true;
											}
										}
                                        System.debug(newSkuName);
                                		PLI.SKU_name_and_list__c = json.serialize(newSkuName);
									}
									catch (exception e){
			                        	system.debug('e = ' + e.getmessage() + e.getlinenumber());
									}
								}
                                
                                
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
                                
                                updatesoItemsStatus.add(soLine);
                                
                                PLI_list.add(PLI);
                                poupdateList.add(PO);
                            }
                        }
                    }
                    
                    if(soInvRelatedList != null && !soInvRelatedList.isEmpty()) {
                    	
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
                                    PO.RecordTypeId = [SELECT DeveloperName,Id,Name,SobjectType FROM RecordType WHERE SobjectType = 'Purchase_Order__c' And Name = 'Internal PO'].id;
                                    
                                    PO_Line_Items__c PLI = new PO_Line_Items__c();
                                    PLI.SO_Line_Item__c = powrapper.SoItem1.id;
                                    PLI.Purchase_Order__c = PO.id;
                                    //if (poItems.size() == 0){
                                    	PLI.Quantity__c = Decimal.valueOf(powrapper.qtyInv);
                                    /*}
                                    else{
                                		PLI.Quantity__c = Decimal.valueOf(soInvRelatedList[0].Quantity);
                                    }*/
                                    PLI.Weight_Pounds__c = Decimal.valueof(powrapper.weight);
	                                SO_Line_Items__c sl = soItems.get(powrapper.SoItem1.id);
									string skuStr = sl.Config_Product__c != null ? sl.Config_Product__r.sku_and_name_list__c : sl.Bundle_Item__c != null ? sl.Bundle_Item__r.Product__r.sku_and_name_list__c : sl.Products__r.sku_and_name_list__c;
									list<productInfo> newSkuName = new list<productInfo>();
									system.debug('skuStr = ' + skuStr);
									if (skuStr != null && skuStr != ''){
										try {
											list<productInfo> productsInfo = (list<productInfo>)json.deserialize(skuStr, list<productInfo>.class);
											for (productInfo pi : productsInfo){
												for (poLineItem poi : poItems){
									system.debug('1poi.quantity = ' + poi.quantity);
													if (poi.sku == pi.sku){
														PLI.Quantity__c = Decimal.valueOf(poi.quantity);
													}
												}
												boolean found = false;
												for (Shipment_Line_Item__c sli : shipmetlineItems){
									system.debug('sli.Shipment_Product_SKU__c = ' + sli.Shipment_Product_SKU__c);
									system.debug('pi.sku = ' + pi.sku);
													if (sli.Shipment_Product_SKU__c == pi.sku){
														newSkuName.add(pi);
														found = true;
														PLI.SKU_list__c = PLI.SKU_list__c != '' && PLI.SKU_list__c != null ? PLI.SKU_list__c + ', ' + pi.sku : pi.sku;
													}
												}
												if (!found){
													PLI.Partial_product_ordered__c = true;
												}
											}
                                            System.debug(newSkuName);
	                                		PLI.SKU_name_and_list__c = json.serialize(newSkuName);
										}
										catch (exception e){
				                        	system.debug('e = ' + e.getmessage() + e.getlinenumber());
										}
									}
                                    
                                    PLI_list.add(PLI);
                                    poupdateList.add(PO);
                                    
                                    SO_Line_Items__c soLine = new SO_Line_Items__c();
                                    
                                    soLine.id = powrapper.SoItem1.id;
                                    soLine.Item__c = 'Order From Warehouse';
                                    updatesoItemsStatus.add(soLine);
                                }
                            }
                        }
                    }
                    
                    if(PLI_list.size() != 0) 
                    {
                        System.debug('poupdateList: '+poupdateList);
                        System.debug('PLI_list: '+PLI_list);
                        System.debug('invUpdtlist: '+invUpdtlist);
                        insert PLI_list;
                        list<Purchase_Order__c> poupdateListtemp = new list<Purchase_Order__c>(poupdateList);
                        update poupdateListtemp;
                        update invUpdtlist;
                        
                        /*if(SO_Obj.Order_Status__c == 'Processing') {
                            Sales_Order__c updateSO = new Sales_Order__c();
                            updateSO.id = SO_Obj.id;
                            updateSO.Order_Status__c = 'Multiple Statuses';
                            
                            update updateSO;
                        }*/
                        
                        
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
                        
                        
                        // Updating bundle Item Status to avoid Duplication. 
                        if(soMainbundleItems != null && soMainbundleItems.size() != 0)
                        {
                            for(SO_Line_Items__c oneSoLine : soMainbundleItems)
                            {
                                SO_Line_Items__c soLine = new SO_Line_Items__c();
                                
                                soLine.id = oneSoLine.id;
                                soLine.Item__c = 'Order From Warehouse';
                                updatesoItemsStatus.add(soLine);
                            }
                        }
                        if(updatesoItemsStatus.size() != 0)
                        {
                            update updatesoItemsStatus;
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
            }
            Catch(Exception e)
            {
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
    
    public class ItemsorderWrapper
    {
        public Boolean selected {get; set;}
        public SO_Line_Items__c SoItem {get; set;}
        public string Quantity {get; set;}
        public string qty {get; set;}
        public String inventoryQty {get;set;}
        public String Manufacture {get;set;}
        public String inventoryId {get;set;}
        public string weight {get;set;}
        public boolean isLessinventorythanquantity {get;set;}
        
        //public ItemsorderWrapper(Boolean sel,SO_Line_Items__c So) 
        public ItemsorderWrapper(Boolean sel,SO_Line_Items__c So,String Quant,string qt,String inv,String manf,String invId,String weigh,Boolean isbuttonVisible) 
        {
            selected = sel;
            SoItem = So; 
            Quantity = Quant;
            qty = qt;
            inventoryQty = inv;
            Manufacture = manf;
            inventoryId = invId;
            weight = weigh;
            isLessinventorythanquantity = isbuttonVisible;
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
	
    global class productInfo{
    	public string sku {get; set;}
    	public string name {get; set;}
    	public string weight {get; set;}
        public string dimensions {get; set;}
        public Decimal cost {get; set;}
    	
    	public productInfo(string sku, string name, string weight, string dimensions, Decimal cost){
    		this.sku = sku;
    		this.name = name;
    		this.weight = weight;
			this.dimensions = dimensions;
			this.cost = cost;
    	}
    }
    
	global class poLineItem {
		public string image {get; set;}
		public string quantity {get; set;}
		public string sku {get; set;}
		public string name {get; set;}
		public string weight {get; set;}
        public Boolean displayQuantity {get; set;}
        public String soLineItemId {get; set;}
	}
}