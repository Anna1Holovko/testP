@isTest
private class ReplacePartCtrlTest {

	
	public static Google_API__c googleAPI;
    public static MagentoAuth__c magentoAuth;
    public static MagentoTokens__c magentoToken;
    
    @testSetup static void setUp() {
        magentoAuth = new MagentoAuth__c(Name='MagentoOAuth', AccessTokenURL__c='http://stage01.colemanfurniture.com/oauth/token',
                                        AuthorizationURL__c='http://stage01.colemanfurniture.com/admin/oauth_authorize',
                                        CallbackURL__c='https://c.cs41.visual.force.com/apex/CompleteAuth', password__c='rfgstage0987',
                                        ClientKey__c='ulzh3hgcx5pcmfkvbcd7x369bxfqjzmp',ClientSecret__c='p1khnuudmoowwiq1avhx8cjj9g573j70',
                                        RequestTokenURL__c='http://stage01.colemanfurniture.com/oauth/initiate/',
                                        RestEndpoint__c='http://stage01.colemanfurniture.com/api/rest',username__c='stage');
        insert magentoAuth;
        
        magentoToken = new MagentoTokens__c(Name='OAuth', isAccess__c=false,owner__c='00555000000IFiGAAW',
                                           secret__c='vrz4dsnqxlf7uj3cq9qs89meferbyf5g', token__c='mbxbk9y7ylsx9kh4lay7y1fvmqursrcb');
        
        insert magentoToken;
        
        googleAPI = new Google_API__c(Name='Google API',Key__c='AIzaSyCAmP-yM5hc67O4stT-VyzMRmDTaVYfXzQ');
        insert googleAPI;
    }
    
