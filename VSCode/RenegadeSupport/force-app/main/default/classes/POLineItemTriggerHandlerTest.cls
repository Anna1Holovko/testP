@isTest
private class POLineItemTriggerHandlerTest {
	
	@isTest static void test_method_one() {
		Account ac = TestUtil.createCustomerAccount(); 
        Account manufactureAccount = TestUtil.createManufacturerAccount(true,false, 'Email');

        Products__c Pro = TestUtil.createConfigProduct();
        
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, Null, Null);
        so.Payment_Status__c = 'Received';
        so.Check_for_Fraud__c = false;
        update so;
        
        Purchase_Order__c po = TestUtil.createpurchaseorder(so.id,'Manufacturer PO');
        po.Ship_From__c = manufactureAccount.Id;//[select Manufacturer_ID__c from EDI_Map__mdt limit 1].Manufacturer_ID__c;
        po.Load_Date__c = Date.today();
        update po;
        po = [SELECT Id, Name FROM Purchase_Order__c LIMIT 1];
        
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,5);
        
        PO_Line_Items__c POl = TestUtil.createpoitem(po.id, Sol.id);
	}
	
}