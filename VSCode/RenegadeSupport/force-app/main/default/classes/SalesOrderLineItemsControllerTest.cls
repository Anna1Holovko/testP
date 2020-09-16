@isTest
private class SalesOrderLineItemsControllerTest {
	
	@isTest static void testGetShipmentLines() {
		Field_Set_Shipment_Line_Items__c fieldSetSetting = new Field_Set_Shipment_Line_Items__c();
        SIStatusExcludeValues__c sev = new SIStatusExcludeValues__c();
        sev.Name = 'Cancelled';
		fieldSetSetting.Value__c = 'Delivery_Companies';
		insert fieldSetSetting;
        insert sev;

        Account ac = TestUtil.createCustomerAccount(); 
        
        Products__c Pro = TestUtil.createConfigProduct();
        
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, Null, Null);
        
        Purchase_Order__c po = TestUtil.createpurchaseorder(so.id,'Manufacturer PO');
                
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,5);
        
        PO_Line_Items__c POl = TestUtil.createpoitem(po.id, Sol.id);
        
        test.startTest();
        Shipment__c ship = TestUtil.createshipment(po.id, So.id,'Ship Via Delivery Company');
        Shipment_Line_Item__c shipitem = TestUtil.createshipmentItem(ship.id, POl.id);
        shipitem.Shipment_Product_Quantity__c = 5;
        update shipitem;
		ApexPages.StandardController sc = new ApexPages.StandardController(so);

        PageReference pageRef = sc.view();
        pageRef.getParameters().put('id', String.valueOf(so.Id));
        Test.setCurrentPage(pageRef);

		SalesOrderLineItemsController controller = new SalesOrderLineItemsController(sc);

		controller.processSelected();
		controller.tmpUpdateItem.Shipment_Item_Status__c = 'Deluxed With Issues';
        controller.fileName = 'test';
        controller.fileBody = 'test';
        controller.collectIds();
        controller.shipmentLineToUpdateList = new List<Shipment_Line_Item__c> {shipitem};
		controller.updateSelected();
        controller.goToNewReplacementPO();
        controller.cancel();
        for (SalesOrderLineItemsController.WrapperShipmentLine wrapper_i : controller.shipmentLineList) {
            wrapper_i.isSelected = true;
        }
        controller.goToNewPartPO();
        controller.selectionCount();
        controller.splitButtonHandle();
        controller.splitSaveHandle();
	}
}