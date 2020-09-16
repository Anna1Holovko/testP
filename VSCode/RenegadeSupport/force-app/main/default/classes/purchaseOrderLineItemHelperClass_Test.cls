/*
*   Author : Vishnu Bijjula & Sowdhanya Karri | Kairos Tech
*   Class  : purchaseOrderLineItemHelperClass_Test
*   Purpose: This test class is to cover the code coverage for purchaseOrderLineItemHelperClass class.
*/
@istest
public class purchaseOrderLineItemHelperClass_Test {
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
    
    // work
    // UPS/FedEx - 'set'
    public static testmethod void InsertShipment(){
        
        // setup data ---
        Account ac = TestUtil.createCustomerAccount();  
        Account manufactureAccount = TestUtil.createManufacturerAccount(true,false, 'Email');
        Account deliveryAccount = TestUtil.createDeliveryAccount();
        Account truckingAccount = TestUtil.createTruckingAccount();
        
        Contact con = TestUtil.setupCustomerContact('Test', 'Name', manufactureAccount.id); 
        
        List<purchaseOrderLineItemHelperClass.productInfo> prodInfo = new List<purchaseOrderLineItemHelperClass.productInfo>();
        purchaseOrderLineItemHelperClass.productInfo productInfo0 = new purchaseOrderLineItemHelperClass.productInfo();
        purchaseOrderLineItemHelperClass.productInfo productInfo1 = new purchaseOrderLineItemHelperClass.productInfo();
        
        productInfo0.sku = 'test0';
        productInfo0.dimensions = '3';
        productInfo0.name = 'Test0';
        productInfo0.weight='5';
        productInfo0.cost = 2.3;
        
        productInfo1.sku = 'test1'; 
        productInfo1.dimensions = '2';
        productInfo1.name = 'Test1';
        productInfo1.weight='6';
        productInfo1.cost = 3.4;
        
        prodInfo.add(productInfo0);
        prodInfo.add(productInfo1);
        
        Products__c Pro = TestUtil.createConfigProduct();
        Pro.SKU_list__c = '123';
        Pro.SKU_and_name_list__c = JSON.serialize(prodInfo);
        update Pro;
        
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, deliveryAccount.id, Null);
        
        Purchase_Order__c PO = TestUtil.createpurchaseorder(so.id, 'Manufacturer PO');
        PO.Ship_From__c = manufactureAccount.id;
        PO.Carrier__c = 'FedEx';
        PO.Suggested_Delivery_Comapny__c = deliveryAccount.id;
        PO.Suggested_Trucking__c = truckingAccount.id;
            
        update PO;
        