    static testMethod void testWithoutSalesOrderItems()
    {
        Account customerAccount = TestUtil.createCustomerAccount(); 
        Account deliveryAccount = TestUtil.createDeliveryAccount(); 
        Account manufactureAccount = TestUtil.createManufacturerAccount(true,false, 'Email');
        
        Sales_Order__c salesOrder = TestUtil.createsalesOrder(customerAccount.id, deliveryAccount.id, Null);
        
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(salesOrder);   
        
        ReplacePartCtrl controller = new ReplacePartCtrl(sc);
        
        controller.getSelectCarrieroption();
        controller.getSelectETAoption();
        
        Test.StopTest();
        //system.assertEquals(0, controller.soRelatedList.size());
    }
    static testMethod void onChangeWithBundleItem()
    {
        Account customerAccount = TestUtil.createCustomerAccount(); 
        Account deliveryAccount = TestUtil.createDeliveryAccount();
        Account manufactureAccount = TestUtil.createManufacturerAccount(true,false, 'Email');
        Account warehouseAccount = TestUtil.createWarehouseAccount();
        Account truckingAccount = TestUtil.createTruckingAccount();
        truckingAccount.Name = 'Watkins';
        update truckingAccount;
        
        Products__c configPro = TestUtil.createConfigProduct();
        Products__c simplePro = TestUtil.createSimpleProduct(configPro.id,manufactureAccount.id);
        Products__c bundlePro = TestUtil.createBundleProduct();
        bundlePro.Select_Manufacturer__c = manufactureAccount.id;
        update bundlePro;
        
        Inventory__c bundleinventoryItem = TestUtil.createInventory(bundlePro.id,5,warehouseAccount.id);
        
        Bundle_Item__c bundleItem = TestUtil.createBundleItemProduct(configPro.id, bundlePro.id);
        
        Sales_Order__c salesOrder = TestUtil.createsalesOrder(customerAccount.id, deliveryAccount.id, Null);
        
        SO_Line_Items__c bundleSol = TestUtil.createsalesOrderLineItem(salesOrder.id, bundlePro.id, null,null,3);
        
        SO_Line_Items__c bundledSol = TestUtil.createsalesOrderLineItem(salesOrder.id, bundlePro.id, null,bundleItem.id,2);
        SO_Line_Items__c bundleSolItems = [select id,Products__r.RecordType.Name,Products__r.recordtypeid,TaxAmount__c,Sub_Total__c,Price__c,name,
                                           Products__c,Products__r.Image__c,Products__r.name,Manufacturer__c,OriginalPrice__c,Product_Brand__c, FedExable__c,
                                           Quantity_Refunded__c,Total_Weight_Pounds__c,Products__r.Select_Manufacturer__r.Order_Communication_Type__c,
                                           Products__r.Select_Manufacturer__r.Website,Bundle_Item__r.Product__c,Products__r.Select_Manufacturer__r.Ship_To_HUB__c,
                                           Products__r.Select_Manufacturer__r.Direct_Shipping__c,Products__r.Select_Manufacturer__c,Promotion_Brand__c,Quantity__c,
                                           DiscountAmount__c,Row_Total__c,Custom_Price__c,Quantity_Invoiced__c,Sales_Order__c,Sales_Order__r.Order_Status__c,Tax_Percent__c,
                                           UnitPrice__c,Bundle_Item__c,Config_Product__c,Product_Name__c,ProductSKU__c,Product_Url__c,Item__c from SO_Line_Items__c where id=:bundledSol.id];
       
	    Purchase_Order__c po = TestUtil.createpurchaseorder(salesOrder.id,'Manufacturer PO');

		PO_Line_Items__c POl = TestUtil.createpoitem(po.id, bundleSol.id);
		
		Shipment__c ship = TestUtil.createshipment(po.id, salesOrder.id,'Ship Via Delivery Company');

        Shipment_Line_Item__c shipitem = TestUtil.createshipmentItem(ship.id, POl.id);
		Test.startTest();
        PageReference pref = Page.SalesOrderLineItemsRelatedList;
        test.setCurrentPage(pref);
        ApexPages.currentPage().getParameters().put('solids',shipitem.id);
        ApexPages.StandardController sc = new ApexPages.StandardController(salesOrder);   
        
        list<SO_Line_Items__c> SOList = new list<SO_Line_Items__c>();
        SOList.add(bundleSolItems);
        
        map<string,ReplacePartCtrl.SOItemsWrapper> soRelatedMap = new map<string,ReplacePartCtrl.SOItemsWrapper>();
        soRelatedMap.put(manufactureAccount.Name+bundledSol.id,new ReplacePartCtrl.SOItemsWrapper(true,bundleSolItems,SOList));
        System.debug('soRelatedMap: '+soRelatedMap);
        
        ReplacePartCtrl controller = new ReplacePartCtrl(sc);
        controller.soRelatedList = soRelatedMap;
        controller.onChange();
        test.stopTest();
        System.assertEquals(true, soRelatedMap.get(manufactureAccount.Name+bundledSol.id).selected);
    }
    static testMethod void onChangeWithoutBundle()
    {
        Account customerAccount = TestUtil.createCustomerAccount(); 
        Account deliveryAccount = TestUtil.createDeliveryAccount();
        Account manufactureAccount = TestUtil.createManufacturerAccount(true,false, 'Email');
        Account warehouseAccount = TestUtil.createWarehouseAccount();
        Account truckingAccount = TestUtil.createTruckingAccount();
        truckingAccount.Name = 'Watkins';
        update truckingAccount;
        
        Trucking_Rule__c trucking = TestUtil.createTruckingRules(manufactureAccount.Id,deliveryAccount.Id);
        trucking.Truking_Selection_Note__c = 'Watkins';
        update trucking;
        
        Products__c configPro = TestUtil.createConfigProduct();
        Products__c simplePro = TestUtil.createSimpleProduct(configPro.id,manufactureAccount.id);
        
        Products__c protectionPro = TestUtil.createprotectionProduct();
        
        Inventory__c inventoryItem = TestUtil.createInventory(simplePro.id,5,warehouseAccount.id);
        Inventory__c configinventoryItem = TestUtil.createInventory(configPro.id,5,warehouseAccount.id);
        
        Sales_Order__c salesOrder = TestUtil.createsalesOrder(customerAccount.id, deliveryAccount.id, Null);
        
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(salesOrder.id, simplePro.id, null,null,2);
        SO_Line_Items__c simpleSolItems = [select id,Products__r.RecordType.Name,Products__r.recordtypeid,TaxAmount__c,Sub_Total__c,Price__c,name,
                                           Products__c,Products__r.Image__c,Products__r.name,Manufacturer__c,OriginalPrice__c,Product_Brand__c, FedExable__c, 
                                           Quantity_Refunded__c,Total_Weight_Pounds__c,Products__r.Select_Manufacturer__r.Order_Communication_Type__c,
                                           Products__r.Select_Manufacturer__r.Website,Bundle_Item__r.Product__c,Products__r.Select_Manufacturer__r.Ship_To_HUB__c,
                                           Products__r.Select_Manufacturer__r.Direct_Shipping__c,Products__r.Select_Manufacturer__c,Promotion_Brand__c,Quantity__c,
                                           DiscountAmount__c,Row_Total__c,Custom_Price__c,Quantity_Invoiced__c,Sales_Order__c,Sales_Order__r.Order_Status__c,Tax_Percent__c,
                                           UnitPrice__c,Bundle_Item__c,Config_Product__c,Product_Name__c,ProductSKU__c,Product_Url__c,Item__c from SO_Line_Items__c where id=:Sol.id];
        
        SO_Line_Items__c configSol = TestUtil.createsalesOrderLineItem(salesOrder.id, simplePro.id, configPro.id,null,2);
        SO_Line_Items__c configSolItems = [select id,Products__r.RecordType.Name,Products__r.recordtypeid,TaxAmount__c,Sub_Total__c,Price__c,name,
                                           Products__c,Products__r.Image__c,Products__r.name,Manufacturer__c,OriginalPrice__c,Product_Brand__c, FedExable__c,
                                           Quantity_Refunded__c,Total_Weight_Pounds__c,Products__r.Select_Manufacturer__r.Order_Communication_Type__c,
                                           Products__r.Select_Manufacturer__r.Website,Bundle_Item__r.Product__c,Products__r.Select_Manufacturer__r.Ship_To_HUB__c,
                                           Products__r.Select_Manufacturer__r.Direct_Shipping__c,Products__r.Select_Manufacturer__c,Promotion_Brand__c,Quantity__c,
                                           DiscountAmount__c,Row_Total__c,Custom_Price__c,Quantity_Invoiced__c,Sales_Order__c,Sales_Order__r.Order_Status__c,Tax_Percent__c,
                                           UnitPrice__c,Bundle_Item__c,Config_Product__c,Product_Name__c,ProductSKU__c,Product_Url__c,Item__c from SO_Line_Items__c where id=:configSol.id];
        
        SO_Line_Items__c protectionSol = TestUtil.createsalesOrderLineItem(salesOrder.id, protectionPro.id, null,null,1);
        
		Purchase_Order__c po = TestUtil.createpurchaseorder(salesOrder.id,'Manufacturer PO');

		PO_Line_Items__c POl = TestUtil.createpoitem(po.id, Sol.id);
		
		Shipment__c ship = TestUtil.createshipment(po.id, salesOrder.id,'Ship Via Delivery Company');

        Shipment_Line_Item__c shipitem = TestUtil.createshipmentItem(ship.id, POl.id);
		
		Test.startTest();
        PageReference pref = Page.SalesOrderLineItemsRelatedList;
        test.setCurrentPage(pref);
        ApexPages.currentPage().getParameters().put('solids',shipitem.id);
        ApexPages.StandardController sc = new ApexPages.StandardController(salesOrder);   
        
        map<string,ReplacePartCtrl.SOItemsWrapper> soRelatedMap = new map<string,ReplacePartCtrl.SOItemsWrapper>();
        soRelatedMap.put(manufactureAccount.Name+Sol.id,new ReplacePartCtrl.SOItemsWrapper(true,simpleSolItems,null));
        soRelatedMap.put(manufactureAccount.Name+configSol.id,new ReplacePartCtrl.SOItemsWrapper(true,configSolItems,null));
        System.debug('soRelatedMap: '+soRelatedMap);
        
        ReplacePartCtrl controller = new ReplacePartCtrl(sc);
        controller.soRelatedList = soRelatedMap;
        controller.onChange();
        controller.submitOnChange();
        test.stopTest();
        System.assertEquals(true, soRelatedMap.get(manufactureAccount.Name+configSol.id).selected);
    }
    static testMethod void onChangeWithoutInventory()
    {
        Account customerAccount = TestUtil.createCustomerAccount(); 
        Account deliveryAccount = TestUtil.createDeliveryAccount();
        Account manufactureAccount = TestUtil.createManufacturerAccount(true,false, 'Email');
        manufactureAccount.Ship_To_HUB__c = true;
        manufactureAccount.Direct_Shipping__c = false;
        update manufactureAccount;
        
        Products__c configPro = TestUtil.createConfigProduct();
        Products__c simplePro = TestUtil.createSimpleProduct(configPro.id,manufactureAccount.id);
        
        Sales_Order__c salesOrder = TestUtil.createsalesOrder(customerAccount.id, null, Null);
        
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(salesOrder.id, simplePro.id, null,null,2);
        SO_Line_Items__c simpleSolItems = [select id,Products__r.RecordType.Name,Products__r.recordtypeid,TaxAmount__c,Sub_Total__c,Price__c,name,
                                           Products__c,Products__r.Image__c,Products__r.name,Manufacturer__c,OriginalPrice__c,Product_Brand__c, FedExable__c,
                                           Quantity_Refunded__c,Total_Weight_Pounds__c,Products__r.Select_Manufacturer__r.Order_Communication_Type__c,
                                           Products__r.Select_Manufacturer__r.Website,Bundle_Item__r.Product__c,Products__r.Select_Manufacturer__r.Ship_To_HUB__c,
                                           Products__r.Select_Manufacturer__r.Direct_Shipping__c,Products__r.Select_Manufacturer__c,Promotion_Brand__c,Quantity__c,
                                           DiscountAmount__c,Row_Total__c,Custom_Price__c,Quantity_Invoiced__c,Sales_Order__c,Sales_Order__r.Order_Status__c,Tax_Percent__c,
                                           UnitPrice__c,Bundle_Item__c,Config_Product__c,Product_Name__c,ProductSKU__c,Product_Url__c,Item__c from SO_Line_Items__c where id=:Sol.id];
        
        SO_Line_Items__c configSol = TestUtil.createsalesOrderLineItem(salesOrder.id, simplePro.id, configPro.id,null,2);
        SO_Line_Items__c configSolItems = [select id,Products__r.RecordType.Name,Products__r.recordtypeid,TaxAmount__c,Sub_Total__c,Price__c,name,
                                           Products__c,Products__r.Image__c,Products__r.name,Manufacturer__c,OriginalPrice__c,Product_Brand__c, FedExable__c,
                                           Quantity_Refunded__c,Total_Weight_Pounds__c,Products__r.Select_Manufacturer__r.Order_Communication_Type__c,
                                           Products__r.Select_Manufacturer__r.Website,Bundle_Item__r.Product__c,Products__r.Select_Manufacturer__r.Ship_To_HUB__c,
                                           Products__r.Select_Manufacturer__r.Direct_Shipping__c,Products__r.Select_Manufacturer__c,Promotion_Brand__c,Quantity__c,
                                           DiscountAmount__c,Row_Total__c,Custom_Price__c,Quantity_Invoiced__c,Sales_Order__c,Sales_Order__r.Order_Status__c,Tax_Percent__c,
                                           UnitPrice__c,Bundle_Item__c,Config_Product__c,Product_Name__c,ProductSKU__c,Product_Url__c,Item__c from SO_Line_Items__c where id=:configSol.id];
        
		SO_Line_Items__c protectionSol = TestUtil.createsalesOrderLineItem(salesOrder.id, configPro.id, null,null,1);
        
		Purchase_Order__c po = TestUtil.createpurchaseorder(salesOrder.id,'Manufacturer PO');

		PO_Line_Items__c POl = TestUtil.createpoitem(po.id, Sol.id);
		
		Shipment__c ship = TestUtil.createshipment(po.id, salesOrder.id,'Ship Via Delivery Company');

        Shipment_Line_Item__c shipitem = TestUtil.createshipmentItem(ship.id, POl.id);
		Test.startTest();
        PageReference pref = Page.SalesOrderLineItemsRelatedList;
        test.setCurrentPage(pref);
        ApexPages.currentPage().getParameters().put('solids',shipitem.id);
        ApexPages.StandardController sc = new ApexPages.StandardController(salesOrder);   
        
        map<string,ReplacePartCtrl.SOItemsWrapper> soRelatedMap = new map<string,ReplacePartCtrl.SOItemsWrapper>();
        soRelatedMap.put(manufactureAccount.Name+Sol.id,new ReplacePartCtrl.SOItemsWrapper(true,simpleSolItems,null));
        soRelatedMap.put(manufactureAccount.Name+configSol.id,new ReplacePartCtrl.SOItemsWrapper(true,configSolItems,null));
        System.debug('soRelatedMap: '+soRelatedMap);
        
        ReplacePartCtrl controller = new ReplacePartCtrl(sc);
        controller.soRelatedList = soRelatedMap;
        controller.onChange();
        controller.submitOnChange();
        test.stopTest();
        System.assertEquals(true, soRelatedMap.get(manufactureAccount.Name+configSol.id).selected);
    }
    static testMethod void submitPOWithCarrerAsNone()
    {
        Account customerAccount = TestUtil.createCustomerAccount(); 
        Account deliveryAccount = TestUtil.createDeliveryAccount();
        Account manufactureAccount = TestUtil.createManufacturerAccount(true,false, 'Email');
        Account warehouseAccount = TestUtil.createWarehouseAccount();
        Account truckingAccount = TestUtil.createTruckingAccount();
        truckingAccount.Name = 'Watkins';
        update truckingAccount;
        
        Trucking_Rule__c trucking = TestUtil.createTruckingRules(manufactureAccount.Id,deliveryAccount.Id);
        trucking.Truking_Selection_Note__c = 'Watkins';
        update trucking;
        
        Products__c configPro = TestUtil.createConfigProduct();
        Products__c simplePro = TestUtil.createSimpleProduct(configPro.id,manufactureAccount.id);
        Products__c bundlePro = TestUtil.createBundleProduct();
        bundlePro.Select_Manufacturer__c = manufactureAccount.id;
        update bundlePro;
        
        Products__c protectionPro = TestUtil.createprotectionProduct();
        
        Inventory__c inventoryItem = TestUtil.createInventory(simplePro.id,5,warehouseAccount.id);
        Inventory__c configinventoryItem = TestUtil.createInventory(configPro.id,5,warehouseAccount.id);
        Inventory__c bundleinventoryItem = TestUtil.createInventory(bundlePro.id,5,warehouseAccount.id);
        
        Bundle_Item__c bundleItem = TestUtil.createBundleItemProduct(configPro.id, bundlePro.id);
        
        Sales_Order__c salesOrder = TestUtil.createsalesOrder(customerAccount.id, deliveryAccount.id, Null);
        
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(salesOrder.id, simplePro.id, null,null,2);
        SO_Line_Items__c simpleSolItems = [select id,Products__r.RecordType.Name,Products__r.recordtypeid,TaxAmount__c,Sub_Total__c,Price__c,name,
                                           Products__c,Products__r.Image__c,Products__r.name,Manufacturer__c,OriginalPrice__c,Product_Brand__c, FedExable__c,
                                           Quantity_Refunded__c,Total_Weight_Pounds__c,Products__r.Select_Manufacturer__r.Order_Communication_Type__c,
                                           Products__r.Select_Manufacturer__r.Website,Bundle_Item__r.Product__c,Products__r.Select_Manufacturer__r.Ship_To_HUB__c,
                                           Products__r.Select_Manufacturer__r.Direct_Shipping__c,Products__r.Select_Manufacturer__c,Promotion_Brand__c,Quantity__c,
                                           DiscountAmount__c,Row_Total__c,Custom_Price__c,Quantity_Invoiced__c,Sales_Order__c,Sales_Order__r.Order_Status__c,Tax_Percent__c,
                                           UnitPrice__c,Bundle_Item__c,Config_Product__c,Product_Name__c,ProductSKU__c,Product_Url__c,Item__c from SO_Line_Items__c where id=:Sol.id];
        
        SO_Line_Items__c configSol = TestUtil.createsalesOrderLineItem(salesOrder.id, simplePro.id, configPro.id,null,2);
        SO_Line_Items__c configSolItems = [select id,Products__r.RecordType.Name,Products__r.recordtypeid,TaxAmount__c,Sub_Total__c,Price__c,name,
                                           Products__c,Products__r.Image__c,Products__r.name,Manufacturer__c,OriginalPrice__c,Product_Brand__c, FedExable__c,
                                           Quantity_Refunded__c,Total_Weight_Pounds__c,Products__r.Select_Manufacturer__r.Order_Communication_Type__c,
                                           Products__r.Select_Manufacturer__r.Website,Bundle_Item__r.Product__c,Products__r.Select_Manufacturer__r.Ship_To_HUB__c,
                                           Products__r.Select_Manufacturer__r.Direct_Shipping__c,Products__r.Select_Manufacturer__c,Promotion_Brand__c,Quantity__c,
                                           DiscountAmount__c,Row_Total__c,Custom_Price__c,Quantity_Invoiced__c,Sales_Order__c,Sales_Order__r.Order_Status__c,Tax_Percent__c,
                                           UnitPrice__c,Bundle_Item__c,Config_Product__c,Product_Name__c,ProductSKU__c,Product_Url__c,Item__c from SO_Line_Items__c where id=:configSol.id];
        SO_Line_Items__c bundleSol = TestUtil.createsalesOrderLineItem(salesOrder.id, bundlePro.id, null,null,3);
        
        SO_Line_Items__c bundledSol = TestUtil.createsalesOrderLineItem(salesOrder.id, bundlePro.id, null,bundleItem.id,2);
        SO_Line_Items__c bundleSolItems = [select id,Products__r.RecordType.Name,Products__r.recordtypeid,TaxAmount__c,Sub_Total__c,Price__c,name,
                                           Products__c,Products__r.Image__c,Products__r.name,Manufacturer__c,OriginalPrice__c,Product_Brand__c, FedExable__c,
                                           Quantity_Refunded__c,Total_Weight_Pounds__c,Products__r.Select_Manufacturer__r.Order_Communication_Type__c,
                                           Products__r.Select_Manufacturer__r.Website,Bundle_Item__r.Product__c,Products__r.Select_Manufacturer__r.Ship_To_HUB__c,
                                           Products__r.Select_Manufacturer__r.Direct_Shipping__c,Products__r.Select_Manufacturer__c,Promotion_Brand__c,Quantity__c,
                                           DiscountAmount__c,Row_Total__c,Custom_Price__c,Quantity_Invoiced__c,Sales_Order__c,Sales_Order__r.Order_Status__c,Tax_Percent__c,
                                           UnitPrice__c,Bundle_Item__c,Config_Product__c,Product_Name__c,ProductSKU__c,Product_Url__c,Item__c from SO_Line_Items__c where id=:bundledSol.id];
        
        SO_Line_Items__c protectionSol = TestUtil.createsalesOrderLineItem(salesOrder.id, protectionPro.id, null,null,1);
        
        Purchase_Order__c purchaseOrder = TestUtil.createpurchaseorder(salesOrder.id, 'Manufacturer PO');
        purchaseOrder.Load_Date__c = System.today();
        purchaseOrder.ETA_Is_Given__c = true;
        update purchaseOrder;

		//SO_Line_Items__c protectionSol = TestUtil.createsalesOrderLineItem(salesOrder.id, configPro.id, null,null,1);
        
		Purchase_Order__c po = TestUtil.createpurchaseorder(salesOrder.id,'Manufacturer PO');

		PO_Line_Items__c POl = TestUtil.createpoitem(po.id, Sol.id);
		
		Shipment__c ship = TestUtil.createshipment(po.id, salesOrder.id,'Ship Via Delivery Company');
        Shipment_Line_Item__c shipitem = TestUtil.createshipmentItem(ship.id, POl.id);
        Test.startTest();
        PageReference pref = Page.SalesOrderLineItemsRelatedList;
        test.setCurrentPage(pref);
        PageReference pref1 = Page.poInitiationpage;
        test.setCurrentPage(pref1);
        ApexPages.currentPage().getParameters().put('solids',shipitem.id);
        ApexPages.StandardController sc = new ApexPages.StandardController(salesOrder);   
        list<SO_Line_Items__c> SOBundleList = new list<SO_Line_Items__c>();
        SOBundleList.add(bundleSolItems);
        map<string,ReplacePartCtrl.SOItemsWrapper> soRelatedMap = new map<string,ReplacePartCtrl.SOItemsWrapper>();
        soRelatedMap.put(manufactureAccount.Name+Sol.id,new ReplacePartCtrl.SOItemsWrapper(true,simpleSolItems,null));
        soRelatedMap.put(manufactureAccount.Name+configSol.id,new ReplacePartCtrl.SOItemsWrapper(true,configSolItems,null));
        soRelatedMap.put(manufactureAccount.Name+bundleSolItems.id,new ReplacePartCtrl.SOItemsWrapper(true,bundleSolItems,SOBundleList));
        System.debug('soRelatedMap: '+soRelatedMap);
        
        ReplacePartCtrl controller = new ReplacePartCtrl(sc);
        controller.soRelatedList = soRelatedMap;
        controller.onChange();
        controller.submitOnChange();
        
        controller.trackingnumberId = '12345';
        controller.selectedETA = '1-2 Weeks';
        controller.POFielddisplay = purchaseOrder;
        
        controller.updateNow();
        controller.addLater();
        controller.submitPO();
        
        salesOrder.Order_Status__c = 'Processing';
        update salesOrder;
        
        controller.SO_Obj = salesOrder;
        controller.ondeliveryChange();
        controller.onTruckingChange();
        controller.stocknotAvailable();
        controller.onETAchange();
        test.stopTest();
        System.assertEquals('none', controller.Carrier);
    }
    static testMethod void submitPOWithCarrerAsWhiteGloveAndDirectShipping()
    {
        Account customerAccount = TestUtil.createCustomerAccount(); 
        Account deliveryAccount = TestUtil.createDeliveryAccount();
        Account manufactureAccount = TestUtil.createManufacturerAccount(true,false, 'Email');
        Account warehouseAccount = TestUtil.createWarehouseAccount();
        Account truckingAccount = TestUtil.createTruckingAccount();
        truckingAccount.Name = 'Watkins';
        update truckingAccount;
        
        Trucking_Rule__c trucking = TestUtil.createTruckingRules(manufactureAccount.Id,deliveryAccount.Id);
        trucking.Truking_Selection_Note__c = 'Watkins';
        update trucking;
        
        Products__c configPro = TestUtil.createConfigProduct();
        Products__c simplePro = TestUtil.createSimpleProduct(configPro.id,manufactureAccount.id);
        Products__c bundlePro = TestUtil.createBundleProduct();
        bundlePro.Select_Manufacturer__c = manufactureAccount.id;
        update bundlePro;
        
        Products__c protectionPro = TestUtil.createprotectionProduct();
        
        Inventory__c inventoryItem = TestUtil.createInventory(simplePro.id,5,warehouseAccount.id);
        Inventory__c configinventoryItem = TestUtil.createInventory(configPro.id,5,warehouseAccount.id);
        Inventory__c bundleinventoryItem = TestUtil.createInventory(bundlePro.id,5,warehouseAccount.id);
        
        Bundle_Item__c bundleItem = TestUtil.createBundleItemProduct(configPro.id, bundlePro.id);
        
        Sales_Order__c salesOrder = TestUtil.createsalesOrder(customerAccount.id, deliveryAccount.id, Null);
        
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(salesOrder.id, simplePro.id, null,null,2);
        SO_Line_Items__c simpleSolItems = [select id,Products__r.RecordType.Name,Products__r.recordtypeid,TaxAmount__c,Sub_Total__c,Price__c,name,
                                           Products__c,Products__r.Image__c,Products__r.name,Manufacturer__c,OriginalPrice__c,Product_Brand__c, FedExable__c,
                                           Quantity_Refunded__c,Total_Weight_Pounds__c,Products__r.Select_Manufacturer__r.Order_Communication_Type__c,
                                           Products__r.Select_Manufacturer__r.Website,Bundle_Item__r.Product__c,Products__r.Select_Manufacturer__r.Ship_To_HUB__c,
                                           Products__r.Select_Manufacturer__r.Direct_Shipping__c,Products__r.Select_Manufacturer__c,Promotion_Brand__c,Quantity__c,
                                           DiscountAmount__c,Row_Total__c,Custom_Price__c,Quantity_Invoiced__c,Sales_Order__c,Sales_Order__r.Order_Status__c,Tax_Percent__c,
                                           UnitPrice__c,Bundle_Item__c,Config_Product__c,Product_Name__c,ProductSKU__c,Product_Url__c,Item__c from SO_Line_Items__c where id=:Sol.id];
        
        SO_Line_Items__c configSol = TestUtil.createsalesOrderLineItem(salesOrder.id, simplePro.id, configPro.id,null,2);
        SO_Line_Items__c configSolItems = [select id,Products__r.RecordType.Name,Products__r.recordtypeid,TaxAmount__c,Sub_Total__c,Price__c,name,
                                           Products__c,Products__r.Image__c,Products__r.name,Manufacturer__c,OriginalPrice__c,Product_Brand__c, FedExable__c,
                                           Quantity_Refunded__c,Total_Weight_Pounds__c,Products__r.Select_Manufacturer__r.Order_Communication_Type__c,
                                           Products__r.Select_Manufacturer__r.Website,Bundle_Item__r.Product__c,Products__r.Select_Manufacturer__r.Ship_To_HUB__c,
                                           Products__r.Select_Manufacturer__r.Direct_Shipping__c,Products__r.Select_Manufacturer__c,Promotion_Brand__c,Quantity__c,
                                           DiscountAmount__c,Row_Total__c,Custom_Price__c,Quantity_Invoiced__c,Sales_Order__c,Sales_Order__r.Order_Status__c,Tax_Percent__c,
                                           UnitPrice__c,Bundle_Item__c,Config_Product__c,Product_Name__c,ProductSKU__c,Product_Url__c,Item__c from SO_Line_Items__c where id=:configSol.id];
        SO_Line_Items__c bundleSol = TestUtil.createsalesOrderLineItem(salesOrder.id, bundlePro.id, null,null,3);
        
        SO_Line_Items__c bundledSol = TestUtil.createsalesOrderLineItem(salesOrder.id, bundlePro.id, null,bundleItem.id,2);
        SO_Line_Items__c bundleSolItems = [select id,Products__r.RecordType.Name,Products__r.recordtypeid,TaxAmount__c,Sub_Total__c,Price__c,name,
                                           Products__c,Products__r.Image__c,Products__r.name,Manufacturer__c,OriginalPrice__c,Product_Brand__c, FedExable__c,
                                           Quantity_Refunded__c,Total_Weight_Pounds__c,Products__r.Select_Manufacturer__r.Order_Communication_Type__c,
                                           Products__r.Select_Manufacturer__r.Website,Bundle_Item__r.Product__c,Products__r.Select_Manufacturer__r.Ship_To_HUB__c,
                                           Products__r.Select_Manufacturer__r.Direct_Shipping__c,Products__r.Select_Manufacturer__c,Promotion_Brand__c,Quantity__c,
                                           DiscountAmount__c,Row_Total__c,Custom_Price__c,Quantity_Invoiced__c,Sales_Order__c,Sales_Order__r.Order_Status__c,Tax_Percent__c,
                                           UnitPrice__c,Bundle_Item__c,Config_Product__c,Product_Name__c,ProductSKU__c,Product_Url__c,Item__c from SO_Line_Items__c where id=:bundledSol.id];
        
        SO_Line_Items__c protectionSol = TestUtil.createsalesOrderLineItem(salesOrder.id, protectionPro.id, null,null,1);
        
        Purchase_Order__c purchaseOrder = TestUtil.createpurchaseorder(salesOrder.id, 'Manufacturer PO');
        purchaseOrder.Load_Date__c = System.today();
        purchaseOrder.ETA_Is_Given__c = true;
        update purchaseOrder;

		//SO_Line_Items__c protectionSol = TestUtil.createsalesOrderLineItem(salesOrder.id, configPro.id, null,null,1);
        
		Purchase_Order__c po = TestUtil.createpurchaseorder(salesOrder.id,'Manufacturer PO');

		PO_Line_Items__c POl = TestUtil.createpoitem(po.id, Sol.id);
		
		Shipment__c ship = TestUtil.createshipment(po.id, salesOrder.id,'Ship Via Delivery Company');

		 Shipment_Line_Item__c shipitem = TestUtil.createshipmentItem(ship.id, POl.id);
        
        Test.startTest();
        PageReference pref = Page.SalesOrderLineItemsRelatedList;
        test.setCurrentPage(pref);
        PageReference pref1 = Page.poInitiationpage;
        test.setCurrentPage(pref1);
        ApexPages.currentPage().getParameters().put('solids',shipitem.id);
        ApexPages.StandardController sc = new ApexPages.StandardController(salesOrder);   
        list<SO_Line_Items__c> SOBundleList = new list<SO_Line_Items__c>();
        SOBundleList.add(bundleSolItems);
        map<string,ReplacePartCtrl.SOItemsWrapper> soRelatedMap = new map<string,ReplacePartCtrl.SOItemsWrapper>();
        soRelatedMap.put(manufactureAccount.Name+Sol.id,new ReplacePartCtrl.SOItemsWrapper(true,simpleSolItems,null));
        soRelatedMap.put(manufactureAccount.Name+configSol.id,new ReplacePartCtrl.SOItemsWrapper(true,configSolItems,null));
        soRelatedMap.put(manufactureAccount.Name+bundleSolItems.id,new ReplacePartCtrl.SOItemsWrapper(true,bundleSolItems,SOBundleList));
        System.debug('soRelatedMap: '+soRelatedMap);
        
        ReplacePartCtrl controller = new ReplacePartCtrl(sc);
        controller.soRelatedList = soRelatedMap;
        controller.onChange();
        controller.submitOnChange();
        
        controller.trackingnumberId = '12345';
        controller.selectedETA = '1-2 Weeks';
        controller.POFielddisplay = purchaseOrder;
        controller.Carrier = 'White Glove';
        
        controller.updateNow();
        controller.addLater();
        controller.submitPO();
        
        salesOrder.Order_Status__c = 'Processing';
        update salesOrder;
        
        controller.SO_Obj = salesOrder;
        controller.ondeliveryChange();
        controller.onTruckingChange();
        controller.stocknotAvailable();
        controller.onETAchange();
        
        controller.onCarrierchange();
        controller.ondeliveryChange();
        controller.onTruckingChange();
        controller.stocknotAvailable();
        controller.onETAchange();
        
        purchaseOrder.Suggested_Trucking__c = truckingAccount.id;
        purchaseOrder.Load_Date__c = null;
        update purchaseOrder;
        controller.POFielddisplay = purchaseOrder;
        
        controller.ondeliveryChange();
        controller.onETAchange();
        controller.validateBeforeInsertPO();
        test.stopTest();
        System.assertEquals('White Glove', controller.Carrier);
    }
    static testMethod void submitPOWithCarrerAsWhiteGloveAndShipTOHub()
    {
        Account customerAccount = TestUtil.createCustomerAccount(); 
        Account deliveryAccount = TestUtil.createDeliveryAccount();
        Account manufactureAccount = TestUtil.createManufacturerAccount(false,true, 'Email');
        Account warehouseAccount = TestUtil.createWarehouseAccount();
        Account truckingAccount = TestUtil.createTruckingAccount();
        truckingAccount.Name = 'Watkins';
        update truckingAccount;
        
        Trucking_Rule__c trucking = TestUtil.createTruckingRules(manufactureAccount.Id,deliveryAccount.Id);
        trucking.Truking_Selection_Note__c = 'Watkins';
        update trucking;
        
        Products__c configPro = TestUtil.createConfigProduct();
        Products__c simplePro = TestUtil.createSimpleProduct(configPro.id,manufactureAccount.id);
        Products__c bundlePro = TestUtil.createBundleProduct();
        bundlePro.Select_Manufacturer__c = manufactureAccount.id;
        update bundlePro;
        
        Products__c protectionPro = TestUtil.createprotectionProduct();
        
        Inventory__c inventoryItem = TestUtil.createInventory(simplePro.id,5,warehouseAccount.id);
        Inventory__c configinventoryItem = TestUtil.createInventory(configPro.id,5,warehouseAccount.id);
        Inventory__c bundleinventoryItem = TestUtil.createInventory(bundlePro.id,5,warehouseAccount.id);
        
        Bundle_Item__c bundleItem = TestUtil.createBundleItemProduct(configPro.id, bundlePro.id);
        
        Sales_Order__c salesOrder = TestUtil.createsalesOrder(customerAccount.id, deliveryAccount.id, Null);
        
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(salesOrder.id, simplePro.id, null,null,2);
        SO_Line_Items__c simpleSolItems = [select id,Products__r.RecordType.Name,Products__r.recordtypeid,TaxAmount__c,Sub_Total__c,Price__c,name,
                                           Products__c,Products__r.Image__c,Products__r.name,Manufacturer__c,OriginalPrice__c,Product_Brand__c, FedExable__c,
                                           Quantity_Refunded__c,Total_Weight_Pounds__c,Products__r.Select_Manufacturer__r.Order_Communication_Type__c,
                                           Products__r.Select_Manufacturer__r.Website,Bundle_Item__r.Product__c,Products__r.Select_Manufacturer__r.Ship_To_HUB__c,
                                           Products__r.Select_Manufacturer__r.Direct_Shipping__c,Products__r.Select_Manufacturer__c,Promotion_Brand__c,Quantity__c,
                                           DiscountAmount__c,Row_Total__c,Custom_Price__c,Quantity_Invoiced__c,Sales_Order__c,Sales_Order__r.Order_Status__c,Tax_Percent__c,
                                           UnitPrice__c,Bundle_Item__c,Config_Product__c,Product_Name__c,ProductSKU__c,Product_Url__c,Item__c from SO_Line_Items__c where id=:Sol.id];
        
        SO_Line_Items__c configSol = TestUtil.createsalesOrderLineItem(salesOrder.id, simplePro.id, configPro.id,null,2);
        SO_Line_Items__c configSolItems = [select id,Products__r.RecordType.Name,Products__r.recordtypeid,TaxAmount__c,Sub_Total__c,Price__c,name,
                                           Products__c,Products__r.Image__c,Products__r.name,Manufacturer__c,OriginalPrice__c,Product_Brand__c, FedExable__c,
                                           Quantity_Refunded__c,Total_Weight_Pounds__c,Products__r.Select_Manufacturer__r.Order_Communication_Type__c,
                                           Products__r.Select_Manufacturer__r.Website,Bundle_Item__r.Product__c,Products__r.Select_Manufacturer__r.Ship_To_HUB__c,
                                           Products__r.Select_Manufacturer__r.Direct_Shipping__c,Products__r.Select_Manufacturer__c,Promotion_Brand__c,Quantity__c,
                                           DiscountAmount__c,Row_Total__c,Custom_Price__c,Quantity_Invoiced__c,Sales_Order__c,Sales_Order__r.Order_Status__c,Tax_Percent__c,
                                           UnitPrice__c,Bundle_Item__c,Config_Product__c,Product_Name__c,ProductSKU__c,Product_Url__c,Item__c from SO_Line_Items__c where id=:configSol.id];
        SO_Line_Items__c bundleSol = TestUtil.createsalesOrderLineItem(salesOrder.id, bundlePro.id, null,null,3);
        
        SO_Line_Items__c bundledSol = TestUtil.createsalesOrderLineItem(salesOrder.id, bundlePro.id, null,bundleItem.id,2);
        SO_Line_Items__c bundleSolItems = [select id,Products__r.RecordType.Name,Products__r.recordtypeid,TaxAmount__c,Sub_Total__c,Price__c,name,
                                           Products__c,Products__r.Image__c,Products__r.name,Manufacturer__c,OriginalPrice__c,Product_Brand__c, FedExable__c,
                                           Quantity_Refunded__c,Total_Weight_Pounds__c,Products__r.Select_Manufacturer__r.Order_Communication_Type__c,
                                           Products__r.Select_Manufacturer__r.Website,Bundle_Item__r.Product__c,Products__r.Select_Manufacturer__r.Ship_To_HUB__c,
                                           Products__r.Select_Manufacturer__r.Direct_Shipping__c,Products__r.Select_Manufacturer__c,Promotion_Brand__c,Quantity__c,
                                           DiscountAmount__c,Row_Total__c,Custom_Price__c,Quantity_Invoiced__c,Sales_Order__c,Sales_Order__r.Order_Status__c,Tax_Percent__c,
                                           UnitPrice__c,Bundle_Item__c,Config_Product__c,Product_Name__c,ProductSKU__c,Product_Url__c,Item__c from SO_Line_Items__c where id=:bundledSol.id];
        
        SO_Line_Items__c protectionSol = TestUtil.createsalesOrderLineItem(salesOrder.id, protectionPro.id, null,null,1);
        
        Purchase_Order__c purchaseOrder = TestUtil.createpurchaseorder(salesOrder.id, 'Manufacturer PO');
        purchaseOrder.Load_Date__c = System.today();
        purchaseOrder.ETA_Is_Given__c = true;
        update purchaseOrder;

		//SO_Line_Items__c protectionSol = TestUtil.createsalesOrderLineItem(salesOrder.id, configPro.id, null,null,1);
        
		Purchase_Order__c po = TestUtil.createpurchaseorder(salesOrder.id,'Manufacturer PO');

		PO_Line_Items__c POl = TestUtil.createpoitem(po.id, Sol.id);
		
		Shipment__c ship = TestUtil.createshipment(po.id, salesOrder.id,'Ship Via Delivery Company');

		 Shipment_Line_Item__c shipitem = TestUtil.createshipmentItem(ship.id, POl.id);
        
        Test.startTest();
        PageReference pref = Page.SalesOrderLineItemsRelatedList;
        test.setCurrentPage(pref);
        PageReference pref1 = Page.poInitiationpage;
        test.setCurrentPage(pref1);
        ApexPages.currentPage().getParameters().put('solids',shipitem.id);
        ApexPages.StandardController sc = new ApexPages.StandardController(salesOrder);   
        list<SO_Line_Items__c> SOBundleList = new list<SO_Line_Items__c>();
        SOBundleList.add(bundleSolItems);
        map<string,ReplacePartCtrl.SOItemsWrapper> soRelatedMap = new map<string,ReplacePartCtrl.SOItemsWrapper>();
        soRelatedMap.put(manufactureAccount.Name+Sol.id,new ReplacePartCtrl.SOItemsWrapper(true,simpleSolItems,null));
        soRelatedMap.put(manufactureAccount.Name+configSol.id,new ReplacePartCtrl.SOItemsWrapper(true,configSolItems,null));
        soRelatedMap.put(manufactureAccount.Name+bundleSolItems.id,new ReplacePartCtrl.SOItemsWrapper(true,bundleSolItems,SOBundleList));
        System.debug('soRelatedMap: '+soRelatedMap);
        
        ReplacePartCtrl controller = new ReplacePartCtrl(sc);
        controller.soRelatedList = soRelatedMap;
        controller.onChange();
        controller.submitOnChange();
        
        controller.trackingnumberId = '12345';
        controller.selectedETA = '1-2 Weeks';
        controller.POFielddisplay = purchaseOrder;
        controller.Carrier = 'White Glove';
        
        controller.updateNow();
        controller.addLater();
        controller.submitPO();
        
        salesOrder.Order_Status__c = 'Processing';
        update salesOrder;
        
        controller.SO_Obj = salesOrder;
        controller.ondeliveryChange();
        controller.onTruckingChange();
        controller.stocknotAvailable();
        controller.onETAchange();
        
        controller.onCarrierchange();
        controller.ondeliveryChange();
        controller.onTruckingChange();
        controller.stocknotAvailable();
        controller.onETAchange();
        
        purchaseOrder.Suggested_Trucking__c = truckingAccount.id;
        purchaseOrder.Load_Date__c = null;
        update purchaseOrder;
        controller.POFielddisplay = purchaseOrder;
        
        controller.ondeliveryChange();
        controller.onETAchange();
        controller.validateBeforeInsertPO();
        test.stopTest();
        System.assertEquals('White Glove', controller.Carrier);
    }
    static testMethod void submitPOWithCarrerAsWhiteGlove()
    {
        Account customerAccount = TestUtil.createCustomerAccount(); 
        Account deliveryAccount = TestUtil.createDeliveryAccount();
        Account manufactureAccount = TestUtil.createManufacturerAccount(false,false, 'Email');
        Account warehouseAccount = TestUtil.createWarehouseAccount();
        Account truckingAccount = TestUtil.createTruckingAccount();
        truckingAccount.Name = 'Watkins';
        update truckingAccount;
        
        Trucking_Rule__c trucking = TestUtil.createTruckingRules(manufactureAccount.Id,deliveryAccount.Id);
        trucking.Truking_Selection_Note__c = 'Watkins';
        update trucking;
        
        Products__c configPro = TestUtil.createConfigProduct();
        Products__c simplePro = TestUtil.createSimpleProduct(configPro.id,manufactureAccount.id);
        Products__c bundlePro = TestUtil.createBundleProduct();
        bundlePro.Select_Manufacturer__c = manufactureAccount.id;
        update bundlePro;
        
        Products__c protectionPro = TestUtil.createprotectionProduct();
        
        Inventory__c inventoryItem = TestUtil.createInventory(simplePro.id,5,warehouseAccount.id);
        Inventory__c configinventoryItem = TestUtil.createInventory(configPro.id,5,warehouseAccount.id);
        Inventory__c bundleinventoryItem = TestUtil.createInventory(bundlePro.id,5,warehouseAccount.id);
        
        Bundle_Item__c bundleItem = TestUtil.createBundleItemProduct(configPro.id, bundlePro.id);
        
        Sales_Order__c salesOrder = TestUtil.createsalesOrder(customerAccount.id, deliveryAccount.id, Null);
        
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(salesOrder.id, simplePro.id, null,null,2);
        SO_Line_Items__c simpleSolItems = [select id,Products__r.RecordType.Name,Products__r.recordtypeid,TaxAmount__c,Sub_Total__c,Price__c,name,
                                           Products__c,Products__r.Image__c,Products__r.name,Manufacturer__c,OriginalPrice__c,Product_Brand__c, FedExable__c,
                                           Quantity_Refunded__c,Total_Weight_Pounds__c,Products__r.Select_Manufacturer__r.Order_Communication_Type__c,
                                           Products__r.Select_Manufacturer__r.Website,Bundle_Item__r.Product__c,Products__r.Select_Manufacturer__r.Ship_To_HUB__c,
                                           Products__r.Select_Manufacturer__r.Direct_Shipping__c,Products__r.Select_Manufacturer__c,Promotion_Brand__c,Quantity__c,
                                           DiscountAmount__c,Row_Total__c,Custom_Price__c,Quantity_Invoiced__c,Sales_Order__c,Sales_Order__r.Order_Status__c,Tax_Percent__c,
                                           UnitPrice__c,Bundle_Item__c,Config_Product__c,Product_Name__c,ProductSKU__c,Product_Url__c,Item__c from SO_Line_Items__c where id=:Sol.id];
        
        SO_Line_Items__c configSol = TestUtil.createsalesOrderLineItem(salesOrder.id, simplePro.id, configPro.id,null,2);
        SO_Line_Items__c configSolItems = [select id,Products__r.RecordType.Name,Products__r.recordtypeid,TaxAmount__c,Sub_Total__c,Price__c,name,
                                           Products__c,Products__r.Image__c,Products__r.name,Manufacturer__c,OriginalPrice__c,Product_Brand__c, FedExable__c,
                                           Quantity_Refunded__c,Total_Weight_Pounds__c,Products__r.Select_Manufacturer__r.Order_Communication_Type__c,
                                           Products__r.Select_Manufacturer__r.Website,Bundle_Item__r.Product__c,Products__r.Select_Manufacturer__r.Ship_To_HUB__c,
                                           Products__r.Select_Manufacturer__r.Direct_Shipping__c,Products__r.Select_Manufacturer__c,Promotion_Brand__c,Quantity__c,
                                           DiscountAmount__c,Row_Total__c,Custom_Price__c,Quantity_Invoiced__c,Sales_Order__c,Sales_Order__r.Order_Status__c,Tax_Percent__c,
                                           UnitPrice__c,Bundle_Item__c,Config_Product__c,Product_Name__c,ProductSKU__c,Product_Url__c,Item__c from SO_Line_Items__c where id=:configSol.id];
        SO_Line_Items__c bundleSol = TestUtil.createsalesOrderLineItem(salesOrder.id, bundlePro.id, null,null,3);
        
        SO_Line_Items__c bundledSol = TestUtil.createsalesOrderLineItem(salesOrder.id, bundlePro.id, null,bundleItem.id,2);
        SO_Line_Items__c bundleSolItems = [select id,Products__r.RecordType.Name,Products__r.recordtypeid,TaxAmount__c,Sub_Total__c,Price__c,name,
                                           Products__c,Products__r.Image__c,Products__r.name,Manufacturer__c,OriginalPrice__c,Product_Brand__c, FedExable__c,
                                           Quantity_Refunded__c,Total_Weight_Pounds__c,Products__r.Select_Manufacturer__r.Order_Communication_Type__c,
                                           Products__r.Select_Manufacturer__r.Website,Bundle_Item__r.Product__c,Products__r.Select_Manufacturer__r.Ship_To_HUB__c,
                                           Products__r.Select_Manufacturer__r.Direct_Shipping__c,Products__r.Select_Manufacturer__c,Promotion_Brand__c,Quantity__c,
                                           DiscountAmount__c,Row_Total__c,Custom_Price__c,Quantity_Invoiced__c,Sales_Order__c,Sales_Order__r.Order_Status__c,Tax_Percent__c,
                                           UnitPrice__c,Bundle_Item__c,Config_Product__c,Product_Name__c,ProductSKU__c,Product_Url__c,Item__c from SO_Line_Items__c where id=:bundledSol.id];
        
        SO_Line_Items__c protectionSol = TestUtil.createsalesOrderLineItem(salesOrder.id, protectionPro.id, null,null,1);
        
        Purchase_Order__c purchaseOrder = TestUtil.createpurchaseorder(salesOrder.id, 'Manufacturer PO');
        purchaseOrder.Load_Date__c = System.today();
        purchaseOrder.ETA_Is_Given__c = true;
        update purchaseOrder;

		//SO_Line_Items__c protectionSol = TestUtil.createsalesOrderLineItem(salesOrder.id, configPro.id, null,null,1);
        
		Purchase_Order__c po = TestUtil.createpurchaseorder(salesOrder.id,'Manufacturer PO');

		PO_Line_Items__c POl = TestUtil.createpoitem(po.id, Sol.id);
		
		Shipment__c ship = TestUtil.createshipment(po.id, salesOrder.id,'Ship Via Delivery Company');

		 Shipment_Line_Item__c shipitem = TestUtil.createshipmentItem(ship.id, POl.id);
        
        Test.startTest();
        PageReference pref = Page.SalesOrderLineItemsRelatedList;
        test.setCurrentPage(pref);
        PageReference pref1 = Page.poInitiationpage;
        test.setCurrentPage(pref1);
        ApexPages.currentPage().getParameters().put('solids',shipitem.id);
        ApexPages.StandardController sc = new ApexPages.StandardController(salesOrder);   
        list<SO_Line_Items__c> SOBundleList = new list<SO_Line_Items__c>();
        SOBundleList.add(bundleSolItems);
        map<string,ReplacePartCtrl.SOItemsWrapper> soRelatedMap = new map<string,ReplacePartCtrl.SOItemsWrapper>();
        soRelatedMap.put(manufactureAccount.Name+Sol.id,new ReplacePartCtrl.SOItemsWrapper(true,simpleSolItems,null));
        soRelatedMap.put(manufactureAccount.Name+configSol.id,new ReplacePartCtrl.SOItemsWrapper(true,configSolItems,null));
        soRelatedMap.put(manufactureAccount.Name+bundleSolItems.id,new ReplacePartCtrl.SOItemsWrapper(true,bundleSolItems,SOBundleList));
        System.debug('soRelatedMap: '+soRelatedMap);
        
        ReplacePartCtrl controller = new ReplacePartCtrl(sc);
        controller.soRelatedList = soRelatedMap;
        controller.onChange();
        controller.submitOnChange();
        
        controller.trackingnumberId = '';
        controller.selectedETA = '1-2 Weeks';
        controller.POFielddisplay = purchaseOrder;
        controller.Carrier = 'White Glove';
        
        controller.updateNow();
        controller.addLater();
        controller.submitPO();
        
        salesOrder.Order_Status__c = 'Processing';
        update salesOrder;
        
        controller.SO_Obj = salesOrder;
        controller.ondeliveryChange();
        controller.onTruckingChange();
        controller.stocknotAvailable();
        controller.onETAchange();
        
        controller.onCarrierchange();
        controller.ondeliveryChange();
        controller.onTruckingChange();
        controller.stockAvailable();
        controller.onETAchange();
        
        purchaseOrder.Suggested_Trucking__c = truckingAccount.id;
        purchaseOrder.Load_Date__c = null;
        update purchaseOrder;
        controller.POFielddisplay = purchaseOrder;
        
        controller.ondeliveryChange();
        controller.onETAchange();
        controller.validateBeforeInsertPO();
        test.stopTest();
        System.assertEquals('White Glove', controller.Carrier);
    }
    static testMethod void sendInventoryAndsendManufacturer()
    {
        Account customerAccount = TestUtil.createCustomerAccount(); 
        Account deliveryAccount = TestUtil.createDeliveryAccount();
        Account manufactureAccount = TestUtil.createManufacturerAccount(false,false, 'Email');
        Account warehouseAccount = TestUtil.createWarehouseAccount();
        Account truckingAccount = TestUtil.createTruckingAccount();
        truckingAccount.Name = 'Watkins';
        update truckingAccount;
        
        Trucking_Rule__c trucking = TestUtil.createTruckingRules(manufactureAccount.Id,deliveryAccount.Id);
        trucking.Truking_Selection_Note__c = 'Watkins';
        update trucking;
        
        Products__c configPro = TestUtil.createConfigProduct();
        Products__c simplePro = TestUtil.createSimpleProduct(configPro.id,manufactureAccount.id);
        Products__c bundlePro = TestUtil.createBundleProduct();
        bundlePro.Select_Manufacturer__c = manufactureAccount.id;
        update bundlePro;
        
        Products__c protectionPro = TestUtil.createprotectionProduct();
        
        Inventory__c inventoryItem = TestUtil.createInventory(simplePro.id,5,warehouseAccount.id);
        Inventory__c configinventoryItem = TestUtil.createInventory(configPro.id,5,warehouseAccount.id);
        Inventory__c bundleinventoryItem = TestUtil.createInventory(bundlePro.id,5,warehouseAccount.id);
        
        Bundle_Item__c bundleItem = TestUtil.createBundleItemProduct(configPro.id, bundlePro.id);
        
        Sales_Order__c salesOrder = TestUtil.createsalesOrder(customerAccount.id, deliveryAccount.id, Null);
        
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(salesOrder.id, simplePro.id, null,null,2);
        SO_Line_Items__c simpleSolItems = [select id,Products__r.RecordType.Name,Products__r.recordtypeid,TaxAmount__c,Sub_Total__c,Price__c,name,
                                           Products__c,Products__r.Image__c,Products__r.name,Manufacturer__c,OriginalPrice__c,Product_Brand__c, FedExable__c,
                                           Quantity_Refunded__c,Total_Weight_Pounds__c,Products__r.Select_Manufacturer__r.Order_Communication_Type__c,
                                           Products__r.Select_Manufacturer__r.Website,Bundle_Item__r.Product__c,Products__r.Select_Manufacturer__r.Ship_To_HUB__c,
                                           Products__r.Select_Manufacturer__r.Direct_Shipping__c,Products__r.Select_Manufacturer__c,Promotion_Brand__c,Quantity__c,
                                           DiscountAmount__c,Row_Total__c,Custom_Price__c,Quantity_Invoiced__c,Sales_Order__c,Sales_Order__r.Order_Status__c,Tax_Percent__c,
                                           UnitPrice__c,Bundle_Item__c,Config_Product__c,Product_Name__c,ProductSKU__c,Product_Url__c,Item__c from SO_Line_Items__c where id=:Sol.id];
        
        SO_Line_Items__c configSol = TestUtil.createsalesOrderLineItem(salesOrder.id, simplePro.id, configPro.id,null,2);
        SO_Line_Items__c configSolItems = [select id,Products__r.RecordType.Name,Products__r.recordtypeid,TaxAmount__c,Sub_Total__c,Price__c,name,
                                           Products__c,Products__r.Image__c,Products__r.name,Manufacturer__c,OriginalPrice__c,Product_Brand__c, FedExable__c,
                                           Quantity_Refunded__c,Total_Weight_Pounds__c,Products__r.Select_Manufacturer__r.Order_Communication_Type__c,
                                           Products__r.Select_Manufacturer__r.Website,Bundle_Item__r.Product__c,Products__r.Select_Manufacturer__r.Ship_To_HUB__c,
                                           Products__r.Select_Manufacturer__r.Direct_Shipping__c,Products__r.Select_Manufacturer__c,Promotion_Brand__c,Quantity__c,
                                           DiscountAmount__c,Row_Total__c,Custom_Price__c,Quantity_Invoiced__c,Sales_Order__c,Sales_Order__r.Order_Status__c,Tax_Percent__c,
                                           UnitPrice__c,Bundle_Item__c,Config_Product__c,Product_Name__c,ProductSKU__c,Product_Url__c,Item__c from SO_Line_Items__c where id=:configSol.id];
        SO_Line_Items__c bundleSol = TestUtil.createsalesOrderLineItem(salesOrder.id, bundlePro.id, null,null,3);
        
        SO_Line_Items__c bundledSol = TestUtil.createsalesOrderLineItem(salesOrder.id, bundlePro.id, null,bundleItem.id,2);
        SO_Line_Items__c bundleSolItems = [select id,Products__r.RecordType.Name,Products__r.recordtypeid,TaxAmount__c,Sub_Total__c,Price__c,name,
                                           Products__c,Products__r.Image__c,Products__r.name,Manufacturer__c,OriginalPrice__c,Product_Brand__c, FedExable__c,
                                           Quantity_Refunded__c,Total_Weight_Pounds__c,Products__r.Select_Manufacturer__r.Order_Communication_Type__c,
                                           Products__r.Select_Manufacturer__r.Website,Bundle_Item__r.Product__c,Products__r.Select_Manufacturer__r.Ship_To_HUB__c,
                                           Products__r.Select_Manufacturer__r.Direct_Shipping__c,Products__r.Select_Manufacturer__c,Promotion_Brand__c,Quantity__c,
                                           DiscountAmount__c,Row_Total__c,Custom_Price__c,Quantity_Invoiced__c,Sales_Order__c,Sales_Order__r.Order_Status__c,Tax_Percent__c,
                                           UnitPrice__c,Bundle_Item__c,Config_Product__c,Product_Name__c,ProductSKU__c,Product_Url__c,Item__c from SO_Line_Items__c where id=:bundledSol.id];
        
        SO_Line_Items__c protectionSol = TestUtil.createsalesOrderLineItem(salesOrder.id, protectionPro.id, null,null,1);
        
        Purchase_Order__c purchaseOrder = TestUtil.createpurchaseorder(salesOrder.id, 'Manufacturer PO');
        purchaseOrder.Load_Date__c = System.today();
        purchaseOrder.ETA_Is_Given__c = true;
        update purchaseOrder;
        //SO_Line_Items__c protectionSol = TestUtil.createsalesOrderLineItem(salesOrder.id, configPro.id, null,null,1);
        
		Purchase_Order__c po = TestUtil.createpurchaseorder(salesOrder.id,'Manufacturer PO');

		PO_Line_Items__c POl = TestUtil.createpoitem(po.id, Sol.id);
		
		Shipment__c ship = TestUtil.createshipment(po.id, salesOrder.id,'Ship Via Delivery Company');

		 Shipment_Line_Item__c shipitem = TestUtil.createshipmentItem(ship.id, POl.id);

        Test.startTest();
        PageReference pref = Page.SalesOrderLineItemsRelatedList;
        test.setCurrentPage(pref);
        PageReference pref1 = Page.poInitiationpage;
        test.setCurrentPage(pref1);
        ApexPages.currentPage().getParameters().put('solids',shipitem.id);
        ApexPages.StandardController sc = new ApexPages.StandardController(salesOrder);   
        list<SO_Line_Items__c> SOBundleList = new list<SO_Line_Items__c>();
        SOBundleList.add(bundleSolItems);
        map<string,ReplacePartCtrl.SOItemsWrapper> soRelatedMap = new map<string,ReplacePartCtrl.SOItemsWrapper>();
        soRelatedMap.put(manufactureAccount.Name+Sol.id,new ReplacePartCtrl.SOItemsWrapper(true,simpleSolItems,null));
        soRelatedMap.put(manufactureAccount.Name+configSol.id,new ReplacePartCtrl.SOItemsWrapper(true,configSolItems,null));
        soRelatedMap.put(manufactureAccount.Name+bundleSolItems.id,new ReplacePartCtrl.SOItemsWrapper(true,bundleSolItems,SOBundleList));
        System.debug('soRelatedMap: '+soRelatedMap);
        
        /*
        list<ReplacePartCtrl.ItemsorderInvWrapper> ItemsorderInvWrapperList = new list<ReplacePartCtrl.ItemsorderInvWrapper>();
        ReplacePartCtrl.ItemsorderInvWrapper wrapper = new ReplacePartCtrl.ItemsorderInvWrapper(simpleSolItems,'2','2','3',inventoryItem.id,warehouseAccount.id,warehouseAccount.Name,'50');
        ItemsorderInvWrapperList.add(wrapper);
        
        ReplacePartCtrl.ItemsorderInvWrapper configWrapper = new ReplacePartCtrl.ItemsorderInvWrapper(configSolItems,'2','2','5',configinventoryItem.id,warehouseAccount.id,warehouseAccount.Name,'50');
        ItemsorderInvWrapperList.add(configWrapper);
        
        ReplacePartCtrl.ItemsorderInvWrapper bundleWrapper = new ReplacePartCtrl.ItemsorderInvWrapper(bundleSolItems,'2','2','1',bundleinventoryItem.id,warehouseAccount.id,warehouseAccount.Name,'50');
        ItemsorderInvWrapperList.add(bundleWrapper);
        */
        ReplacePartCtrl controller = new ReplacePartCtrl(sc);
        controller.soRelatedList = soRelatedMap;
        controller.onChange();
        controller.submitOnChange();        
        controller.soItem1Id = simpleSolItems.id;
        controller.Carrier = 'none';
        controller.sendInventory();
        controller.submitPO();
        controller.stockAvailable();
        
        controller.poStatus = 'On Order';
        controller.submitOrder = 1;
        controller.insertPO();
        
        controller.sendManufacturer();
        test.stopTest();
        System.assertEquals(simpleSolItems.id, controller.soItem1Id);
    }
    static testMethod void duplicatePO()
    {
        Account customerAccount = TestUtil.createCustomerAccount(); 
        Account deliveryAccount = TestUtil.createDeliveryAccount();
        Account manufactureAccount = TestUtil.createManufacturerAccount(false,false, 'Email');
        Account warehouseAccount = TestUtil.createWarehouseAccount();
        Account truckingAccount = TestUtil.createTruckingAccount();
        truckingAccount.Name = 'Zenith';
        update truckingAccount;
        
        Trucking_Rule__c trucking = TestUtil.createTruckingRules(manufactureAccount.Id,deliveryAccount.Id);
        
        Products__c simplePro = TestUtil.createSimpleProduct(null,manufactureAccount.id);
        simplePro.Weight__c = 300;
        update simplePro;
        
        Inventory__c inventoryItem = TestUtil.createInventory(simplePro.id,5,warehouseAccount.id);
        
        Sales_Order__c salesOrder = TestUtil.createsalesOrder(customerAccount.id, deliveryAccount.id, Null);
        
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(salesOrder.id, simplePro.id, null,null,2);
        
        SO_Line_Items__c simpleSolItems = [select id,Products__r.RecordType.Name,Products__r.recordtypeid,TaxAmount__c,Sub_Total__c,Price__c,name,
                                           Products__c,Products__r.Image__c,Products__r.name,Manufacturer__c,OriginalPrice__c,Product_Brand__c, FedExable__c,
                                           Quantity_Refunded__c,Total_Weight_Pounds__c,Products__r.Select_Manufacturer__r.Order_Communication_Type__c,
                                           Products__r.Select_Manufacturer__r.Website,Bundle_Item__r.Product__c,Products__r.Select_Manufacturer__r.Ship_To_HUB__c,
                                           Products__r.Select_Manufacturer__r.Direct_Shipping__c,Products__r.Select_Manufacturer__c,Promotion_Brand__c,Quantity__c,
                                           DiscountAmount__c,Row_Total__c,Custom_Price__c,Quantity_Invoiced__c,Sales_Order__c,Sales_Order__r.Order_Status__c,Tax_Percent__c,
                                           UnitPrice__c,Bundle_Item__c,Config_Product__c,Product_Name__c,ProductSKU__c,Product_Url__c,Item__c from SO_Line_Items__c where id=:Sol.id];
        
		 Products__c protectionPro = TestUtil.createprotectionProduct();

	    Purchase_Order__c purchaseOrder = TestUtil.createpurchaseorder(salesOrder.id, 'Manufacturer PO');
        
        PO_Line_Items__c simplePO = TestUtil.createpoitem(purchaseOrder.id, simpleSolItems.id);
        
		SO_Line_Items__c protectionSol = TestUtil.createsalesOrderLineItem(salesOrder.id, protectionPro.Id, null,null,1);
        
		Purchase_Order__c po = TestUtil.createpurchaseorder(salesOrder.id,'Manufacturer PO');

		PO_Line_Items__c POl = TestUtil.createpoitem(po.id, Sol.id);
		
		Shipment__c ship = TestUtil.createshipment(po.id, salesOrder.id,'Ship Via Delivery Company');

		Shipment_Line_Item__c shipitem = TestUtil.createshipmentItem(ship.id, POl.id);


        Test.startTest();
        PageReference pref = Page.SalesOrderLineItemsRelatedList;
        test.setCurrentPage(pref);
        PageReference pref1 = Page.poInitiationpage;
        test.setCurrentPage(pref1);
        ApexPages.currentPage().getParameters().put('solids',shipitem.id);
        ApexPages.StandardController sc = new ApexPages.StandardController(salesOrder);   
        
        map<string,ReplacePartCtrl.SOItemsWrapper> soRelatedMap = new map<string,ReplacePartCtrl.SOItemsWrapper>();
        soRelatedMap.put(manufactureAccount.Name+Sol.id,new ReplacePartCtrl.SOItemsWrapper(true,simpleSolItems,null));
        
        ReplacePartCtrl controller = new ReplacePartCtrl(sc);
        controller.soRelatedList = soRelatedMap;
        controller.onChange();
        controller.submitOnChange();
        
        Sol.Item__c = 'PO-Draft';
        update Sol;
        controller.submitPO();
        test.stopTest();
        System.assertEquals(simplePO.SO_Line_Item__c, simpleSolItems.id);
    }
    static testMethod void ondeliveryChangeWithShiptoHubNodelivery()
    {
        Account ac = TestUtil.createCustomerAccount();
        
        Account deliveryAccount = TestUtil.createDeliveryAccount();
        Account manufactureAccount = TestUtil.createManufacturerAccount(false,true, 'Email');
        Account warehouseAccount = TestUtil.createWarehouseAccount();
        Account truckingAccount = TestUtil.createTruckingAccount();
        
        Trucking_Rule__c trucking = TestUtil.createTruckingRules(manufactureAccount.Id,deliveryAccount.Id);
        
        Products__c configPro = TestUtil.createConfigProduct();
        
        Products__c pro = TestUtil.createSimpleProduct(Null,manufactureAccount.id);
        
        Inventory__c inventoryItem = TestUtil.createInventory(pro.id,5,warehouseAccount.id);
        
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, Null, Null);
        
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,2);
        
        SO_Line_Items__c simpleSolItems = [select id,Products__r.RecordType.Name,Products__r.recordtypeid,TaxAmount__c,Sub_Total__c,Price__c,name,
                                           Products__c,Products__r.Image__c,Products__r.name,Manufacturer__c,OriginalPrice__c,Product_Brand__c, FedExable__c,
                                           Quantity_Refunded__c,Total_Weight_Pounds__c,Products__r.Select_Manufacturer__r.Order_Communication_Type__c,
                                           Products__r.Select_Manufacturer__r.Website,Bundle_Item__r.Product__c,Products__r.Select_Manufacturer__r.Ship_To_HUB__c,
                                           Products__r.Select_Manufacturer__r.Direct_Shipping__c,Products__r.Select_Manufacturer__c,Promotion_Brand__c,Quantity__c,
                                           DiscountAmount__c,Row_Total__c,Custom_Price__c,Quantity_Invoiced__c,Sales_Order__c,Sales_Order__r.Order_Status__c,Tax_Percent__c,
                                           UnitPrice__c,Bundle_Item__c,Config_Product__c,Product_Name__c,ProductSKU__c,Product_Url__c,Item__c from SO_Line_Items__c where id=:Sol.id];
        
        
		SO_Line_Items__c protectionSol = TestUtil.createsalesOrderLineItem(so.id, configPro.id, null,null,1);
        
		Purchase_Order__c po = TestUtil.createpurchaseorder(so.id,'Manufacturer PO');

		PO_Line_Items__c POl = TestUtil.createpoitem(po.id, Sol.id);
		
		Shipment__c ship = TestUtil.createshipment(po.id, so.id,'Ship Via Delivery Company');

		 Shipment_Line_Item__c shipitem = TestUtil.createshipmentItem(ship.id, POl.id);

		Test.startTest();
        PageReference pref = Page.SalesOrderLineItemsRelatedList;
        test.setCurrentPage(pref);
        PageReference pref1 = Page.poInitiationpage;
        test.setCurrentPage(pref1);
        ApexPages.currentPage().getParameters().put('solids',shipitem.id);
        ApexPages.StandardController sc = new ApexPages.StandardController(so);   
        
        map<string,ReplacePartCtrl.SOItemsWrapper> soRelatedMap = new map<string,ReplacePartCtrl.SOItemsWrapper>();
        soRelatedMap.put(manufactureAccount.Name+Sol.id,new ReplacePartCtrl.SOItemsWrapper(true,simpleSolItems,null));
        
        ReplacePartCtrl controller = new ReplacePartCtrl(sc);
        controller.soRelatedList = soRelatedMap;
        controller.isShiptoHub = true;
        controller.Carrier = 'none';
        
        controller.ondeliveryChange();
        controller.onTruckingChange();
        controller.submitPO();
        
        controller.isShiptoHub = false;
        controller.isDirectShipping = false;
        controller.Carrier = 'none';
        
        controller.ondeliveryChange();
        controller.onTruckingChange();
        Test.StopTest();
        system.assertEquals(false, controller.isDirectShipping);
    }
    static testMethod void ontruckingChangeWithoutdelivery()
    {
        Account ac = TestUtil.createCustomerAccount();
        
        Account deliveryAccount = TestUtil.createDeliveryAccount();
        Account manufactureAccount = TestUtil.createManufacturerAccount(false,true, 'Email');
        Account warehouseAccount = TestUtil.createWarehouseAccount();
        Account truckingAccount = TestUtil.createTruckingAccount();
        
        Trucking_Rule__c trucking = TestUtil.createTruckingRules(manufactureAccount.Id,deliveryAccount.Id);
        
        Products__c configPro = TestUtil.createConfigProduct();
        
        Products__c pro = TestUtil.createSimpleProduct(Null,manufactureAccount.id);
        
        Inventory__c inventoryItem = TestUtil.createInventory(pro.id,5,warehouseAccount.id);
        
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, Null, Null);
        
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,2);
        
        SO_Line_Items__c simpleSolItems = [select id,Products__r.RecordType.Name,Products__r.recordtypeid,TaxAmount__c,Sub_Total__c,Price__c,name,
                                           Products__c,Products__r.Image__c,Products__r.name,Manufacturer__c,OriginalPrice__c,Product_Brand__c, FedExable__c,
                                           Quantity_Refunded__c,Total_Weight_Pounds__c,Products__r.Select_Manufacturer__r.Order_Communication_Type__c,
                                           Products__r.Select_Manufacturer__r.Website,Bundle_Item__r.Product__c,Products__r.Select_Manufacturer__r.Ship_To_HUB__c,
                                           Products__r.Select_Manufacturer__r.Direct_Shipping__c,Products__r.Select_Manufacturer__c,Promotion_Brand__c,Quantity__c,
                                           DiscountAmount__c,Row_Total__c,Custom_Price__c,Quantity_Invoiced__c,Sales_Order__c,Sales_Order__r.Order_Status__c,Tax_Percent__c,
                                           UnitPrice__c,Bundle_Item__c,Config_Product__c,Product_Name__c,ProductSKU__c,Product_Url__c,Item__c from SO_Line_Items__c where id=:Sol.id];
        
        Purchase_Order__c purchaseOrder = TestUtil.createpurchaseorder(so.id, 'Manufacturer PO');
        purchaseOrder.Suggested_Trucking__c = truckingAccount.id;
        purchaseOrder.Load_Date__c = System.today();
        purchaseOrder.ETA_Is_Given__c = true;
        update purchaseOrder;

		SO_Line_Items__c protectionSol = TestUtil.createsalesOrderLineItem(so.id, configPro.id, null,null,1);
        
		Purchase_Order__c po = TestUtil.createpurchaseorder(so.id,'Manufacturer PO');

		PO_Line_Items__c POl = TestUtil.createpoitem(po.id, Sol.id);
		
		Shipment__c ship = TestUtil.createshipment(po.id, so.id,'Ship Via Delivery Company');

		 Shipment_Line_Item__c shipitem = TestUtil.createshipmentItem(ship.id, POl.id);
        
        Test.startTest();
        PageReference pref = Page.SalesOrderLineItemsRelatedList;
        test.setCurrentPage(pref);
        PageReference pref1 = Page.poInitiationpage;
        test.setCurrentPage(pref1);
        ApexPages.currentPage().getParameters().put('solids',shipitem.id);
        ApexPages.StandardController sc = new ApexPages.StandardController(so);   
        
        map<string,ReplacePartCtrl.SOItemsWrapper> soRelatedMap = new map<string,ReplacePartCtrl.SOItemsWrapper>();
        soRelatedMap.put(manufactureAccount.Name+Sol.id,new ReplacePartCtrl.SOItemsWrapper(true,simpleSolItems,null));
        
        ReplacePartCtrl controller = new ReplacePartCtrl(sc);
        controller.soRelatedList = soRelatedMap;
        controller.isShiptoHub = true;
        controller.POFielddisplay = purchaseOrder;
        controller.Carrier = 'White Glove';
        
        controller.onTruckingChange();
        controller.submitPO();
        
        controller.isShiptoHub = false;
        controller.isDirectShipping = true;
        
        controller.onTruckingChange();
        controller.submitPO();
        
        controller.soitemId = simpleSolItems.id;
        controller.redirect();
        Test.StopTest();
        system.assertEquals(false, controller.isShiptoHub);
    }
    static testMethod void testupdateStatusforPoLIneFromPO()
    {
        Account customerAccount = TestUtil.createCustomerAccount(); 
        Account deliveryAccount = TestUtil.createDeliveryAccount();
        Account manufactureAccount = TestUtil.createManufacturerAccount(true,false, 'Email');
        Account warehouseAccount = TestUtil.createWarehouseAccount();
        Account truckingAccount = TestUtil.createTruckingAccount();
        truckingAccount.Name = 'Watkins';
        update truckingAccount;
        
        Trucking_Rule__c trucking = TestUtil.createTruckingRules(manufactureAccount.Id,deliveryAccount.Id);
        trucking.Truking_Selection_Note__c = 'Watkins';
        update trucking;
        
        Products__c simplePro = TestUtil.createSimpleProduct(null,manufactureAccount.id);
        
        Sales_Order__c salesOrder = TestUtil.createsalesOrder(customerAccount.id, deliveryAccount.id, Null);
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(salesOrder.id, simplePro.id, null,null,2);
        
        Test.startTest();
        Purchase_Order__c purchaseOrder = TestUtil.createpurchaseorder(salesOrder.Id, 'Manufacturer PO');
        purchaseOrder.Ship_From__c = manufactureAccount.id;
        purchaseOrder.Suggested_Delivery_Comapny__c = deliveryAccount.id;
        update purchaseOrder;
        test.stopTest();
    }
	
}