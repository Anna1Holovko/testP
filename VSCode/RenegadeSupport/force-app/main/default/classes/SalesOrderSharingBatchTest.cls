@isTest
private class SalesOrderSharingBatchTest {
    @TestSetup
	static void makeData(){
		User portalUSer = TestUtil.createCustomerPortalUser('delierUser@test.unit');
		portalUSer.ProfileId = [select id, name from profile  WHERE Name = 'Delivery Community Profile' LIMIT 1].Id;
        //portalUSer.UserRoleId = [SELECT Id FROM UserRole  WHERE Name LIKE '%executive%' LIMIT 1].Id;
		//portalUSer.UserRoleId = [Select Id,name From UserRole Where PortalType != 'None' Limit 1].Id;
		insert portalUSer;      
        
    }
    
    @IsTest
    static void testBatch(){
        user devUser= [SELECT id, Contact.AccountId, UserRoleId, UserRole.Name FROM User WHERE   UserRole.Name LIKE '%executive%' AND  Profile.Name = 'Delivery Community Profile' LIMIT 1 ]  ;
        
        
        Test.startTest();
        Account acc = [SELECT ID FROM Account WHERE Name = 'TEST ACCOUNT' LIMIT 1];
		Id accRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Delivery Company').getRecordTypeId();
		acc.recordTypeId = accRecordTypeId;
		update acc;
		Fideliton_Setting__c setting = new Fideliton_Setting__c();
		setting.Password__c = '12314';
		setting.UserName__c = 'Test';
		insert setting;
		Google_API__c settGoogle = new Google_API__c(Name='Google API',Key__c='AIzaSyCAmP-yM5hc67O4stT-VyzMRmDTaVYfXzQ');
		insert settGoogle;
		Dispatch_Track_Setting__c settDiscpatch = new Dispatch_Track_Setting__c();
		//settDiscpatch.api_key__c = 'asfadfsfasssdsdasd';
		settDiscpatch.server__c = 'teset.com';
		//settDiscpatch.code__c = 'aeas2';
		insert settDiscpatch;
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
		ship.Delivery_Company__c = acc.ID;								   
        Database.insert(ship);
        SalesOrderSharingBatch notif = new SalesOrderSharingBatch();
        Id batchId = Database.executeBatch(notif, 10);
        Test.stopTest();
        notif = new SalesOrderSharingBatch(Date.newInstance(2020, 12, 1));
        batchId = Database.executeBatch(notif, 10);
        
    }
}