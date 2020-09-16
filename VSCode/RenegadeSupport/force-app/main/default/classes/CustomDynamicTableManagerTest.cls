@isTest
public class CustomDynamicTableManagerTest {
     @isTest
    static void obtainsPayablesInvoiceListTest(){
        Account ac = TestUtil.createCustomerAccount(); 
        
        Products__c Pro = TestUtil.createConfigProduct();
        
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, Null, Null);
        
        Purchase_Order__c po = TestUtil.createpurchaseorder(so.id,'Manufacturer PO');
                
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,5);
        
        PO_Line_Items__c POl = TestUtil.createpoitem(po.id, Sol.id);

        Shipment__c ship = TestUtil.createshipment(po.id, So.id,'Ship Via Delivery Company');
        Shipment_Line_Item__c shipitem = TestUtil.createshipmentItem(ship.id, POl.id);

        List<CustomDynamicTableManager.Column> responseColumn =  CustomDynamicTableManager.obtainColumns(Schema.SObjectType.Shipment_Line_Item__c.fieldSets.getMap().get('DeliveryCompanyToUpdate').getFields());
        List<CustomDynamicTableManager.ObjectWrapper> responseObject =  CustomDynamicTableManager.obtainObjectList(new List<Shipment_Line_Item__c>{shipitem}, Schema.SObjectType.Shipment_Line_Item__c.fieldSets.getMap().get('DeliveryCompanyToUpdate').getFields());
        
    }       
}