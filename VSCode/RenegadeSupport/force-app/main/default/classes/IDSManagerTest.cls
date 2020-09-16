@isTest
private class IDSManagerTest {
	
	@isTest static void placeOrderTest() {
		IDS_Setting__c setting = new IDS_Setting__c();
		setting.URL__c = 'www.google.com';
		setting.Token__c = 'AIzaSyCAmP-yM5hc67O4stT-VyzMRmDTaVYfXzQ';
		insert setting;
		Google_API__c settGoogle = new Google_API__c(Name='Google API',Key__c='AIzaSyCAmP-yM5hc67O4stT-VyzMRmDTaVYfXzQ');
		insert settGoogle;


		Account ac = TestUtil.createCustomerAccount(); 
        
        Products__c Pro = TestUtil.createConfigProduct();
        
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, Null, Null);
        
        Purchase_Order__c po = TestUtil.createpurchaseorder(so.id,'Manufacturer PO');
                
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,5);
        
        PO_Line_Items__c POl = TestUtil.createpoitem(po.id, Sol.id);

	    Sales_Order__c order = new Sales_Order__c();
	    order.Magento_order_No__c = '12312';
	    order.Customer_Name__c = ac.Id;
	    order.Email__c = '12312@gmail.com';
	    order.Billing_phone__c = '+382569654456';
	    order.Shipping_Phone__c = '+382522654456';
	    order.Shipping_Street__c = 'test 1';
	    order.Shipping_City__c = 'test';
	    order.Shipping_State__c = 'te';
	    order.Shipping_ZipCode__c = '65895';
	    order.Note_for_Delivery_Company__C = 'asdasdaqw qawdqa wdas dqwd asdrgs dcsa dfsd';
	    insert order;

        Shipment__c ship = TestUtil.createshipment(po.id, So.id,'Ship Via Delivery Company');
        ship.Sent_to_the_delivery_company__c = Date.today()-2;
        ship.Related_Sales_Order__c = order.Id;

        update ship;
        
        Shipment_Line_Item__c sli = TestUtil.createshipmentItem(ship.id, POl.id);

        IDSManager.placeOrder(ship.Id, true, '123123', true, true, false, false, false);
        Shipment__c newShip = [SELECT Id, Sent_to_the_delivery_company__c FROM Shipment__c WHERE Id = :ship.Id];
        System.assertEquals(Date.today()-2, newShip.Sent_to_the_delivery_company__c);
	}

}