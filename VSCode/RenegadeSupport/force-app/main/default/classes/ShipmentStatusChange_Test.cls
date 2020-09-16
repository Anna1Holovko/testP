/*
*   Author : Mani Kumar | Kairos Tech
*   Class  : ShipmentStatusChange_Test
*   Purpose: This test class is to cover the code coverage for trigger ShipmentStatusChange.
*/
@istest
public class ShipmentStatusChange_Test {
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
    }
    public static testmethod void shipmentShipViaDelivery()
    {
        Account ac = TestUtil.createCustomerAccount(); 
        
        Products__c Pro = TestUtil.createConfigProduct();
        
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, Null, Null);
        so.Payment_Status__c = 'Received';
        update so;
        
        Purchase_Order__c po = TestUtil.createpurchaseorder(so.id,'Manufacturer PO');
        po.Total_PO_Items_Loaded__c=1;
        update po;
        
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,5);
        
        PO_Line_Items__c POl = TestUtil.createpoitem(po.id, Sol.id);
        
        test.startTest();
        Shipment__c ship = TestUtil.createshipment(po.id, So.id,'Ship Via Delivery Company');
        Shipment_Line_Item__c shipitem = TestUtil.createshipmentItem(ship.id, POl.id);
        ship.Carrier__c = '';//'White Glove';
        ship.Shipment_Status__c = 'En Route Shipments';
        ship.Pickup_Date_Expected__c =system.today();
        update ship; 
        
        ship.Shipment_Status__c = 'Received By Warehouse';
        //ship.Drop_Off_Date_Actual__c =system.today();
        update ship;
        
        
        ship.Shipment_Status__c = 'Deluxed No Issues-Waiting On Scheduling';
        update ship;
        
        ship.Shipment_Status__c = 'Scheduled Shipments';
        ship.Scheduled_Date__c =system.today();
        update ship;
        
        ship.Shipment_Status__c = 'Delivered No Issues';
        ship.Delivery_Date_Actual__c =system.today();
        update ship;
        
        
        test.stopTest();
        System.assertEquals(''/*'White Glove'*/, ship.Carrier__c);
    }
    
    public static testmethod void shipmentDirect()
    {
        Account ac = TestUtil.createCustomerAccount(); 
        
        Products__c Pro = TestUtil.createConfigProduct();
        
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, Null, Null);
        so.Payment_Status__c = 'Received';
        update so;
        
        Purchase_Order__c po=TestUtil.createpurchaseorder(so.id,'Manufacturer PO');
        po.Total_PO_Items_Loaded__c=1;
        update po;
        
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,5);
        
        PO_Line_Items__c POl = TestUtil.createpoitem(po.id, Sol.id);
        
        test.startTest();
        Shipment__c ship = TestUtil.createshipment(po.id, So.id,'Direct Shipment');
        Shipment_Line_Item__c shipitem = TestUtil.createshipmentItem(ship.id, POl.id);
        ship.Carrier__c = 'LTL';
        
        ship.Shipment_Status__c = 'En Route Shipments';
        ship.Pickup_Date_Expected__c =system.today();
        update ship; 
        
        ship.Shipment_Status__c = 'Delivered No Issues';
        ship.Delivery_Date_Actual__c =system.today();
        update ship;
        
        test.stopTest();
        System.assertEquals('LTL', ship.Carrier__c);
    }
    
    public static testmethod void shipmentShipToHUB()
    {
        Account ac = TestUtil.createCustomerAccount(); 
        
        Products__c Pro = TestUtil.createConfigProduct();
        
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, Null, Null);
        so.Payment_Status__c = 'Received';
        update so;
        
        Purchase_Order__c po=TestUtil.createpurchaseorder(so.id,'Manufacturer PO');
        po.Total_PO_Items_Loaded__c=1;
        update po;
        
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,5);
        
        PO_Line_Items__c POl = TestUtil.createpoitem(po.id, Sol.id);
        
        test.startTest();
        Shipment__c ship = TestUtil.createshipment(po.id, So.id,'Ship To HUB');
        Shipment_Line_Item__c shipitem = TestUtil.createshipmentItem(ship.id, POl.id);
        ship.Carrier__c = '';
        
        ship.Shipment_Status__c = 'En Route Shipments';
        ship.Pickup_Date_Expected__c =system.today();
        update ship; 
        
        ship.Shipment_Status__c = 'Received By Warehouse';
        //ship.Drop_Off_Date_Actual__c =system.today();
        update ship;
        
        ship.Shipment_Status__c = 'Deluxed No Issues-Waiting On Scheduling';
        update ship;
        
        ship.Shipment_Status__c = 'Scheduled Shipments';
        ship.Scheduled_Date__c =system.today();
        update ship;
        
        ship.Shipment_Status__c = 'Delivered No Issues';
        ship.Delivery_Date_Actual__c =system.today();
        update ship;
        
        test.stopTest();
        System.assertEquals('', ship.Carrier__c);
        
    }
}