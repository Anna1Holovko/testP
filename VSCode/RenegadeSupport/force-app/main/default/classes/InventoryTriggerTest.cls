@isTest
public class InventoryTriggerTest {

    static testMethod void InventoryTrigger(){
        Account warehouseAccount = TestUtil.createWarehouseAccount();
        Account deliveryAccount = TestUtil.createDeliveryAccount();
        Account manufactureAccount = TestUtil.createManufacturerAccount(true,false, 'Email');
        Products__c simplePro = TestUtil.createSimpleProductwithoutMaster(manufactureAccount.id);
        Products__c simplePro2 = TestUtil.createSimpleProductwithoutMaster(manufactureAccount.id);
		Account ac = TestUtil.createCustomerAccount(); 

        // Test Delivery Company Inventory
        Sales_Order__c so_delivery = TestUtil.createsalesOrder(ac.id, Null, Null);
        Purchase_Order__c po_delivery = TestUtil.createpurchaseorder(so_delivery.id,'Manufacturer PO');
        SO_Line_Items__c Sol_delivery = TestUtil.createsalesOrderLineItem(so_delivery.id, simplePro.id, null,null,1);
       // SO_Line_Items__c Sol_delivery2 = TestUtil.createsalesOrderLineItem(so_delivery.id, simplePro2.id, null,null,6);
        PO_Line_Items__c POl_delivery = TestUtil.createpoitem(po_delivery.id, Sol_delivery.id);
        pol_delivery.Quantity__c = 5;

        Inventory__c inventory_delivery = TestUtil.createDeliveryInventory(simplePro.id,5,deliveryAccount.id, null);
        inventory_delivery.Related_POL__c = POl_delivery.Id;
       	
        test.startTest();
        
        Shipment__c ship_delivery = TestUtil.createshipment(po_delivery.id, So_delivery.id,'Ship Via Delivery Company');
        Shipment_Line_Item__c shipitem_delivery = TestUtil.createshipmentItem(ship_delivery.id, POl_delivery.id);
        shipitem_delivery.Shipment_Item_Status__c = 'Hold As Stock';
        shipitem_delivery.Furniture_Condition__c = 'Opened';
        shipitem_delivery.Inventory__c = inventory_delivery.Id;
        
        Sales_Order__c so_delivery2 = TestUtil.createsalesOrder(ac.id, Null, Null);
        SO_Line_Items__c Sol_delivery3 = TestUtil.createsalesOrderLineItem(so_delivery2.id, simplePro.id, null,null,2);
        Purchase_Order__c po_delivery2 = TestUtil.createpurchaseorder(so_delivery2.id,'Internal PO');
        inventory_delivery.Quantity__c = inventory_delivery.Quantity__c - 1.0;
        update inventory_delivery;

        test.stopTest();
        
    }
    
    @isTest
    static void TestOwnInvenotry() {
        Account warehouseAccount = TestUtil.createWarehouseAccount();
        Account deliveryAccount = TestUtil.createDeliveryAccount();
        Account manufactureAccount = TestUtil.createManufacturerAccount(true,false, 'Email');
        Products__c simplePro = TestUtil.createSimpleProductwithoutMaster(manufactureAccount.id);
        Products__c simplePro2 = TestUtil.createSimpleProductwithoutMaster(manufactureAccount.id);

        
        // Test Own Inventory
        
        Account ac = TestUtil.createCustomerAccount(); 
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, Null, Null);
        
        Purchase_Order__c po = TestUtil.createpurchaseorder(so.id,'Manufacturer PO');
        Test.startTest();
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, simplePro.id, null,null,5);
        PO_Line_Items__c POl = TestUtil.createpoitem(po.id, Sol.id);
        Shipment__c ship = TestUtil.createshipment(po.id, So.id,'Ship Via Delivery Company');
        Shipment_Line_Item__c shipitem = TestUtil.createshipmentItem(ship.id, POl.id);
        
        Inventory__c inventoryItem = TestUtil.createDeliveryInventory(simplePro.id,5,warehouseAccount.id, shipitem.id);
        
        SO_Line_Items__c Sol2 = TestUtil.createsalesOrderLineItem(so.id, simplePro.id, null,null,5);
        PO_Line_Items__c POl2 = TestUtil.createpoitem(po.id, Sol2.id);
        Inventory__c inventoryItem2 = TestUtil.createDeliveryInventory(simplePro.id,5,warehouseAccount.id, shipitem.id);
        Test.stopTest();
    }
     
}