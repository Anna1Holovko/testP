@isTest
public class POlineComponentControllerTest {
	@isTest
    public static void testComponent(){
        Account ac = TestUtil.createCustomerAccount(); 
        
        Products__c Pro = TestUtil.createConfigProduct();
        
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, Null, Null);
        so.Payment_Status__c = 'Received';
        so.Check_for_Fraud__c = false;
        update so;
        
        Purchase_Order__c po = TestUtil.createpurchaseorder(so.id,'Manufacturer PO');
        po.Ship_From__c = [select Manufacturer_ID__c from EDI_Map__mdt limit 1].Manufacturer_ID__c;
        po.Load_Date__c = Date.today();
        update po;
        po = [SELECT Id, Name FROM Purchase_Order__c LIMIT 1];
        
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,5);
        
        PO_Line_Items__c POl = TestUtil.createpoitem(po.id, Sol.id);
        Shipment__c ship = TestUtil.createshipment(po.id, So.id,'Ship Via Delivery Company');
        ship.Carrier__c = '';//'White Glove';
        ship.Tracking_Number__c = '111';
        ship.Shipment_notification_sent_to_customer__c = Datetime.now();
        update ship;
        
         Test.startTest();
        Shipment_Line_Item__c shipitem = TestUtil.createshipmentItem(ship.id, POl.id);
       
        POlineComponentController ctrl = new POlineComponentController();
        ctrl.poId = po.id;
        Test.stopTest();
    }
}