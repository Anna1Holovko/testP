@isTest
private class ShipmentTriggerHandlerTest {

	@TestSetup
	static void makeData(){
		User portalUSer = TestUtil.createCustomerPortalUser('delierUser@test.unit');
		portalUSer.ProfileId = [select id, name from profile  WHERE Name = 'Delivery Community Profile' LIMIT 1].Id;
        //portalUSer.UserRoleId = [SELECT Id FROM UserRole  WHERE Name LIKE '%executive%' LIMIT 1].Id;
		//portalUSer.UserRoleId = [Select Id,name From UserRole Where PortalType != 'None' Limit 1].Id;
		insert portalUSer;      
        
	}
	
	@isTest static void insertTest() {     
        Fideliton_Setting__c setting = new Fideliton_Setting__c();
        setting.Password__c = '12314';
        setting.UserName__c = 'Test';
        insert setting;
        Google_API__c settGoogle = new Google_API__c(Name='Google API',Key__c='AIzaSyCAmP-yM5hc67O4stT-VyzMRmDTaVYfXzQ');
        insert settGoogle;
        Dispatch_Track_Setting__c settDiscpatch = new Dispatch_Track_Setting__c();
        settDiscpatch.server__c = 'teset.com';
        insert settDiscpatch;
        
		Account acc = [SELECT ID FROM Account WHERE Name = 'TEST ACCOUNT' LIMIT 1];
		Id accRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Delivery Company').getRecordTypeId();
		acc.recordTypeId = accRecordTypeId;
		update acc;
		Account ac = TestUtil.createCustomerAccount(); 
        Products__c Pro = TestUtil.createConfigProduct();
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, Null, Null);
        Purchase_Order__c po = TestUtil.createpurchaseorder(so.id,'Manufacturer PO');
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,5);
        PO_Line_Items__c POl = TestUtil.createpoitem(po.id, Sol.id);
		Account acDel = TestUtil.createDeliveryAccount(); 


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

		
		RecordType shipmentRecordType = [Select id,Name from RecordType where SObjectType = 'Shipment__c' and Name ='Ship Via Delivery Company'];
        
        Shipment__c ship = new Shipment__c(RecordTypeId=shipmentRecordType.id,
                                           Purchase_Order__c=po.id,
                                           Related_Sales_Order__c=So.id,
                                           Shipment_Status__c='Draft');

        ship.Carrier__c = null;
		ship.Delivery_Company__c = acDel.ID;								   
        Database.insert(ship);
        Shipment_Line_Item__c lineItem = TestUtil.createshipmentItem(ship.id, POl.id);
        ship.Sent_to_the_delivery_company__c = Date.today()-2;
        ship.Related_Sales_Order__c = order.Id;
        ship.Send_to_a_delivery_company__c = true;
		ship.Delivery_Company__c = acc.ID;
        
        Test.startTest();
        update ship;
		
        List<Shipment__c> listShip = new List<Shipment__c>{ship};
        ShipmentTriggerHandler.beforeInsert(listShip);

		
		ship.Delivery_Company__c = null;
        ship.Magento_Order_Number_Searchable__c = '';
        ship.Carrier__c = 'LTL';
        ship.Carrier_Name__c = 'FedEx';
        ship.Pickup_Date_Expected__c = Date.today();
        update ship;
		Test.stopTest();
        
        ship = [SELECT Id, Magento_Order_Number_Searchable__c FROM Shipment__c WHERE Id =: ship.Id];
        so = [SELECT Id, Magento_order_No__c FROM Sales_Order__c WHERE Id =: order.Id];
        System.assertEquals(ship.Magento_Order_Number_Searchable__c, so.Magento_order_No__c);
	}
    
    @isTest 
    static void shipNotificationToAshleyTest() {
        Fideliton_Setting__c setting = new Fideliton_Setting__c();
        setting.Password__c = '12314';
        setting.UserName__c = 'Test';
        insert setting;
        Google_API__c settGoogle = new Google_API__c(Name='Google API',Key__c='AIzaSyCAmP-yM5hc67O4stT-VyzMRmDTaVYfXzQ');
        insert settGoogle;
        Dispatch_Track_Setting__c settDiscpatch = new Dispatch_Track_Setting__c();
        settDiscpatch.server__c = 'teset.com';
        insert settDiscpatch;
        
        Account acc = [SELECT ID FROM Account WHERE Name = 'TEST ACCOUNT' LIMIT 1];
        Id accRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Delivery Company').getRecordTypeId();
        acc.recordTypeId = accRecordTypeId;
        update acc;
        

        Account ac = TestUtil.createCustomerAccount(); 
        Products__c Pro = TestUtil.createConfigProduct();
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, Null, Null);
        Purchase_Order__c po = TestUtil.createpurchaseorder(so.id,'Manufacturer PO');
        
        
        
        String shipmentRecordTypeId = Shipment__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Ship Via Delivery Company').getRecordTypeId();
        
        Shipment__c shipmentToNotify =  new Shipment__c(RecordTypeId=shipmentRecordTypeId,
                               Purchase_Order__c=po.id,
                               Related_Sales_Order__c=So.id,
                               Shipment_Status__c='Draft', 
                               Delivery_Company__c = acc.ID,
                               Carrier__c = 'LTL',
                               Pickup_Date_Expected__c = Date.today()
                              );
        Test.startTest();
        	insert shipmentToNotify;
            System.assertEquals(true, [SELECT En_Route_Email__c FROM Purchase_Order__c WHERE Id = :po.id].get(0).En_Route_Email__c); 
        Test.stopTest();
    }
    
    @isTest
    static void changeSalesOrderSendGuardianTest() {
        Account acc = [SELECT ID FROM Account WHERE Name = 'TEST ACCOUNT' LIMIT 1];
        acc.recordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Delivery Company').getRecordTypeId();
        update acc;
        Account ac = TestUtil.createCustomerAccount(); 
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, Null, Null);
        so.Protection_Plan_included__c = true;
        so.Plan_code__c = 'P1PZ';
        update so;
        Purchase_Order__c po = TestUtil.createpurchaseorder(so.id,'Manufacturer PO');
        String shipmentRecordTypeId = Shipment__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Ship Via Delivery Company').getRecordTypeId();
        
        Shipment__c shipmentToChangeOrderGuardian =  new Shipment__c(RecordTypeId=shipmentRecordTypeId,
                               Purchase_Order__c=po.id,
                               Related_Sales_Order__c=So.id,
                               Shipment_Status__c='Draft', 
                               Delivery_Company__c = acc.ID,
                               Carrier__c = 'LTL',
                               Pickup_Date_Expected__c = Date.today()
                              );
        
        insert shipmentToChangeOrderGuardian;
        Test.startTest();
        	shipmentToChangeOrderGuardian.Shipment_Status__c = 'Received By Warehouse';
            update shipmentToChangeOrderGuardian;
            System.assertEquals(true, [SELECT Send_Guardian__c FROM Sales_Order__c WHERE Id = :So.id].get(0).Send_Guardian__c); 
        Test.stopTest();
    }
    
}