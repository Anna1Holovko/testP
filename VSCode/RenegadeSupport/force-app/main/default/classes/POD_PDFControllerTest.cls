@isTest
private class POD_PDFControllerTest {
	@isTest
    public static void testController(){
        insert new PODShipmentLineItemExcludedStatuses__c(Name = 'Retagged');
        
        Account ac = TestUtil.createCustomerAccount(); 
        
        Products__c Pro = TestUtil.createConfigProduct();
        
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, Null, Null);
        
        Purchase_Order__c po = TestUtil.createpurchaseorder(so.id,'Manufacturer PO');
        
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,5);
        
        PO_Line_Items__c POl = TestUtil.createpoitem(po.id, Sol.id);
        
        test.startTest();
        Shipment__c ship = TestUtil.createshipment(po.id, So.id,'Ship Via Delivery Company');
        Shipment_Line_Item__c shipitem = TestUtil.createshipmentItem(ship.id, POl.id);
        
        
        ApexPages.currentPage().getParameters().put('Id',so.id); 
        
        POD_PDFController controller = new POD_PDFController();
        test.stopTest();
    }
}