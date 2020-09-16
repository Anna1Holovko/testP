@isTest
private class ShipmentLineItemTriggerTest {
    @testsetup
    static void setup (){
        insert new Shipment_Line_Item_status_settings__c(Name = 'Hold As Stock', Support_Type__c = 'Support', 	Entitlement_Template__c = 'Test');
        insert new Payment_Methods_for_Automated_Charge__c(Name = 'Affirm');
        Account currentAccount = TestUtil.createCustomerAccount(); 
        Account manufactureAccount = TestUtil.createManufacturerAccount(true, false, 'Email');
        manufactureAccount.Automated_Payment_Capture__c = true;
        update manufactureAccount;
        Products__c product = TestUtil.createConfigProduct();
        Sales_Order__c so = TestUtil.createsalesOrder(currentAccount.id, Null, Null);
        so.Check_for_Fraud__c = false;
        so.Payment_Status__c = 'Received';
        so.Payment_Status__c = 'Pending';
        so.Payment_Method__c = 'Affirm';
        update so;
        
        Purchase_Order__c po=TestUtil.createpurchaseorder(so.id,'Manufacturer PO');
        po.Ship_From__c = manufactureAccount.Id;
        update po;
        
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, product.id, null,null,4);
        
        PO_Line_Items__c POl = TestUtil.createpoitem(po.id, Sol.id);
        Inventory_Management__c setting = new Inventory_Management__c(name = 'Inventory', Retagged_Status__c = 'Retagged', Stock_Status__c = 'Hold As Stock', Furniture_Condition__c = 'Opened');
        insert setting;
        Shipment__c ship = TestUtil.createshipment(po.id, So.id,'Ship Via Delivery Company');
        ship.Carrier__c = '';//'White Glove';
        update ship;
    }

    @isTest
    public static void shipmentLineItemTriggerHandlerTest1(){
        Test.startTest();
        
        Id shipmentId = [SELECT Id FROM Shipment__c LIMIT 1][0].Id;
        Id poLineItemsId = [SELECT Id FROM PO_Line_Items__c LIMIT 1][0].Id;
        Shipment_Line_Item__c shipitem = new Shipment_Line_Item__c(Shipment__c = shipmentId,
                                                                   PO_Line_Item__c = poLineItemsId,
                                                                   Shipment_Item_Status__c = ' Out for Delivery',
                                                                   Approval_Status__c = '');
        Database.SaveResult saveRes = Database.insert(shipitem);
        if (saveRes.isSuccess()) {
            Shipitem.Shipment_Item_Status__c = 'Delivered With Issues';
            Shipment_Line_Item__c newshipitem = new Shipment_Line_Item__c(Id = saveRes.getId());
            newshipitem.Shipment_Item_Status__c = 'Hold As Stock';
            newshipitem.Furniture_Condition__c = 'Opened';
            update newshipitem;
        }
        
        Test.stopTest();
    }
    
    @isTest
    private static void shipmetnLineItemTriggerHandlerTest2() {
        Test.startTest();
        
        Id shipmentId = [SELECT Id FROM Shipment__c LIMIT 1][0].Id;
        Id poLineItemsId = [SELECT Id FROM PO_Line_Items__c LIMIT 1][0].Id;
        Shipment_Line_Item__c shipitem = new Shipment_Line_Item__c(Shipment__c = shipmentId,
                                                                   PO_Line_Item__c = poLineItemsId,
                                                                   Shipment_Item_Status__c = ' Out for Delivery',
                                                                   Approval_Status__c = '');
        Database.SaveResult saveShip = Database.insert(shipitem);
        if (saveShip.isSuccess()) {
            Shipment_Line_Item__c newshipitem = new Shipment_Line_Item__c(Id = saveShip.getId());
            newshipitem.Shipment_Item_Status__c = 'Hold As Stock';
            newshipitem.Furniture_Condition__c = 'Opened';
            newshipitem.Drop_Off_Date_Expected__c = Date.today();
            newshipitem.Furniture_Condition__c = 'Opened';
            update newshipitem;
        }
        
        Test.stopTest();
    }
}