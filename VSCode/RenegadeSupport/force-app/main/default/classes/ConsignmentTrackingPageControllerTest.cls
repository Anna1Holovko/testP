@istest
public class ConsignmentTrackingPageControllerTest{
    
    
    @testSetup
    static void setup(){
        
       	Account ac = TestUtil.createCustomerAccount(); 
        
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, Null, Null);
        
        Purchase_Order__c po = TestUtil.createpurchaseorder(so.id,'Manufacturer PO');
       
        Shipment__c ship = TestUtil.createshipment(po.id, So.id,'Ship Via Delivery Company');
        //system.debug('ShipmentID: '+ship.Id);
        
        shipment_line_item__c SLI_1 = new shipment_line_item__c(Shipment__c = ship.id);
        insert SLI_1;
        shipment_line_item__c SLI_2 = new shipment_line_item__c(Shipment__c = ship.id);
        insert SLI_2;
    }     
    
    testmethod public static void positiveTestCaseVfpage(){
		Shipment__c[] shipmentList = [select id from shipment__c limit 1];
        if(shipmentList.size()>0){
            Shipment__c shipment=shipmentList[0];
            
            ApexPages.StandardController sc = new ApexPages.StandardController(shipment);
            PageReference pageRef = sc.view();
        	pageRef.getParameters().put('id', String.valueOf(shipment.Id));
        	Test.setCurrentPage(pageRef);

            test.startTest();
			ConsignmentTrackingPageController obj = new ConsignmentTrackingPageController(sc);
            obj.shipmentLineItemlist[0].isSelected=true;
            obj.shipmentLineItemlist[1].isSelected=true;
            obj.updateShipmentLineItemStatus();
            obj.checkForErrors();            
            obj.shipmentLineItemlist[0].SLI.Shipment_Item_Status__c='Send to Consignment';
            obj.updateLineItems();
            test.stopTest();
        }
    }
    
    testmethod public static void negativeTestCaseVfpage(){
        Shipment__c[] shipmentList = [select id from shipment__c limit 1];
        if(shipmentList.size()>0){
            Shipment__c shipment=shipmentList[0];
            
            ApexPages.StandardController sc = new ApexPages.StandardController(shipment);
            PageReference pageRef = sc.view();
        	pageRef.getParameters().put('id', String.valueOf(shipment.Id));
        	Test.setCurrentPage(pageRef);

            test.startTest();
			ConsignmentTrackingPageController obj = new ConsignmentTrackingPageController(sc);
            obj.checkForErrors();
            obj.cancel();
            test.stopTest();
        }
    }
}