        Purchase_Order__c poList = [Select name,Ship_From__c,Email_Response__c,Manufacturer_Name__c from Purchase_Order__c where id=:PO.id];
        
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,5);
        Sol.Product_Name__c = 'Set';
        update Sol;
        
        PO_Line_Items__c POl = TestUtil.createpoitem(po.id, Sol.id);
        
        PO_Line_Items__c poiWithPathOrdered = new PO_Line_Items__c(Purchase_Order__c=po.Id, SO_Line_Item__c=Sol.Id, PO_Item_Status__c='On Order', Parts_ordered__c = true );
        insert poiWithPathOrdered;
        
		//----------------

        test.startTest();
        
        purchaseOrderLineItemHelperClass.InsertShipment(''+POl.id);
        List<Shipment__c> shipments = [SELECT Id, Name FROM Shipment__c WHERE Purchase_Order__c = :po.Id];
        System.assertEquals(2, shipments.size());

        List<Shipment_Line_Item__c> shipmentLineItems0 = [SELECT Id FROM Shipment_Line_Item__c WHERE Shipment__c = :shipments[0].id];
        System.assertEquals(1, shipmentLineItems0.size());
        List<Shipment_Line_Item__c> shipmentLineItems1 = [SELECT Id FROM Shipment_Line_Item__c WHERE Shipment__c = :shipments[1].id];
        System.assertEquals(1, shipmentLineItems1.size());

        //---
        /*purchaseOrderLineItemHelperClass.InsertShipment(''+poiWithPathOrdered.id);
        
        manufactureAccount.Ship_To_HUB__c = true;
        manufactureAccount.Direct_Shipping__c = false;
        update manufactureAccount;
        
        purchaseOrderLineItemHelperClass.InsertShipment(''+POl.id);
        
        manufactureAccount.Ship_To_HUB__c = false;
        update manufactureAccount;
        
        PO.RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Purchase_Order__c' and Name='Internal PO'].id;
        update PO;
        
        purchaseOrderLineItemHelperClass.InsertShipment(''+POl.id);
        
        PO.RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Purchase_Order__c' and Name='Manufacturer PO'].id;
        update PO;
        
        purchaseOrderLineItemHelperClass.InsertShipment(''+POl.id);*/
        
        
        test.stopTest();
    }
    
    // work
    // UPS/FedEx - 'set of 2'
    public static testmethod void InsertShipment1() {
        
        // setup data ---
        Account ac = TestUtil.createCustomerAccount();  
        Account manufactureAccount = TestUtil.createManufacturerAccount(false,true, 'Email');
        Account deliveryAccount = TestUtil.createDeliveryAccount();
        Account truckingAccount = TestUtil.createTruckingAccount();
        
        Contact con = TestUtil.setupCustomerContact('Test', 'Name', manufactureAccount.id); 
        
        List<purchaseOrderLineItemHelperClass.productInfo> prodInfo = new List<purchaseOrderLineItemHelperClass.productInfo>();
        purchaseOrderLineItemHelperClass.productInfo productInfo0 = new purchaseOrderLineItemHelperClass.productInfo();
        purchaseOrderLineItemHelperClass.productInfo productInfo1 = new purchaseOrderLineItemHelperClass.productInfo();
        
        productInfo0.sku = 'test0';
        productInfo0.dimensions = '3';
        productInfo0.name = 'Test0';
        productInfo0.weight='5';
        productInfo0.cost = 2.3;
        
        productInfo1.sku = 'test1'; 
        productInfo1.dimensions = '2';
        productInfo1.name = 'Test1';
        productInfo1.weight='6';
        productInfo1.cost = 3.4;
        
        prodInfo.add(productInfo0);
        prodInfo.add(productInfo1);
        
        Products__c Pro = TestUtil.createConfigProduct();
        Pro.SKU_list__c = '123';
        Pro.SKU_and_name_list__c = JSON.serialize(prodInfo);
        update Pro;
        
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, deliveryAccount.id, Null);
        
        Purchase_Order__c PO = TestUtil.createpurchaseorder(so.id, 'Manufacturer PO');
        PO.Ship_From__c = manufactureAccount.id;
        PO.Carrier__c = 'FedEx';
        PO.Suggested_Delivery_Comapny__c = deliveryAccount.id;
        PO.Suggested_Trucking__c = truckingAccount.id;
            
        update PO;
        
        Purchase_Order__c poList = [Select name,Ship_From__c,Email_Response__c,Manufacturer_Name__c from Purchase_Order__c where id=:PO.id];
        
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,5);
        Sol.Product_Name__c = 'Set of 2';
        update Sol;
        
        PO_Line_Items__c POl = TestUtil.createpoitem(po.id, Sol.id);
        POl.Quantity__c = 2;
        update POl;
        //----------------
        
        test.startTest();
        
        purchaseOrderLineItemHelperClass.InsertShipment(''+POl.id);
        Map<Id, Shipment__c> shipmentsForSet2 = new Map<Id, Shipment__c>([SELECT Id, Name FROM Shipment__c WHERE Purchase_Order__c = :po.Id]);
        System.assertEquals(1, shipmentsForSet2.size());
        List<Shipment_Line_Item__c> shipmentLineItemsForSet2 = [SELECT Id FROM Shipment_Line_Item__c WHERE Shipment__c IN :shipmentsForSet2.keySet()];
        System.assertEquals(2, shipmentLineItemsForSet2.size());
        
        test.stopTest();
        
    }
    
    // work
    // carrier = null
    public static testmethod void InsertShipment2() {
         
        // setup data ---
        Account ac = TestUtil.createCustomerAccount();  
        Account manufactureAccount = TestUtil.createManufacturerAccount(true,false, 'Email');
        Account deliveryAccount = TestUtil.createDeliveryAccount();
        Account truckingAccount = TestUtil.createTruckingAccount();
        
        Contact con = TestUtil.setupCustomerContact('Test', 'Name', manufactureAccount.id); 
        
        List<purchaseOrderLineItemHelperClass.productInfo> prodInfo = new List<purchaseOrderLineItemHelperClass.productInfo>();
        purchaseOrderLineItemHelperClass.productInfo productInfo0 = new purchaseOrderLineItemHelperClass.productInfo();
        purchaseOrderLineItemHelperClass.productInfo productInfo1 = new purchaseOrderLineItemHelperClass.productInfo();
        
        productInfo0.sku = 'test0';
        productInfo0.dimensions = '3';
        productInfo0.name = 'Test0';
        productInfo0.weight='5';
        productInfo0.cost = 2.3;
        
        productInfo1.sku = 'test1'; 
        productInfo1.dimensions = '2';
        productInfo1.name = 'Test1';
        productInfo1.weight='6';
        productInfo1.cost = 3.4;
        
        prodInfo.add(productInfo0);
        prodInfo.add(productInfo1);
        
        Products__c Pro = TestUtil.createConfigProduct();
        Pro.SKU_list__c = '123';
        Pro.SKU_and_name_list__c = JSON.serialize(prodInfo);
        update Pro;
        
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, deliveryAccount.id, Null);
        
        Purchase_Order__c PO = TestUtil.createpurchaseorder(so.id, 'Manufacturer PO');
        PO.Ship_From__c = manufactureAccount.id;
        PO.Carrier__c = null;
        PO.Suggested_Delivery_Comapny__c = deliveryAccount.id;
        PO.Suggested_Trucking__c = truckingAccount.id;
            
        update PO;
        
        Purchase_Order__c poList = [Select name,Ship_From__c,Email_Response__c,Manufacturer_Name__c from Purchase_Order__c where id=:PO.id];
        
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,5);
        Sol.Product_Name__c = 'Set of 2';
        update Sol;
        
        PO_Line_Items__c POl = TestUtil.createpoitem(po.id, Sol.id);
       
        //----------------
        
        test.startTest();

        purchaseOrderLineItemHelperClass.InsertShipment(''+POl.id);
        Map<Id, Shipment__c> shipmentsForSet2 = new Map<Id, Shipment__c>([SELECT Id, Name FROM Shipment__c WHERE Purchase_Order__c = :po.Id]);
        System.assertEquals(1, shipmentsForSet2.size());
        List<Shipment_Line_Item__c> shipmentLineItemsForSet2 = [SELECT Id FROM Shipment_Line_Item__c WHERE Shipment__c IN :shipmentsForSet2.keySet()];
        System.assertEquals(2, shipmentLineItemsForSet2.size());
        
        test.stopTest();
    }
    
    // carrier = null
    // Parts_ordered__c = true
    public static testmethod void InsertShipment3() {
        
        // setup data ---
        Account ac = TestUtil.createCustomerAccount();  
        Account manufactureAccount = TestUtil.createManufacturerAccount(true,false, 'Email');
        Account deliveryAccount = TestUtil.createDeliveryAccount();
        Account truckingAccount = TestUtil.createTruckingAccount();
        
        Contact con = TestUtil.setupCustomerContact('Test', 'Name', manufactureAccount.id); 
        
        List<purchaseOrderLineItemHelperClass.productInfo> prodInfo = new List<purchaseOrderLineItemHelperClass.productInfo>();
        purchaseOrderLineItemHelperClass.productInfo productInfo0 = new purchaseOrderLineItemHelperClass.productInfo();
        purchaseOrderLineItemHelperClass.productInfo productInfo1 = new purchaseOrderLineItemHelperClass.productInfo();
        
        productInfo0.sku = 'test0';
        productInfo0.dimensions = '3';
        productInfo0.name = 'Test0';
        productInfo0.weight='5';
        productInfo0.cost = 2.3;
        
        productInfo1.sku = 'test1'; 
        productInfo1.dimensions = '2';
        productInfo1.name = 'Test1';
        productInfo1.weight='6';
        productInfo1.cost = 3.4;
        
        prodInfo.add(productInfo0);
        prodInfo.add(productInfo1);
        
        Products__c Pro = TestUtil.createConfigProduct();
        Pro.SKU_list__c = '123';
        Pro.SKU_and_name_list__c = JSON.serialize(prodInfo);
        update Pro;
        
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, deliveryAccount.id, Null);
        
        Purchase_Order__c PO = TestUtil.createpurchaseorder(so.id, 'Manufacturer PO');
        PO.Ship_From__c = manufactureAccount.id;
        PO.Carrier__c = null;
        PO.Suggested_Delivery_Comapny__c = deliveryAccount.id;
        PO.Suggested_Trucking__c = truckingAccount.id;
            
        update PO;
        
        Purchase_Order__c poList = [Select name,Ship_From__c,Email_Response__c,Manufacturer_Name__c from Purchase_Order__c where id=:PO.id];
        
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,5);
        Sol.Product_Name__c = 'Set of 2';
        update Sol;
        
        PO_Line_Items__c POl = TestUtil.createpoitem(po.id, Sol.id);
        POl.Parts_ordered__c = true;
        update POl;
        //----------------
        
        test.startTest();

        purchaseOrderLineItemHelperClass.InsertShipment(''+POl.id);
        Map<Id, Shipment__c> shipmentsForSet2 = new Map<Id, Shipment__c>([SELECT Id, Name FROM Shipment__c WHERE Purchase_Order__c = :po.Id]);
        System.assertEquals(1, shipmentsForSet2.size());
        List<Shipment_Line_Item__c> shipmentLineItemsForSet2 = [SELECT Id FROM Shipment_Line_Item__c WHERE Shipment__c IN :shipmentsForSet2.keySet()];
        System.assertEquals(1, shipmentLineItemsForSet2.size());
        
        test.stopTest();
        
    }
}